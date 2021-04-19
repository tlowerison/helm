{{/* matchLabels helper */}}
{{ define "tlowerison/standard-base.matchLabels" -}}
app.kubernetes.io/name: {{ include "tlowerison/standard-base.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.Version }}{{ if hasKey .Values "component" }}
app.kubernetes.io/component: {{ .Values.component }}{{ end }}{{ if hasKey .Values "selector" }}{{ if hasKey .Values.selector "matchLabels" }}
{{ include "tlowerison/standard-base.yaml" .Values.selector.matchLabels }}{{ end }}{{ end }}{{ end }}
