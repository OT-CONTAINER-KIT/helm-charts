{{- define "microservice.fullname" -}}
{{- printf "%s-%s" (default .Chart.Name .Values.env.microservice.fullname) .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end -}}

{{- define "microservice.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name | quote }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | replace ":" "-" | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/version: {{ .Chart.AppVersion | replace "+" "_" | replace ":" "-" | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
{{- end -}}

{{- define "microservice.selectorLabels" -}}
app: {{ default .Values.env.microservice.selectorLabels .Chart.Name | quote }}
{{- end -}}

{{- define "microservice.matchLabels" -}}
app: {{ default .Values.env.microservice.selectorLabels .Chart.Name | quote }}
{{- end -}}
