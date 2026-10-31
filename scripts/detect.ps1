<#
.SYNOPSIS
Detect a cua-driver installation on Windows and report machine state as JSON.

.PARAMETER Path
Optional explicit path to cua-driver.exe (user-provided install location).
#>
param([string]$Path)

$ErrorActionPreference = 'SilentlyContinue'

$candidates = New-Object System.Collections.Generic.List[string]
if ($Path) { $candidates.Add($Path) }
$cmd = Get-Command cua-driver
if ($cmd) { $candidates.Add($cmd.Source) }
$candidates.Add((Join-Path $env:LOCALAPPDATA 'Programs\Cua\cua-driver\bin\cua-driver.exe'))
$candidates.Add((Join-Path $env:USERPROFILE '.cua-driver\packages\current\cua-driver.exe'))

$exe = $null
foreach ($c in $candidates) {
    if ($c -and (Test-Path -LiteralPath $c -PathType Leaf)) { $exe = $c; break }
}

$result = [ordered]@{
    platform       = 'windows'
    found          = [bool]$exe
    exe            = $exe
    version        = $null
    doctor_ok      = $false
    doctor_fail    = @()
    daemon         = $null
    autostart      = $null
    mcp_invocation = $null
}

if ($exe) {
    $result.version = ((& $exe --version 2>&1) -join ' ').Trim()

    $doctor = (& $exe doctor 2>&1) -join "`n"
    $result.doctor_fail = @($doctor -split "`n" | Where-Object { $_ -match '\[fail\]' } | ForEach-Object { $_.Trim() })
    $result.doctor_ok = ($result.doctor_fail.Count -eq 0)

    $statusText = ((& $exe status 2>&1) -join ' ')
    $result.daemon = if ($statusText -match 'is running') { 'running' } else { 'not running' }

    $autoText = ((& $exe autostart status 2>&1) -join ' ')
    $result.autostart = ($autoText -replace '\s+', ' ').Trim()

    $manifest = (& $exe manifest 2>&1) -join "`n"
    if ($manifest -match '\{') {
        try { $result.mcp_invocation = ($manifest | ConvertFrom-Json).mcp_invocation } catch { }
    }
    if (-not $result.mcp_invocation) {
        $result.mcp_invocation = [ordered]@{ command = $exe; args = @('mcp') }
    }
}

$result | ConvertTo-Json -Depth 6
