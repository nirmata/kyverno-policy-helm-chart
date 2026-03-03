{{- define "kyverno-policy.patchValidationFailureAction" -}}
{{- regexReplaceAll "(?m)^([[:space:]]*)validationFailureAction:.*$" .content (printf "${1}validationFailureAction: \"%s\"" .context.Values.validationFailureAction) }}
{{- end -}}
