{{- define "configmap" -}}
{{- if .Values.base.config -}}
{{- $top := . -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "base.fullname" . }}
  labels:
    {{- include "base.labels" . | nindent 4 }}
data:
  {{- toYaml .Values.base.config | nindent 2 -}}
{{- end -}}
{{- end -}}
