{{/* Expand the name of the chart. */}}
{{- define "knox.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Fully qualified app name. Kept stable (fullnameOverride: knox in the umbrella)
so the gateway Service has a predictable DNS name to port-forward / ingress.
*/}}
{{- define "knox.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "knox.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "knox.labels" -}}
app.kubernetes.io/name: {{ include "knox.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{- define "knox.selectorLabels" -}}
app.kubernetes.io/name: {{ include "knox.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
