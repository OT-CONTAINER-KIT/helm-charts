{{- define "gateway.controllerName" -}}
{{- if eq .Values.controller.type "kong" -}}
konghq.com/gateway-controller
{{- else if eq .Values.controller.type "istio" -}}
istio.io/gateway-controller
{{- else if eq .Values.controller.type "aws" -}}
gateway.networking.k8s.io/aws-gateway-controller
{{- else if eq .Values.controller.type "gcp" -}}
gateway.networking.k8s.io/gke-gateway-controller
{{- end -}}
{{- end -}}
