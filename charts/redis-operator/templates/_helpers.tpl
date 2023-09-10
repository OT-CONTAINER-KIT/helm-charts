{{/* vim: set filetype=mustache: */}}

{{/* Define issuer spec based on the type */}}
{{- define "redis-operator.issuerSpec" -}}
{{- if eq .Values.issuer.type "acme" }}
acme:
  email: {{ .Values.issuer.email }}
  server: {{ .Values.issuer.server }}
  privateKeySecretRef:
    name: {{ .Values.issuer.privateKeySecretName }}
  solvers:
  - http01:
      ingress:
        class: {{ .Values.issuer.solver.ingressClass }}
{{- else }}
selfSigned: {}
{{- end }}
{{- end -}}
