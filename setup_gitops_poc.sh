# setup_multi_env_poc.sh v1.0.0
# This script creates a multi-environment GitOps structure using Kustomize and Helm.
# It will delete previous directories (apps, components, clusters) to start clean.

echo "🚀 Starting Multi-Environment GitOps PoC setup..."

# --- Step 1: Clean up old directories and create the new structure ---
echo ">> Deleting old structure and creating new directories..."
rm -rf apps components clusters
mkdir -p apps/dev apps/pre apps/pro \
         base/helloworld-chart/templates \
         environments/base \
         environments/dev \
         environments/pre \
         environments/pro

# --- Step 2: Create a reusable Helm Chart in 'base/' ---
echo ">> Creating a generic Helm chart for the helloworld app..."

# Chart.yaml
cat <<'EOF' > base/helloworld-chart/Chart.yaml
# base/helloworld-chart/Chart.yaml v1.0.0
apiVersion: v2
name: helloworld-chart
description: A Helm chart for the HelloWorld application
type: application
version: 0.1.0
appVersion: "1.0.0"
EOF

# values.yaml (The API of our chart)
cat <<'EOF' > base/helloworld-chart/values.yaml
# base/helloworld-chart/values.yaml v1.0.0
# Default values for helloworld-chart.
replicaCount: 1

image:
  repository: nginxdemos/hello
  pullPolicy: IfNotPresent
  tag: "plain-text"

service:
  type: ClusterIP
  port: 80

# Extra environment variables to inject into the container
envVars: []
#  - name: "ENV_NAME"
#    value: "development"
EOF

# deployment.yaml template
cat <<'EOF' > base/helloworld-chart/templates/deployment.yaml
# base/helloworld-chart/templates/deployment.yaml v1.0.0
apiVersion: apps/v1
kind: Deployment
metadata:
  name: helloworld-deployment
  labels:
    app: helloworld
spec:
  replicas: {{ .Values.replicaCount }}
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
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - containerPort: 80
          env: {{- toYaml .Values.envVars | nindent 12 }}
EOF

# service.yaml template
cat <<'EOF' > base/helloworld-chart/templates/service.yaml
# base/helloworld-chart/templates/service.yaml v1.0.0
apiVersion: v1
kind: Service
metadata:
  name: helloworld-service
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: 80
      protocol: TCP
  selector:
    app: helloworld
EOF

# --- Step 3: Create Kustomize configurations for each environment ---
echo ">> Creating Kustomize overlays for dev, pre, and pro..."

# Kustomize Base (common for all environments)
cat <<'EOF' > environments/base/kustomization.yaml
# environments/base/kustomization.yaml v1.0.0
# This is the Kustomize base. It renders the Helm chart with default values.
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: helloworld-dev # This will be overridden by each environment
helmCharts:
  - name: helloworld-chart
    releaseName: helloworld
    version: 0.1.0
    repo: "https://some-repo.com" # This is unused as we use 'path' but required by the schema
    path: ../../base/helloworld-chart
    # You can include a default values file if needed, e.g.:
    # valuesFile: values.yaml
EOF

# --- DEV Environment ---
cat <<'EOF' > environments/dev/kustomization.yaml
# environments/dev/kustomization.yaml v1.0.0
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: helloworld-dev # Specific namespace for dev
resources:
  - ../base # Inherit from the common base

patches:
  - path: patch-replicas-and-env.yaml
    target:
      kind: Deployment
      name: helloworld-deployment
EOF

cat <<'EOF' > environments/dev/patch-replicas-and-env.yaml
# environments/dev/patch-replicas-and-env.yaml v1.0.0
# Patch for DEV: 1 replica and add an environment variable
apiVersion: apps/v1
kind: Deployment
metadata:
  name: helloworld-deployment
spec:
  replicas: 1
  template:
    spec:
      containers:
        - name: helloworld
          env:
            - name: "ENVIRONMENT"
              value: "development"
EOF

# --- PRE Environment ---
cat <<'EOF' > environments/pre/kustomization.yaml
# environments/pre/kustomization.yaml v1.0.0
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: helloworld-pre
resources:
  - ../base
patches:
  - path: patch-replicas-and-env.yaml
    target:
      kind: Deployment
      name: helloworld-deployment
EOF

cat <<'EOF' > environments/pre/patch-replicas-and-env.yaml
# environments/pre/patch-replicas-and-env.yaml v1.0.0
# Patch for PRE: 3 replicas and add an environment variable
apiVersion: apps/v1
kind: Deployment
metadata:
  name: helloworld-deployment
spec:
  replicas: 3
  template:
    spec:
      containers:
        - name: helloworld
          env:
            - name: "ENVIRONMENT"
              value: "preproduction"
EOF

# --- PRO Environment ---
cat <<'EOF' > environments/pro/kustomization.yaml
# environments/pro/kustomization.yaml v1.0.0
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: helloworld-pro
resources:
  - ../base
patches:
  - path: patch-replicas-and-env.yaml
    target:
      kind: Deployment
      name: helloworld-deployment
EOF

cat <<'EOF' > environments/pro/patch-replicas-and-env.yaml
# environments/pro/patch-replicas-and-env.yaml v1.0.0
# Patch for PRO: 5 replicas and add an environment variable
apiVersion: apps/v1
kind: Deployment
metadata:
  name: helloworld-deployment
spec:
  replicas: 5
  template:
    spec:
      containers:
        - name: helloworld
          env:
            - name: "ENVIRONMENT"
              value: "production"
EOF

# --- Step 4: Create Argo CD applications to deploy each environment ---
echo ">> Creating Argo CD application definitions for each environment..."

cat <<'EOF' > apps/dev/app-helloworld-dev.yaml
# apps/dev/app-helloworld-dev.yaml v1.0.0
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: helloworld-dev
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: 'https://github.com/andres20980/gitops-poc.git' # IMPORTANT: VERIFY YOUR REPO URL
    targetRevision: HEAD
    path: environments/dev # This app points to the DEV Kustomize overlay
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: helloworld-dev # Deploy to the dev namespace
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

# You would create similar files for pre and pro in their respective directories
# cp apps/dev/app-helloworld-dev.yaml apps/pre/app-helloworld-pre.yaml
# cp apps/dev/app-helloworld-dev.yaml apps/pro/app-helloworld-pro.yaml
# ... and then edit them to change 'name', 'path', and 'namespace'.

echo "✅ Multi-Environment setup complete!"
echo "➡️ Next steps: "
echo "1. Verify the repoURL in apps/dev/app-helloworld-dev.yaml"
echo "2. Add, commit, and push all files to your Git repository."
echo "3. Apply the DEV application: kubectl apply -f apps/dev/app-helloworld-dev.yaml"