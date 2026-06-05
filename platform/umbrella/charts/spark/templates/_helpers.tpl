{{/* Expand the name of the chart. */}}
{{- define "spark.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Fully qualified app name. Kept stable (or pinned via fullnameOverride) so the
Service has a predictable DNS name.
*/}}
{{- define "spark.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "spark.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "spark.labels" -}}
app.kubernetes.io/name: {{ include "spark.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{- define "spark.selectorLabels" -}}
app.kubernetes.io/name: {{ include "spark.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
