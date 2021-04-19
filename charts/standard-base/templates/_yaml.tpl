{{/* yaml helper */}}
{{ define "tlowerison/standard-base.yaml" }}{{ if kindIs "map" . }}{{ include "tlowerison/standard-base.yaml.map" . }}{{ else if kindIs "slice" . }}{{ include "tlowerison/standard-base.yaml.slice" . }}{{ else }}{{ toString . }}{{ end }}{{ end }}

{{/* yaml.base helper */}}
{{ define "tlowerison/standard-base.yaml.base" }}{{ range $key, $value := . }}{{ if not (kindIs "invalid" $value) }}{{ $key }}: {{ if kindIs "map" $value }}{{ "\n  " }}{{ include "tlowerison/standard-base.yaml.map" $value | nindent 2 | trim }}
{{ else if kindIs "slice" $value }}{{ include "tlowerison/standard-base.yaml.slice" $value }}
{{ else }}{{ toString $value }}
{{ end }}{{ end }}{{ end }}{{ end }}

{{/* yaml.map helper */}}
{{ define "tlowerison/standard-base.yaml.map" }}{{ $baseMap := include "tlowerison/standard-base.yaml.base" . }}{{ trimSuffix "\n" $baseMap }}{{ end }}

{{/* yaml.slice helper */}}
{{ define "tlowerison/standard-base.yaml.slice" }}{{ range $key, $value := . }}
- {{ include "tlowerison/standard-base.yaml" $value | nindent 2 | trim }}{{ end }}{{ end }}
