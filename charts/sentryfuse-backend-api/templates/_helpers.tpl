{{- define "base.fullname" -}}
sentryfuse-api
{{- end }}

{{- define "sentryfuse.labels" -}}
app.kubernetes.io/name: {{ .Values.name }}
app.kubernetes.io/component: {{ .Values.component }}
app.kubernetes.io/part-of: sentryfuse
{{- end }}
