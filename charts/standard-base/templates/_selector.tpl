{{/* selector helper */}}
{{ define "tlowerison/standard-base.selector" -}}
matchLabels:
{{ include "tlowerison/standard-base.matchLabels" . | indent 2 }}{{ if hasKey .Values "selector" }}
{{ include "tlowerison/standard-base.yaml" (omit .Values.selector "matchLabels") }}{{ end }}
{{- end }}
