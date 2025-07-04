{{/* helm-base/templates/_helpers.tpl v1.0.0 */}}
{{/*
Reusable template for creating PersistentVolumes.
*/}}
{{- define "pvTemplate" -}}
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: {{ .name }}
spec:
  capacity:
    storage: 100Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: {{ .storageClassName }}
  {{- if eq .type "blob" }}
  mountOptions:
    - -o allow_other
    - --file-cache-timeout-in-seconds=120
  csi:
    driver: blob.csi.azure.com
    readOnly: false
    volumeHandle: {{ .name }}
    volumeAttributes:
      containerName: {{ .containerName }}
    nodeStageSecretRef:
      name: {{ .secretName }}
      namespace: {{ .releaseNamespace }}
  {{- else if eq .type "azurefile" }}
  azureFile:
    secretName: {{ .secretName }}
    shareName: {{ .containerName }}
    readOnly: false
  {{- end }}
{{- end -}}

{{/*
Reusable template for creating PersistentVolumeClaims.
*/}}
{{- define "pvcTemplate" -}}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ .resourceName }}
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: {{ .storageSize }}
  volumeName: {{ .volumeResourceName }}
  storageClassName: {{ .storageClassName }}
{{- end -}}

{{/*
Reusable template for creating ExternalSecrets.
*/}}
{{- define "externalSecretTemplate" -}}
{{- $appName := .appName -}}
{{- $externalsecretName := .externalsecretName -}}
{{- $secretName := .secretName -}}
{{- $releaseNamespace := .releaseNamespace -}}
{{- $secretStoreKind := .secretStoreKind -}}
{{- $configSection := .configSection -}}

{{- with $configSection -}}
{{- if .secrets -}}
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: {{ $appName }}-{{ $externalsecretName }}
spec:
  refreshInterval: 1h
  secretStoreRef:
    kind: {{ .secretStoreName | default "SecretStore" }}
    name: {{ .secretStoreRef | default (printf "%s-kv-secretstore" $releaseNamespace) }}

  target:
    name: {{ $appName }}-{{ $secretName }}
    creationPolicy: {{ .target | default "Owner" }}
  data:
    {{- range $key, $value := .secrets }}
    - secretKey: {{ $key }}
      remoteRef:
        key: {{ $value }}
    {{- end }}
{{- end -}}
{{- end -}}
{{- end -}}