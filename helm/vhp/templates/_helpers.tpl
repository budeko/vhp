{{/*
VHP namespace adları
*/}}
{{- define "vhp.coreNamespace" -}}vhp-core{{- end -}}
{{- define "vhp.certNamespace" -}}vhp-cert{{- end -}}
{{- define "vhp.controlNamespace" -}}vhp-control{{- end -}}
{{- define "vhp.panelNamespace" -}}vhp-panel{{- end -}}
{{- define "vhp.policyNamespace" -}}vhp-policy{{- end -}}
{{- define "vhp.backupNamespace" -}}vhp-backup{{- end -}}
{{- define "vhp.dataNamespace" -}}vhp-data{{- end -}}
{{- define "vhp.dnsNamespace" -}}vhp-dns{{- end -}}
{{- define "vhp.gitopsNamespace" -}}vhp-gitops{{- end -}}
{{- define "vhp.observabilityNamespace" -}}vhp-observability{{- end -}}

{{/*
Release name + chart label
*/}}
{{- define "vhp.labels" -}}
app.kubernetes.io/name: {{ include "vhp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "vhp.name" -}}vhp{{- end -}}
