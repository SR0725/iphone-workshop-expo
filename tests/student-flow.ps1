param([string]$Evidence)
# Simulates what the student setup prompt asks Codex to do, then launches the
# shipped double-click launcher exactly as a student would.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$env:Path = "$env:SystemRoot\system32;$env:SystemRoot;$env:SystemRoot\System32\WindowsPowerShell\v1.0"
$env:EXPO_NO_TELEMETRY = '1'
$starterSha = 'ae4080d1d55e1536f7c36e04892ae78b4d059f18'
# Test-only switch: the launcher normally opens a browser for Expo login.
$env:WORKSHOP_SKIP_LOGIN = '1'
$result = [ordered]@{ user = $env:USERNAME; localAppData = $env:LOCALAPPDATA; scenarios = @() }
New-Item -ItemType Directory -Force $Evidence | Out-Null

function Save-Result { $result | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $Evidence 'student-flow.json') -Encoding UTF8 }

try {
  $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
  $result.administrator = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  if ($result.administrator) { throw 'Expected a non-administrator process' }
  $result.absentCommands = @('node','npm','npx','git','winget') | ForEach-Object {
    if (Get-Command $_ -ErrorAction SilentlyContinue) { throw "Unexpected command on PATH: $_" }
    $_
  }

  # Step 1: portable Node in the user's own folder, checksum verified.
  $version = '22.23.3'
  $arch = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'x64' }
  $name = "node-v$version-win-$arch"
  $tools = Join-Path $env:LOCALAPPDATA 'RayWorkshop'
  New-Item -ItemType Directory -Force $tools | Out-Null
  $zip = Join-Path $env:TEMP "$name.zip"
  Invoke-WebRequest "https://nodejs.org/dist/v$version/$name.zip" -OutFile $zip -UseBasicParsing
  $sums = (Invoke-WebRequest "https://nodejs.org/dist/v$version/SHASUMS256.txt" -UseBasicParsing).Content
  $line = @($sums -split "`n" | Where-Object { $_.Trim().EndsWith(" $name.zip") })
  if ($line.Count -ne 1) { throw 'Checksum entry missing or ambiguous' }
  $expected = ($line[0].Trim() -split '\s+')[0]
  $actual = (Get-FileHash $zip -Algorithm SHA256).Hash
  if ($actual -ne $expected) { throw 'Node checksum mismatch' }
  Expand-Archive $zip -DestinationPath $tools -Force
  $result.node = @{ dir = (Join-Path $tools $name); sha256 = $actual }

  # Step 2: download the pinned starter, no Git.
  $starterZip = Join-Path $env:TEMP 'starter.zip'
  Invoke-WebRequest "https://codeload.github.com/SR0725/iphone-workshop-expo/zip/$starterSha" -OutFile $starterZip -UseBasicParsing

  $targets = @(
    @{ label = 'recommended C:\workshop'; path = 'C:\workshop' },
    @{ label = 'non-ASCII path with a space under the profile'; path = (Join-Path $env:USERPROFILE (-join [char[]](0x6211,0x7684,0x20,0x5DE5,0x4F5C,0x574A))) }
  )
  foreach ($t in $targets) {
    $s = [ordered]@{ label = $t.label; path = $t.path }
    $result.scenarios += $s
    New-Item -ItemType Directory $t.path | Out-Null
    $s.createdByStandardUser = $true
    $unpack = Join-Path $env:TEMP ('unpack-' + [guid]::NewGuid())
    Expand-Archive $starterZip -DestinationPath $unpack
    $inner = Get-ChildItem $unpack -Directory | Select-Object -First 1
    Get-ChildItem $inner.FullName -Force | Move-Item -Destination $t.path
    $launcher = Get-ChildItem $t.path -Filter '*App.cmd' | Select-Object -First 1
    if (-not $launcher) { throw 'Launcher .cmd missing after unzip' }
    $s.launcher = $launcher.Name

    # Step 3: double-click equivalent. Launcher installs packages on first run, then starts Expo Go mode.
    $out = Join-Path $Evidence ("launcher-" + $result.scenarios.Count + ".out.log")
    $err = Join-Path $Evidence ("launcher-" + $result.scenarios.Count + ".err.log")
    $started = Get-Date
    $proc = Start-Process cmd.exe -ArgumentList '/c', ('"' + $launcher.FullName + '"') -WorkingDirectory $t.path -RedirectStandardOutput $out -RedirectStandardError $err -PassThru -WindowStyle Hidden
    try {
      $status = ''
      $curl = Join-Path $env:SystemRoot 'System32\curl.exe'
      for ($i = 0; $i -lt 150; $i++) {
        if ($proc.HasExited) { throw "Launcher exited early with code $($proc.ExitCode)" }
        $status = (& $curl -s -m 3 'http://127.0.0.1:8081/status') -join ''
        if ($status -match 'packager-status:running') { break }
        Start-Sleep -Seconds 2
      }
      $s.listening = @(& netstat.exe -ano | Select-String ':8081\s' | ForEach-Object { $_.Line.Trim() })
      if ($status -notmatch 'packager-status:running') {
        $s.lastStatus = $status
        $s.localhostStatus = (& $curl -s -m 5 -w ' http=%{http_code}' 'http://localhost:8081/status') -join ''
        throw 'Metro did not answer /status within 5 minutes'
      }
      $s.secondsUntilServerReady = [int]((Get-Date) - $started).TotalSeconds
      $manifestFile = Join-Path $Evidence ("manifest-" + $result.scenarios.Count + ".json")
      & $curl -s -m 60 -H 'expo-platform: ios' -H 'accept: application/expo+json,application/json' -o $manifestFile 'http://127.0.0.1:8081/'
      $manifest = Get-Content $manifestFile -Raw -Encoding UTF8 | ConvertFrom-Json
      $client = $manifest.extra.expoClient
      $s.manifest = @{ name = $client.name; sdkVersion = $client.sdkVersion; launchAssetHost = ([uri]$manifest.launchAsset.url).Host }
      if ($client.sdkVersion -notlike '57.*') { throw "Unexpected SDK in manifest: $($client.sdkVersion)" }
      $bundleUrl = ([uri]$manifest.launchAsset.url)
      $bundleFile = Join-Path $env:TEMP ("bundle-" + $result.scenarios.Count + ".js")
      $code = (& $curl -s -m 600 -o $bundleFile -w '%{http_code}' ('http://127.0.0.1:8081' + $bundleUrl.PathAndQuery)) -join ''
      $bundleText = [IO.File]::ReadAllText($bundleFile, [Text.Encoding]::UTF8)
      $s.iosBundle = @{ status = $code; bytes = (Get-Item $bundleFile).Length; containsAppTitle = ($bundleText.Contains((-join [char[]](0x4ECA,0x5929,0x7684,0x5C0F,0x4E8B))) -or $bundleText.ToLower().Contains('\u4eca\u5929\u7684\u5c0f\u4e8b')) }
      if ($code -ne '200' -or -not $s.iosBundle.containsAppTitle) { throw 'iOS bundle missing or without the app title' }
      $s.passed = $true
    } finally {
      & taskkill.exe /PID $proc.Id /T /F | Out-Null
      Start-Sleep -Seconds 3
    }
  }
  # Step 4: fallback launcher through Expo's tunnel (outbound only).
  $t = [ordered]@{ label = 'tunnel fallback launcher in C:\workshop' }
  $result.tunnel = $t
  $fallback = Get-ChildItem 'C:\workshop' -Filter '*App.cmd' | Where-Object { $_.Name -ne $launcher.Name } | Select-Object -First 1
  if (-not $fallback) { throw 'Fallback launcher missing' }
  $out = Join-Path $Evidence 'fallback.out.log'
  $err = Join-Path $Evidence 'fallback.err.log'
  $proc = Start-Process cmd.exe -ArgumentList '/c', ('"' + $fallback.FullName + '"') -WorkingDirectory 'C:\workshop' -RedirectStandardOutput $out -RedirectStandardError $err -PassThru -WindowStyle Hidden
  try {
    $curl = Join-Path $env:SystemRoot 'System32\curl.exe'
    $ready = $false
    for ($i = 0; $i -lt 90; $i++) {
      if ($proc.HasExited) { throw "Fallback launcher exited early with code $($proc.ExitCode)" }
      if ((Get-Content $out -Raw -ErrorAction SilentlyContinue) -match 'Tunnel ready') { $ready = $true; break }
      Start-Sleep -Seconds 2
    }
    if (-not $ready) { throw 'Tunnel was not ready within 3 minutes' }
    $mf = Join-Path $Evidence 'manifest-tunnel.json'
    & $curl -s -m 60 -H 'expo-platform: ios' -H 'accept: application/expo+json,application/json' -o $mf 'http://127.0.0.1:8081/'
    $m = Get-Content $mf -Raw -Encoding UTF8 | ConvertFrom-Json
    $u = [uri]$m.launchAsset.url
    $t.publicHost = $u.Host
    $t.publicStatus = (& $curl -s -m 30 ($u.Scheme + '://' + $u.Host + '/status')) -join ''
    if ($t.publicStatus -notmatch 'packager-status:running') { throw 'Tunnel URL did not answer' }
    $t.passed = $true
  } finally {
    & taskkill.exe /PID $proc.Id /T /F | Out-Null
    Get-Process ngrok -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
  }
  $result.passed = $true
  Save-Result
  exit 0
} catch {
  $result.error = $_.ToString()
  $result.passed = $false
  Save-Result
  Write-Error $_
  exit 1
}
