[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Version,

    [ValidateSet("Release", "Debug")]
    [string]$Configuration = "Release",

    [string]$QtRoot = $env:QEPM_QT_ROOT,

    [string]$BuildRoot = (Join-Path $PSScriptRoot "..\build-release-msvc"),

    [string]$OutputRoot = (Join-Path $PSScriptRoot "..\artifacts"),

    [switch]$SkipBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$configuration = $Configuration
$architecture = "x64"
$artifactName = "QEPM-$Version-windows-$architecture"
$artifactRoot = Join-Path $OutputRoot $artifactName
$runtimeSource = Join-Path $repositoryRoot "__Builds\$architecture\$configuration\bin"
$configSource = Join-Path $repositoryRoot "configurations"
$examplesSource = Join-Path $repositoryRoot "examples"
$pythonSource = Join-Path $repositoryRoot "interfaces\Python"
$docsSource = Join-Path $repositoryRoot "docs"
$releaseNotesSource = Join-Path $repositoryRoot "CHANGELOG.md"
$zipPath = Join-Path $OutputRoot "$artifactName.zip"

$requiredExecutables = @(
    "EPM.exe",
    "EPMConfigurationEditor.exe",
    "EPMScope.exe",
    "EPMViewer.exe",
    "EPMDump.exe",
    "PSOCProgrammer.exe",
    "SCLDump.exe",
    "BugWriter.exe"
)

$requiredInterfaces = @(
    "EPMDev.dll",
    "UDASDev.dll"
)

function Copy-DirectoryIfPresent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [string]$Destination
    )

    if (Test-Path -Path $Source -PathType Container) {
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
        Copy-Item -Path (Join-Path $Source "*") -Destination $Destination -Recurse -Force
    }
}

if (-not $SkipBuild) {
    if ([string]::IsNullOrWhiteSpace($QtRoot)) {
        throw "Set QEPM_QT_ROOT or pass -QtRoot. Expected a Qt root such as C:\Qt\6.9.3\msvc2022_64."
    }

    $vcVars = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
    $compiler = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.44.35207\bin\Hostx64\x64\cl.exe"
    $sdkBin = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64"

    if (-not (Test-Path $vcVars)) {
        throw "MSVC environment script was not found: $vcVars"
    }

    if (-not (Test-Path $compiler)) {
        throw "MSVC compiler was not found: $compiler"
    }

    if (-not (Test-Path (Join-Path $QtRoot "bin\windeployqt.exe"))) {
        throw "Qt root does not contain bin\windeployqt.exe: $QtRoot"
    }

    $command = @"
set "PATH=C:\Program Files (x86)\Microsoft Visual Studio\Installer;%PATH%"
call "$vcVars"
set "PATH=$QtRoot\bin;$sdkBin;%PATH%"
cmake -S "$repositoryRoot" -B "$BuildRoot" -G Ninja -DCMAKE_C_COMPILER="$compiler" -DCMAKE_CXX_COMPILER="$compiler" -DCMAKE_PREFIX_PATH="$QtRoot" -DCMAKE_BUILD_TYPE=$configuration
if errorlevel 1 exit /b %errorlevel%
cmake --build "$BuildRoot" --parallel 4
"@

    & cmd.exe /d /c $command
    if ($LASTEXITCODE -ne 0) {
        throw "QEPM public release build failed with exit code $LASTEXITCODE."
    }
}

if (-not (Test-Path -Path $runtimeSource -PathType Container)) {
    throw "QEPM runtime output is missing: $runtimeSource. Build the public release first or use -SkipBuild with an existing output."
}

if (Test-Path $artifactRoot) {
    Remove-Item -Path $artifactRoot -Recurse -Force
}

New-Item -ItemType Directory -Path $artifactRoot -Force | Out-Null
Copy-DirectoryIfPresent -Source $runtimeSource -Destination (Join-Path $artifactRoot "bin")
Copy-DirectoryIfPresent -Source $configSource -Destination (Join-Path $artifactRoot "configurations")
Copy-DirectoryIfPresent -Source $examplesSource -Destination (Join-Path $artifactRoot "examples")
Copy-DirectoryIfPresent -Source $pythonSource -Destination (Join-Path $artifactRoot "python")
Copy-DirectoryIfPresent -Source $docsSource -Destination (Join-Path $artifactRoot "docs")

if (Test-Path -Path $releaseNotesSource -PathType Leaf) {
    Copy-Item -Path $releaseNotesSource -Destination (Join-Path $artifactRoot "Release Notes.txt") -Force
}

$missing = @()
foreach ($file in $requiredExecutables + $requiredInterfaces) {
    if (-not (Test-Path -Path (Join-Path $artifactRoot "bin\$file") -PathType Leaf)) {
        $missing += $file
    }
}

if ($missing.Count -gt 0) {
    throw "QEPM release staging is incomplete. Missing: $($missing -join ', ')"
}

$configurations = Get-ChildItem -Path (Join-Path $artifactRoot "configurations") -Filter "*.ccnf" -File -Recurse
if ($configurations.Count -ne 81) {
    throw "QEPM release staging must contain 81 .ccnf configurations; found $($configurations.Count)."
}

$installerScript = @'
param(
    [string]$InstallRoot = "${env:ProgramFiles}\Qualcomm\QEPM",
    [string]$DataRoot = "${env:ProgramData}\Qualcomm\Alpaca\epm_configs"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$packageRoot = Split-Path -Parent $PSCommandPath
Copy-Item -Path (Join-Path $packageRoot "bin\*") -Destination $InstallRoot -Recurse -Force
Copy-Item -Path (Join-Path $packageRoot "configurations\*") -Destination $DataRoot -Recurse -Force

Write-Output "QEPM installed to: $InstallRoot"
Write-Output "EPM configurations installed to: $DataRoot"
'@

Set-Content -Path (Join-Path $artifactRoot "Install-QEPM.ps1") -Value $installerScript -Encoding utf8

$files = Get-ChildItem -Path $artifactRoot -File -Recurse | ForEach-Object {
    [PSCustomObject]@{
        path = $_.FullName.Substring($artifactRoot.Length).TrimStart('\', '/').Replace('\', '/')
        sha256 = (Get-FileHash -Path $_.FullName -Algorithm SHA256).Hash
        size = $_.Length
    }
}

$manifest = [PSCustomObject]@{
    product = "QEPM"
    version = $Version
    configuration = $configuration
    architecture = $architecture
    sourceCommit = (& git -C $repositoryRoot rev-parse HEAD).Trim()
    generatedUtc = (Get-Date).ToUniversalTime().ToString("o")
    configurationCount = $configurations.Count
    files = $files
}

$manifest | ConvertTo-Json -Depth 6 | Set-Content -Path (Join-Path $artifactRoot "release-manifest.json") -Encoding utf8

New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null
if (Test-Path $zipPath) {
    Remove-Item -Path $zipPath -Force
}

Compress-Archive -Path (Join-Path $artifactRoot "*") -DestinationPath $zipPath -CompressionLevel Optimal

Write-Output "QEPM standalone release created:"
Write-Output "  Staging: $artifactRoot"
Write-Output "  Archive: $zipPath"