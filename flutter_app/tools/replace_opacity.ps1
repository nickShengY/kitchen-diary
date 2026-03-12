$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $PSCommandPath
$projectRoot = Split-Path -Parent $scriptDir
$libPath = Join-Path $projectRoot 'lib'
$files = Get-ChildItem -Path $libPath -Recurse -Filter '*.dart'
foreach ($f in $files) {
    $path = $f.FullName
    $content = Get-Content -LiteralPath $path -Raw
    $updated = $content -replace 'withOpacity\(([^)]*)\)', 'withValues(alpha: $1)'
    if ($updated -ne $content) {
        Set-Content -LiteralPath $path -Value $updated -Encoding UTF8
    }
}
