{{/* pod helper */}}
{{ define "tlowerison/standard-base.pod" -}}
metadata:
  labels: {{ include "tlowerison/standard-base.labels" $ | nindent 4 }}{{ if hasKey .Values "annotations" }}
  annotations: {{ include "tlowerison/standard-base.fmt-yaml" (dict "nindent" 4 "data" .Values.annotations) }}{{ end }}
spec: {{ include "tlowerison/standard-base.pod.spec" $ | nindent 2 }}{{ end }}

{{/* pod.spec helper */}}
{{ define "tlowerison/standard-base.pod.spec" -}}
{{- $template := .Values.template -}}
{{- $base := regexReplaceAll "^( |\n)*" (include "tlowerison/standard-base.pod.spec.base" $) "" -}}
{{- $rest := regexReplaceAll "( |\n)*$" (include "tlowerison/standard-base.yaml" (omit $template "imagePullSecrets" "initContainers" "containers")) "" }}
{{- if not (eq "" (trim $base)) }}{{ $base }}
{{ end }}{{ if not (eq "" (trim $rest)) }}{{ $rest }}{{ end }}{{ end }}

{{/* pod.spec.base helper */}}
{{ define "tlowerison/standard-base.pod.spec.base" -}}
{{- $template := .Values.template -}}
{{- if hasKey $template "imagePullSecrets" }}{{ if (lt 0 (len $template.imagePullSecrets)) -}}
imagePullSecrets: {{ include "tlowerison/standard-base.pod.imagePullSecrets" $template.imagePullSecrets | nindent 0 }}{{ end }}{{ end }}
{{- if hasKey $template "initContainers" }}{{ if (lt 0 (len $template.initContainers)) }}
initContainers: {{ include "tlowerison/standard-base.pod.containers" (deepCopy $ | merge (dict "containers" $template.initContainers)) }}{{ end }}{{ end }}
{{- if hasKey $template "containers" }}{{ if (lt 0 (len $template.containers)) }}
containers: {{ include "tlowerison/standard-base.pod.containers" (deepCopy $ | merge (dict "containers" $template.containers)) }}{{ end }}{{ end }}{{ end }}

{{/* pod.imagePullSecrets helper */}}
{{ define "tlowerison/standard-base.pod.imagePullSecrets" }}
{{- range . -}}
- name: {{ . }}
{{- end -}}{{- end }}

{{/* pod.containers helper */}}
{{ define "tlowerison/standard-base.pod.containers" -}}
{{- range $i, $ctr := .containers -}}
{{- $rest := include "tlowerison/standard-base.yaml" (omit $ctr "name" "image" "imagePullPolicy" "ports" "env" "secrets" "externalSecrets") | nindent 2 -}}
{{- $tpl := (deepCopy $ | merge (dict "container" $ctr)) }}
- name: {{ if hasKey $ctr "name" }}{{ $ctr.name }}{{ else }}{{ "container-" }}{{ $i }}{{ end }}
  image: {{ include "tlowerison/standard-base.pod.container.image" $ctr.image }}
  imagePullPolicy: {{ if hasKey $ctr "imagePullPolicy" }}{{ $ctr.imagePullPolicy }}{{ else }}Always{{ end }}
  {{- if hasKey $ctr "ports" }}
  ports: {{ include "tlowerison/standard-base.pod.container.ports" $ctr.ports | nindent 2 }}{{ end }}{{ if (or (hasKey $ctr "env") (hasKey $ctr "secrets")) }}
  env: {{ if hasKey $ctr "env" }}{{ include "tlowerison/standard-base.pod.container.env" $tpl }}{{ end }}
  {{- if hasKey $ctr "secrets" }}{{ include "tlowerison/standard-base.pod.container.secrets" $tpl }}{{ end }}{{ end }}
  {{- if not (eq "" (trim $rest)) }}{{ regexReplaceAll "( |\n)*$" $rest "" }}{{ end }}{{ end }}{{ end }}

{{/* pod.container.image helper */}}
{{ define "tlowerison/standard-base.pod.container.image" -}}
{{ if hasKey . "repo" }}{{ .repo }}{{ "/" }}{{ end }}{{ .name }}{{ ":" }}{{ .tag }}
{{- end }}

{{/* pod.container.ports helper */}}
{{ define "tlowerison/standard-base.pod.container.ports" }}
{{- range $name, $port := . -}}
- name: {{ if hasKey $port "name" }}{{ $port.name }}{{ else }}{{ "port-" }}{{ $name }}{{ end }}
  containerPort: {{ $port.container }}{{ if hasKey $port "host" }}
  hostPort: {{ $port.host }}{{ end }}{{ if hasKey $port "protocol" }}
  protocol: {{ $port.protocol }}{{ end }}{{ end }}{{ end }}

{{/* pod.container.env helper */}}
{{ define "tlowerison/standard-base.pod.container.env" }}{{ range $name, $value := .container.env -}}
{{- $name = (include "tlowerison/standard-base.tpl" (deepCopy $ | merge (dict "tpl" $name))) -}}
{{- $value = (include "tlowerison/standard-base.tpl" (deepCopy $ | merge (dict "tpl" $value)) | quote) }}
  - name: {{ $name }}
    value: {{ $value }}{{ end }}{{ end }}

{{/* pod.container.secrets helper */}}
{{ define "tlowerison/standard-base.pod.container.secrets" }}{{ range $newKey, $secret := .container.secrets -}}
{{- $name := (include "tlowerison/standard-base.tpl" (deepCopy $ | merge (dict "tpl" $secret.from))) -}}
{{- $key := (include "tlowerison/standard-base.tpl" (deepCopy $ | merge (dict "tpl" $secret.key)) | quote) }}
  - name: {{ $newKey }}
    valueFrom:
      secretKeyRef:
        name: {{ $name }}
        key: {{ $key }}{{ end }}{{ end }}
