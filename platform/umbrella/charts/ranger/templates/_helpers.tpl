{{/* Chart name. */}}
{{- define "ranger.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Base fully-qualified name. Component Services derive `<fullname>-admin` and
`<fullname>-db` from it; set fullnameOverride: ranger in the umbrella to get the
stable `ranger-admin` / `ranger-db` names load-policies.sh expects.
*/}}
{{- define "ranger.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "ranger.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "ranger.admin.fullname" -}}
{{- printf "%s-admin" (include "ranger.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ranger.db.fullname" -}}
{{- printf "%s-db" (include "ranger.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ranger.labels" -}}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
app.kubernetes.io/part-of: {{ include "ranger.name" . }}
{{- end -}}

{{- define "ranger.admin.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ranger.name" . }}
app.kubernetes.io/component: admin
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "ranger.db.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ranger.name" . }}
app.kubernetes.io/component: db
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
