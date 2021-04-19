{{/* name helper */}}
{{ define "tlowerison/standard-base.name" -}}
{{ if hasKey .Values "name" }}{{ .Values.name }}{{ else }}{{ .Values.global.name }}{{ end }}
{{- end }}
