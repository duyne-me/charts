# Changelog for {{ .Name }}

{{- range .Releases }}
## {{ .Version }}

{{- if .Date }}
**Release date:** {{ .Date }}
{{- end }}

{{- if .Badges }}
{{ .Badges }}
{{- end }}

{{- if .Notes }}
{{ .Notes }}
{{- end }}

{{- end }}

