# ==============================================================================
# StyleSync Local Designer Seeding Runner
# ==============================================================================
param(
    [string]$DbHost = "localhost",
    [int]$Port = 5433,
    [string]$Database = "stylesync_db",
    [string]$Username = "postgres",
    [string]$Password = "postgres"
)

$ErrorActionPreference = "Stop"

Write-Host "Checking local PostgreSQL connection at ${DbHost}:${Port}/${Database}..." -ForegroundColor Cyan

$scriptPath = Join-Path $PSScriptRoot "seed_dev_designers.sql"
if (-not (Test-Path $scriptPath)) {
    Write-Error "Could not find SQL file at $scriptPath"
    exit 1
}

# Option 1: Try via docker exec if running in local docker container (stylesync-db)
$dockerRunning = $false
try {
    $containerStatus = docker inspect -f '{{.State.Running}}' stylesync-db 2>$null
    if ($containerStatus -eq "true") {
        $dockerRunning = $true
    }
} catch { }

if ($dockerRunning) {
    Write-Host "Found running Docker container 'stylesync-db'. Executing SQL via container..." -ForegroundColor Green
    Get-Content $scriptPath -Raw | docker exec -i stylesync-db psql -U $Username -d $Database
    Write-Host "Seeding completed successfully via Docker!" -ForegroundColor Green
    exit 0
}

# Option 2: Fall back to local psql command
if (Get-Command psql -ErrorAction SilentlyContinue) {
    Write-Host "Executing SQL via local psql..." -ForegroundColor Green
    $env:PGPASSWORD = $Password
    psql -h $DbHost -p $Port -U $Username -d $Database -f $scriptPath
    Write-Host "Seeding completed successfully via psql!" -ForegroundColor Green
    exit 0
}

Write-Host "Neither 'stylesync-db' docker container nor local 'psql' was detected." -ForegroundColor Yellow
Write-Host "Make sure your database is running via: docker compose up -d postgres" -ForegroundColor Yellow
Write-Host "Then run: Get-Content scripts/seed_dev_designers.sql -Raw | docker exec -i stylesync-db psql -U postgres -d stylesync_db" -ForegroundColor Cyan
