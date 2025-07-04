{{/*
# _helpers.tpl v1.0.0
# This file contains reusable template definitions (helpers) for the cronjob chart.
*/}}

{{/*
Template to generate an ExternalSecret resource.
*/}}
{{- define "cronjob.externalSecretTemplate" -}}
{{- $jobName := .jobName -}}
{{- $appName := .appName -}}
{{- $externalsecretName := .externalsecretName -}}
{{- $secretName := .secretName -}}
{{- $releaseNamespace := .releaseNamespace -}}
{{- $configSection := .configSection -}}
{{- $additionalLabels := .additionalLabels -}}

{{- with $configSection -}}
{{- if .secrets -}}
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: {{ $appName }}-{{ $jobName }}-{{ $externalsecretName }}
  labels:
    {{- include "cronjob.additionalLabels" $additionalLabels | trim | nindent 4 }}
spec:
  refreshInterval: 1h
  secretStoreRef:
    kind: {{ .secretStoreKind | default "SecretStore" }}
    name: {{ .secretStoreRef | default (printf "%s-kv-secretstore" $releaseNamespace) }}
  target:
    name: {{ $appName }}-{{ $jobName }}-{{ $secretName }}
    creationPolicy: Owner
    template:
      metadata:
        labels:
          {{- include "cronjob.additionalLabels" $additionalLabels | trim | nindent 10 }}
  data:
    {{- range $key, $value := .secrets }}
    - secretKey: {{ $key }}
      remoteRef:
        key: {{ $value }}
    {{- end }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Template to generate a PersistentVolume resource.
*/}}
{{- define "cronjob.pvTemplate" -}}
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: {{ .name }}
  labels:
    {{- include "cronjob.additionalLabels" .additionalLabels | trim | nindent 4 }}
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
      containerName: {{ .containerName | quote }}
    nodeStageSecretRef:
      name: {{ .secretName }}
      namespace: {{ .releaseNamespace }}
  {{- else if eq .type "azurefile" }}
  azureFile:
    secretName: {{ .secretName }}
    shareName: {{ .containerName | quote }}
    readOnly: false
  {{- end }}
{{- end -}}

{{/*
Template to generate a PersistentVolumeClaim resource.
*/}}
{{- define "cronjob.pvcTemplate" -}}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ .name }}
  labels:
    {{- include "cronjob.additionalLabels" .additionalLabels | trim | nindent 4 }}
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: {{ .storageSize }}
  volumeName: {{ .volumeName }}
  storageClassName: {{ .storageClassName }}
{{- end -}}

{{/*
Template to generate a ConfigMap resource.
*/}}
{{- define "cronjob.configmapTemplate" -}}
{{- $jobName := .jobName -}}
{{- $appName := .appName -}}
{{- $configMapName := .configMapName -}}
{{- $configSection := .configSection -}}
{{- $additionalLabels := .additionalLabels -}}
{{- with $configSection -}}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $appName }}-{{ $jobName }}-{{ $configMapName }}
  labels:
    app: {{ $appName }}
    {{- include "cronjob.additionalLabels" $additionalLabels | trim | nindent 4 }}
data:
{{- if .configuration }}
{{- range $key, $value := .configuration }}
  {{ $key }}: {{ $value | quote }}
{{- end }}
{{- end }}
{{- if and .name (eq $configMapName (printf "app-%s-config" .name)) }}
  {{ .name }}: |
{{ .data | indent 4 }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Helper to include additional labels.
*/}}
{{- define "cronjob.additionalLabels" -}}
{{- range $key, $value := . }}
{{ $key | quote }}: {{ $value | quote }}
{{- end }}
{{- end -}}