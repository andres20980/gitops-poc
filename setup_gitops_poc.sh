# setup_kustomize_poc.sh v1.0.0
# This script builds the Kustomize-based structure for the GitOps PoC,
# including components with Canary and Blue-Green rollout strategies.

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

echo "🚀 Starting Kustomize & Argo Rollouts PoC setup..."
echo "🧹 Cleaning up previous structure and creating new hierarchy..."

# Clean up old directories and the old script
rm -rf apps components clusters environments argo-cd kustomize services
rm -f setup_gitops_poc.sh

# --- Step 1: Create the main directory structure ---
echo "🏗️  Creating base directories for Kustomize and Argo CD..."
mkdir -p \
  argo-cd/apps \
  kustomize/apps/kustomiworld/overlays/dev \
  kustomize/apps/kustomispace/overlays/dev \
  kustomize/components/custom/helloworld/base \
  kustomize/components/custom/byebyeworld/base \
  kustomize/components/custom/moon/base \
  kustomize/components/custom/sun/base

# --- Step 2: Create Component Bases with Rollout Strategies ---
echo "🛠️  Creating Kustomize component bases with Rollout strategies..."

# --- Helloworld Component (Canary) ---
tee kustomize/components/custom/helloworld/base/kustomization.yaml > /dev/null <<'EOF'
# kustomize/components/custom/helloworld/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - rollout.yaml
  - service.yaml
  - service-canary.yaml
EOF

tee kustomize/components/custom/helloworld/base/rollout.yaml > /dev/null <<'EOF'
# kustomize/components/custom/helloworld/base/rollout.yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: helloworld
spec:
  replicas: 1
  selector:
    matchLabels:
      app: helloworld
  template:
    metadata:
      labels:
        app: helloworld
    spec:
      containers:
        - name: helloworld
          image: "nginxdemos/hello:plain-text"
          ports:
            - containerPort: 80
  strategy:
    canary:
      stableService: helloworld-service
      canaryService: helloworld-service-canary
      steps:
      - setWeight: 20
      - pause: {}
EOF

tee kustomize/components/custom/helloworld/base/service.yaml > /dev/null <<'EOF'
# kustomize/components/custom/helloworld/base/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: helloworld-service
spec:
  ports:
    - port: 80
      targetPort: 80
  selector:
    app: helloworld
EOF

tee kustomize/components/custom/helloworld/base/service-canary.yaml > /dev/null <<'EOF'
# kustomize/components/custom/helloworld/base/service-canary.yaml
apiVersion: v1
kind: Service
metadata:
  name: helloworld-service-canary
spec:
  ports:
    - port: 80
      targetPort: 80
  selector:
    app: helloworld
EOF

# --- Sun Component (Blue-Green) ---
tee kustomize/components/custom/sun/base/kustomization.yaml > /dev/null <<'EOF'
# kustomize/components/custom/sun/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - rollout.yaml
  - service.yaml
  - service-preview.yaml
EOF

tee kustomize/components/custom/sun/base/rollout.yaml > /dev/null <<'EOF'
# kustomize/components/custom/sun/base/rollout.yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: sun
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sun
  template:
    metadata:
      labels:
        app: sun
    spec:
      containers:
        - name: sun
          image: "nginxdemos/hello:plain-text"
          ports:
            - containerPort: 80
  strategy:
    blueGreen: 
      activeService: sun-service
      previewService: sun-service-preview
      autoPromotionEnabled: false
EOF

tee kustomize/components/custom/sun/base/service.yaml > /dev/null <<'EOF'
# kustomize/components/custom/sun/base/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: sun-service
spec:
  ports:
    - port: 80
      targetPort: 80
  selector:
    app: sun
EOF

tee kustomize/components/custom/sun/base/service-preview.yaml > /dev/null <<'EOF'
# kustomize/components/custom/sun/base/service-preview.yaml
apiVersion: v1
kind: Service
metadata:
  name: sun-service-preview
spec:
  ports:
    - port: 80
      targetPort: 80
  selector:
    app: sun
EOF

# Note: For brevity, 'byebyeworld' and 'moon' would be created similarly.
# This script focuses on demonstrating one of each pattern (Canary, Blue-Green).

# --- Step 3: Create Application Compositions (Bases and Overlays) ---
echo "📦 Composing applications using Kustomize bases and overlays..."

# --- kustomiworld App ---
tee kustomize/apps/kustomiworld/base/kustomization.yaml > /dev/null <<'EOF'
# kustomize/apps/kustomiworld/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../../components/custom/helloworld/base
  # Add other components like byebyeworld, moon here
EOF

tee kustomize/apps/kustomiworld/overlays/dev/kustomization.yaml > /dev/null <<'EOF'
# kustomize/apps/kustomiworld/overlays/dev/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
bases:
  - ../../base
namespace: kustomiworld-dev
patches:
- patch: |-
    - op: add
      path: /spec/template/metadata/labels/rollout-timestamp
      value: "2025-06-27T10-30-00Z"
  target:
    kind: Rollout
    name: helloworld
EOF

# --- kustomispace App ---
tee kustomize/apps/kustomispace/base/kustomization.yaml > /dev/null <<'EOF'
# kustomize/apps/kustomispace/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../../components/custom/sun/base
  # Add other components like moon here
EOF

tee kustomize/apps/kustomispace/overlays/dev/kustomization.yaml > /dev/null <<'EOF'
# kustomize/apps/kustomispace/overlays/dev/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
bases:
  - ../../base
namespace: kustomispace-dev
patches:
- patch: |-
    - op: add
      path: /spec/template/metadata/labels/rollout-timestamp
      value: "2025-06-27T10-30-00Z"
  target:
    kind: Rollout
    name: sun
EOF

# --- Step 4: Create Argo CD Application Definitions ---
echo "🎯 Creating Argo CD Application definitions for Kustomize..."

tee argo-cd/apps/app-kustomiworld-dev.yaml > /dev/null <<'EOF'
# argo-cd/apps/app-kustomiworld-dev.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: kustomiworld-dev
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/andres20980/gitops-poc.git # EDIT THIS URL
    targetRevision: HEAD
    path: kustomize/apps/kustomiworld/overlays/dev
  destination:
    server: https://kubernetes.default.svc
    namespace: kustomiworld-dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

tee argo-cd/apps/app-kustomispace-dev.yaml > /dev/null <<'EOF'
# argo-cd/apps/app-kustomispace-dev.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: kustomispace-dev
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/andres20980/gitops-poc.git # EDIT THIS URL
    targetRevision: HEAD
    path: kustomize/apps/kustomispace/overlays/dev
  destination:
    server: https://kubernetes.default.svc
    namespace: kustomispace-dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

echo ""
echo "✅ Kustomize PoC setup completed successfully."
echo "➡️  NEXT STEPS:"
echo "1. Review and commit all the generated files."
echo "2. IMPORTANT: Edit the 'repoURL' in the Argo CD YAML files to point to your repository."
echo "3. Apply the Argo CD applications: kubectl apply -f argo-cd/apps/"