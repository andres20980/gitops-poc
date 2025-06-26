# update-k8s-image-pull-secret.sh v2.0.0
# This script prompts for a GitHub Personal Access Token (PAT),
# generates the base64 encoded .dockerconfigjson for GHCR,
# and prints it to the console for manual update of GitOps YAML files.

set -euo pipefail

echo "This script will generate the base64 encoded .dockerconfigjson string for GHCR."
echo "You will need to manually copy this string into your Kubernetes Secret YAML file in Git."

# Step 1: Prompt for GitHub PAT securely
read -s -p "Enter your GitHub Personal Access Token (PAT, with read:packages scope): " GITHUB_PAT
echo

# Step 2: Encode the PAT to Base64
ENCODED_PAT=$(echo -n "${GITHUB_PAT}" | base64)

# Step 3: Construct the .dockerconfigjson structure
# Important: Use ghcr.io for GitHub Container Registry
DOCKER_CONFIG_JSON=$(cat <<EOF
{
  "auths": {
    "ghcr.io": {
      "auth": "${ENCODED_PAT}"
    }
  }
}
EOF
)

# Step 4: Encode the entire JSON structure to Base64 (single line)
FINAL_ENCODED_STRING=$(echo -n "${DOCKER_CONFIG_JSON}" | base64 -w 0)

# Step 5: Print the final Base64 string
echo "--------------------------------------------------------------------------"
echo "Copy this entire string (it's on a single line):"
echo "${FINAL_ENCODED_STRING}"
echo "--------------------------------------------------------------------------"
echo "Now, manually paste this string into the '.dockerconfigjson' field of your"
echo "kustomize/base/secrets/github-image-pull-secret.yaml file."
echo "Remember to change 'name: github-image-pull-secret' to 'name: ghcr-creds' "
echo "in that YAML file if you haven't already."
echo "Finally, commit and push your changes to Git."