# fix-and-deploy.sh v1.0
# This script automates the process of fixing, deploying, and verifying the GitOps PoC.

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
  # This error was found in the 'sun' component and likely exists in others.
  echo "INFO: Checking for incorrect 'rollout.yaml' references in components..."
  for component in "${COMPONENTS_TO_FIX[@]}"; do
    KUSTOMIZATION_FILE="kustomize/components/custom/${component}/base/kustomization.yaml"
    if [ -f "$KUSTOMIZATION_FILE" ]; then
      # The '-i.bak' flag is used for macOS compatibility, creating a backup file. Use '-i' on Linux if preferred.
      sed -i.bak '/rollout.yaml/d' "$KUSTOMIZATION_FILE"
      rm -f "${KUSTOMIZATION_FILE}.bak"
      echo "  - Fixed: Removed 'rollout.yaml' reference from ${component}."
    else
      echo "  - WARNING: Could not find ${KUSTOMIZATION_FILE}. Skipping."
    fi
  done

  # 2. Proactive fix: 'bases:' is deprecated in Kustomize. Replace with 'resources:'.
  # This warning appeared in the error log. Let's fix it everywhere.
  echo "INFO: Fixing deprecated 'bases:' directive in all kustomization files..."
  # The find command safely handles all kustomization.yaml files.
  find . -type f -name "kustomization.yaml" -exec sed -i.bak 's/^bases:/resources:/g' {} +
  # Clean up backup files created by sed.
  find . -type f -name "kustomization.yaml.bak" -delete
  echo "  - Fixed: Replaced 'bases:' with 'resources:'."

  echo "SUCCESS: Repository files fixed."
}

# --- Function to commit and push changes to Git ---
commit_and_push_changes() {
  echo "INFO: Staging, committing, and pushing changes to Git..."
  git add .
  # Check if there are any changes to commit to avoid an error.
  if git diff-index --quiet HEAD --; then
    echo "INFO: No changes to commit. Working directory is clean."
  else
    git commit -m "Fix: Automate correction of kustomization files" -m "- Removed erroneous 'rollout.yaml' resources. - Replaced deprecated 'bases' directive with 'resources'."
    git push
    echo "SUCCESS: Changes pushed to the remote repository."
  fi
}

# --- Function to refresh Argo CD and get logs ---
sync_and_verify_argocd() {
  echo "INFO: Starting Argo CD sync and verification..."
  echo "====================================================================="
  for app in "${ARGO_APPS[@]}"; do
    echo "--- Processing Argo CD App: ${app} ---"
    echo "INFO: Triggering refresh for ${app}..."
    argocd app refresh "${app}"

    echo "INFO: Waiting for ${app} to sync and become healthy (timeout 2m)..."
    # Wait for the app to sync and report a healthy status.
    argocd app wait "${app}" --health --timeout 120s || echo "WARNING: App ${app} did not become healthy within the timeout."

    echo "INFO: Fetching final status for ${app}..."
    argocd app get "${app}"
    echo "====================================================================="
  done
  echo "SUCCESS: Argo CD verification process complete."
}


# --- Main execution ---
main() {
  echo "### Starting Automated GitOps PoC Fix ###"
  fix_repository_files
  commit_and_push_changes
  sync_and_verify_argocd
  echo "### Script finished successfully! ###"
  echo "Please review the log above to check the status of your Argo CD applications."
}

# Run the main function
main