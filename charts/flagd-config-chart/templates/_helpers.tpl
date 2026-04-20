{{- define "flagd.name" -}}
{{- .Values.name | default "flagd" }}
{{- end }}

{{- define "flagd.fullname" -}}
{{- printf "%s-%s" .Values.name .Values.environment | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "flagd.labels" -}}
app: {{ .Values.name }}
environment: {{ .Values.environment }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "flagd.selectorLabels" -}}
app: {{ .Values.name }}
environment: {{ .Values.environment }}
{{- end }}

{{- define "flagd.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- .Values.serviceAccount.name | default (include "flagd.fullname" .) }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
