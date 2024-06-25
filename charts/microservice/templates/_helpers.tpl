{{- define "microservice.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "microservice.fullname" -}}
{{- printf "%s-%s" (include "microservice.name" .) .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "microservice.labels" -}}
app: {{ include "microservice.name" . }}
{{- end -}}

{{- define "microservice.selectorLabels" -}}
app: {{ include "microservice.name" . }}
{{- end -}}
