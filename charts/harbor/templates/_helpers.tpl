{{- define "harbor.name" -}}
harbor
{{- end }}

{{- define "harbor.fullname" -}}
{{ printf "%s-%s" .Release.Name (.Values.namespace | default "harbor") }}
{{- end }}

{{- define "harbor.labels" -}}
app: harbor
release: {{ .Release.Name }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
