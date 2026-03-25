{{/* vim: set filetype=mustache: */}}
# templates/_helpers.tpl


{{/* Global section */}}

{{/* Create Label section */}}
{{- define "global.labels" -}}
{{- if .labels -}}
{{- range $key, $val := .labels }}
{{ $key }}: {{ $val }}
{{- end -}}
{{- end -}}
{{- end -}}


{{/* Deployment/StatefulSet section */}}

{{/* Create imagePullSecrets section */}}
  {{/* range .imagePullSecrets */}}
  {{/* end */}}
{{- define "workload.imagePullSecrets" -}}
{{- if .imagePullSecrets }}
imagePullSecrets:
  - name: {{ .imagePullSecrets.name | default "bp-regcred" }}
{{- end }}
{{- end }}

{{/* Create resources section */}}
{{- define "workload.resources" -}}
{{- if .resources.enabled }}
resources:
{{- if .resources.limits }}
  limits:
{{- if .resources.limits.cpu }}
    cpu: {{ .resources.limits.cpu }}
{{- end }}
{{- if .resources.limits.memory }}
    memory: {{ .resources.limits.memory }}
{{- end }}
{{- end }}
{{- if .resources.requests }}
  requests:
{{- if .resources.requests.cpu }}
    cpu: {{ .resources.limits.cpu }}
{{- end }}
{{- if .resources.requests.memory }}
    memory: {{ .resources.limits.memory }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/* Create startupProbe section */}}
{{- define "workload.startupProbe" -}}
{{- if .startupProbe.enabled }}
startupProbe:
{{- if kindIs "map" .startupProbe.httpGet }}
{{- if (hasKey .startupProbe.httpGet "path") }}
{{- if .startupProbe.httpGet.path }}
  httpGet:
    path: {{ .startupProbe.httpGet.path }}
{{- if (hasKey .startupProbe.httpGet "port") }}
    port: {{ .startupProbe.httpGet.port }}
{{- end }}
{{- if (hasKey .startupProbe.httpGet "host") }}
    host: {{ .startupProbe.httpGet.host }}
{{- end }}
{{- if (hasKey .startupProbe.httpGet "scheme") }}
    scheme: {{ .startupProbe.httpGet.scheme }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- if kindIs "map" .startupProbe.exec }}
{{- if (hasKey .startupProbe.exec "command") }}
{{- if and .startupProbe.exec.command (gt (len .startupProbe.exec.command) 0) }}
  exec:
    command:
{{- range .startupProbe.exec.command }}
    - {{ . }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- if kindIs "map" .startupProbe.tcpSocket }}
{{- if (hasKey .startupProbe.tcpSocket "port") }}
{{- if .startupProbe.tcpSocket.port and .startupProbe.tcpSocket.port (ne .startupProbe.tcpSocket.port 0) }}
  tcpSocket:
    port: {{ .startupProbe.tcpSocket.port }}
{{- end }}
{{- end }}
{{- end }}
{{- if .startupProbe.initialDelaySeconds }}
  initialDelaySeconds: {{ .startupProbe.initialDelaySeconds }}
{{- end }}
{{- if .startupProbe.periodSeconds }}
  periodSeconds: {{ .startupProbe.periodSeconds }}
{{- end }}
{{- if .startupProbe.timeoutSeconds }}
  timeoutSeconds: {{ .startupProbe.timeoutSeconds }}
{{- end }}
{{- if .startupProbe.successThreshold }}
  successThreshold: {{ .startupProbe.successThreshold }}
{{- end }}
{{- if .startupProbe.failureThreshold }}
  failureThreshold: {{ .startupProbe.failureThreshold }}
{{- end }}
{{- end }}
{{- end }}

{{/* Create readinessProbe section */}}
{{- define "workload.readinessProbe" -}}
{{- if .readinessProbe.enabled }}
readinessProbe:
{{- if kindIs "map" .readinessProbe.httpGet }}
{{- if (hasKey .readinessProbe.httpGet "path") }}
{{- if .readinessProbe.httpGet.path }}
  httpGet:
    path: {{ .readinessProbe.httpGet.path }}
{{- if (hasKey .readinessProbe.httpGet "port") }}
    port: {{ .readinessProbe.httpGet.port }}
{{- end }}
{{- if (hasKey .readinessProbe.httpGet "host") }}
    host: {{ .readinessProbe.httpGet.host }}
{{- end }}
{{- if (hasKey .readinessProbe.httpGet "scheme") }}
    scheme: {{ .readinessProbe.httpGet.scheme }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- if kindIs "map" .readinessProbe.exec }}
{{- if (hasKey .readinessProbe.exec "command") }}
{{- if and .readinessProbe.exec.command (gt (len .readinessProbe.exec.command) 0) }}
  exec:
    command:
{{- range .readinessProbe.exec.command }}
    - {{ . }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- if kindIs "map" .readinessProbe.tcpSocket }}
{{- if (hasKey .readinessProbe.tcpSocket "port") }}
{{- if .readinessProbe.tcpSocket.port and .readinessProbe.tcpSocket.port (ne .readinessProbe.tcpSocket.port 0) }}
  tcpSocket:
    port: {{ .readinessProbe.tcpSocket.port }}
{{- end }}
{{- end }}
{{- end }}
{{- if .readinessProbe.initialDelaySeconds }}
  initialDelaySeconds: {{ .readinessProbe.initialDelaySeconds }}
{{- end }}
{{- if .readinessProbe.periodSeconds }}
  periodSeconds: {{ .readinessProbe.periodSeconds }}
{{- end }}
{{- if .readinessProbe.timeoutSeconds }}
  timeoutSeconds: {{ .readinessProbe.timeoutSeconds }}
{{- end }}
{{- if .readinessProbe.successThreshold }}
  successThreshold: {{ .readinessProbe.successThreshold }}
{{- end }}
{{- if .readinessProbe.failureThreshold }}
  failureThreshold: {{ .readinessProbe.failureThreshold }}
{{- end }}
{{- end }}
{{- end }}

{{/* Create livenessProbe section */}}
{{- define "workload.livenessProbe" -}}
{{- if .livenessProbe.enabled }}
livenessProbe:
{{- if kindIs "map" .livenessProbe.httpGet }}
{{- if (hasKey .livenessProbe.httpGet "path") }}
{{- if .livenessProbe.httpGet.path }}
  httpGet:
    path: {{ .livenessProbe.httpGet.path }}
{{- if (hasKey .livenessProbe.httpGet "port") }}
    port: {{ .livenessProbe.httpGet.port }}
{{- end }}
{{- if (hasKey .livenessProbe.httpGet "host") }}
    host: {{ .livenessProbe.httpGet.host }}
{{- end }}
{{- if (hasKey .livenessProbe.httpGet "scheme") }}
    scheme: {{ .livenessProbe.httpGet.scheme }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- if kindIs "map" .livenessProbe.exec }}
{{- if (hasKey .livenessProbe.exec "command") }}
{{- if and .livenessProbe.exec.command (gt (len .livenessProbe.exec.command) 0) }}
  exec:
    command:
{{- range .livenessProbe.exec.command }}
    - {{ . }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- if kindIs "map" .livenessProbe.tcpSocket }}
{{- if (hasKey .livenessProbe.tcpSocket "port") }}
{{- if .livenessProbe.tcpSocket.port and .livenessProbe.tcpSocket.port (ne .livenessProbe.tcpSocket.port 0) }}
  tcpSocket:
    port: {{ .livenessProbe.tcpSocket.port }}
{{- end }}
{{- end }}
{{- end }}
{{- if .livenessProbe.initialDelaySeconds }}
  initialDelaySeconds: {{ .livenessProbe.initialDelaySeconds }}
{{- end }}
{{- if .livenessProbe.periodSeconds }}
  periodSeconds: {{ .livenessProbe.periodSeconds }}
{{- end }}
{{- if .livenessProbe.timeoutSeconds }}
  timeoutSeconds: {{ .livenessProbe.timeoutSeconds }}
{{- end }}
{{- if .livenessProbe.successThreshold }}
  successThreshold: {{ .livenessProbe.successThreshold }}
{{- end }}
{{- if .livenessProbe.failureThreshold }}
  failureThreshold: {{ .livenessProbe.failureThreshold }}
{{- end }}
{{- end }}
{{- end }}

{{/* Create VolumeMounts section */}}
{{- define "workload.volumeMounts" -}}
{{- if .volumeMounts }}
{{- range .volumeMounts }}
- name: {{ .name }}
  mountPath: {{ .mountPath }}
  {{- if .readOnly }}
  readOnly: {{ .readOnly }}
  {{- end }}
  {{- if .subPath }}
  subPath: {{ .subPath }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/* Create Volume section */}}
{{- define "workload.volumes" -}}
{{- if .volumes }}
{{- range $volume := .volumes }}
- name: {{ $volume.name }}
  {{- if $volume.persistentVolumeClaim }} 
  persistentVolumeClaim:
    claimName: {{ $volume.persistentVolumeClaim.claimName }}
  {{- end }}
  {{- if $volume.configMap }}
  configMap:
    name: {{ $volume.configMap.name }}
    {{- if $volume.configMap.items }}
    items:
      {{- range $item := $volume.configMap.items }}
    - key: {{ $item.key }}
      path: {{ $item.path }}
      {{- end }}
    {{- end }}
    
  {{- end }}
  {{- if $volume.secret }}
  secret:
    secretName: {{ $volume.secret.secretName }}
    {{- if $volume.secret.items }}
    items:
      {{- range $item := $volume.secret.items }}
    - key: {{ $item.key }}
      path: {{ $item.path }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/* Create ports section */}}
{{- define "workload.ports" -}}
{{- if .ports }}
{{- range .ports }}
- containerPort: {{ .targetPort }}
  {{- if .name }}
  name: {{ .name | quote }}
  {{- end }}
  {{- if .protocol }}
  protocol: {{ .protocol }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/* Create env for container */}}
{{- define "workload.env" -}}
{{- if .env }}
{{- range .env }}
- name: {{ .name }}
  {{- if .value }}
  value: {{ .value | quote }}
  {{- end }}
  {{- if .valueFrom }}
  {{- if .valueFrom.fieldRef }}
  {{- if .valueFrom.fieldRef.fieldPath }}
  valueFrom:
    fieldRef:
      fieldPath: {{ .valueFrom.fieldRef.fieldPath }}
  {{- end }}
  {{- end }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}

## Service Section 

{{/*Define service ports*/}}
{{- define "service.servicePorts" -}}
{{- range .ports }}
- port: {{ .port }}
  {{- if .name }}
  name: {{ .name | quote }}
  {{- end }}
  targetPort: {{ .targetPort }}
  {{- if .protocol }}
  protocol: {{ .protocol }}
  {{- end }}
  {{- if .appProtocol }}
  appProtocol: {{ .appProtocol }}
  {{- end }}
  {{- if .nodePort }}
  nodePort: {{ .nodePort }}
  {{- end }}
{{- end }}
{{- end }}


{{/* Volume Section */}}

{{/* Create volume resources section */}}
{{- define "volume.volumeResources" -}}
{{- if .size -}}
requests:
  storage: {{ .size }} 
{{- end -}}
{{- end -}}

{{/* Create volume accessModes section */}}
{{- define "volume.volumeAccessModes" -}}
{{- if .accessModes -}}
{{- range .accessModes }}
- {{ . }}
{{- end -}}
{{- end -}}
{{- end -}}


{{/* Create mysql host */}}
{{- define "mysql.host" -}}
{{- if and .Values.apiJson.database.host (ne .Values.apiJson.database.host "") -}}
"{{ .Values.apiJson.database.host }}"
{{- else -}}
"{{ .Values.mysql.service.name }}.{{ .Release.Namespace }}.svc"
{{- end -}}
{{- end -}}


{{/* Create redis host */}}
{{- define "redis.host" -}}
{{- if and .Values.apiJson.redis.host (ne .Values.apiJson.redis.host "") -}}
"redis://{{ .Values.apiJson.redis.host }}:{{ .Values.apiJson.redis.port }}"
{{- else -}}
"redis://{{ .Values.redis.service.name }}.{{ .Release.Namespace }}.svc:{{ .Values.apiJson.redis.port }}"
{{- end -}}
{{- end -}}

## HPA Helper

{{/* HPA Helper */}}
{{- define "workload.hpa" -}}
{{- if .enabled }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ .name }}
  labels:
    app.kubernetes.io/instance: {{ .Release.Name }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ .targetDeployment }}
  minReplicas: {{ .minReplicas }}
  maxReplicas: {{ .maxReplicas }}
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: {{ .targetCPU }}
{{- end }}
{{- end -}}
