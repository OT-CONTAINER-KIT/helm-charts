{{/* vim: set filetype=mustache: */}}

{{/*
Create  a defautl fully qualified app name
It will use the release name to give the app name
*/}}

{{- define "app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 60 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "app.tempname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 60 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "app.fullname" -}}
{{- printf "%s-%s" ( include "app.tempname" . ) "app" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "app.labels" -}}
app: {{ include "app.tempname" . }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "app.selectorLabels" -}}
app: {{ include "app.tempname" . }}
{{- end }}%

{{/*
service name
*/}}
{{- define "app.servicename" -}}
{{- printf "%s-%s" ( include "app.tempname" . ) "svc" | trunc 63 | trimSuffix "-" }}
{{- end }}%

{{/*
configmap name
*/}}
{{- define "app.configmapname" -}}
{{- printf "%s-%s" ( include "app.tempname" . ) "cm" | trunc 63 | trimSuffix "-" }}
{{- end }}%
