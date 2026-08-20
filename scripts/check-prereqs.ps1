# Quick check that everyone on the team has the required tooling installed.
# Usage (PowerShell): .\scripts\check-prereqs.ps1
#
# If this fails to run with an "execution policy" error, either:
#   Right-click the file -> Properties -> Unblock, or
#   run once: Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

function Check-Tool {
    param(
        [string]$Name,
        [string]$Command,
        [string]$VersionArg = "--version"
    )

    $found = Get-Command $Command -ErrorAction SilentlyContinue
    if ($found) {
        try {
            $version = & $Command $VersionArg 2>&1 | Select-Object -First 1
        } catch {
            $version = "(installed, version check failed)"
        }
        Write-Host "OK  $Name found: $version" -ForegroundColor Green
    } else {
        Write-Host "MISSING  $Name NOT found - install it before continuing" -ForegroundColor Red
    }
}

Write-Host "Checking prerequisites for the StyleSync project..."
Write-Host ""

Check-Tool -Name "Docker"    -Command "docker"
Check-Tool -Name ".NET SDK"  -Command "dotnet"
Check-Tool -Name "Node.js"   -Command "node"
Check-Tool -Name "npm"       -Command "npm"
Check-Tool -Name "Python"    -Command "python"
Check-Tool -Name "Flutter"   -Command "flutter"

Write-Host ""
Write-Host "If anything is missing, see docs\setup\*.md for install links."
