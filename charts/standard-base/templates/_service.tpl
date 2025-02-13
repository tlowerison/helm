{{/* service helper (ClusterIP) */}}
{{ define "tlowerison/standard-base.service" -}}
{{- $portPairs := list -}}
{{- range $ctrName, $ctr := .Values.template.containers -}}
  {{- range $portName, $port := $ctr.ports -}}
    {{- $portPairs = append $portPairs (dict "name" $portName "port" $port) -}}
  {{- end -}}
{{- end -}}
{{- if (lt 0 (len $portPairs)) -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "tlowerison/standard-base.name" $ }}
  labels: {{ include "tlowerison/standard-base.labels" $ | nindent 4 }}
spec:
  type: ClusterIP
  selector: {{ include "tlowerison/standard-base.matchLabels" $ | nindent 4 }}
  ports: {{ range $portPair := $portPairs -}}
    {{- $portName := $portPair.name }}
    {{- $port := $portPair.port }}
  - name: {{ if hasKey $port "name" }}{{ $port.name }}{{ else }}{{ "port-" }}{{ $portName }}{{ end }}
    port: {{ if hasKey $port "service" }}{{ $port.service }}{{ else }}{{ $port.container }}{{ end }}
    targetPort: {{ $port.container }}
    {{- if hasKey $port "protocol" }}
    protocol: {{ $port.protocol }}{{ end }}{{ end }}{{ end }}{{ end }}
