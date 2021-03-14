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
meta.helm.sh/release-namespace: {{ .Release.Namespace }}
{{- end }}

{{/* selections helper, for injecting selectors into helm managed resouces */}}
{{ define "tlowerison/standard-base.selectors" -}}
app.kubernetes.io/name: {{ include "tlowerison/standard-base.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.Version }}{{ if hasKey .Values "component" }}
app.kubernetes.io/component: {{ .Values.component }}{{ end }}
{{- end }}

{{ define "tlowerison/standard-base.image" -}}
{{ if hasKey . "repo" }}{{ .repo }}{{ "/" }}{{ end }}{{ .name }}{{ ":" }}{{ .tag }}
{{- end }}

{{/* env helper */}}
{{ define "tlowerison/standard-base.env" }}{{ range $name, $value := .container.env }}
  - name: {{ $name }}
    value: {{ tpl $value $ | quote }}{{ end }}{{ end }}

{{/* secrets helper */}}
{{ define "tlowerison/standard-base.secrets" }}{{ range $_, $name := .container.secrets }}- name: {{ $name }}
  valueFrom:
    secretKeyRef:
      name: {{ include "tlowerison/standard-base.name" }}
      key: {{ $name }}
{{- end }}{{ end }}

{{/* externalSecrets helper */}}
{{ define "tlowerison/standard-base.externalSecrets" }}{{ range $_, $externalSecret := .container.externalSecrets }}- name: {{ tpl $externalSecret.key }}
  valueFrom:
    secretKeyRef:
      name: {{ tpl $externalSecret.from . | quote }}
      key: {{ tpl $externalSecret.key . | quote }}
{{- end }}{{ end }}

{{/* args helper */}}
{{ define "tlowerison/standard-base.args" }}{{ range . }}- {{ . | quote }}
{{- end }}{{ end }}

{{/* container ports helper */}}
{{ define "tlowerison/standard-base.containerPorts" }}
{{- range $name, $port := . -}}
- name: {{ if hasKey $port "name" }}{{ $port.name }}{{ else }}{{ "port-" }}{{ $name }}{{ end }}
  containerPort: {{ $port.container }}{{ if hasKey $port "host" }}
  hostPort: {{ $port.host }}{{ end }}{{ if hasKey $port "protocol" }}
  protocol: {{ $port.protocol }}{{ end }}
{{- end }}{{ end }}

{{/* containers helper */}}
{{ define "tlowerison/standard-base.containers" }}
{{- range $i, $ctr := .containers -}}
{{- $tpl := (deepCopy (dict "container" $ctr) | merge $) }}- name: {{ if hasKey $ctr "name" }}{{ $ctr.name }}{{ else }}{{ "container-" }}{{ $i }}{{ end }}
  image: {{ include "tlowerison/standard-base.image" $ctr.image }}
  imagePullPolicy: {{ if hasKey $ctr "imagePullPolicy" }}{{ $ctr.imagePullPolicy }}{{ else }}Always{{ end }}
  {{- if hasKey $ctr "ports" }}
  ports: {{ include "tlowerison/standard-base.containerPorts" $ctr.ports | nindent 2 }}{{ end }}
  {{- if (or $ctr.env $ctr.secrets $ctr.externalSecrets) }}
  env: {{ if hasKey $ctr "env" }}{{ include "tlowerison/standard-base.env" $tpl}}{{ end }}
  {{- if hasKey $ctr "secrets" }}{{ include "tlowerison/standard-base.secrets" $tpl}}{{ end }}
  {{- if hasKey $ctr "externalSecrets" }}{{ include "tlowerison/standard-base.externalSecrets" $tpl}}{{ end }}{{ end -}}
  {{- $rest := include "tlowerison/standard-base.yaml" (omit $ctr "name" "image" "imagePullPolicy" "ports" "env" "secrets" "externalSecrets") | nindent 2 -}}
  {{- if not (eq "" (trim $rest)) }}{{ regexReplaceAll "( |\n)*$" $rest "" }}
{{ end }}{{ end }}{{ end }}

{{/* imagePullSecrets helper */}}
{{ define "tlowerison/standard-base.imagePullSecrets" }}
{{- range . -}}
- name: {{ . }}
{{- end -}}{{- end }}

{{/* base pod spec helper */}}
{{ define "tlowerison/standard-base.basePod" -}}
{{- $template := .Values.template -}}
{{- if hasKey $template "imagePullSecrets" }}{{ if (lt 0 (len $template.imagePullSecrets)) -}}
imagePullSecrets: {{ include "tlowerison/standard-base.imagePullSecrets" $template.imagePullSecrets | nindent 0 }}
{{ end }}{{ end }}
{{- if hasKey $template "initContainers" }}{{ if (lt 0 (len $template.initContainers)) -}}
initContainers: {{ include "tlowerison/standard-base.containers" (deepCopy (dict "containers" $template.initContainers) | merge (deepCopy $)) | nindent 0 }}
{{ end }}{{ end }}
{{- if hasKey $template "containers" }}{{ if (lt 0 (len $template.containers)) -}}
containers: {{ include "tlowerison/standard-base.containers" (deepCopy (dict "containers" $template.containers) | merge (deepCopy $)) | nindent 0 }}{{ end }}{{ end }}{{ end }}

{{ define "tlowerison/standard-base.pod" -}}
{{- $template := .Values.template -}}
{{- $basePod := include "tlowerison/standard-base.basePod" $ -}}
{{- $rest := include "tlowerison/standard-base.yaml" (omit $template "imagePullSecrets" "initContainers" "containers") -}}
{{ $basePod }}{{ if not (eq "" (trim $basePod)) }}{{ end }}{{ if not (eq "" (trim $rest)) }}{{ regexReplaceAll "( |\n)*$" $rest "" }}{{ end }}{{end}}
