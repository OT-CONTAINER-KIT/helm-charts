{{- define "pmm.name" -}}
pmm
{{- end }}

{{- define "pmm.fullname" -}}
{{ .Release.Name }}-pmm
{{- end }}

{{- define "pmm.labels" -}}
app.kubernetes.io/name: {{ include "pmm.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: "{{ .Chart.AppVersion }}"
helm.sh/chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
{{- end }}
