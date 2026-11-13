$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$tocFile = Join-Path $projectRoot 'per-hour.toc'
$versionLine = Get-Content -LiteralPath $tocFile | Where-Object { $_ -match '^## Version:' }
$version = ($versionLine -replace '^## Version:\s*', '').Trim()
if ($version -notmatch '^[A-Za-z0-9.-]+$') { throw 'Invalid addon version in per-hour.toc' }

$outputDirectory = Join-Path $projectRoot 'dist'
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
$outputPath = Join-Path $outputDirectory ('per-hour-' + $version + '.zip')

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$stream = [System.IO.File]::Open($outputPath, [System.IO.FileMode]::Create)
$archive = [System.IO.Compression.ZipArchive]::new($stream, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    $files = @(
        Get-Item -LiteralPath $tocFile
        Get-Item -LiteralPath (Join-Path $projectRoot 'LICENSE')
        Get-ChildItem -LiteralPath (Join-Path $projectRoot 'src') -Recurse -File
    )
    foreach ($file in ($files | Sort-Object FullName)) {
        $relativePath = $file.FullName.Substring($projectRoot.Length + 1).Replace('\', '/')
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $archive, $file.FullName, ('per-hour/' + $relativePath)
        ) | Out-Null
    }
} finally {
    $archive.Dispose()
    $stream.Dispose()
}
Write-Output $outputPath
