<#
.SYNOPSIS
Deploys Guild Feed Box Sync to the active Palworld-compatible UE4SS installation.

.DESCRIPTION
Mirrors the repository's runtime scripts into a GuildFeedBoxDev directory of an
existing Workshop or manual UE4SS installation. The separate folder name avoids
Palworld's Workshop loader managing or removing the local development payload.
The released Workshop copy must be disabled or unsubscribed while testing.
Palworld must be restarted afterward.

.PARAMETER PalworldPath
Palworld installation containing Palworld.exe. Defaults to the standard Steam
library under Program Files (x86).
#>
param(
    [string]$PalworldPath = "C:\Program Files (x86)\Steam\steamapps\common\Palworld"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path (Join-Path $PalworldPath "Palworld.exe"))) {
    throw "Palworld not found at '$PalworldPath'. Pass -PalworldPath <dir>."
}

$workshopModsDir = Join-Path $PalworldPath "Mods\NativeMods\UE4SS\Mods"
$manualModsDir = Join-Path $PalworldPath "Pal\Binaries\Win64\ue4ss\Mods"
if (Test-Path $workshopModsDir) {
    $ue4ssModsDir = $workshopModsDir
} elseif (Test-Path $manualModsDir) {
    $ue4ssModsDir = $manualModsDir
} else {
    throw "Palworld-compatible UE4SS not found. Install exactly one UE4SS distribution first."
}

$source = Join-Path $PSScriptRoot "..\mod"
$destination = Join-Path $ue4ssModsDir "GuildFeedBoxDev"
$destinationFull = [System.IO.Path]::GetFullPath($destination)
$modsDirFull = [System.IO.Path]::GetFullPath($ue4ssModsDir).TrimEnd('\') + '\'
if (-not $destinationFull.StartsWith($modsDirFull, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Development destination must remain inside the active UE4SS Mods directory."
}

New-Item -ItemType Directory -Force -Path $destinationFull | Out-Null
Copy-Item -LiteralPath (Join-Path $source "enabled.txt") -Destination $destinationFull -Force
robocopy (Join-Path $source "Scripts") (Join-Path $destinationFull "Scripts") /MIR /NFL /NDL /NJH /NJS | Out-Null
if ($LASTEXITCODE -ge 8) { throw "robocopy failed with exit code $LASTEXITCODE" }

Write-Host "Deployed Guild Feed Box Sync development build to $destinationFull"
Write-Host "Keep the released GuildFeedBox Workshop item disabled or unsubscribed during this test."
Write-Host "Restart Palworld, load a world with Feed Boxes, then inspect UE4SS.log."
Write-Host "Production build: automatic filter-aware transfers are enabled after the readiness delay."
