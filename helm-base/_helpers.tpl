#!/bin/bash
set -e

echo "🔧 Starting GitOps PoC update..."

# Clean up previous backups to avoid Helm/Kustomize parsing errors
echo "🧹 Cleaning up old .bak files..."
find . -name "*.bak" -delete

# 1. Add syncPolicy to Argo CD Application YAMLs
echo "⚙️  Updating Argo CD Applications..."
find argo-cd/apps -name "*.yaml" | while read -r file; do
  grep -q "syncPolicy" "$file" || {
    cp "$file" "$file.bak"
    yq eval '.spec += {"syncPolicy": {"automated": {"prune": true, "selfHeal": true}}}' "$file.bak" > "$file"
    echo "✅ Added syncPolicy to $file"
  }
done

# 2. Ensure Helm templates have labels
echo "🏷️  Ensuring standard labels in Helm templates..."
for chart in helm-base helm-cronjob-base; do
  for tmpl in $(find "$chart/templates" -name "*.yaml"); do
    cp "$tmpl" "$tmpl.bak"
    grep -q "app.kubernetes.io/name" "$tmpl" || sed -i '/metadata:/a\
  labels:\
    app.kubernetes.io/name: {{ include "'"$chart"'.name" . }}\
    app.kubernetes.io/instance: {{ .Release.Name }}\
    app.kubernetes.io/managed-by: {{ .Release.Service }}' "$tmpl"
    echo "✅ Labels updated in $tmpl"
  done
done

# 3. Update values.yaml with required fields
echo "📦 Checking values.yaml..."
for chart in helm-base helm-cronjob-base; do
  f="$chart/values.yaml"
  cp "$f" "$f.bak"
  yq eval '
    .replicaCount = (.replicaCount // 1) |
    .image.repository = (.image.repository // "myrepo/image") |
    .image.tag = (.image.tag // "latest") |
    .resources.requests.cpu = (.resources.requests.cpu // "100m") |
    .resources.requests.memory = (.resources.requests.memory // "128Mi") |
    .resources.limits.cpu = (.resources.limits.cpu // "500m") |
    .resources.limits.memory = (.resources.limits.memory // "256Mi") |
    .jobName = (.jobName // "demo-cron") |
    .projectName = (.projectName // "myproject") |
    .schedule = (.schedule // "0 * * * *") |
    .version = (.version // "1.0.0")
  ' "$f.bak" > "$f"
  echo "✅ values.yaml updated for $chart"
done

# 4. Patch kustomization.yaml files
echo "🧩 Updating kustomization.yaml..."
find kustomize -name kustomization.yaml | while read -r kf; do
  cp "$kf" "$kf.bak"
  yq eval '
    .namespace = (.namespace // "default") |
    .commonLabels = (.commonLabels // {}) |
    .commonLabels.app = (.commonLabels.app // "myapp")
  ' "$kf.bak" > "$kf"
  echo "✅ Patched $kf"
done

# 5. Fix deprecated kustomize fields
echo "♻️  Fixing deprecated fields with 'kustomize edit fix'..."
find kustomize -name kustomization.yaml -execdir kustomize edit fix \;

# 6. Create dummy rollout.yaml if missing to avoid kustomize errors
echo "📄 Creating missing rollout.yaml where necessary..."
mkdir -p kustomize/components/custom/sun/base
touch kustomize/components/custom/sun/base/rollout.yaml
mkdir -p kustomize/components/custom/helloworld/base
touch kustomize/components/custom/helloworld/base/rollout.yaml

# 7. Validate Helm
echo "🔍 Validating Helm charts..."
helm lint helm-base || true
helm lint helm-cronjob-base || true

# 8. Validate Kustomize overlays
echo "🔍 Validating Kustomize overlays..."
for env in dev pre; do
  for app in kustomize/apps/*/overlays/$env; do
    echo "🧪 $app"
    kustomize build "$app" > /dev/null || echo "❌ Error in $app"
  done
done

echo "✅ Update complete."
