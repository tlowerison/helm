{{/* labels helper */}}
{{ define "tlowerison/standard-base.labels" -}}
app.kubernetes.io/name: {{ include "tlowerison/standard-base.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.Version }}{{ if hasKey .Values "component" }}
app.kubernetes.io/component: {{ .Values.component }}{{ end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
meta.helm.sh/release-namespace: {{ .Release.Namespace }}{{ if hasKey .Values "labels" }}
{{ include "tlowerison/standard-base.yaml" (dict "Values" .Values "key" "labels") }}
{{- end }}{{ end }}
