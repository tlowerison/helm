{{define "name" -}}
{{if .name}}{{.name}}{{"-"}}{{end}}{{.cpt}}{{if .env}}{{"-"}}{{.env}}{{end}}
{{- end}}

{{define "secretName" -}}
{{list .name .cpt .env | join "-"}}
{{- end}}

{{/* labels helper, for injecting labels into helm managed resources */}}
{{define "labels" -}}
app.kubernetes.io/name: {{.name}}
app.kubernetes.io/managed-by: Helm
app.kubernetes.io/instance: {{.instance}}
app.kubernetes.io/version: {{.version}}
app.kubernetes.io/component: {{.cpt}}
environment: {{.env}}
meta.helm.sh/release-namespace: {{.releaseNamespace}}
tier: {{.tier}}
{{- end}}

{{/* selections helper, for injecting selectors into helm managed resouces */}}
{{define "selectors" -}}
app.kubernetes.io/name: {{.name}}
app.kubernetes.io/instance: {{.instance}}
app.kubernetes.io/version: {{.version}}
app.kubernetes.io/component: {{.chartName}}
environment: {{.env}}
tier: {{.tier}}
{{- end}}

{{define "image" -}}
{{if hasKey . "repo"}}{{.repo}}{{"/"}}{{end}}{{if hasKey . "name"}}{{.name}}{{else}}{{.Values.name}}{{"-"}}{{index .Values "standard-deployment" | .tier}}{{end}}{{":"}}{{.tag}}
{{- end}}

{{/* env helper */}}
{{define "env"}}{{range $name, $value := .container.env}}- name: {{ $name }}
  value: {{tpl $value . | quote}}
{{end}}{{end}}

{{/* secrets helper */}}
{{define "secrets"}}{{range $_, $name := .container.secrets}}- name: {{$name}}
  valueFrom:
    secretKeyRef:
      name: {{include "secretName"}}
      key: {{$name}}
{{end}}{{end}}

{{/* externalSecrets helper */}}
{{define "externalSecrets"}}{{range $_, $externalSecret := .container.externalSecrets}}- name: {{tpl $externalSecret.key}}
  valueFrom:
    secretKeyRef:
      name: {{tpl $externalSecret.from . | quote}}
      key: {{tpl $externalSecret.key . | quote}}
{{end}}{{end}}

{{/* args helper */}}
{{define "args"}}{{range .}}- {{ . | quote }}
{{end}}{{end}}

{{/* ports helper */}}
{{define "ports"}}
{{range $name, $port := .}}
- name: {{if hasKey $port "name"}}{{$port.name}}{{else}}{{"port-"}}{{$name}}{{end}}
  containerPort: {{$port.value}}{{if hasKey $port "protocol"}}
  protocol: {{$port.protocol}}{{end}}
{{end}}{{end}}

{{/* containers helper */}}
{{define "containers"}}
{{- range $i, $ctr := .containers -}}
{{- required "container.image is required" $ctr.image -}}
{{- $tplEnv := dict "container" $ctr "Values" .Values -}}
- name: {{if hasKey $ctr "name"}}{{$ctr.name}}{{else}}{{"container-"}}{{$i}}{{end}}
  image: {{include "image" $ctr.image}}
  imagePullPolicy: {{if hasKey $ctr "imagePullPolicy"}}{{$ctr.imagePullPolicy}}{{else}}Always{{end}}
  ports: {{include "ports" $ctr.ports | nindent 2}}{{if hasKey $ctr "command"}}
  command: {{$ctr.command | toPrettyJson}}{{end}}{{if (or $ctr.env $ctr.secrets $ctr.externalSecrets)}}
  env: {{if hasKey $ctr "env"}}{{include "env" $tplEnv}}{{end}}
     {{- if hasKey $ctr "secrets"}}{{include "secrets" $tplEnv}}{{end}}
     {{- if hasKey $ctr "externalSecrets"}}{{include "externalSecrets" $tplEnv}}{{end}}
  {{- end}}{{if hasKey $ctr "args"}}
  args: {{include "args" $ctr.args | nindent 2}}{{end}}{{if hasKey $ctr "resources"}}
  resources: {{mustToPrettyJson $ctr.resources}}{{end}}{{if hasKey $ctr "lifecycle"}}
  lifecycle: {{mustToPrettyJson $ctr.lifecycle}}{{end}}{{if hasKey $ctr "volumeMounts"}}
  volumeMounts: {{mustToPrettyJson $ctr.volumeMounts}}{{end}}
{{end}}{{end}}

{{/* imagePullSecrets helper */}}
{{define "imagePullSecrets"}}
{{range .}}
- name: {{.}}
{{end}}{{end}}
