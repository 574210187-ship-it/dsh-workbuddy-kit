#requires -Version 5.1
<#
  DSH WorkBuddy Kit bootstrap
  Restores DeepSeek Harness 0.2.2-rc.5 with plugins, config and settings
  on a fresh Windows machine. Session records are intentionally excluded.
  Repository: https://github.com/574210187-ship-it/dsh-workbuddy-kit
#>
[CmdletBinding()]
param(
    [string]$InstallDir = '',
    [string]$DocsRoot = '',
    [switch]$NoLaunch,
    [switch]$SkipMagpie
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$repo = '574210187-ship-it/dsh-workbuddy-kit'
$releaseBase = "https://github.com/$repo/releases/latest/download"
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

function Write-Step([string]$text) {
    Write-Host ""
    Write-Host "==> $text" -ForegroundColor Cyan
}

function Get-ReleaseFile([string]$name, [string]$dest) {
    if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Force }
    $urls = @(
        "$releaseBase/$name",
        "https://github.com/$repo/releases/latest/download/$name"
    )
    $lastError = $null
    foreach ($url in $urls) {
        try {
            Write-Host "Downloading $name ..."
            Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing -Headers @{ 'User-Agent' = 'dsh-workbuddy-kit' }
            if ((Test-Path -LiteralPath $dest) -and (Get-Item -LiteralPath $dest).Length -gt 0) { return }
        } catch { $lastError = $_ }
    }
    throw "Download failed: $name ; $lastError"
}

function Stop-TargetDsh([string]$targetDir) {
    Get-Process -Name 'DeepSeek Harness' -ErrorAction SilentlyContinue |
        Where-Object { $_.Path -and $_.Path.StartsWith($targetDir, [StringComparison]::OrdinalIgnoreCase) } |
        Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 800
}

function New-Shortcut([string]$target, [string]$arguments, [string]$workdir, [string]$name) {
    $shell = New-Object -ComObject WScript.Shell
    $desktop = [Environment]::GetFolderPath('Desktop')
    $lnk = $shell.CreateShortcut((Join-Path $desktop $name))
    $lnk.TargetPath = $target
    $lnk.Arguments = $arguments
    $lnk.WorkingDirectory = $workdir
    $lnk.Description = 'DeepSeek Harness'
    $lnk.Save()
}

Write-Step 'Select install location'
if ([string]::IsNullOrWhiteSpace($InstallDir)) {
    if (Test-Path 'D:\') { $InstallDir = 'D:\DSH022' }
    elseif (Test-Path 'E:\') { $InstallDir = 'E:\DSH022' }
    else { $InstallDir = Join-Path $env:LOCALAPPDATA 'Programs\DSH022' }
}
if ([string]::IsNullOrWhiteSpace($DocsRoot)) {
    if (Test-Path 'D:\') { $DocsRoot = Join-Path 'D:\Users' (Join-Path $env:USERNAME 'Documents\deepseek-harness') }
    elseif (Test-Path 'E:\') { $DocsRoot = Join-Path 'E:\Users' (Join-Path $env:USERNAME 'Documents\deepseek-harness') }
    else { $DocsRoot = Join-Path $env:USERPROFILE 'Documents\deepseek-harness' }
}
$DshHome = Join-Path $DocsRoot 'dsh-rc5-home'
$AgentsDir = Join-Path $DocsRoot 'agents'
$UserData = Join-Path $DocsRoot 'dsh-user-data'
$TempDir = Join-Path $env:TEMP 'dsh-workbuddy-kit'
Write-Host "InstallDir = $InstallDir"
Write-Host "DocsRoot   = $DocsRoot"

New-Item -ItemType Directory -Force -Path $TempDir, $DocsRoot, $AgentsDir, $UserData | Out-Null

Write-Step 'Stop old DSH in target folder'
Stop-TargetDsh $InstallDir

Write-Step 'Backup and install DeepSeek Harness 0.2.2-rc.5'
if (Test-Path -LiteralPath $InstallDir) {
    $backup = "$InstallDir.bak-$stamp"
    Write-Host "Moving old install to: $backup"
    Move-Item -LiteralPath $InstallDir -Destination $backup -Force
}
Get-ReleaseFile 'dsh-app.zip' (Join-Path $TempDir 'dsh-app.zip')
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
Expand-Archive -LiteralPath (Join-Path $TempDir 'dsh-app.zip') -DestinationPath $InstallDir -Force

Write-Step 'Restore DSH_HOME (no sessions)'
if (Test-Path -LiteralPath $DshHome) {
    $homeBackup = "$DshHome.bak-$stamp"
    Write-Host "Moving old home to: $homeBackup"
    Move-Item -LiteralPath $DshHome -Destination $homeBackup -Force
}
Get-ReleaseFile 'dsh-home.zip' (Join-Path $TempDir 'dsh-home.zip')
Expand-Archive -LiteralPath (Join-Path $TempDir 'dsh-home.zip') -DestinationPath $DocsRoot -Force

# Recreate the local link plugin junction (ZIP cannot preserve Windows junctions)
$phoneLink = Join-Path $DshHome 'profiles\desktop\node_modules\dsh-phone-remote'
$phoneTarget = Join-Path $DshHome 'bundles\dsh-phone-remote'
if (Test-Path -LiteralPath $phoneLink) { Remove-Item -LiteralPath $phoneLink -Recurse -Force }
New-Item -ItemType Junction -Path $phoneLink -Target $phoneTarget | Out-Null

# Keep the local process environment consistent with the persisted user environment
$env:DSH_HOME = $DshHome
$env:DSH_AGENTS_HOME = $AgentsDir
$env:MAGPIE_GATEWAY_KEY = 'magpie'

# Make every DSH instruction root contain the same AGENTS.md
Copy-Item -LiteralPath (Join-Path $DshHome 'AGENTS.md') -Destination (Join-Path $AgentsDir 'AGENTS.md') -Force
$harnessDir = Join-Path $UserData 'harness'
New-Item -ItemType Directory -Force -Path $harnessDir | Out-Null
Copy-Item -LiteralPath (Join-Path $DshHome 'AGENTS.md') -Destination (Join-Path $harnessDir 'AGENTS.md') -Force

Write-Step 'Set user environment variables'
[Environment]::SetEnvironmentVariable('DSH_HOME', $DshHome, 'User')
[Environment]::SetEnvironmentVariable('DSH_AGENTS_HOME', $AgentsDir, 'User')
[Environment]::SetEnvironmentVariable('MAGPIE_GATEWAY_KEY', 'magpie', 'User')

if (-not $SkipMagpie) {
    Write-Step 'Install and start Magpie gateway'
    $magpieDir = Join-Path (Split-Path -Parent $InstallDir) 'apps\magpie'
    if (Test-Path -LiteralPath $magpieDir) {
        Move-Item -LiteralPath $magpieDir -Destination "$magpieDir.bak-$stamp" -Force
    }
    Get-ReleaseFile 'magpie.zip' (Join-Path $TempDir 'magpie.zip')
    New-Item -ItemType Directory -Force -Path $magpieDir | Out-Null
    Expand-Archive -LiteralPath (Join-Path $TempDir 'magpie.zip') -DestinationPath $magpieDir -Force
    $magpieExe = Join-Path $magpieDir 'magpie.exe'
    if (Test-Path -LiteralPath $magpieExe) {
        Start-Process -FilePath $magpieExe -WorkingDirectory $magpieDir -WindowStyle Hidden
    }
}

Write-Step 'Create shortcut'
$exe = Join-Path $InstallDir 'DeepSeek Harness.exe'
$arguments = "--user-data-dir=`"$UserData`""
New-Shortcut -target $exe -arguments $arguments -workdir $InstallDir -name 'DeepSeek Harness.lnk'

Write-Step 'Done'
Write-Host "DSH_HOME        = $DshHome"
Write-Host "DSH_AGENTS_HOME = $AgentsDir"
Write-Host "Program         = $exe"
if (-not $NoLaunch) {
    Write-Host "Starting DeepSeek Harness ..."
    Start-Process -FilePath $exe -ArgumentList $arguments -WorkingDirectory $InstallDir
}
Write-Host ""
Write-Host 'Install complete. Open Magpie and sign in WorkBuddy / Antigravity / Codex if model access is needed.' -ForegroundColor Green
