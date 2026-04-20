{{- define "flagd-config-chart-dr.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "flagd-config-chart-dr.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 32 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 32 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 32 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "flagd-config-chart-dr.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "flagd-config-chart-dr.labels" -}}
helm.sh/chart: {{ include "flagd-config-chart-dr.chart" . }}
{{ include "flagd-config-chart-dr.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "flagd-config-chart-dr.selectorLabels" -}}
app.kubernetes.io/name: {{ include "flagd-config-chart-dr.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "flagd-config-chart-dr.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "flagd-config-chart-dr.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "flagd-config-chart-dr.imageTag" -}}
{{- .Values.image.tag | default .Chart.AppVersion }}
{{- end }}
