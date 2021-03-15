{{ define "tlowerison/standard-base.tpl" }}{{ if (regexMatch "^\\{\\{.*\\}\\}$" .tpl) }}{{ tpl .tpl $ }}{{ else }}{{ .tpl }}{{ end }}{{ end }}

{{ define "tlowerison/standard-base.yaml" }}{{ if kindIs "map" . }}{{ include "tlowerison/standard-base.map" . }}{{ else if kindIs "slice" . }}{{ include "tlowerison/standard-base.slice" . }}{{ else }}{{ toString . }}{{ end }}{{ end }}

{{ define "tlowerison/standard-base.baseMap" }}{{ range $key, $value := . }}{{ if not (kindIs "invalid" $value) }}{{ $key }}: {{ if kindIs "map" $value }}{{ "\n  " }}{{ include "tlowerison/standard-base.map" $value | nindent 2 | trim }}
{{ else if kindIs "slice" $value }}{{ include "tlowerison/standard-base.slice" $value }}
{{ else }}{{ toString $value }}
{{ end }}{{ end }}{{ end }}{{ end }}

{{ define "tlowerison/standard-base.map" }}{{ $baseMap := include "tlowerison/standard-base.baseMap" . }}{{ trimSuffix "\n" $baseMap }}{{ end }}

{{ define "tlowerison/standard-base.slice" }}{{ range $key, $value := . }}
- {{ include "tlowerison/standard-base.yaml" $value | nindent 2 | trim }}{{ end }}{{ end }}

{{ define "tlowerison/standard-base.name" -}}
{{ if hasKey .Values "name" }}{{ .Values.name }}{{ else }}{{ .Values.global.name }}{{ end }}
{{- end }}

{{/* labels helper, for injecting labels into helm managed resources */}}
{{ define "tlowerison/standard-base.labels" -}}
app.kubernetes.io/name: {{ include "tlowerison/standard-base.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.Version }}{{ if hasKey .Values "component" }}
app.kubernetes.io/component: {{ .Values.component }}{{ end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
meta.helm.sh/release-namespace: {{ .Release.Namespace }}{{ if hasKey .Values "labels" }}
{{ include "tlowerison/standard-base.yaml" (dict "Values" .Values "key" "labels") }}
{{- end }}{{ end }}

{{/* matchLabels / service.selector helper */}}
{{ define "tlowerison/standard-base.matchLabels" -}}
app.kubernetes.io/name: {{ include "tlowerison/standard-base.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.Version }}{{ if hasKey .Values "component" }}
app.kubernetes.io/component: {{ .Values.component }}{{ end }}{{ if hasKey .Values "selector" }}{{ if hasKey .Values.selector "matchLabels" }}
{{ include "tlowerison/standard-base.yaml" .Values.selector.matchLabels }}{{ end }}{{ end }}{{ end }}

{{/* selections helper, for injecting selectors into helm managed resouces */}}
{{ define "tlowerison/standard-base.selector" -}}
matchLabels:
{{ include "tlowerison/standard-base.matchLabels" . | indent 2 }}{{ if hasKey .Values "selector" }}
{{ include "tlowerison/standard-base.yaml" (omit .Values.selector "matchLabels") }}{{ end }}
{{- end }}

{{ define "tlowerison/standard-base.image" -}}
{{ if hasKey . "repo" }}{{ .repo }}{{ "/" }}{{ end }}{{ .name }}{{ ":" }}{{ .tag }}
{{- end }}

{{/* env helper */}}
{{ define "tlowerison/standard-base.env" }}{{ range $name, $value := .container.env -}}
{{- $name = (include "tlowerison/standard-base.tpl" (deepCopy $ | merge (dict "tpl" $name))) -}}
{{- $value = (include "tlowerison/standard-base.tpl" (deepCopy $ | merge (dict "tpl" $value)) | quote) }}
  - name: {{ $name }}
    value: {{ $value }}{{ end }}{{ end }}

{{/* tpl env helper */}}
{{ define "tlowerison/standard-base.secrets" }}{{ range $newKey, $secret := .container.secrets -}}
{{- $name := (include "tlowerison/standard-base.tpl" (deepCopy $ | merge (dict "tpl" $secret.from))) -}}
{{- $key := (include "tlowerison/standard-base.tpl" (deepCopy $ | merge (dict "tpl" $secret.key)) | quote) }}
  - name: {{ $newKey }}
    valueFrom:
      secretKeyRef:
        name: {{ $name }}
        key: {{ $key }}{{ end }}{{ end }}

{{/* args helper */}}
{{ define "tlowerison/standard-base.args" }}{{ range . }}- {{ . | quote }}
{{- end }}{{ end }}

{{/* container ports helper */}}
{{ define "tlowerison/standard-base.containerPorts" }}
{{- range $name, $port := . -}}
- name: {{ if hasKey $port "name" }}{{ $port.name }}{{ else }}{{ "port-" }}{{ $name }}{{ end }}
  containerPort: {{ $port.container }}{{ if hasKey $port "host" }}
  hostPort: {{ $port.host }}{{ end }}{{ if hasKey $port "protocol" }}
  protocol: {{ $port.protocol }}{{ end }}{{ end }}{{ end }}

{{/* containers helper */}}
{{ define "tlowerison/standard-base.containers" -}}
{{- range $i, $ctr := .containers -}}
{{- $rest := include "tlowerison/standard-base.yaml" (omit $ctr "name" "image" "imagePullPolicy" "ports" "env" "secrets" "externalSecrets") | nindent 2 -}}
{{- $tpl := (deepCopy $ | merge (dict "container" $ctr)) }}
- name: {{ if hasKey $ctr "name" }}{{ $ctr.name }}{{ else }}{{ "container-" }}{{ $i }}{{ end }}
  image: {{ include "tlowerison/standard-base.image" $ctr.image }}
  imagePullPolicy: {{ if hasKey $ctr "imagePullPolicy" }}{{ $ctr.imagePullPolicy }}{{ else }}Always{{ end }}
  {{- if hasKey $ctr "ports" }}
  ports: {{ include "tlowerison/standard-base.containerPorts" $ctr.ports | nindent 2 }}{{ end }}{{ if (or (hasKey $ctr "env") (hasKey $ctr "secrets")) }}
  env: {{ if hasKey $ctr "env" }}{{ include "tlowerison/standard-base.env" $tpl }}{{ end }}
  {{- if hasKey $ctr "secrets" }}{{ include "tlowerison/standard-base.secrets" $tpl }}{{ end }}{{ end }}
  {{- if not (eq "" (trim $rest)) }}{{ regexReplaceAll "( |\n)*$" $rest "" }}{{ end }}{{ end }}{{ end }}

{{/* imagePullSecrets helper */}}
{{ define "tlowerison/standard-base.imagePullSecrets" }}
{{- range . -}}
- name: {{ . }}
{{- end -}}{{- end }}

{{/* base pod spec helper */}}
{{ define "tlowerison/standard-base.basePod" -}}
{{- $template := .Values.template -}}
{{- if hasKey $template "imagePullSecrets" }}{{ if (lt 0 (len $template.imagePullSecrets)) -}}
imagePullSecrets: {{ include "tlowerison/standard-base.imagePullSecrets" $template.imagePullSecrets | nindent 0 }}{{ end }}{{ end }}
{{- if hasKey $template "initContainers" }}{{ if (lt 0 (len $template.initContainers)) }}
initContainers: {{ include "tlowerison/standard-base.containers" (deepCopy $ | merge (dict "containers" $template.initContainers)) }}{{ end }}{{ end }}
{{- if hasKey $template "containers" }}{{ if (lt 0 (len $template.containers)) }}
containers: {{ include "tlowerison/standard-base.containers" (deepCopy $ | merge (dict "containers" $template.containers)) }}{{ end }}{{ end }}{{ end }}

{{ define "tlowerison/standard-base.pod" -}}
{{- $template := .Values.template -}}
{{- $base := regexReplaceAll "^( |\n)*" (include "tlowerison/standard-base.basePod" $) "" -}}
{{- $rest := regexReplaceAll "( |\n)*$" (include "tlowerison/standard-base.yaml" (omit $template "imagePullSecrets" "initContainers" "containers")) "" }}
{{- if not (eq "" (trim $base)) }}{{ $base }}
{{ end }}{{ if not (eq "" (trim $rest)) }}{{ $rest }}
{{ end }}{{ end }}
