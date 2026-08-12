[CmdletBinding()]
param(
    [string]$OutputRoot = (Join-Path $PSScriptRoot "..\dist")
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$modRoot = Join-Path $repoRoot "mod"
$infoPath = Join-Path $modRoot "Info.json"
$info = Get-Content -Raw -LiteralPath $infoPath | ConvertFrom-Json

if ($info.PackageName -notmatch '^[A-Za-z0-9]+$') {
    throw "PackageName must contain only ASCII letters and digits."
}
if ([string]::IsNullOrWhiteSpace($info.Version) -or $info.Version -match '(?i)dev') {
    throw "Set a non-development Version before packaging."
}
if ($info.DebugMode -ne $false) {
    throw "DebugMode must be false for a release package."
}
if ($info.Dependencies -notcontains "UE4SSExperimentalPW") {
    throw "The UE4SSExperimentalPW dependency is required."
}
if ([string]::IsNullOrWhiteSpace($info.Thumbnail)) {
    throw "Info.json must declare a Thumbnail."
}

$workshopFiles = @(
    "Info.json",
    [string]$info.Thumbnail,
    "Scripts\main.lua",
    "Scripts\balance.lua",
    "Scripts\config.lua",
    "Scripts\gamedefs.lua",
    "Scripts\identity.lua",
    "Scripts\runtime_policy.lua"
)

$manualFiles = @(
    "enabled.txt",
    "Scripts\main.lua",
    "Scripts\balance.lua",
    "Scripts\config.lua",
    "Scripts\gamedefs.lua",
    "Scripts\identity.lua",
    "Scripts\runtime_policy.lua"
)

foreach ($relativePath in ($workshopFiles + $manualFiles | Select-Object -Unique)) {
    $sourcePath = Join-Path $modRoot $relativePath
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Required package file is missing: $relativePath"
    }
}

$luaRules = @($info.InstallRule | Where-Object { $_.Type -eq "Lua" })
$clientRules = @($luaRules | Where-Object { -not $_.IsServer })
$serverRules = @($luaRules | Where-Object { $_.IsServer -eq $true })
if ($luaRules.Count -ne 2 -or $clientRules.Count -ne 1 -or $serverRules.Count -ne 1) {
    throw "Info.json must contain one client/listen-host and one server Lua rule."
}
foreach ($rule in $luaRules) {
    if (@($rule.Targets).Count -ne 1 -or $rule.Targets[0] -ne "./Scripts") {
        throw "Every Lua rule must target ./Scripts."
    }
}

$outputRootFull = [System.IO.Path]::GetFullPath($OutputRoot)
$repoRootWithSeparator = $repoRoot.TrimEnd('\') + '\'
if (-not $outputRootFull.StartsWith($repoRootWithSeparator, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "OutputRoot must remain inside the repository."
}

$baseName = "$($info.PackageName)-$($info.Version)"
$workshopName = "$baseName-workshop"
$workshopRoot = Join-Path $outputRootFull $workshopName
$workshopZipPath = Join-Path $outputRootFull "$workshopName.zip"
$workshopChecksumPath = "$workshopZipPath.sha256"
$manualName = "$baseName-manual"
$manualRoot = Join-Path $outputRootFull $manualName
$manualModRoot = Join-Path $manualRoot $info.PackageName
$manualZipPath = Join-Path $outputRootFull "$manualName.zip"
$manualChecksumPath = "$manualZipPath.sha256"

$legacyPaths = @(
    (Join-Path $outputRootFull $baseName),
    (Join-Path $outputRootFull "$baseName.zip"),
    (Join-Path $outputRootFull "$baseName.zip.sha256")
)
$outputPaths = @(
    $workshopRoot,
    $workshopZipPath,
    $workshopChecksumPath,
    $manualRoot,
    $manualZipPath,
    $manualChecksumPath
) + $legacyPaths

New-Item -ItemType Directory -Force -Path $outputRootFull | Out-Null
foreach ($path in $outputPaths) {
    if (Test-Path -LiteralPath $path) {
        Remove-Item -LiteralPath $path -Recurse -Force
    }
}

New-Item -ItemType Directory -Force -Path (Join-Path $workshopRoot "Scripts") | Out-Null
foreach ($relativePath in $workshopFiles) {
    $destinationPath = Join-Path $workshopRoot $relativePath
    Copy-Item -LiteralPath (Join-Path $modRoot $relativePath) -Destination $destinationPath
}

New-Item -ItemType Directory -Force -Path (Join-Path $manualModRoot "Scripts") | Out-Null
foreach ($relativePath in $manualFiles) {
    $destinationPath = Join-Path $manualModRoot $relativePath
    Copy-Item -LiteralPath (Join-Path $modRoot $relativePath) -Destination $destinationPath
}
Copy-Item -LiteralPath (Join-Path $repoRoot "docs\MANUAL-INSTALL.md") -Destination (Join-Path $manualModRoot "INSTALL.md")

$unexpectedWorkshopFiles = Get-ChildItem -LiteralPath $workshopRoot -Recurse -File |
    ForEach-Object { $_.FullName.Substring($workshopRoot.Length + 1) } |
    Where-Object { $workshopFiles -notcontains $_ }
if ($unexpectedWorkshopFiles) {
    throw "Unexpected files entered the Workshop package: $($unexpectedWorkshopFiles -join ', ')"
}

$expectedManualFiles = @($manualFiles | ForEach-Object { "$($info.PackageName)\$_" }) + "$($info.PackageName)\INSTALL.md"
$unexpectedManualFiles = Get-ChildItem -LiteralPath $manualRoot -Recurse -File |
    ForEach-Object { $_.FullName.Substring($manualRoot.Length + 1) } |
    Where-Object { $expectedManualFiles -notcontains $_ }
if ($unexpectedManualFiles) {
    throw "Unexpected files entered the manual package: $($unexpectedManualFiles -join ', ')"
}

Compress-Archive -Path (Join-Path $workshopRoot "*") -DestinationPath $workshopZipPath -CompressionLevel Optimal
Compress-Archive -Path (Join-Path $manualRoot "*") -DestinationPath $manualZipPath -CompressionLevel Optimal

$workshopHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $workshopZipPath).Hash.ToLowerInvariant()
$manualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $manualZipPath).Hash.ToLowerInvariant()
Set-Content -LiteralPath $workshopChecksumPath -Value "$workshopHash  $([System.IO.Path]::GetFileName($workshopZipPath))" -Encoding ascii
Set-Content -LiteralPath $manualChecksumPath -Value "$manualHash  $([System.IO.Path]::GetFileName($manualZipPath))" -Encoding ascii

Write-Host "Workshop folder:  $workshopRoot"
Write-Host "Workshop archive: $workshopZipPath"
Write-Host "Workshop SHA-256: $workshopHash"
Write-Host "Manual folder:    $manualRoot"
Write-Host "Manual archive:   $manualZipPath"
Write-Host "Manual SHA-256:   $manualHash"
