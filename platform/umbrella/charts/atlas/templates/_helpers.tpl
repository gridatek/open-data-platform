{{/* Chart name. */}}
{{- define "atlas.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Fully qualified name. Kept stable (or fullnameOverride) so register-lineage and
the console can address Atlas by a predictable DNS name.
*/}}
{{- define "atlas.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "atlas.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "atlas.labels" -}}
app.kubernetes.io/name: {{ include "atlas.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{- define "atlas.selectorLabels" -}}
app.kubernetes.io/name: {{ include "atlas.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Health-check command: wget /api/atlas/admin/version with the admin creds from the
ATLAS_USER/ATLAS_PASSWORD env (the image ships wget, not curl). Returns non-zero
unless Atlas answers 200, so it gates the startup/readiness/liveness probes.
*/}}
{{- define "atlas.probeCommand" -}}
- sh
- -c
- wget -q -O /dev/null --user="$ATLAS_USER" --password="$ATLAS_PASSWORD" http://127.0.0.1:{{ .Values.service.port }}/api/atlas/admin/version
{{- end -}}

{{/* Image ref: prefer digest, fall back to tag. */}}
{{- define "atlas.image" -}}
{{- if .Values.image.digest -}}
{{- printf "%s@%s" .Values.image.repository .Values.image.digest -}}
{{- else -}}
{{- printf "%s:%s" .Values.image.repository .Values.image.tag -}}
{{- end -}}
{{- end -}}
