{{/* configmap helper */}}
{{ define "tlowerison/standard-base.configmap" -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "tlowerison/standard-base.name" $ }}
  labels: {{ include "tlowerison/standard-base.labels" $ | nindent 4 }}
data: {{ include "tlowerison/standard-base.fmt-yaml" (dict "nindent" 2 "data" .Values.data)}}
{{- end }}
