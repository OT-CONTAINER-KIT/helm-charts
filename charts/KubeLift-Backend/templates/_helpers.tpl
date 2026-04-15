{{- define "base.fullname" -}}
kubelift-api
{{- end }}

{{- define "kubelift.labels" -}}
app.kubernetes.io/name: {{ .Values.name }}
app.kubernetes.io/component: {{ .Values.component }}
app.kubernetes.io/part-of: kubelift
{{- end }}
