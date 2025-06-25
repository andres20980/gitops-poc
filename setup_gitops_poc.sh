# setup_multi_app_poc.sh v2.0.0
# This script creates a sophisticated multi-app, multi-component GitOps structure.
# It uses Helm for component packaging, Kustomize for app composition and environment
# configuration, and a dedicated Argo CD directory for the App-of-Apps pattern.
# WARNING: This will delete previous directories to start clean.

echo "🚀 Starting Multi-App, Multi-Component GitOps PoC setup..."

# --- Step 1: Clean up old structure and create the new one ---
echo ">> Deleting old structure and creating new directories..."
rm -rf apps components clusters environments argo-cd
mkdir -p argo-cd/apps-of-apps \
         components/helloworld-chart/templates \
         components/byebyeworld-chart/templates \
         components/moon-chart/templates \
         components/sun-chart/templates \
         apps/world \
         apps/space \
         environments/dev/world \
         environments/dev/space \
         environments/pre/world \
         environments/pre/space \
         environments/pro/world \
         environments/pro/space

# --- Step 2: Create reusable Helm Charts for each component ---
echo ">> Creating reusable Helm charts for all components..."

# Function to create a simple Helm chart
create_chart() {
  CHART_NAME=$1
  CHART_PATH="components/${CHART_NAME}-chart"
  cat <<EOF > "${CHART_PATH}/Chart.yaml"
apiVersion: v2
name: ${CHART_NAME}-chart
description: A Helm chart for the ${CHART_NAME} component
type: application
version: 0.1.0
appVersion: "1.0.0"
EOF

  cat <<EOF > "${CHART_PATH}/values.yaml"
replicaCount: 1
image:
  repository: nginxdemos/hello
  tag: "plain-text"
service:
  port: 80
EOF

  cat <<EOF > "${CHART_PATH}/templates/deployment.yaml"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${CHART_NAME}-deployment
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: ${CHART_NAME}
  template:
    metadata:
      labels:
        app: ${CHART_NAME}
    spec:
      containers:
        - name: ${CHART_NAME}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          ports:
            - containerPort: 80
EOF

  cat <<EOF > "${CHART_PATH}/templates/service.yaml"
apiVersion: v1
kind: Service
metadata:
  name: ${CHART_NAME}-service
spec:
  ports:
    - port: {{ .Values.service.port }}
      targetPort: 80
  selector:
    app: ${CHART_NAME}
EOF
}

create_chart "helloworld"
create_chart "byebyeworld"
create_chart "moon"
create_chart "sun"

# --- Step 3: Create Application Compositions in 'apps/' ---
echo ">> Creating application compositions (grouping components)..."

# App 'world' composition
cat <<'EOF' > apps/world/kustomization.yaml
# apps/world/kustomization.yaml v1.0.0
# Defines the 'world' application by composing multiple component charts.
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../components/helloworld-chart
  - ../../components/byebyeworld-chart
  - ../../components/moon-chart
EOF

# App 'space' composition
cat <<'EOF' > apps/space/kustomization.yaml
# apps/space/kustomization.yaml v1.0.0
# Defines the 'space' application. Note it reuses the 'moon' component.
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../components/sun-chart
  - ../../components/moon-chart
EOF

# --- Step 4: Create Environment Overlays in 'environments/' ---
echo ">> Creating environment-specific overlays..."

# Function to create an environment overlay for an app
create_env_overlay() {
  ENV=$1 # dev, pre, pro
  APP=$2 # world, space
  REPLICAS=$3

  ENV_PATH="environments/${ENV}/${APP}"
  NAMESPACE="${APP}-${ENV}"

  # Kustomization file for the environment-app combination
  cat <<EOF > "${ENV_PATH}/kustomization.yaml"
# environments/${ENV}/${APP}/kustomization.yaml v1.0.0
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: ${NAMESPACE}
resources:
  - ../../../apps/${APP} # Inherit from the app composition

# Apply a patch to all deployments within this app for this environment
patches:
  - path: patch-replicas.yaml
EOF

  # Patch file for the environment-app combination
  cat <<EOF > "${ENV_PATH}/patch-replicas.yaml"
# environments/${ENV}/${APP}/patch-replicas.yaml v1.0.0
# Generic patch that sets the replica count. Kustomize will apply it
# to all Deployment resources found.
apiVersion: apps/v1
kind: Deployment
metadata:
  name: not-important # Kustomize ignores this and uses the resource's name
spec:
  replicas: ${REPLICAS}
EOF
}

# Create overlays for all env/app combinations
create_env_overlay "dev" "world" 1
create_env_overlay "dev" "space" 1
create_env_overlay "pre" "world" 3
create_env_overlay "pre" "space" 2
create_env_overlay "pro" "world" 5
create_env_overlay "pro" "space" 4

# --- Step 5: Create the Argo CD App-of-Apps definitions ---
echo ">> Creating Argo CD App-of-Apps definitions..."

# Using an ApplicationSet for DEV to automatically find and deploy all apps for that environment
cat <<'EOF' > argo-cd/apps-of-apps/appset-dev-environment.yaml
# argo-cd/apps-of-apps/appset-dev-environment.yaml v1.0.0
# This ApplicationSet will automatically discover and create Argo CD Applications
# for every app defined in the 'environments/dev' directory.
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: dev-environment
  namespace: argocd
spec:
  generators:
  - git:
      repoURL: https://github.com/andres20980/gitops-poc.git # IMPORTANT: VERIFY YOUR REPO URL
      revision: HEAD
      directories:
      - path: environments/dev/* # Discover every subdirectory in environments/dev
  template:
    metadata:
      name: '{{path.basename}}-dev' # e.g., 'world-dev', 'space-dev'
    spec:
      project: default
      source:
        repoURL: https://github.com/andres20980/gitops-poc.git # IMPORTANT: VERIFY YOUR REPO URL
        targetRevision: HEAD
        path: '{{path}}' # The path discovered by the generator (e.g., environments/dev/world)
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{path.basename}}-dev' # Deploy to a dedicated namespace
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
EOF


echo "✅ Multi-App setup complete!"
echo "➡️ Next steps: "
echo "1. VERY IMPORTANT: Verify the repoURL in argo-cd/apps-of-apps/appset-dev-environment.yaml (it appears twice!)"
echo "2. Add, commit, and push all files to your Git repository."
echo "3. Apply the DEV ApplicationSet to deploy everything for the dev environment:"
echo "   kubectl apply -f argo-cd/apps-of-apps/appset-dev-environment.yaml"