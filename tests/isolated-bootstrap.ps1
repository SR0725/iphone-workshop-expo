param([string]$Root)
$ErrorActionPreference = 'Stop'
$env:Path = "$env:SystemRoot\system32;$env:SystemRoot;$env:SystemRoot\System32\WindowsPowerShell\v1.0"
$env:TEMP = $Root
$env:TMP = $Root
$env:CI = '1'
$env:EXPO_NO_TELEMETRY = '1'
$env:PLAYWRIGHT_BROWSERS_PATH = Join-Path $Root 'browsers'
$env:npm_config_cache = Join-Path $Root 'npm-cache'
try {
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = New-Object Security.Principal.WindowsPrincipal($identity)
  $admin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  if ($admin) { throw 'Expected non-administrator process' }
  $missing = @('node','npm','npx','git','winget') | ForEach-Object {
    if (Get-Command $_ -ErrorAction SilentlyContinue) { throw "Unexpected command: $_" }
    $_
  }
  @{ administrator=$admin; absentCommands=$missing; isolation='New local standard user and restricted PATH; not a factory-clean OS'; os=[Environment]::OSVersion.ToString() } | ConvertTo-Json | Set-Content "$Root\before.json"
  & "$PSScriptRoot\bootstrap-windows.ps1" -Root $Root -Verify
  exit 0
} catch { Write-Error $_; exit 1 }
