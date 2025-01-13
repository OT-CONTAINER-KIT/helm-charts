{{- define "serviceAccount" -}}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "base.serviceAccountName" . }}
  labels:
    {{- include "base.labels" . | nindent 4 }}
  {{- with .Values.base.serviceAccount.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}
