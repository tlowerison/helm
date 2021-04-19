{{/* cronjob helper */}}
{{ define "tlowerison/standard-base.cronjob" -}}
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: {{ include "tlowerison/standard-base.name" $ }}
  labels: {{ include "tlowerison/standard-base.labels" $ | nindent 4 }}
spec: {{ include "tlowerison/standard-base.fmt-yaml" (dict "nindent" 2 "data" (omit .Values "annotations" "component" "global" "name" "standard-base" "template")) }}
  jobTemplate: {{ include "tlowerison/standard-base.pod" $ | nindent 4 }}{{ end }}
