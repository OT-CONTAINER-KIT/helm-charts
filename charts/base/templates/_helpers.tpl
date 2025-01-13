{{/*
Create a default fully qualified app name.
We truncate service name aka .Release.Name at 59 chars because some Kubernetes name fields are limited to 63 (by the DNS naming spec).
We append 4 characters for chart type at the end which is -web or -crn or -wrk or -job or -sts.
*/}}
{{- define "base.fullname" -}}
{{- $name := .Release.Name | trunc 59 | trimSuffix "-" }}
{{- printf "%s-%s" $name .Chart.Name }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "base.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "base.labels" -}}
helm.sh/chart: {{ include "base.chart" . }}
{{ include "base.selectorLabels" . }}
{{- if .Release.Revision }}
app.kubernetes.io/version: {{ .Release.Revision | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "base.selectorLabels" -}}
app.kubernetes.io/name: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "base.serviceAccountName" -}}
{{- default (include "base.fullname" .) .Values.base.serviceAccount.name }}
{{- end }}
