{{/* tpl helper */}}
{{ define "tlowerison/standard-base.tpl" }}{{ if (regexMatch "^\\{\\{.*\\}\\}$" .tpl) }}{{ tpl .tpl $ }}{{ else }}{{ .tpl }}{{ end }}{{ end }}
