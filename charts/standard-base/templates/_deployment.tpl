{{/* deployment helper */}}
{{ define "tlowerison/standard-base.deployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "tlowerison/standard-base.name" $ }}
  labels: {{ include "tlowerison/standard-base.labels" $ | nindent 4 }}
spec:
  replicas: {{ .Values.replicas }}
  selector: {{ include "tlowerison/standard-base.selector" $ | nindent 4 }}
  template: {{ include "tlowerison/standard-base.pod" $ | nindent 4 }}{{ end }}
