# fix-and-deploy.sh v1.1
# This script automates the process of fixing, deploying, and verifying the GitOps PoC.
# v1.1: Corrected 'argocd app refresh' to 'argocd app sync'.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
# List of custom components to check and fix.
# Based on the structure in 'kustomize/components/custom/'.
COMPONENTS_TO_FIX=("byebyeworld" "helloworld" "moon" "sun")

# List of Argo CD applications to sync and check.
# Based on the structure in 'argo-cd/apps/'.
ARGO_APPS=("app-space-dev" "app-world-dev" "app-space-pre" "app-world-pre")

# --- Function to fix local repository files ---
fix_repository_files() {
  echo "INFO: Starting to fix repository files..."

  # 1. Fix the primary error: remove direct reference to 'rollout.yaml' from components.
  echo "INFO: Checking for incorrect 'rollout.yaml' references in components..."
  for component in "${COMPONENTS_TO_FIX[@]}"; do
    KUSTOMIZATION_FILE="kustomize/components/custom/${component}/base/kustomization.yaml"
    if [ -f "$KUSTOMIZATION_FILE" ]; then
      # The '-i.bak' flag is used for macOS compatibility, creating a backup file. Use '-i' on Linux if preferred.
      sed -i.bak '/rollout.yaml/d' "$KUSTOMIZATION_FILE"
      rm -f "${KUSTOMIZATION_FILE}.bak"
    fi
  done
  echo "  - Check complete for 'rollout.yaml' references."

  # 2. Proactive fix: 'bases:' is deprecated in Kustomize. Replace with 'resources:'.
  echo "INFO: Checking for deprecated 'bases:' directive in all kustomization files..."
  find . -type f -name "kustomization.yaml" -exec sed -i.bak 's/^bases:/resources:/g' {} +
  find . -type f -name "kustomization.yaml.bak" -delete
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
    git commit -m "Fix: Automate correction of kustomization files" -m "- Removed erroneous 'rollout.yaml' resources. - Replaced deprecated 'bases' directive with 'resources'."
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
  echo "### Starting Automated GitOps PoC Fix (v1.1) ###"
  fix_repository_files
  commit_and_push_changes
  sync_and_verify_argocd
  echo "### Script finished successfully! ###"
  echo "Please review the log above to check the status of your Argo CD applications."
}

# Run the main function
main