{{/* Expand the name of the chart. */}}
{{- define "iceberg-rest.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Fully qualified app name. Kept stable (release-prefixed) so Trino and Spark can
address the catalog Service by a predictable DNS name.
*/}}
{{- define "iceberg-rest.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "iceberg-rest.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "iceberg-rest.labels" -}}
app.kubernetes.io/name: {{ include "iceberg-rest.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{- define "iceberg-rest.selectorLabels" -}}
app.kubernetes.io/name: {{ include "iceberg-rest.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
