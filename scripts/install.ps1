[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$AddOnsPath = 'C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns'
)

$ErrorActionPreference = 'Stop'
$projectRoot = [System.IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
if (-not (Test-Path -LiteralPath (Join-Path $projectRoot 'per-hour.toc') -PathType Leaf)) {
    throw 'per-hour.toc was not found in the project root.'
}
if (-not (Test-Path -LiteralPath $AddOnsPath -PathType Container)) {
    throw "AddOns directory not found: $AddOnsPath. Use -AddOnsPath to select your Forever installation."
}

$destination = Join-Path ([System.IO.Path]::GetFullPath($AddOnsPath)) 'per-hour'
$existing = Get-Item -LiteralPath $destination -Force -ErrorAction SilentlyContinue
if ($existing) {
    $existingTarget = [string](@($existing.Target)[0])
    if ($existing.LinkType -eq 'Junction' -and $existingTarget -and
        [System.IO.Path]::GetFullPath($existingTarget).TrimEnd('\') -eq $projectRoot.TrimEnd('\')) {
        Write-Output "Already linked: $destination -> $projectRoot"
        return
    }
    throw "The destination already exists and was left intact: $destination"
}

if ($PSCmdlet.ShouldProcess($destination, "Create a directory junction to $projectRoot")) {
    New-Item -ItemType Junction -Path $destination -Target $projectRoot | Out-Null
    Write-Output "Installed: $destination -> $projectRoot"
    Write-Output 'Restart WoW after this first installation. Later code edits only need /reload.'
}
