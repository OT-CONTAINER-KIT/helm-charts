{{/* Define the "microservice.fullname" template */}}
{{- define "microservice.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Define the "microservice.name" template (if needed) */}}
{{- define "microservice.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Define the "microservice.chart" template (if needed) */}}
{{- define "microservice.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Define other templates as necessary */}}
{{/* Define the "microservice.labels" template */}}
{{- define "microservice.labels" -}}
{{- with .Values.labels }}
{{- toYaml . | nindent 4 }}
{{- end }}
{{- end }}

{{/* Define the "microservice.matchLabels" template */}}
{{- define "microservice.matchLabels" -}}
{{- with .Values.app.name }}
  app: {{ . }}
{{- end }}
{{- end }}

{{/* Define the "microservice.selectorLabels" template */}}
{{- define "microservice.selectorLabels" -}}
{{- with .Values.app.name }}
  app: {{ . }}
{{- end }}
{{- end }}

