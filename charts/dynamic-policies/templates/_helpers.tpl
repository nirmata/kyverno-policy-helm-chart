{{/*
Helper function to join image registries with pipe separator
*/}}
{{- define "imageRegistries.join" -}}
{{- if . -}}
{{- join . " | " -}}
{{- end -}}
{{- end -}}

{{/*
Get the appropriate image registry pattern for a container type
*/}}
{{- define "imageRegistries.pattern" -}}
{{- $type := .type -}}
{{- $values := .values -}}
{{- if index $values.imageRegistries $type -}}
{{- include "imageRegistries.join" (index $values.imageRegistries $type) -}}
{{- else if $values.imageRegistries.global -}}
{{- include "imageRegistries.join" $values.imageRegistries.global -}}
{{- else -}}
{{- $values.allowedRegistries -}}
{{- end -}}
{{- end -}} 