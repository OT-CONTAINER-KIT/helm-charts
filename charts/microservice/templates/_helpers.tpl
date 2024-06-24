{{- define "microservice.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "microservice.fullname" -}}
{{- $name := include "microservice.name" . -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" $name .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- define "microservice.labels" -}}
  app: {{ include "microservice.name" . }}
{{- end -}}
{{- define "microservice.selectorLabels" -}}
  app: {{ include "microservice.name" . }}
{{- end -}}
