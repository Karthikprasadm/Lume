$ErrorActionPreference = 'Stop'

function Get-MsBuildPath {
	$knownPaths = @(
		"C:\\Program Files (x86)\\Microsoft Visual Studio\\2022\\BuildTools\\MSBuild\\Current\\Bin\\amd64\\MSBuild.exe",
		"C:\\Program Files\\Microsoft Visual Studio\\2022\\BuildTools\\MSBuild\\Current\\Bin\\amd64\\MSBuild.exe",
		"C:\\Program Files\\Microsoft Visual Studio\\2022\\BuildTools\\MSBuild\\Current\\Bin\\MSBuild.exe",
		"C:\\Program Files\\Microsoft Visual Studio\\2022\\Community\\MSBuild\\Current\\Bin\\amd64\\MSBuild.exe",
		"C:\\Program Files\\Microsoft Visual Studio\\2022\\Community\\MSBuild\\Current\\Bin\\MSBuild.exe"
	)
	foreach ($p in $knownPaths) { if (Test-Path $p) { return $p } }
	$vswhere = "C:\\Program Files (x86)\\Microsoft Visual Studio\\Installer\\vswhere.exe"
	if (Test-Path $vswhere) {
		$found = & $vswhere -latest -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe | Select-Object -First 1
		if ($found) { return $found }
	}
	return 'msbuild'
}

function Invoke-Build {
	param(
		[string]$Project
	)
	$msbuild = Get-MsBuildPath
    # Ensure SolutionDir is defined so post-build copy steps work
    $root = (Split-Path -Parent $PSScriptRoot)
    if (-not $root.EndsWith('\')) { $root = $root + '\' }
    $arguments = @($Project, '/nologo', '/m', '/restore', '/p:Configuration=Release', '/p:Platform=x64', "/p:SolutionDir=$root")
	$proc = Start-Process -FilePath $msbuild -ArgumentList $arguments -NoNewWindow -PassThru -Wait
	if ($proc.ExitCode -ne 0) { throw "Build failed for $Project (exit $($proc.ExitCode))" }
}

function Stop-Explorer {
	Get-Process explorer -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}

function Start-Explorer {
	Start-Process explorer.exe -ErrorAction SilentlyContinue | Out-Null
}

Write-Host "Stopping Explorer to unlock extension..."
Stop-Explorer

Write-Host "Building FileConverterExtension..."
Invoke-Build -Project 'Application\FileConverterExtension\FileConverterExtension.csproj'

Write-Host "Building FileConverter..."
Invoke-Build -Project 'Application\FileConverter\FileConverter.csproj'

$exe = $null
$candidates = @(
	'Application\FileConverter\bin\x64\Release\LumeConverter.exe',
	'Application\FileConverter\bin\x64\Release\FileConverter.exe'
)
foreach ($c in $candidates) {
	if (Test-Path $c) { $exe = (Resolve-Path $c).Path; break }
}
if (-not $exe) { throw 'Executable not found after build.' }

New-Item -Path 'HKCU:\Software\LumeConverter' -Force | Out-Null
Set-ItemProperty -Path 'HKCU:\Software\LumeConverter' -Name 'Path' -Value $exe

# Optionally re-register shell extension only if running as Administrator
try {
	$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
	$principal = New-Object Security.Principal.WindowsPrincipal($identity)
	$IsAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
	if ($IsAdmin) {
		$extDll = (Resolve-Path 'Application\FileConverterExtension\bin\x64\Release\FileConverterExtension.dll').Path
		& $exe --register-shell-extension "$extDll" | Out-Null
	}
}
catch { }

Write-Host "Restarting Explorer..."
Start-Explorer

Get-Process -Name 'LumeConverter','FileConverter' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

Start-Process -FilePath $exe | Out-Null
Start-Sleep -Seconds 2

$running = Get-Process -Name 'LumeConverter','FileConverter' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ProcessName -Unique | Sort-Object
$regPath = (Get-ItemProperty -Path 'HKCU:\Software\LumeConverter' -Name 'Path').Path

Write-Host ("Exe: " + $exe)
Write-Host ("Running: " + ($running -join ', '))
Write-Host ("RegistryPath: " + $regPath)


