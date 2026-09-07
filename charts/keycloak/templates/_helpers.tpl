{{/* Chart name (optionally overridden). */}}
{{- define "keycloak.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Fully-qualified app name. */}}
{{- define "keycloak.fullname" -}}
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

{{/* Chart label value. */}}
{{- define "keycloak.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Stable selector labels — MUST NOT change across upgrades. Used by the Deployment
     selector, the pod template, and the Service selector. */}}
{{- define "keycloak.selectorLabels" -}}
app.kubernetes.io/name: {{ include "keycloak.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* Full label set (postgres-16 shape). */}}
{{- define "keycloak.labels" -}}
helm.sh/chart: {{ include "keycloak.chart" . }}
{{ include "keycloak.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* Image ref, tolerating an empty registry. tag falls back to appVersion. */}}
{{- define "keycloak.image" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion -}}
{{- with .Values.image.registry }}{{ . }}/{{ end }}{{ .Values.image.repository }}:{{ $tag }}
{{- end }}

{{/* Secret holding db-password + admin-password. */}}
{{- define "keycloak.secretName" -}}
{{- if .Values.existingSecret }}{{ tpl .Values.existingSecret . }}
{{- else }}{{ printf "%s-secret" (include "keycloak.fullname" .) }}
{{- end }}
{{- end }}

{{- define "keycloak.dbPasswordKey" -}}
{{- if .Values.existingSecret }}{{ .Values.existingSecretKeys.dbPassword | default "db-password" }}
{{- else }}db-password
{{- end }}
{{- end }}

{{- define "keycloak.adminPasswordKey" -}}
{{- if .Values.existingSecret }}{{ .Values.existingSecretKeys.adminPassword | default "admin-password" }}
{{- else }}admin-password
{{- end }}
{{- end }}

{{- define "keycloak.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}{{ default (include "keycloak.fullname" .) .Values.serviceAccount.name }}
{{- else }}{{ default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/* KC_DB_URL. Full override via db.url wins; else built from db.{host,port,name,extraParams}. */}}
{{- define "keycloak.dbUrl" -}}
{{- if .Values.db.url -}}
{{- tpl .Values.db.url . -}}
{{- else -}}
{{- $vendor := .Values.db.vendor | default "postgres" -}}
{{- $scheme := ternary "postgresql" $vendor (eq $vendor "postgres") -}}
{{- $url := printf "jdbc:%s://%s:%v/%s" $scheme (required "db.host is required" .Values.db.host) (.Values.db.port | default 5432) .Values.db.name -}}
{{- with .Values.db.extraParams }}{{- $url = printf "%s?%s" $url . -}}{{- end -}}
{{- $url -}}
{{- end -}}
{{- end }}

{{/* Guard: probes need the health endpoint enabled. */}}
{{- define "keycloak.validate" -}}
{{- if and (not .Values.health.enabled) (or .Values.startupProbe.enabled .Values.readinessProbe.enabled .Values.livenessProbe.enabled) -}}
{{- fail "health.enabled must be true when any of startupProbe/readinessProbe/livenessProbe is enabled (probes hit /health/* on the management port)" -}}
{{- end -}}
{{- end }}
