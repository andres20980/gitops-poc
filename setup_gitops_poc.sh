# setup_gitops_poc.sh v5.0.0
# This is the final, definitive, and correct script.
# It creates a multi-app, multi-component GitOps structure.
# The key fix is removing the unnecessary kustomization.yaml from within the component charts.

echo "🚀 Starting definitive multi-app GitOps PoC setup..."
echo "🧹 Cleaning up previous structure and creating new hierarchy..."

rm -rf apps components clusters environments argo-cd

mkdir -p \
  argo-cd/apps-of-apps \
  components/{helloworld-chart,byebyeworld-chart,moon-chart,sun-chart}/templates \
  apps/{world,space} \
  environments/{dev,pre,pro}/{world,space}

echo "🛠️ Creating reusable component Helm Charts..."

create_component() {
  local COMPONENT=$1
  local CHART_PATH="components/${COMPONENT}-chart"

  # Create Chart.yaml for the component
  tee "${CHART_PATH}/Chart.yaml" > /dev/null <<EOF
# components/${COMPONENT}-chart/Chart.yaml
apiVersion: v2
name: ${COMPONENT}-chart
description: Helm chart for ${COMPONENT}
type: application
version: 0.1.0
appVersion: "1.0.0"
EOF

  # Create values.yaml for the component
  tee "${CHART_PATH}/values.yaml" > /dev/null <<EOF
# components/${COMPONENT}-chart/values.yaml
replicaCount: 1
image:
  repository: nginxdemos/hello
  tag: "plain-text"
service:
  port: 80
EOF

  # Create deployment.yaml template for the component
  tee "${CHART_PATH}/templates/deployment.yaml" > /dev/null <<EOF
# components/${COMPONENT}-chart/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${COMPONENT}-deployment
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: ${COMPONENT}
  template:
    metadata:
      labels:
        app: ${COMPONENT}
    spec:
      containers:
        - name: ${COMPONENT}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          ports:
            - containerPort: 80
EOF

  # Create service.yaml template for the component
  tee "${CHART_PATH}/templates/service.yaml" > /dev/null <<EOF
# components/${COMPONENT}-chart/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: ${COMPONENT}-service
spec:
  ports:
    - port: {{ .Values.service.port }}
      targetPort: 80
  selector:
    app: ${COMPONENT}
EOF
  # CORRECTED: The kustomization.yaml inside the component itself was removed.
  # The global --enable-helm flag in argocd-cm handles the Helm rendering.
}

create_component "helloworld"
create_component "byebyeworld"
create_component "moon"
create_component "sun"

echo "📦 Composing applications from components..."

# This is correct: the app composition layer points to component directories.
tee apps/world/kustomization.yaml > /dev/null <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../components/helloworld-chart
  - ../../components/byebyeworld-chart
  - ../../components/moon-chart
EOF

tee apps/space/kustomization.yaml > /dev/null <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../components/sun-chart
  - ../../components/moon-chart
EOF

echo "🌍 Creating environment-specific overlays (dev, pre, pro)..."

create_env_overlay() {
  local ENV=$1; local APP=$2; local REPLICAS=$3
  local DIR="environments/${ENV}/${APP}"; local NS="${APP}-${ENV}"

  tee "${DIR}/kustomization.yaml" > /dev/null <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: ${NS}
resources:
  - ../../../apps/${APP}
patches:
  - path: patch-replicas.yaml
EOF

  tee "${DIR}/patch-replicas.yaml" > /dev/null <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: not-important
spec:
  replicas: ${REPLICAS}
EOF
}

create_env_overlay dev world 1
create_env_overlay dev space 1
create_env_overlay pre world 3
create_env_overlay pre space 2
create_env_overlay pro world 5
create_env_overlay pro space 4

echo "🎯 Creating ApplicationSet for the 'dev' environment..."

tee argo-cd/apps-of-apps/appset-dev-environment.yaml > /dev/null <<'EOF'
# argo-cd/apps-of-apps/appset-dev-environment.yaml v5.0.0
# This is the final and correct ApplicationSet definition.
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
        repoURL: https://github.com/andres20980/gitops-poc.git # ⚠️ VERIFY THIS URL
        targetRevision: HEAD
        path: environments/dev/{{name}}
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

echo "✅ Setup completed successfully."
echo "➡️ NEXT STEPS:"
echo "1. Ensure argocd-cm is patched with '--enable-helm' and repo-server was restarted."
echo "2. Verify the repoURL in the ApplicationSet YAML file."
echo "3. Add, commit, and push the repository files."
echo "4. Run:"
echo "   kubectl apply -f argo-cd/apps-of-apps/appset-dev-environment.yaml"