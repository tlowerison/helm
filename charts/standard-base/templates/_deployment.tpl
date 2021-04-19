{{/* deployment helper */}}
{{ define "tlowerison/standard-base.deployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "tlowerison/standard-base.name" $ }}
  labels: {{ include "tlowerison/standard-base.labels" $ | nindent 4 }}{{ if hasKey .Values "annotations" }}
  annotations: {{ include "tlowerison/standard-base.yaml" .Values.annotations | nindent 4 }}{{ end }}
spec:
  replicas: {{ .Values.replicas }}
  selector: {{ include "tlowerison/standard-base.selector" $ | nindent 4 }}
  template: {{ include "tlowerison/standard-base.pod" $ | nindent 4 }}{{ end }}
