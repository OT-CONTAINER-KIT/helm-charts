{{/*
All helpers take a ctx dict: root ($), key (services map key), svc (the service values).
*/}}

{{/* Object name: services.<key>.name, else <release>-<key> */}}
{{- define "sentryfuse.name" -}}
{{- .svc.name | default (printf "%s-%s" .root.Release.Name .key) -}}
{{- end }}

{{- define "sentryfuse.selectorLabels" -}}
app.kubernetes.io/name: {{ include "sentryfuse.name" . }}
app.kubernetes.io/component: {{ .key }}
app.kubernetes.io/part-of: sentryfuse
{{- end }}

{{- define "sentryfuse.labels" -}}
{{ include "sentryfuse.selectorLabels" . }}
{{- with .svc.labels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/* Pod annotations: service values win over global */}}
{{- define "sentryfuse.podAnnotations" -}}
{{- $a := merge (dict) (.svc.podAnnotations | default dict) (.root.Values.global.podAnnotations | default dict) -}}
{{- with $a }}{{ toYaml . }}{{ end -}}
{{- end }}

{{/* env: from a map; blank values are skipped */}}
{{- define "sentryfuse.env" -}}
{{- $out := list -}}
{{- range $k, $v := . }}{{ if $v }}{{ $out = append $out (dict "name" $k "value" ($v | toString)) }}{{ end }}{{ end -}}
{{- if $out }}
env:
{{- toYaml $out | nindent 2 }}
{{- end }}
{{- end }}
