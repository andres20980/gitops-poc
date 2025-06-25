# setup_gitops_poc.sh v1.0.0
# This script creates the complete directory structure and all necessary
# manifest files for the Argo CD GitOps Proof of Concept.

echo "🚀 Starting GitOps PoC setup..."

# Step 1: Create the directory structure.
# Using -p ensures that the command doesn't fail if directories already exist.
echo ">> Creating directory structure..."
mkdir -p apps components/helloworld clusters/minikube

# Step 2: Create all the manifest files with their content.
# We use cat with a quoted 'EOF' to prevent shell expansion of variables ($)
# inside the documents, ensuring the YAML content is written literally.
echo ">> Creating manifest files..."

# --- App of Apps (Root Application) ---
cat <<'EOF' > apps/app-of-apps.yaml
# apps/app-of-apps.yaml v1.0.0
# This is the root application, also known as the "App of Apps".
# It manages all other applications in the specified path.
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-of-apps
  namespace: argocd
spec:
  project: default
  source:
    # IMPORTANT: This URL is based on your previous input. Verify it is correct.
    repoURL: 'https://github.com/andres20980/gitops-poc.git'
    targetRevision: HEAD
    path: clusters/minikube # This points to the directory containing our cluster-specific app definitions.
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

# --- HelloWorld Application Definition for Minikube Cluster ---
cat <<'EOF' > clusters/minikube/helloworld-app.yaml
# clusters/minikube/helloworld-app.yaml v1.0.0
# Argo CD Application definition for the helloworld app on the minikube cluster.
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: helloworld
  namespace: argocd # This application resource must live in the argocd namespace.
  finalizers:
    # The default behaviour is that when an Application CRD is deleted,
    # all of its child resources are also deleted.
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    # IMPORTANT: This URL is based on your previous input. Verify it is correct.
    repoURL: 'https://github.com/andres20980/gitops-poc.git'
    targetRevision: HEAD
    path: components/helloworld # This points to the directory with the component manifests.
  destination:
    server: 'https://kubernetes.default.svc' # This means the local cluster where Argo CD is running.
    namespace: helloworld # The namespace where the app will be deployed.
  syncPolicy:
    automated:
      prune: true # Deletes resources that are no longer defined in Git.
      selfHeal: true # Reverts any manual changes made in the cluster to match Git.
    syncOptions:
      - CreateNamespace=true # Allows Argo CD to create the namespace if it doesn't exist.
EOF

# --- HelloWorld Component: Namespace ---
cat <<'EOF' > components/helloworld/namespace.yaml
# components/helloworld/namespace.yaml v1.0.0
# Defines the namespace for the helloworld application.
apiVersion: v1
kind: Namespace
metadata:
  name: helloworld
EOF

# --- HelloWorld Component: Deployment ---
cat <<'EOF' > components/helloworld/deployment.yaml
# components/helloworld/deployment.yaml v1.0.0
# Defines the deployment for the helloworld application.
apiVersion: apps/v1
kind: Deployment
metadata:
  name: helloworld-deployment
  namespace: helloworld
  labels:
    app: helloworld
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
        image: nginxdemos/hello:plain-text # A simple image that responds to HTTP requests.
        ports:
        - containerPort: 80
EOF

# --- HelloWorld Component: Service ---
cat <<'EOF' > components/helloworld/service.yaml
# components/helloworld/service.yaml v1.0.0
# Exposes the helloworld deployment within the cluster.
apiVersion: v1
kind: Service
metadata:
  name: helloworld-service
  namespace: helloworld
spec:
  selector:
    app: helloworld
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
EOF

echo "✅ Setup complete! All directories and files have been created."
echo "➡️ Next steps: "
echo "1. Add these files to Git: git add ."
echo "2. Commit the files: git commit -m \"feat: Initial GitOps structure\""
echo "3. Push to your repository: git push --set-upstream origin main"
echo "4. Apply the root app to Argo CD: kubectl apply -f apps/app-of-apps.yaml"
