param(
    [string]$Solution = "FileConverter.sln",
    [string]$Configuration = "Release",
    [string]$Platform = "x64",
    [int]$DebounceMs = 1500
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $Root

function Get-MSBuildPath {
    $candidates = @(
        "$env:ProgramFiles(x86)\Microsoft Visual Studio\Installer\vswhere.exe",
        "$env:ProgramFiles\Microsoft Visual Studio\Installer\vswhere.exe"
    ) | Where-Object { Test-Path $_ }
    if ($candidates) {
        $vswhere = $candidates[0]
        $path = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -find "MSBuild\**\Bin\amd64\MSBuild.exe" | Select-Object -First 1
        if ($path) { return $path }
    }
    # Known standard locations
    $known = @(
        'C:\\Program Files (x86)\\Microsoft Visual Studio\\2022\\BuildTools\\MSBuild\\Current\\Bin\\amd64\\MSBuild.exe',
        'C:\\Program Files\\Microsoft Visual Studio\\2022\\BuildTools\\MSBuild\\Current\\Bin\\amd64\\MSBuild.exe',
        'C:\\Program Files (x86)\\Microsoft Visual Studio\\2022\\Community\\MSBuild\\Current\\Bin\\amd64\\MSBuild.exe',
        'C:\\Program Files\\Microsoft Visual Studio\\2022\\Community\\MSBuild\\Current\\Bin\\amd64\\MSBuild.exe'
    )
    foreach ($p in $known) { if (Test-Path $p) { return $p } }
    return 'msbuild'
}

$MSBUILD = Get-MSBuildPath
$Bin = Join-Path $Root "Application\FileConverter\bin\$Platform\$Configuration"
$Exe = Join-Path $Bin 'LumeConverter.exe'
$ExtDll = Join-Path $Root "Application\FileConverterExtension\bin\$Platform\$Configuration\FileConverterExtension.dll"
$script:LastExtWrite = if (Test-Path $ExtDll) { (Get-Item $ExtDll).LastWriteTimeUtc } else { [DateTime]::MinValue }

function Ensure-Middleware {
    if (!(Test-Path $Bin)) { return }
    $ff = Join-Path $Bin 'ffmpeg.exe'
    $gsd = Join-Path $Bin 'gsdll64.dll'
    $gse = Join-Path $Bin 'gswin64c.exe'
    if (!(Test-Path $ff) -and (Test-Path (Join-Path $Root 'Middleware\ffmpeg\ffmpeg.exe'))) {
        Copy-Item -Force (Join-Path $Root 'Middleware\ffmpeg\ffmpeg.exe') $ff
    }
    if (!(Test-Path $gsd) -and (Test-Path (Join-Path $Root 'Middleware\gs\gsdll64.dll'))) {
        Copy-Item -Force (Join-Path $Root 'Middleware\gs\gsdll64.dll') $gsd
    }
    if (!(Test-Path $gse) -and (Test-Path (Join-Path $Root 'Middleware\gs\gswin64c.exe'))) {
        Copy-Item -Force (Join-Path $Root 'Middleware\gs\gswin64c.exe') $gse
    }
}

function Restart-ExplorerIfNeeded {
    if (!(Test-Path $ExtDll)) { return }
    $now = (Get-Item $ExtDll).LastWriteTimeUtc
    if ($now -gt $script:LastExtWrite) {
        $script:LastExtWrite = $now
        Get-Process explorer -ErrorAction SilentlyContinue | Stop-Process -Force
        Start-Sleep -Seconds 1
        Start-Process explorer.exe | Out-Null
    }
}

function Rebuild-And-Reload {
    Write-Host "[dev-watch] Building..." -ForegroundColor Cyan
    # Stop Explorer first so the shell extension DLL is not locked
    Get-Process explorer -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Milliseconds 400

    $extProj = Join-Path $Root 'Application\FileConverterExtension\FileConverterExtension.csproj'
    $appProj = Join-Path $Root 'Application\FileConverter\FileConverter.csproj'

    if (Test-Path $extProj) {
        & "$MSBUILD" $extProj /nologo /m /restore /p:Configuration=$Configuration /p:Platform=$Platform | Write-Host
        if ($LASTEXITCODE -ne 0) { Write-Warning "[dev-watch] Extension build failed ($LASTEXITCODE)."; Start-Process explorer.exe | Out-Null; return }
    }

    & "$MSBUILD" $appProj /nologo /m /restore /p:Configuration=$Configuration /p:Platform=$Platform | Write-Host
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "[dev-watch] Build failed ($LASTEXITCODE)."
        Start-Process explorer.exe | Out-Null
        return
    }
    Ensure-Middleware
    # Restart app
    Get-Process LumeConverter -ErrorAction SilentlyContinue | Stop-Process -Force
    if (Test-Path $Exe) {
        Start-Process -FilePath $Exe -WorkingDirectory $Bin | Out-Null
    }
    # Always restart explorer after extension build
    Start-Process explorer.exe | Out-Null
    Write-Host "[dev-watch] Build complete. App reloaded." -ForegroundColor Green
}

# Initial build & run (optional)
Rebuild-And-Reload

# Watch for changes
$filters = @('*.cs','*.xaml','*.csproj','*.wxs','*.resx','*.ico','*.png')
$watchers = @()
foreach ($f in $filters) {
    $w = New-Object System.IO.FileSystemWatcher($Root, $f)
    $w.IncludeSubdirectories = $true
    $w.EnableRaisingEvents = $true
    $watchers += $w
}

$queue = New-Object System.Collections.Queue
foreach ($w in $watchers) {
    Register-ObjectEvent -InputObject $w -EventName Changed -Action { $queue.Enqueue([DateTime]::UtcNow) } | Out-Null
    Register-ObjectEvent -InputObject $w -EventName Created -Action { $queue.Enqueue([DateTime]::UtcNow) } | Out-Null
    Register-ObjectEvent -InputObject $w -EventName Renamed -Action { $queue.Enqueue([DateTime]::UtcNow) } | Out-Null
    Register-ObjectEvent -InputObject $w -EventName Deleted -Action { $queue.Enqueue([DateTime]::UtcNow) } | Out-Null
}

Write-Host "[dev-watch] Watching $Root for changes... (Ctrl+C to stop)" -ForegroundColor Yellow
$lastSignal = [DateTime]::MinValue
while ($true) {
    Start-Sleep -Milliseconds 300
    while ($queue.Count -gt 0) { $null = $queue.Dequeue(); $lastSignal = [DateTime]::UtcNow }
    if ($lastSignal -ne [DateTime]::MinValue -and (([DateTime]::UtcNow - $lastSignal).TotalMilliseconds -ge $DebounceMs)) {
        $lastSignal = [DateTime]::MinValue
        Rebuild-And-Reload
    }
}


