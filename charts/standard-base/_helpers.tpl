{{ define "standard-base.yaml" }}{{ if kindIs "map" . }}{{ include "standard-base.map" . }}{{ else if kindIs "slice" . }}{{ include "standard-base.slice" . }}{{ else }}{{ toString . }}{{ end }}{{ end }}

{{ define "standard-base.baseMap" }}{{ range $key, $value := . }}{{ if not (kindIs "invalid" $value) }}{{ $key }}: {{ if kindIs "map" $value }}{{ "\n  " }}{{ include "standard-base.map" $value | nindent 2 | trim }}
{{ else if kindIs "slice" $value }}{{ include "standard-base.slice" $value }}
{{ else }}{{ toString $value }}
{{ end }}{{ end }}{{ end }}{{ end }}

{{ define "standard-base.map" }}{{ $baseMap := include "standard-base.baseMap" . }}{{ trimSuffix "\n" $baseMap }}{{ end }}

{{ define "standard-base.slice" }}{{ range $key, $value := . }}
- {{ include "standard-base.yaml" $value | nindent 2 | trim }}{{ end }}{{ end }}

{{ define "standard-base.name" -}}
{{ if hasKey .Values "name" }}{{ .Values.name }}{{ else }}{{ .Values.global.name }}{{ end }}
{{- end }}

{{/* labels helper, for injecting labels into helm managed resources */}}
{{ define "standard-base.labels" -}}
app.kubernetes.io/name: {{ include "standard-base.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.Version }}{{ if hasKey .Values "component" }}
app.kubernetes.io/component: {{ .Values.component }}{{ end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
meta.helm.sh/release-namespace: {{ .Release.Namespace }}
{{- end }}

{{/* selections helper, for injecting selectors into helm managed resouces */}}
{{ define "standard-base.selectors" -}}
app.kubernetes.io/name: {{ include "standard-base.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.Version }}{{ if hasKey .Values "component" }}
app.kubernetes.io/component: {{ .Values.component }}{{ end }}
{{- end }}

{{ define "standard-base.image" -}}
{{ if hasKey . "repo" }}{{ .repo }}{{ "/" }}{{ end }}{{ .name }}{{ ":" }}{{ .tag }}
{{- end }}

{{/* env helper */}}
{{ define "standard-base.env" }}{{ range $name, $value := .container.env }}
  - name: {{ $name }}
    value: {{ tpl $value $ | quote }}{{ end }}{{ end }}

{{/* secrets helper */}}
{{ define "standard-base.secrets" }}{{ range $_, $name := .container.secrets }}- name: {{ $name }}
  valueFrom:
    secretKeyRef:
      name: {{ include "standard-base.secretName" }}
      key: {{ $name }}
{{- end }}{{ end }}

{{/* externalSecrets helper */}}
{{ define "standard-base.externalSecrets" }}{{ range $_, $externalSecret := .container.externalSecrets }}- name: {{ tpl $externalSecret.key }}
  valueFrom:
    secretKeyRef:
      name: {{ tpl $externalSecret.from . | quote }}
      key: {{ tpl $externalSecret.key . | quote }}
{{- end }}{{ end }}

{{/* args helper */}}
{{ define "standard-base.args" }}{{ range . }}- {{ . | quote }}
{{- end }}{{ end }}

{{/* container ports helper */}}
{{ define "standard-base.containerPorts" }}
{{- range $name, $port := . -}}
- name: {{ if hasKey $port "name" }}{{ $port.name }}{{ else }}{{ "port-" }}{{ $name }}{{ end }}
  containerPort: {{ $port.container }}{{ if hasKey $port "protocol" }}
  protocol: {{ $port.protocol }}{{ end }}
{{- end }}{{ end }}

{{/* containers helper */}}
{{ define "standard-base.containers" }}
{{- range $i, $ctr := .containers -}}
{{- $tpl := (deepCopy (dict "container" $ctr) | merge $) -}}
- name: {{ if hasKey $ctr "name" }}{{ $ctr.name }}{{ else }}{{ "container-" }}{{ $i }}{{ end }}
  image: {{ include "standard-base.image" $ctr.image }}
  imagePullPolicy: {{ if hasKey $ctr "imagePullPolicy" }}{{ $ctr.imagePullPolicy }}{{ else }}Always{{ end }}
  {{- if hasKey $ctr "ports" }}
  ports: {{ include "standard-base.containerPorts" $ctr.ports | nindent 2 }}{{ end }}
  {{- if (or $ctr.env $ctr.secrets $ctr.externalSecrets) }}
  env: {{ if hasKey $ctr "env" }}{{ include "standard-base.env" $tpl}}{{ end }}
  {{- if hasKey $ctr "secrets" }}{{ include "standard-base.secrets" $tpl}}{{ end }}
  {{- if hasKey $ctr "externalSecrets" }}{{ include "standard-base.externalSecrets" $tpl}}{{ end }}{{ end -}}
  {{- $rest := include "standard-base.yaml" (omit $ctr "name" "image" "imagePullPolicy" "ports" "env" "secrets" "externalSecrets") | nindent 2 -}}
  {{- if not (eq "" (trim $rest)) }}{{ regexReplaceAll "( |\n)*$" $rest "" }}{{ end }}
{{- end }}{{ end }}

{{/* imagePullSecrets helper */}}
{{ define "standard-base.imagePullSecrets" }}
{{- range . -}}
- name: {{ . }}
{{- end -}}{{- end }}

{{/* base pod spec helper */}}
{{ define "standard-base.basePod" -}}
{{- $template := .Values.template -}}
{{- if hasKey $template "imagePullSecrets" }}{{ if (lt 0 (len $template.imagePullSecrets)) -}}
imagePullSecrets: {{ include "standard-base.imagePullSecrets" $template.imagePullSecrets | nindent 0 }}
{{ end }}{{ end }}
{{- if hasKey $template "initContainers" }}{{ if (lt 0 (len $template.initContainers)) -}}
initContainers: {{ include "standard-base.containers" $template.initContainers | nindent 0 }}
{{ end }}{{ end }}
{{- if hasKey $template "containers" }}{{ if (lt 0 (len $template.containers)) -}}
containers: {{ include "standard-base.containers" (deepCopy (dict "containers" $template.containers) | merge $) | nindent 0 }}{{ end }}{{ end }}{{ end }}

{{ define "standard-base.pod" -}}
{{- $template := .Values.template -}}
{{- $basePod := include "standard-base.basePod" $ -}}
{{- $rest := include "standard-base.yaml" (omit $template "imagePullSecrets" "initContainers" "containers") -}}
{{ $basePod }}{{ if not (eq "" (trim $basePod)) }}
{{ end }}{{ if not (eq "" (trim $rest)) }}{{ regexReplaceAll "( |\n)*$" $rest "" }}{{ end }}{{end}}
