{{define "name" -}}
{{if hasKey .Values "name"}}{{.Values.name}}{{else}}{{.Values.global.name}}{{end}}
{{- end}}

{{/* labels helper, for injecting labels into helm managed resources */}}
{{define "labels" -}}
app.kubernetes.io/name: {{include "name" .}}
app.kubernetes.io/instance: {{.Release.Name}}
app.kubernetes.io/version: {{.Chart.Version}}{{if hasKey .Values "component"}}
app.kubernetes.io/component: {{.Values.component}}{{end}}
app.kubernetes.io/managed-by: {{.Release.Service}}
helm.sh/chart: {{.Chart.Name}}-{{.Chart.Version | replace "+" "_" }}
meta.helm.sh/release-namespace: {{.Release.Namespace}}
{{- end}}

{{/* selections helper, for injecting selectors into helm managed resouces */}}
{{define "selectors" -}}
app.kubernetes.io/name: {{include "name" .}}
app.kubernetes.io/instance: {{.Release.Name}}
app.kubernetes.io/version: {{.Chart.Version}}{{if hasKey .Values "component"}}
app.kubernetes.io/component: {{.Values.component}}{{end}}
{{- end}}

{{define "image" -}}
{{if hasKey . "repo"}}{{.repo}}{{"/"}}{{end}}{{.name}}{{":"}}{{.tag}}
{{- end}}

{{/* env helper */}}
{{define "env"}}{{range $name, $value := .container.env}}- name: {{ $name }}
  value: {{tpl $value . | quote}}
{{- end}}{{end}}

{{/* secrets helper */}}
{{define "secrets"}}{{range $_, $name := .container.secrets}}- name: {{$name}}
  valueFrom:
    secretKeyRef:
      name: {{include "secretName"}}
      key: {{$name}}
{{- end}}{{end}}

{{/* externalSecrets helper */}}
{{define "externalSecrets"}}{{range $_, $externalSecret := .container.externalSecrets}}- name: {{tpl $externalSecret.key}}
  valueFrom:
    secretKeyRef:
      name: {{tpl $externalSecret.from . | quote}}
      key: {{tpl $externalSecret.key . | quote}}
{{- end}}{{end}}

{{/* args helper */}}
{{define "args"}}{{range .}}- {{ . | quote }}
{{- end}}{{end}}

{{/* container ports helper */}}
{{define "containerPorts"}}
{{- range $name, $port := . -}}
- name: {{if hasKey $port "name"}}{{$port.name}}{{else}}{{"port-"}}{{$name}}{{end}}
  containerPort: {{$port.container}}{{if hasKey $port "protocol"}}
  protocol: {{$port.protocol}}{{end}}
{{- end}}{{end}}

{{/* containers helper */}}
{{define "containers"}}
{{- range $i, $ctr := .containers -}}
{{- $tplEnv := dict "container" $ctr "Values" .Values -}}
- name: {{if hasKey $ctr "name"}}{{$ctr.name}}{{else}}{{"container-"}}{{$i}}{{end}}
  image: {{include "image" $ctr.image}}
  imagePullPolicy: {{if hasKey $ctr "imagePullPolicy"}}{{$ctr.imagePullPolicy}}{{else}}Always{{end}}{{if hasKey $ctr "ports"}}
  ports: {{include "containerPorts" $ctr.ports | nindent 2}}{{end}}{{if hasKey $ctr "command"}}
  command: {{$ctr.command | toPrettyJson}}{{end}}{{if (or $ctr.env $ctr.secrets $ctr.externalSecrets)}}
  env: {{if hasKey $ctr "env"}}{{include "env" $tplEnv}}{{end}}
     {{- if hasKey $ctr "secrets"}}{{include "secrets" $tplEnv}}{{end}}
     {{- if hasKey $ctr "externalSecrets"}}{{include "externalSecrets" $tplEnv}}{{end}}
  {{- end}}{{if hasKey $ctr "args"}}
  args: {{include "args" $ctr.args | nindent 2}}{{end}}{{if hasKey $ctr "resources"}}
  resources: {{mustToPrettyJson $ctr.resources}}{{end}}{{if hasKey $ctr "lifecycle"}}
  lifecycle: {{mustToPrettyJson $ctr.lifecycle}}{{end}}{{if hasKey $ctr "volumeMounts"}}
  volumeMounts: {{mustToPrettyJson $ctr.volumeMounts}}{{end}}
{{- end}}{{end}}

{{/* imagePullSecrets helper */}}
{{define "imagePullSecrets"}}
{{- range . -}}
- name: {{.}}
{{- end -}}{{- end}}
