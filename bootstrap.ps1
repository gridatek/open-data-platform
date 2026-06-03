# One-command bootstrap of the Open Data Platform (docker-compose laptop subset).
#
#   .\bootstrap.ps1            # bring up the whole platform
#   .\bootstrap.ps1 core       # just the Phase 0 lakehouse
#   .\bootstrap.ps1 down       # tear everything down
#
# Requires: Docker Desktop (with the compose plugin).
param([string]$Action = "all")

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not (Test-Path quickstart/.env)) {
  Copy-Item quickstart/.env.example quickstart/.env
}

$compose = @(
  "--project-directory", "quickstart",
  "-f", "quickstart/docker-compose.yml",
  "-f", "quickstart/docker-compose.governance.yml",
  "-f", "quickstart/docker-compose.services.yml",
  "-f", "quickstart/docker-compose.console.yml"
)

switch ($Action) {
  "core" { docker compose --project-directory quickstart -f quickstart/docker-compose.yml up -d }
  "down" { docker compose @compose down -v }
  { $_ -in @("all", "") } {
    Write-Host "Bringing up the whole platform (heavy — Ranger build, Atlas, all services)."
    docker compose @compose up -d --build
  }
  default { Write-Error "usage: .\bootstrap.ps1 [all|core|down]"; exit 1 }
}

Write-Host ""
Write-Host "Console : http://localhost:8090/api/services"
Write-Host "Superset: http://localhost:8088   Airflow: http://localhost:8082   MLflow: http://localhost:5000"
Write-Host "Ranger  : http://localhost:6080   Atlas:   http://localhost:21000  NiFi:   http://localhost:8095/nifi"
