{{/* vim: set filetype=mustache: */}}

{{/*
Create  a defautl fully qualified app name
It will use the release name to give the app name
*/}}

{{- define "microservice.name" -}}
{{- default .Values.global.nameOverride | trunc 60 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "microservice.tempname" -}}
{{- if .Values.global.fullnameOverride }}
{{- .Values.global.fullnameOverride | trunc 60 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Values.global.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "microservice.fullname" -}}
{{- printf "%s-%s" ( include "microservice.tempname" . ) "app" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "microservice.labels" -}}
app: {{ include "microservice.tempname" . }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "microservice.selectorLabels" -}}
app: {{ include "microservice.tempname" . }}
{{- end }}%

{{/*
service name
*/}}
{{- define "microservice.servicename" -}}
{{- printf "%s-%s" ( include "microservice.tempname" . ) "svc" | trunc 63 | trimSuffix "-" }}
{{- end }}%

{{/*
configmap name
*/}}
{{- define "microservice.configmapname" -}}
{{- printf "%s-%s" ( include "microservice.tempname" . ) "cm" | trunc 63 | trimSuffix "-" }}
{{- end }}%

{{/*
Create name of the HPA to use 
*/}}
{{- define "microservice.HorizontalScalingName" -}}
{{- printf "%s-%s" ( include "microservice.tempname" . ) "hpa" | trunc 63 | trimSuffix "-" }}
{{- end }}%
