{{/* Expand the name of the chart. */}}
{{- define "hue.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Fully qualified app name (fullnameOverride: hue in the umbrella → stable `hue` Service). */}}
{{- define "hue.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "hue.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "hue.labels" -}}
app.kubernetes.io/name: {{ include "hue.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{- define "hue.selectorLabels" -}}
app.kubernetes.io/name: {{ include "hue.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
