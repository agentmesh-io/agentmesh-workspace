{{/*
Expand the chart name.
*/}}
{{- define "agentmesh.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Fully-qualified app name. We prefer the release name when it already
contains the chart name to avoid `agentmesh-agentmesh`.
*/}}
{{- define "agentmesh.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "agentmesh.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels (Helm + Kubernetes recommended set).
*/}}
{{- define "agentmesh.labels" -}}
helm.sh/chart: {{ include "agentmesh.chart" . }}
{{ include "agentmesh.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: agentmesh
agentmesh.io/stage: {{ .Values.stage | quote }}
{{- end -}}

{{- define "agentmesh.selectorLabels" -}}
app.kubernetes.io/name: {{ include "agentmesh.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
ServiceAccount name resolver.
*/}}
{{- define "agentmesh.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "agentmesh.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
Container image reference (`appVersion` fallback when tag is unset).
*/}}
{{- define "agentmesh.image" -}}
{{- printf "%s:%s" .Values.image.repository (default .Chart.AppVersion .Values.image.tag) -}}
{{- end -}}

{{/*
Resolve the SPRING_PROFILES_ACTIVE — explicit override wins, otherwise
falls back to the canonical stage label.
*/}}
{{- define "agentmesh.springProfile" -}}
{{- $explicit := index .Values.config "SPRING_PROFILES_ACTIVE" -}}
{{- if $explicit -}}
{{- $explicit -}}
{{- else -}}
{{- .Values.stage -}}
{{- end -}}
{{- end -}}

{{/*
Resolve the Secret name (`existingSecret` wins for prod-style flows).
*/}}
{{- define "agentmesh.secretName" -}}
{{- if .Values.existingSecret -}}
{{- .Values.existingSecret -}}
{{- else -}}
{{- default (printf "%s-secrets" (include "agentmesh.fullname" .)) .Values.secret.name -}}
{{- end -}}
{{- end -}}

