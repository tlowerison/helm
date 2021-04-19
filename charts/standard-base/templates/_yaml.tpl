{{/* yaml helper */}}
{{ define "tlowerison/standard-base.yaml" }}{{ if kindIs "map" . }}{{ include "tlowerison/standard-base.yaml.map" . }}{{ else if kindIs "slice" . }}{{ include "tlowerison/standard-base.yaml.slice" . }}{{ else }}{{ toString . }}{{ end }}{{ end }}

{{/* yaml.map helper */}}
{{ define "tlowerison/standard-base.yaml.map" }}{{ if eq 0 (len (keys .)) }}{{ include "tlowerison/standard-base.empty" . }}{{ else }}{{ $baseMap := include "tlowerison/standard-base.yaml.map.base" . }}{{ trimSuffix "\n" $baseMap }}{{ end }}{{ end }}

{{/* yaml.map.base helper */}}
{{ define "tlowerison/standard-base.yaml.map.base" }}{{ range $key, $value := . }}{{ if not (kindIs "invalid" $value) }}{{ $key }}: {{ if kindIs "map" $value -}}
{{- $fmt := include "tlowerison/standard-base.yaml.map" $value }}{{ if eq (include "tlowerison/standard-base.empty" $value) $fmt }}{{ $fmt }}{{ else }}{{ "\n  " }}{{ $fmt | nindent 2 | trim }}{{ end }}
{{ else if kindIs "slice" $value }}{{ include "tlowerison/standard-base.yaml.slice" $value }}
{{ else }}{{ toString $value }}
{{ end }}{{ end }}{{ end }}{{ end }}

{{/* yaml.slice helper */}}
{{ define "tlowerison/standard-base.yaml.slice" }}{{ if eq 0 (len .) }}{{ include "tlowerison/standard-base.empty" . }}{{ else -}}
{{- range $key, $value := . -}}
{{- if empty $value }}
- {{ include "tlowerison/standard-base.empty" $value }}
{{- else }}
- {{ include "tlowerison/standard-base.yaml" $value | nindent 2 | trim }}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/* empty helper */}}
{{ define "tlowerison/standard-base.empty" -}}
{{- if kindIs "map" . -}}{}
{{- else if kindIs "slice" . -}}[]
{{- else -}}{{ toString . }}
{{- end -}}
{{- end -}}

{{/* fmt-yaml helper */}}
{{ define "tlowerison/standard-base.fmt-yaml" -}}
{{- if empty .data -}}
{{ include "tlowerison/standard-base.empty" .data }}
{{- else if kindIs "map" .data -}}
{{ include "tlowerison/standard-base.yaml" .data | nindent .nindent }}
{{- else if kindIs "slice" .data -}}
{{ include "tlowerison/standard-base.yaml" .data | indent (int (add .nindent -2)) }}
{{- else -}}
{{ toString .data }}
{{- end -}}
{{- end -}}
