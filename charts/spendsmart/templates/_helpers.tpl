{{/*
Expand the name of the chart.
*/}}
{{- define "spendsmart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "spendsmart.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Chart label.
*/}}
{{- define "spendsmart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "spendsmart.labels" -}}
helm.sh/chart: {{ include "spendsmart.chart" . }}
{{ include "spendsmart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "spendsmart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "spendsmart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Backend name.
*/}}
{{- define "spendsmart.backend.fullname" -}}
{{- printf "%s-backend" (include "spendsmart.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Frontend name.
*/}}
{{- define "spendsmart.frontend.fullname" -}}
{{- printf "%s-frontend" (include "spendsmart.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Cloud-Sentry name.
*/}}
{{- define "spendsmart.cloudsentry.fullname" -}}
{{- printf "%s-cloud-sentry" (include "spendsmart.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Engine name.
*/}}
{{- define "spendsmart.engine.fullname" -}}
{{- printf "%s-engine" (include "spendsmart.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
