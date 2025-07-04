#!/bin/bash

echo "### Starting Automated GitOps PoC Setup (Clean & Recreate) ###"
echo " "

# --- Cleanup Phase ---
echo "INFO: Cleaning up old PoC structure..."

echo "INFO: Removing old kustomize configurations..."
rm -rf kustomize/*

echo "INFO: Removing old Argo CD configurations..."
rm -rf argo-cd/*

echo "INFO: Removing helm-cronjob-base (not needed in simplified PoC)..."
rm -rf helm-cronjob-base

echo "INFO: Removing any residual .bak files..."
find . -type f -name "*.bak" -delete

echo "SUCCESS: Cleanup complete."
echo " "

# --- Directory Creation Phase ---
echo "INFO: Creating new directory structure..."

mkdir -p kustomize/components/carbone/base
mkdir -p kustomize/components/helloworld/base
mkdir -p kustomize/components/moon/base
mkdir -p kustomize/components/sun/base
mkdir -p kustomize/components/world/base # Used as a component for 'space' app

mkdir -p kustomize/apps/space/base
mkdir -p kustomize/apps/space/overlays/dev
mkdir -p kustomize/apps/space/overlays/pre

mkdir -p kustomize/apps/world/base
mkdir -p kustomize/apps/world/overlays/dev
mkdir -p kustomize/apps/world/overlays/pre

mkdir -p argo-cd/apps/dev
mkdir -p argo-cd/apps/pre
mkdir -p argo-cd/projects

echo "SUCCESS: Directory structure created."
echo " "

# --- File Generation Phase ---
echo "INFO: Generating kustomize/components files..."

# carbone component
cat > kustomize/components/carbone/base/kustomization.yaml << 'EOF'
# kustomize/components/carbone/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - helmrelease.yaml

configMapGenerator:
  - name: carbone-values
    files:
      - values.yaml

patches:
  - target:
      group: helm.toolkit.fluxcd.io
      version: v2beta1
      kind: HelmRelease
      name: carbone
    patch: |-
      - op: replace
        path: /spec/chart/spec/chart
        value: ./helm-base
      - op: replace
        path: /spec/chart/spec/sourceRef/kind
        value: GitRepository
      - op: replace
        path: /spec/chart/spec/sourceRef/name
        value: gitops-poc-repo # Replace with your actual Flux GitRepository name if different
      - op: replace
        path: /spec/valuesFrom/0/sourceRef/name
        value: carbone-values
EOF

cat > kustomize/components/carbone/base/helmrelease.yaml << 'EOF'
# kustomize/components/carbone/base/helmrelease.yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: carbone # This name will be prefixed/suffixed by Kustomize higher up
spec:
  interval: 1m
  chart:
    spec:
      chart: placeholder # This will be patched
      sourceRef:
        kind: GitRepository
        name: placeholder # This will be patched
  valuesFrom:
    - kind: ConfigMap
      name: placeholder # This will be patched
EOF

cat > kustomize/components/carbone/base/values.yaml << 'EOF'
# kustomize/components/carbone/base/values.yaml
serviceName: carbone
image: andres20980/carbone-ee-docker:latest
replicas: 1
service:
  type: ClusterIP
  port: 80
ingress:
  enabled: false
EOF

# helloworld component
cat > kustomize/components/helloworld/base/kustomization.yaml << 'EOF'
# kustomize/components/helloworld/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - helmrelease.yaml

configMapGenerator:
  - name: helloworld-values
    files:
      - values.yaml

patches:
  - target:
      group: helm.toolkit.fluxcd.io
      version: v2beta1
      kind: HelmRelease
      name: helloworld
    patch: |-
      - op: replace
        path: /spec/chart/spec/chart
        value: ./helm-base
      - op: replace
        path: /spec/chart/spec/sourceRef/kind
        value: GitRepository
      - op: replace
        path: /spec/chart/spec/sourceRef/name
        value: gitops-poc-repo # Replace with your actual Flux GitRepository name if different
      - op: replace
        path: /spec/valuesFrom/0/sourceRef/name
        value: helloworld-values
EOF

cat > kustomize/components/helloworld/base/helmrelease.yaml << 'EOF'
# kustomize/components/helloworld/base/helmrelease.yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: helloworld
spec:
  interval: 1m
  chart:
    spec:
      chart: placeholder
      sourceRef:
        kind: GitRepository
        name: placeholder
  valuesFrom:
    - kind: ConfigMap
      name: placeholder
EOF

cat > kustomize/components/helloworld/base/values.yaml << 'EOF'
# kustomize/components/helloworld/base/values.yaml
serviceName: helloworld
image: andres20980/helloworld-app:latest
replicas: 1
service:
  type: ClusterIP
  port: 80
ingress:
  enabled: false
EOF

# moon component
cat > kustomize/components/moon/base/kustomization.yaml << 'EOF'
# kustomize/components/moon/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - helmrelease.yaml

configMapGenerator:
  - name: moon-values
    files:
      - values.yaml

patches:
  - target:
      group: helm.toolkit.fluxcd.io
      version: v2beta1
      kind: HelmRelease
      name: moon
    patch: |-
      - op: replace
        path: /spec/chart/spec/chart
        value: ./helm-base
      - op: replace
        path: /spec/chart/spec/sourceRef/kind
        value: GitRepository
      - op: replace
        path: /spec/chart/spec/sourceRef/name
        value: gitops-poc-repo # Replace with your actual Flux GitRepository name if different
      - op: replace
        path: /spec/valuesFrom/0/sourceRef/name
        value: moon-values
EOF

cat > kustomize/components/moon/base/helmrelease.yaml << 'EOF'
# kustomize/components/moon/base/helmrelease.yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: moon
spec:
  interval: 1m
  chart:
    spec:
      chart: placeholder
      sourceRef:
        kind: GitRepository
        name: placeholder
  valuesFrom:
    - kind: ConfigMap
      name: placeholder
EOF

cat > kustomize/components/moon/base/values.yaml << 'EOF'
# kustomize/components/moon/base/values.yaml
serviceName: moon
image: your-repo/moon-service:latest # Placeholder for moon image
replicas: 1
service:
  type: ClusterIP
  port: 80
ingress:
  enabled: false
EOF

# sun component
cat > kustomize/components/sun/base/kustomization.yaml << 'EOF'
# kustomize/components/sun/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - helmrelease.yaml

configMapGenerator:
  - name: sun-values
    files:
      - values.yaml

patches:
  - target:
      group: helm.toolkit.fluxcd.io
      version: v2beta1
      kind: HelmRelease
      name: sun
    patch: |-
      - op: replace
        path: /spec/chart/spec/chart
        value: ./helm-base
      - op: replace
        path: /spec/chart/spec/sourceRef/kind
        value: GitRepository
      - op: replace
        path: /spec/chart/spec/sourceRef/name
        value: gitops-poc-repo # Replace with your actual Flux GitRepository name if different
      - op: replace
        path: /spec/valuesFrom/0/sourceRef/name
        value: sun-values
EOF

cat > kustomize/components/sun/base/helmrelease.yaml << 'EOF'
# kustomize/components/sun/base/helmrelease.yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: sun
spec:
  interval: 1m
  chart:
    spec:
      chart: placeholder
      sourceRef:
        kind: GitRepository
        name: placeholder
  valuesFrom:
    - kind: ConfigMap
      name: placeholder
EOF

cat > kustomize/components/sun/base/values.yaml << 'EOF'
# kustomize/components/sun/base/values.yaml
serviceName: sun
image: your-repo/sun-service:latest # Placeholder for sun image
replicas: 1
service:
  type: ClusterIP
  port: 80
ingress:
  enabled: false
EOF

# world component (as a sub-component for 'space' application)
cat > kustomize/components/world/base/kustomization.yaml << 'EOF'
# kustomize/components/world/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - helmrelease.yaml

configMapGenerator:
  - name: world-values
    files:
      - values.yaml

patches:
  - target:
      group: helm.toolkit.fluxcd.io
      version: v2beta1
      kind: HelmRelease
      name: world
    patch: |-
      - op: replace
        path: /spec/chart/spec/chart
        value: ./helm-base
      - op: replace
        path: /spec/chart/spec/sourceRef/kind
        value: GitRepository
      - op: replace
        path: /spec/chart/spec/sourceRef/name
        value: gitops-poc-repo # Replace with your actual Flux GitRepository name if different
      - op: replace
        path: /spec/valuesFrom/0/sourceRef/name
        value: world-values
EOF

cat > kustomize/components/world/base/helmrelease.yaml << 'EOF'
# kustomize/components/world/base/helmrelease.yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: world
spec:
  interval: 1m
  chart:
    spec:
      chart: placeholder
      sourceRef:
        kind: GitRepository
        name: placeholder
  valuesFrom:
    - kind: ConfigMap
      name: placeholder
EOF

cat > kustomize/components/world/base/values.yaml << 'EOF'
# kustomize/components/world/base/values.yaml
serviceName: world
image: your-repo/world-service:latest # Placeholder for world image
replicas: 1
service:
  type: ClusterIP
  port: 80
ingress:
  enabled: false
EOF

echo "INFO: Generating kustomize/apps files..."

# space application base
cat > kustomize/apps/space/base/kustomization.yaml << 'EOF'
# kustomize/apps/space/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../../components/world/base
  - ../../../components/sun/base
  - ../../../components/moon/base
  - ../../../components/carbone/base

commonLabels:
  app: space-app

patches:
  - target:
      kind: HelmRelease
      name: world
    patch: |-
      - op: replace
        path: /metadata/name
        value: space-world
  - target:
      kind: HelmRelease
      name: sun
    patch: |-
      - op: replace
        path: /metadata/name
        value: space-sun
  - target:
      kind: HelmRelease
      name: moon
    patch: |-
      - op: replace
        path: /metadata/name
        value: space-moon
  - target:
      kind: HelmRelease
      name: carbone
    patch: |-
      - op: replace
        path: /metadata/name
        value: space-carbone
EOF

# space application overlays
cat > kustomize/apps/space/overlays/dev/kustomization.yaml << 'EOF'
# kustomize/apps/space/overlays/dev/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources: # Changed from 'bases' to 'resources' for future compatibility
  - ../../base

namespace: space-dev

patches:
  - target:
      kind: HelmRelease
      name: space-world
    patch: |-
      - op: replace
        path: /spec/values/ingress/enabled
        value: true
      - op: replace
        path: /spec/values/ingress/host
        value: world-dev.space.example.com
EOF

cat > kustomize/apps/space/overlays/pre/kustomization.yaml << 'EOF'
# kustomize/apps/space/overlays/pre/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources: # Changed from 'bases' to 'resources' for future compatibility
  - ../../base

namespace: space-pre

patches:
  - target:
      kind: HelmRelease
      name: space-world
    patch: |-
      - op: replace
        path: /spec/values/ingress/enabled
        value: true
      - op: replace
        path: /spec/values/ingress/host
        value: world-pre.space.example.com
EOF

# world application base
cat > kustomize/apps/world/base/kustomization.yaml << 'EOF'
# kustomize/apps/world/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../../components/helloworld/base
  - ../../../components/moon/base
  - ../../../components/carbone/base

commonLabels:
  app: world-app

patches:
  - target:
      kind: HelmRelease
      name: helloworld
    patch: |-
      - op: replace
        path: /metadata/name
        value: world-helloworld
  - target:
      kind: HelmRelease
      name: moon
    patch: |-
      - op: replace
        path: /metadata/name
        value: world-moon
  - target:
      kind: HelmRelease
      name: carbone
    patch: |-
      - op: replace
        path: /metadata/name
        value: world-carbone
EOF

# world application overlays
cat > kustomize/apps/world/overlays/dev/kustomization.yaml << 'EOF'
# kustomize/apps/world/overlays/dev/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources: # Changed from 'bases' to 'resources' for future compatibility
  - ../../base

namespace: world-dev

patches:
  - target:
      kind: HelmRelease
      name: world-helloworld
    patch: |-
      - op: replace
        path: /spec/values/ingress/enabled
        value: true
      - op: replace
        path: /spec/values/ingress/host
        value: helloworld-dev.world.example.com
EOF

cat > kustomize/apps/world/overlays/pre/kustomization.yaml << 'EOF'
# kustomize/apps/world/overlays/pre/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources: # Changed from 'bases' to 'resources' for future compatibility
  - ../../base

namespace: world-pre

patches:
  - target:
      kind: HelmRelease
      name: world-helloworld
    patch: |-
      - op: replace
        path: /spec/values/ingress/enabled
        value: true
      - op: replace
        path: /spec/values/ingress/host
        value: helloworld-pre.world.example.com
EOF

echo "INFO: Generating Argo CD project files..."

# project-dev.yaml
cat > argo-cd/projects/project-dev.yaml << 'EOF'
# argo-cd/projects/project-dev.yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: dev-project
  namespace: argocd
spec:
  description: Development Project
  sourceRepos:
  - '*'
  destinations:
  - namespace: space-dev
    server: https://kubernetes.default.svc
  - namespace: world-dev
    server: https://kubernetes.default.svc
  clusterResourceWhitelist:
  - group: '*'
    kind: '*'
  namespaceResourceWhitelist:
  - group: '*'
    kind: '*'
EOF

# project-pre.yaml
cat > argo-cd/projects/project-pre.yaml << 'EOF'
# argo-cd/projects/project-pre.yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: pre-project
  namespace: argocd
spec:
  description: Pre-production Project
  sourceRepos:
  - '*'
  destinations:
  - namespace: space-pre
    server: https://kubernetes.default.svc
  - namespace: world-pre
    server: https://kubernetes.default.svc
  clusterResourceWhitelist:
  - group: '*'
    kind: '*'
  namespaceResourceWhitelist:
  - group: '*'
    kind: '*'
EOF

echo "INFO: Generating Argo CD application files..."

# app-space-dev.yaml
cat > argo-cd/apps/dev/app-space-dev.yaml << 'EOF'
# argo-cd/apps/dev/app-space-dev.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-space-dev
  namespace: argocd
spec:
  project: dev-project
  source:
    repoURL: https://github.com/andres20980/gitops-poc.git # Replace with your repository URL
    targetRevision: HEAD
    path: kustomize/apps/space/overlays/dev
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

# app-world-dev.yaml
cat > argo-cd/apps/dev/app-world-dev.yaml << 'EOF'
# argo-cd/apps/dev/app-world-dev.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-world-dev
  namespace: argocd
spec:
  project: dev-project
  source:
    repoURL: https://github.com/andres20980/gitops-poc.git # Replace with your repository URL
    targetRevision: HEAD
    path: kustomize/apps/world/overlays/dev
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

# app-space-pre.yaml
cat > argo-cd/apps/pre/app-space-pre.yaml << 'EOF'
# argo-cd/apps/pre/app-space-pre.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-space-pre
  namespace: argocd
spec:
  project: pre-project
  source:
    repoURL: https://github.com/andres20980/gitops-poc.git # Replace with your repository URL
    targetRevision: HEAD
    path: kustomize/apps/space/overlays/pre
  destination:
    server: https://kubernetes.default.svc
    namespace: space-pre
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF

# app-world-pre.yaml
cat > argo-cd/apps/pre/app-world-pre.yaml << 'EOF'
# argo-cd/apps/pre/app-world-pre.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-world-pre
  namespace: argocd
spec:
  project: pre-project
  source:
    repoURL: https://github.com/andres20980/gitops-poc.git # Replace with your repository URL
    targetRevision: HEAD
    path: kustomize/apps/world/overlays/pre
  destination:
    server: https://kubernetes.default.svc
    namespace: world-pre
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF

echo "INFO: Updating fix-and-deploy.sh script..."

cat > fix-and-deploy.sh << 'EOF'
# fix-and-deploy.sh v1.2
# This script automates the process of fixing, deploying, and verifying the GitOps PoC.
# v1.2: Updated for simplified PoC structure (space and world apps).

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
# List of custom components to check and fix.
# Note: For this simplified structure, the 'fix_repository_files' function might not be strictly necessary
# if the generated kustomizations are correct, but it's kept for consistency.
COMPONENTS_TO_FIX=("carbone" "helloworld" "moon" "sun" "world") # Updated component list

# List of Argo CD applications to sync and check.
ARGO_APPS=("app-space-dev" "app-world-dev" "app-space-pre" "app-world-pre") # Updated app list

# --- Function to fix local repository files ---
fix_repository_files() {
  echo "INFO: Starting to fix repository files..."

  # 1. Fix the primary error: remove direct reference to 'rollout.yaml' from components.
  # This fix is less relevant with the new HelmRelease approach but kept as a safeguard.
  echo "INFO: Checking for incorrect 'rollout.yaml' references in components..."
  for component in "${COMPONENTS_TO_FIX[@]}"; do
    KUSTOMIZATION_FILE="kustomize/components/${component}/base/kustomization.yaml"
    if [ -f "$KUSTOMIZATION_FILE" ]; then
      # The '-i.bak' flag is used for macOS compatibility, creating a backup file. Use '-i' on Linux if preferred.
      sed -i.bak '/rollout.yaml/d' "$KUSTOMIZATION_FILE"
      rm -f "${KUSTOMIZATION_FILE}.bak"
    fi
  done
  echo "  - Check complete for 'rollout.yaml' references."

  # 2. Proactive fix: 'bases:' is deprecated in Kustomize. Replace with 'resources:'.
  echo "INFO: Checking for deprecated 'bases:' directive in all kustomization files..."
  # Apply this only to components/bases that might use it, or apps/overlays
  find kustomize/ -type f -name "kustomization.yaml" -exec sed -i.bak 's/^bases:/resources:/g' {} +
  find kustomize/ -type f -name "kustomization.yaml.bak" -delete
  echo "  - Check complete for deprecated 'bases:'."

  echo "SUCCESS: Repository file check complete."
}

# --- Function to commit and push changes to Git ---
commit_and_push_changes() {
  echo "INFO: Staging and checking for Git changes..."
  git add .
  # Check if there are any changes to commit to avoid an error.
  if git diff-index --quiet HEAD --; then
    echo "INFO: No new file changes to commit. Working directory is up-to-date with remote."
  else
    echo "INFO: Found new changes. Committing and pushing..."
    git commit -m "feat: Simplified GitOps PoC structure" -m "- Refactored kustomize components and applications. - Updated Argo CD apps and projects."
    git push
    echo "SUCCESS: Changes pushed to the remote repository."
  fi
}

# --- Function to sync and verify Argo CD ---
sync_and_verify_argocd() {
  echo "INFO: Starting Argo CD sync and verification..."
  echo "====================================================================="
  for app in "${ARGO_APPS[@]}"; do
    echo "--- Processing Argo CD App: ${app} ---"
    
    # The command 'sync' tells Argo CD to compare with Git and apply the changes.
    echo "INFO: Triggering sync for ${app}..."
    argocd app sync "${app}"

    echo "INFO: Waiting for ${app} to become healthy (timeout 2m)..."
    # Wait for the app to report a healthy status.
    argocd app wait "${app}" --health --timeout 120s || echo "WARNING: App ${app} did not become healthy within the timeout."

    echo "INFO: Fetching final status for ${app}..."
    argocd app get "${app}"
    echo "====================================================================="
  done
  echo "SUCCESS: Argo CD verification process complete."
}


# --- Main execution ---
main() {
  echo "### Starting Automated GitOps PoC Simplification and Deployment (v1.2) ###"
  fix_repository_files # Keeping this as a safeguard, though new files should be clean
  commit_and_push_changes
  sync_and_verify_argocd
  echo "### Script finished successfully! ###"
  echo "Please review the log above to check the status of your Argo CD applications."
}

# Run the main function
main
EOF

echo " "
echo "SUCCESS: All files and directories have been cleaned, created, and updated."
echo " "
echo "Next Steps:"
echo "1. Review the generated files, especially: "
echo "   - The 'repoURL' in argo-cd/apps/*/app-*.yaml to ensure it points to YOUR Git repository."
echo "   - The 'gitops-poc-repo' name in kustomize/components/*/base/kustomization.yaml to match your Flux GitRepository name."
echo "2. If you don't use FluxCD, you might need to adjust the HelmRelease definitions."
echo "3. Run './fix-and-deploy.sh' to commit changes to Git and sync with Argo CD."
echo "   Remember that your Argo CD user needs 'login, apiKey, tokens, exec, *' capabilities."
echo "   If permissions issues persist, restart Argo CD server pods: "
echo "   kubectl scale deployment argocd-server -n argocd --replicas=0 && sleep 5 && kubectl scale deployment argocd-server -n argocd --replicas=1"
echo "   (and similarly for argocd-repo-server, argocd-application-controller if needed)."
echo " "
echo "Script finished at $(date)"