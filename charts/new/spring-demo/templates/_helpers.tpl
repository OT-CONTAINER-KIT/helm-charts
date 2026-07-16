{{/*
Chart name and version label.
*/}}
{{- define "spring-demo.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Base fullname used as a prefix for all resource names.
*/}}
{{- define "spring-demo.fullname" -}}
{{- if contains .Chart.Name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Common labels applied to every resource.
*/}}
{{- define "spring-demo.labels" -}}
helm.sh/chart: {{ include "spring-demo.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels for the app component.
*/}}
{{- define "spring-demo.app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "spring-demo.fullname" . }}-app
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Selector labels for the nginx component.
*/}}
{{- define "spring-demo.nginx.selectorLabels" -}}
app.kubernetes.io/name: {{ include "spring-demo.fullname" . }}-nginx
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
