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

$requiredFiles = @(
    "Info.json",
    [string]$info.Thumbnail,
    "Scripts\main.lua",
    "Scripts\balance.lua",
    "Scripts\config.lua",
    "Scripts\gamedefs.lua",
    "Scripts\identity.lua"
)

foreach ($relativePath in $requiredFiles) {
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

$packageName = "$($info.PackageName)-$($info.Version)"
$packageRoot = Join-Path $outputRootFull $packageName
$zipPath = Join-Path $outputRootFull "$packageName.zip"
$checksumPath = "$zipPath.sha256"

New-Item -ItemType Directory -Force -Path $outputRootFull | Out-Null
if (Test-Path -LiteralPath $packageRoot) {
    Remove-Item -LiteralPath $packageRoot -Recurse -Force
}
if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}
if (Test-Path -LiteralPath $checksumPath) {
    Remove-Item -LiteralPath $checksumPath -Force
}

New-Item -ItemType Directory -Force -Path (Join-Path $packageRoot "Scripts") | Out-Null
foreach ($relativePath in $requiredFiles) {
    $destinationPath = Join-Path $packageRoot $relativePath
    Copy-Item -LiteralPath (Join-Path $modRoot $relativePath) -Destination $destinationPath
}

Compress-Archive -Path (Join-Path $packageRoot "*") -DestinationPath $zipPath -CompressionLevel Optimal
$hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $zipPath).Hash.ToLowerInvariant()
Set-Content -LiteralPath $checksumPath -Value "$hash  $([System.IO.Path]::GetFileName($zipPath))" -Encoding ascii

$unexpected = Get-ChildItem -LiteralPath $packageRoot -Recurse -File |
    ForEach-Object { $_.FullName.Substring($packageRoot.Length + 1) } |
    Where-Object { $requiredFiles -notcontains $_ }
if ($unexpected) {
    throw "Unexpected files entered the package: $($unexpected -join ', ')"
}

Write-Host "Workshop folder: $packageRoot"
Write-Host "Archive:         $zipPath"
Write-Host "SHA-256:        $hash"
