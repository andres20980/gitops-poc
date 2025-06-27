# setup_kustomize_poc.sh v1.1.0
# This script builds the Kustomize-based structure for the GitOps PoC.
# This version adds prerequisite checks and instructions for dependencies
# like Argo CD, Argo Rollouts, and kubectl.

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# --- Step 0: Prerequisites Check ---

check_deps() {
  if ! command -v kubectl &> /dev/null; then
    echo "❌ ERROR: kubectl is not installed or not in your PATH."
    echo "Please install kubectl and configure access to your Kubernetes cluster first."
    exit 1
  fi
  echo "✅ kubectl command found."
}

cat << "EOF"

################################################################################
#                              PREREQUISITES                                   #
################################################################################

This script will generate the file structure for the GitOps PoC.
Before you can deploy these applications, you MUST ensure the following
tools are installed and configured in your Kubernetes cluster:

1. Argo CD:
   - Follow the official installation guide:
     https://argo-cd.readthedocs.io/en/stable/getting_started/

2. Argo Rollouts:
   a) Install the controller in your cluster:
      kubectl create namespace argo-rollouts
      kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

   b) (Recommended) Install the kubectl plugin for easier management:
      - macOS: brew install argoproj/tap/kubectl-argo-rollouts
      - Linux: https://argo-rollouts.readthedocs.io/en/stable/installation/#kubectl-plugin-installation

3. Carbone Service Note:
   - The 'carbone' component uses a public image from GHCR for convenience.
     In a real-world scenario, you would have a CI pipeline to build and push
     your own version of this service's container image to your registry.

Press ENTER to acknowledge and continue, or CTRL+C to cancel.
EOF

read -p ""

check_deps

# --- The rest of the script remains the same ---

echo "🚀 Starting Kustomize & Argo Rollouts PoC setup..."
echo "🧹 Cleaning up previous structure and creating new hierarchy..."

rm -rf argo-cd kustomize services
mkdir -p \
  argo-cd/apps \
  kustomize/apps/kustomiworld/overlays/dev \
  kustomize/apps/kustomispace/overlays/dev \
  kustomize/components/custom/helloworld/base \
  kustomize/components/custom/sun/base

echo "🛠️  Creating Kustomize component bases with Rollout strategies..."

# --- Helloworld Component (Canary) ---
tee kustomize/components/custom/helloworld/base/kustomization.yaml > /dev/null <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - rollout.yaml
  - service.yaml
  - service-canary.yaml
EOF
tee kustomize/components/custom/helloworld/base/rollout.yaml > /dev/null <<'EOF'
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
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - rollout.yaml
  - service.yaml
  - service-preview.yaml
EOF
tee kustomize/components/custom/sun/base/rollout.yaml > /dev/null <<'EOF'
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

echo "📦 Composing applications using Kustomize bases and overlays..."

# --- kustomiworld App ---
tee kustomize/apps/kustomiworld/base/kustomization.yaml > /dev/null <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../../components/custom/helloworld/base
EOF
tee kustomize/apps/kustomiworld/overlays/dev/kustomization.yaml > /dev/null <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
bases:
  - ../../base
namespace: kustomiworld-dev
patches:
- patch: |-
    - op: add
      path: /spec/template/metadata/labels/rollout-timestamp
      value: "2025-06-27T10-40-00Z"
  target:
    kind: Rollout
    name: helloworld
EOF

# --- kustomispace App ---
tee kustomize/apps/kustomispace/base/kustomization.yaml > /dev/null <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../../components/custom/sun/base
EOF
tee kustomize/apps/kustomispace/overlays/dev/kustomization.yaml > /dev/null <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
bases:
  - ../../base
namespace: kustomispace-dev
patches:
- patch: |-
    - op: add
      path: /spec/template/metadata/labels/rollout-timestamp
      value: "2025-06-27T10-40-00Z"
  target:
    kind: Rollout
    name: sun
EOF

echo "🎯 Creating Argo CD Application definitions for Kustomize..."

tee argo-cd/apps/app-kustomiworld-dev.yaml > /dev/null <<'EOF'
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
echo "1. Verify that all prerequisites (Argo CD, Rollouts) are running in your cluster."
echo "2. Review and commit all the generated files."
echo "3. IMPORTANT: Edit the 'repoURL' in the Argo CD YAML files to point to your repository."
echo "4. Apply the Argo CD applications: kubectl apply -f argo-cd/apps/"