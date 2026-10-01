param([string]$Root = "$env:LOCALAPPDATA\RayWorkshop", [switch]$Verify)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
New-Item -ItemType Directory -Force $Root | Out-Null
$version = '22.23.3'
$arch = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'x64' }
$name = "node-v$version-win-$arch"
$zip = Join-Path $Root "$name.zip"
$base = "https://nodejs.org/dist/v$version"
Invoke-WebRequest "$base/$name.zip" -OutFile $zip -UseBasicParsing
$sums = (Invoke-WebRequest "$base/SHASUMS256.txt" -UseBasicParsing).Content
$line = $sums -split "`n" | Where-Object { $_.Trim().EndsWith(" $name.zip") }
if (@($line).Count -ne 1) { throw 'Checksum entry missing or ambiguous' }
$expected = ($line.Trim() -split '\s+')[0]
if ((Get-FileHash $zip -Algorithm SHA256).Hash -ne $expected) { throw 'Node checksum mismatch' }
Expand-Archive $zip -DestinationPath $Root -Force
$nodeDir = Join-Path $Root $name
$env:Path = "$nodeDir;$env:Path"
$project = Join-Path $Root 'iphone-workshop-expo-394fc232c535702f0c3cd4b586df70aaf1510c48'
if (Test-Path $project) { throw "Project already exists; preserve it: $project" }
Invoke-WebRequest 'https://codeload.github.com/SR0725/iphone-workshop-expo/zip/394fc232c535702f0c3cd4b586df70aaf1510c48' -OutFile (Join-Path $Root 'app.zip') -UseBasicParsing
Expand-Archive (Join-Path $Root 'app.zip') -DestinationPath $Root
Set-Location $project
& "$nodeDir\npm.cmd" ci
if ($LASTEXITCODE -ne 0) { throw 'npm ci failed' }
@('@echo off', "set `"PATH=$nodeDir;%PATH%`"", "cd /d `"$project`"", 'call npm.cmd run start -- --go') | Set-Content (Join-Path $Root 'start-app.cmd') -Encoding ASCII
if ($Verify) {
  & "$nodeDir\node.exe" node_modules/typescript/bin/tsc --noEmit
  if ($LASTEXITCODE -ne 0) { throw 'Typecheck failed' }
  & "$nodeDir\node.exe" node_modules/expo/bin/cli export --platform ios --output-dir dist-ios
  if ($LASTEXITCODE -ne 0) { throw 'iOS export failed' }
  & "$nodeDir\node.exe" node_modules/playwright/cli.js install chromium
  if ($LASTEXITCODE -ne 0) { throw 'Browser install failed' }
  & "$nodeDir\node.exe" tests/metro-smoke.mjs
  if ($LASTEXITCODE -ne 0) { throw 'Metro smoke failed' }
}
Write-Output "READY: $Root\start-app.cmd"
