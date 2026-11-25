<#
  tailscale-remote-magpie.ps1
  Connect a new Windows PC's Magpie to the main PC's Magpie gateway.
  Default path: Tailscale Funnel (HTTPS) - works without Tailscale.
  Tailscale is installed and tried by default; -SkipTailscale uses Funnel only.
  The DSH settings.yaml model ids are rewritten to use the Remote magpie prefix.
#>
param(
  [string]$GatewayKey = "",
  [string]$FunnelUrl = "https://win-eh8er79jhss.tail8e5fa5.ts.net",
  [string]$TailscaleIP = "100.117.46.38",
  [string]$ProviderId = "office",
  [switch]$SkipTailscale,
  [switch]$NoRestart,
  [string]$DshHome = "",
  [switch]$SkipElevation,
  [switch]$SkipEnv
)

$ErrorActionPreference = "Continue"
$script:LogPath = Join-Path $env:TEMP "dsh-remote-magpie.log"
function Log([string]$Message) {
  $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
  Write-Host $line
  Add-Content -Path $script:LogPath -Value $line -Encoding UTF8
}
function Fail([string]$Message) { Log ("ERROR: " + $Message); throw $Message }

if (-not $GatewayKey) {
  if ($env:MAGPIE_GATEWAY_KEY -and $env:MAGPIE_GATEWAY_KEY -ne "magpie") { $GatewayKey = $env:MAGPIE_GATEWAY_KEY }
}
if (-not $GatewayKey) {
  $GatewayKey = Read-Host "Paste the Magpie gateway key (sk-magpie-key-...)"
}
if (-not $GatewayKey) { Fail "GatewayKey is required." }
$GatewayKey = $GatewayKey.Trim()
$FunnelUrl = $FunnelUrl.TrimEnd("/")
$ProviderId = $ProviderId.Trim()

# Elevate when needed (Tailscale install and DSH restart need admin).
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ((-not $isAdmin) -and (-not $SkipElevation)) {
  $argLine = '-NoProfile -ExecutionPolicy Bypass -File "{0}" -GatewayKey "{1}" -FunnelUrl "{2}" -TailscaleIP "{3}" -ProviderId "{4}"' -f $PSCommandPath, $GatewayKey, $FunnelUrl, $TailscaleIP, $ProviderId
  if ($NoRestart) { $argLine += " -NoRestart" }
  if ($DshHome) { $argLine += " -DshHome `"$DshHome`"" }
  Log "Requesting administrator elevation..."
  Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList $argLine
  exit 0
}

function Find-Magpie {
  $candidates = @(
    (Join-Path $env:USERPROFILE "Documents\deepseek-harness\apps\magpie\magpie.exe"),
    "D:\deepseek-harness\apps\magpie\magpie.exe",
    "D:\DSH022\apps\magpie\magpie.exe",
    "D:\apps\magpie\magpie.exe",
    "D:\Magpie\magpie.exe",
    "C:\Program Files\Magpie\magpie.exe"
  )
  foreach ($c in $candidates) { if (Test-Path $c) { return $c } }
  $found = Get-ChildItem -Path "D:\" -Filter "magpie.exe" -Recurse -Depth 4 -File -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($found) { return $found.FullName }
  return $null
}

function Ensure-MagpieRunning([string]$Exe) {
  $p = Get-Process -Name "magpie" -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $p) {
    Log "Starting Magpie tray..."
    Start-Process -FilePath $Exe -ArgumentList "tray" -WorkingDirectory (Split-Path $Exe) | Out-Null
  }
  for ($i = 0; $i -lt 30; $i++) {
    try {
      $r = Invoke-WebRequest -Uri "http://127.0.0.1:3425/v1/models" -UseBasicParsing -TimeoutSec 2
      if ($r.StatusCode -eq 200) { Log "Magpie gateway is listening on 127.0.0.1:3425."; return }
    } catch { }
    Start-Sleep -Seconds 1
  }
  Fail "Magpie gateway did not start on 127.0.0.1:3425."
}

function Try-InstallTailscale {
  $ts = "C:\Program Files\Tailscale\tailscale.exe"
  if (Test-Path $ts) { return $ts }
  Log "Tailscale not found; trying winget..."
  $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
  if ($winget) {
    & $winget.Source install --id Tailscale.Tailscale -e --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-Host
  }
  if (-not (Test-Path $ts)) {
    $installer = Join-Path $env:TEMP "tailscale-setup-latest.exe"
    Log "Downloading Tailscale installer..."
    try {
      Invoke-WebRequest -Uri "https://pkgs.tailscale.com/stable/tailscale-setup-latest.exe" -OutFile $installer -UseBasicParsing -TimeoutSec 120
      Start-Process -FilePath $installer -ArgumentList "/quiet" -Wait
    } catch { Log ("Tailscale install failed: " + $_.Exception.Message); return $null }
  }
  if (Test-Path $ts) { return $ts }
  return $null
}

function Try-TailscaleOnline([string]$TsExe) {
  try {
    & $TsExe up --accept-routes --accept-dns 2>&1 | Out-Host
  } catch { }
  for ($i = 0; $i -lt 20; $i++) {
    try {
      $j = & $TsExe status --json 2>$null | ConvertFrom-Json
      if ($j.BackendState -eq "Running" -and $j.Self.Online) { return $true }
    } catch { }
    Start-Sleep -Seconds 1
  }
  return $false
}

Log "=== DSH Remote Magpie setup ==="
$magpie = Find-Magpie
if (-not $magpie) { Fail "magpie.exe not found. Re-run the DSH bootstrap first." }
Log ("Magpie: " + $magpie)
Ensure-MagpieRunning $magpie

$providerUrl = $FunnelUrl
if (-not $SkipTailscale) {
  $ts = Try-InstallTailscale
  if ($ts) {
    Log "Tailscale found; trying tailnet connection..."
    if (Try-TailscaleOnline $ts) {
      $providerUrl = "http://$TailscaleIP" + ":3425"
      Log ("Tailscale online; provider URL = " + $providerUrl)
    } else {
      Log "Tailscale not online; falling back to Funnel."
    }
  } else {
    Log "Tailscale unavailable; using Funnel."
  }
}
Log ("Remote provider URL: " + $providerUrl)

# Add or update the Remote magpie provider.
$providerList = (& $magpie providers 2>$null | Out-String)
$providerPattern = "(?m)^\s*Remote magpie\s+" + [regex]::Escape($ProviderId) + "\s"
if ($providerList -match $providerPattern) {
  Log "Provider exists; removing old entry before re-adding with the new key."
  & $magpie provider rm $ProviderId 2>$null | Out-Host
}
$addArgs = @("provider", "add", "remote-magpie", $GatewayKey, "url=$providerUrl", "id=$ProviderId")
$out = & $magpie @addArgs 2>$null
$out | Out-Host
if ($LASTEXITCODE -ne 0) {
  $joined = ($out | Out-String)
  if ($joined -match "already added|already exists") {
    Log "Provider already exists; removing and retrying."
    & $magpie provider rm $ProviderId 2>$null | Out-Host
    $out = & $magpie @addArgs 2>$null
    $out | Out-Host
    if ($LASTEXITCODE -ne 0) { Fail ("provider add failed after retry: " + (($out | Out-String))) }
  } else {
    Fail ("provider add failed: " + $joined)
  }
}
& $magpie provider refresh $ProviderId 2>$null | Out-Host

$modelsOut = (& $magpie provider models $ProviderId 2>$null | Out-String)
if ($modelsOut -notmatch [regex]::Escape($ProviderId + "/group/")) {
  Fail ("Remote models did not appear. Output: " + $modelsOut)
}
Log "Remote provider models verified."

# Rewrite DSH settings model ids to the Remote provider prefix.
$dshHome = $DshHome
if (-not $dshHome) { $dshHome = [Environment]::GetEnvironmentVariable("DSH_HOME", "User") }
if (-not $dshHome -or -not (Test-Path $dshHome)) {
  $candidates = @(
    (Join-Path $env:USERPROFILE "Documents\deepseek-harness\dsh-rc5-home"),
    "D:\deepseek-harness\dsh-rc5-home",
    (Join-Path $env:USERPROFILE ".dsh")
  )
  foreach ($c in $candidates) { if (Test-Path $c) { $dshHome = $c; break } }
}
if (-not $dshHome) { Fail "DSH_HOME not found." }
$settings = Join-Path $dshHome "settings.yaml"
if (-not (Test-Path $settings)) { Fail ("settings.yaml not found: " + $settings) }
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = "$settings.bak-remote-$stamp"
Copy-Item -Path $settings -Destination $backup -Force
Log ("Backed up settings to " + $backup)

$text = [IO.File]::ReadAllText($settings)
$lines = $text -split "`r?`n"
$inProviders = $false
$current = ""
$changed = 0
for ($i = 0; $i -lt $lines.Count; $i++) {
  $line = $lines[$i]
  if ($line -match "^  providers:\s*$") { $inProviders = $true; $current = ""; continue }
  if ($inProviders -and $line -match "^    ([A-Za-z0-9_.-]+):\s*$") { $current = $Matches[1]; continue }
  if ($inProviders -and $current -in @("magpie", "magpie-responses", "magpie-anthropic")) {
    $m = [regex]::Match($line, "^(\s*-\s*id:\s*)([^\s#]+)")
    if ($m.Success) {
      $id = $m.Groups[2].Value
      if ($id -notlike ($ProviderId + "/*")) {
        $lines[$i] = $m.Groups[1].Value + $ProviderId + "/" + $id + $line.Substring($m.Length)
        $changed++
      }
    }
  }
}
if ($changed -eq 0) { Log "No model ids needed rewriting (already prefixed or no models)." }
else {
  [IO.File]::WriteAllText($settings, ($lines -join "`r`n"), (New-Object Text.UTF8Encoding($false)))
  Log ("Rewrote " + $changed + " DSH model ids with prefix " + $ProviderId + "/.")
}
if (-not $SkipEnv) {
  [Environment]::SetEnvironmentVariable("MAGPIE_GATEWAY_KEY", $GatewayKey, "User")
  $env:MAGPIE_GATEWAY_KEY = $GatewayKey
}

# Verify a real chat through the local Magpie gateway using the prefixed id.
try {
  $testBody = @{
    model = "$ProviderId/group/hy4flash-free"
    messages = @(@{ role = "user"; content = "Reply with OK only." })
    stream = $false
  } | ConvertTo-Json -Depth 8
  $r = Invoke-RestMethod -Uri "http://127.0.0.1:3425/v1/chat/completions" -Method Post -ContentType "application/json" -Body $testBody -TimeoutSec 120
  if ($r.choices -and $r.choices.Count -gt 0) { Log "Local Magpie chat test OK." }
  else { Fail "Local Magpie chat test returned no choices." }
} catch { Fail ("Local Magpie chat test failed: " + $_.Exception.Message) }

if (-not $NoRestart) {
  Log "Restarting DSH..."
  Get-CimInstance Win32_Process -Filter "Name = 'DeepSeek Harness.exe'" -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
  Start-Sleep -Seconds 3
  $dshExe = @("D:\DSH022\DeepSeek Harness.exe", "C:\Program Files\DeepSeek Harness\DeepSeek Harness.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
  if ($dshExe) {
    $userData = Join-Path (Split-Path $dshHome -Parent) "dsh-user-data"
    Start-Process -FilePath $dshExe -ArgumentList ("--user-data-dir=`"" + $userData + "`"") | Out-Null
    Log "DSH restarted."
  } else { Log "WARNING: DeepSeek Harness.exe not found; start it from the desktop shortcut." }
}

Log "=== DONE ==="
Log ("Provider: " + $ProviderId)
Log ("URL: " + $providerUrl)
Log ("DSH settings: " + $settings)








