# setup_multi_app_poc.sh v3.1.0
# This script creates the definitive multi-app, multi-component GitOps structure.
# This version fixes a YAML syntax error in the ApplicationSet template.
# WARNING: This will delete previous directories to start clean.

echo "🚀 Starting Definitive Multi-App GitOps PoC setup..."

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

create_component() {
  COMPONENT_NAME=$1
  CHART_PATH="components/${COMPONENT_NAME}-chart"
  # Create Helm Chart.yaml
  cat <<EOF > "${CHART_PATH}/Chart.yaml"
apiVersion: v2
name: ${COMPONENT_NAME}-chart
description: A Helm chart for the ${COMPONENT_NAME} component
type: application
version: 0.1.0
appVersion: "1.0.0"
EOF
  # Create Helm values.yaml
  cat <<EOF > "${CHART_PATH}/values.yaml"
replicaCount: 1
image:
  repository: nginxdemos/hello
  tag: "plain-text"
service:
  port: 80
EOF
  # Create Helm deployment template
  cat <<EOF > "${CHART_PATH}/templates/deployment.yaml"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${COMPONENT_NAME}-deployment
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: ${COMPONENT_NAME}
  template:
    metadata:
      labels:
        app: ${COMPONENT_NAME}
    spec:
      containers:
        - name: ${COMPONENT_NAME}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          ports:
            - containerPort: 80
EOF
  # Create Helm service template
  cat <<EOF > "${CHART_PATH}/templates/service.yaml"
apiVersion: v1
kind: Service
metadata:
  name: ${COMPONENT_NAME}-service
spec:
  ports:
    - port: {{ .Values.service.port }}
      targetPort: 80
  selector:
    app: ${COMPONENT_NAME}
EOF
  # Create a kustomization.yaml inside the chart directory
  cat <<EOF > "${CHART_PATH}/kustomization.yaml"
# components/${COMPONENT_NAME}-chart/kustomization.yaml v1.0.0
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
helmCharts:
- name: ${COMPONENT_NAME}-chart
  releaseName: ${COMPONENT_NAME}
  version: 0.1.0
EOF
}
create_component "helloworld"; create_component "byebyeworld"; create_component "moon"; create_component "sun"

# --- Step 3: Create Application Compositions in 'apps/' ---
echo ">> Creating application compositions (grouping components)..."
cat <<'EOF' > apps/world/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../components/helloworld-chart
  - ../../components/byebyeworld-chart
  - ../../components/moon-chart
EOF
cat <<'EOF' > apps/space/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../components/sun-chart
  - ../../components/moon-chart
EOF

# --- Step 4: Create Environment Overlays ---
echo ">> Creating environment-specific overlays..."
create_env_overlay() {
  ENV=$1; APP=$2; REPLICAS=$3;
  ENV_PATH="environments/${ENV}/${APP}"; NAMESPACE="${APP}-${ENV}";
  cat <<EOF > "${ENV_PATH}/kustomization.yaml"
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: ${NAMESPACE}
resources:
  - ../../../apps/${APP}
patches:
  - path: patch-replicas.yaml
EOF
  cat <<EOF > "${ENV_PATH}/patch-replicas.yaml"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: not-important
spec:
  replicas: ${REPLICAS}
EOF
}
create_env_overlay "dev" "world" 1; create_env_overlay "dev" "space" 1;
create_env_overlay "pre" "world" 3; create_env_overlay "pre" "space" 2;
create_env_overlay "pro" "world" 5; create_env_overlay "pro" "space" 4;

# --- Step 5: Create the Argo CD App-of-Apps definitions ---
echo ">> Creating Argo CD application definitions..."
cat <<'EOF' > argo-cd/apps-of-apps/appset-dev-environment.yaml
# argo-cd/apps-of-apps/appset-dev-environment.yaml v3.1.0
# This ApplicationSet uses a list generator and has CORRECT YAML syntax.
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: dev-environment
  namespace: argocd
spec:
  generators:
  - list:
      elements:
      - name: world
      - name: space
  template:
    metadata:
      name: '{{name}}-dev'
    spec:
      project: default
      source:
        repoURL: https://github.com/andres20980/gitops-poc.git # IMPORTANT: VERIFY YOUR REPO URL
        targetRevision: HEAD
        path: 'environments/dev/{{name}}'
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{name}}-dev'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
EOF

echo "✅ Definitive Multi-App setup complete with corrected syntax!"
echo "➡️ Next steps: "
echo "1. VERY IMPORTANT: Verify the repoURL in argo-cd/apps-of-apps/appset-dev-environment.yaml"
echo "2. Add, commit, and push all files to your Git repository."
echo "3. Run kubectl apply -f argo-cd/apps-of-apps/appset-dev-environment.yaml"