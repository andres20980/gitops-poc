# setup_gitops_poc.sh v6.0.0
# This is the final, definitive script using a robust Helm Umbrella Chart pattern.
# This approach avoids the complexities and errors from the Kustomize+Helm integration.
# WARNING: This will delete previous directories to start clean.

echo "🚀 Starting definitive setup using Helm Umbrella Charts..."
echo "🧹 Cleaning up previous structure and creating new hierarchy..."

rm -rf apps components clusters environments argo-cd

mkdir -p \
  argo-cd/apps-of-apps \
  components/{helloworld-chart,byebyeworld-chart,moon-chart,sun-chart}/templates \
  apps/{world,space}

# --- Step 1: Create reusable Helm Charts for each component (as before) ---
echo "🛠️ Creating reusable component Helm Charts..."

create_component_chart() {
  local COMPONENT=$1
  local CHART_PATH="components/${COMPONENT}-chart"
  mkdir -p "${CHART_PATH}/templates"
  tee "${CHART_PATH}/Chart.yaml" > /dev/null <<EOF
apiVersion: v2
name: ${COMPONENT}-chart
description: Helm chart for the ${COMPONENT} component.
type: application
version: 0.1.0
appVersion: "1.0.0"
EOF
  tee "${CHART_PATH}/values.yaml" > /dev/null <<EOF
replicaCount: 1
image:
  repository: nginxdemos/hello
  tag: "plain-text"
service:
  port: 80
EOF
  tee "${CHART_PATH}/templates/deployment.yaml" > /dev/null <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-${COMPONENT}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Release.Name }}-${COMPONENT}
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}-${COMPONENT}
    spec:
      containers:
        - name: ${COMPONENT}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          ports:
            - containerPort: 80
EOF
  tee "${CHART_PATH}/templates/service.yaml" > /dev/null <<EOF
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}-${COMPONENT}-service
spec:
  ports:
    - port: {{ .Values.service.port }}
      targetPort: 80
  selector:
    app: {{ .Release.Name }}-${COMPONENT}
EOF
}
create_component_chart "helloworld"
create_component_chart "byebyeworld"
create_component_chart "moon"
create_component_chart "sun"

# --- Step 2: Create the Umbrella Charts for 'world' and 'space' apps ---
echo "📦 Creating Umbrella Charts to compose applications..."

# World App Umbrella Chart
tee apps/world/Chart.yaml > /dev/null <<'EOF'
# apps/world/Chart.yaml
apiVersion: v2
name: world-app
description: An umbrella chart for the World application.
type: application
version: 0.1.0
appVersion: "1.0"
dependencies:
  - name: helloworld-chart
    version: "0.1.0"
    repository: "file://../../components/helloworld-chart"
  - name: byebyeworld-chart
    version: "0.1.0"
    repository: "file://../../components/byebyeworld-chart"
  - name: moon-chart
    version: "0.1.0"
    repository: "file://../../components/moon-chart"
EOF

# World App Values (to override sub-chart values)
tee apps/world/values.yaml > /dev/null <<'EOF'
# apps/world/values.yaml
# Per-component values for the 'world' application
helloworld-chart:
  replicaCount: 1
byebyeworld-chart:
  replicaCount: 1
moon-chart:
  replicaCount: 1
EOF

# Space App Umbrella Chart
tee apps/space/Chart.yaml > /dev/null <<'EOF'
# apps/space/Chart.yaml
apiVersion: v2
name: space-app
description: An umbrella chart for the Space application.
type: application
version: 0.1.0
appVersion: "1.0"
dependencies:
  - name: sun-chart
    version: "0.1.0"
    repository: "file://../../components/sun-chart"
  - name: moon-chart # Reusing the moon component
    version: "0.1.0"
    repository: "file://../../components/moon-chart"
EOF

# Space App Values
tee apps/space/values.yaml > /dev/null <<'EOF'
# apps/space/values.yaml
sun-chart:
  replicaCount: 2
moon-chart:
  replicaCount: 2
EOF

# --- Step 3: Create the Argo CD Application ---
# We will create one Argo CD App per application, which is simpler to manage.
echo "🎯 Creating Argo CD Application definitions..."

tee argo-cd/apps-of-apps/app-world-dev.yaml > /dev/null <<'EOF'
# argo-cd/apps-of-apps/app-world-dev.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: world-dev
  namespace: argocd
spec:
  project: default
  source:
    # This now points directly to the Helm Umbrella chart
    repoURL: https://github.com/andres20980/gitops-poc.git # ⚠️ VERIFY THIS URL
    targetRevision: HEAD
    path: apps/world
    helm:
      # Here you could specify a different values file for each environment
      # For now, we use the default values.yaml
      valueFiles:
        - values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: world-dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

tee argo-cd/apps-of-apps/app-space-dev.yaml > /dev/null <<'EOF'
# argo-cd/apps-of-apps/app-space-dev.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: space-dev
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/andres20980/gitops-poc.git # ⚠️ VERIFY THIS URL
    targetRevision: HEAD
    path: apps/space
    helm:
      valueFiles:
        - values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: space-dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

echo "✅ Setup completed successfully using the Umbrella Chart pattern."
echo "➡️ NEXT STEPS:"
echo "1. Verify the repoURL in the Argo CD YAML files."
echo "2. Run 'helm dependency build' in 'apps/world' and 'apps/space' directories."
echo "   Example: cd apps/world && helm dependency build && cd ../../"
echo "3. Add, commit, and push the repository files (including the 'charts/' directories created by helm)."
echo "4. Run: kubectl apply -f argo-cd/apps-of-apps/"