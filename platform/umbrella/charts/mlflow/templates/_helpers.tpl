{{- define "mlflow.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "mlflow.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "mlflow.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "mlflow.labels" -}}
app.kubernetes.io/name: {{ include "mlflow.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{- define "mlflow.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mlflow.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "mlflow.db.fullname" -}}
{{- printf "%s-db" (include "mlflow.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Component selectors so the server and its Postgres don't select each other. */}}
{{- define "mlflow.server.selectorLabels" -}}
{{ include "mlflow.selectorLabels" . }}
app.kubernetes.io/component: server
{{- end -}}

{{- define "mlflow.db.selectorLabels" -}}
{{ include "mlflow.selectorLabels" . }}
app.kubernetes.io/component: db
{{- end -}}
