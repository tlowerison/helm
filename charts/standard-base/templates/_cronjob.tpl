{{/* cronjob helper */}}
{{ define "tlowerison/standard-base.cronjob" -}}
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: {{include "tlowerison/standard-base.name" $}}
  labels: {{include "tlowerison/standard-base.labels" $ | nindent 4}}{{ if hasKey .Values "annotations" }}
  annotations: {{ include "tlowerison/standard-base.yaml" .Values.annotations | nindent 4 }}{{ end }}
spec: {{ include "tlowerison/standard-base.yaml" (omit .Values "component" "global" "name" "template") | nindent 2 }}
  jobTemplate:
    spec:
      template: {{ include "tlowerison/standard-base.pod" $ | nindent 8 }}{{ end }}
