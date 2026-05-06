# locales/en.json の全キーが locales/ja.json に存在するか検証する。
# _help_* は ja のみに存在してよい（本家 en には無い派生用キー）。
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$enPath = Join-Path $root 'locales\en.json'
$jaPath = Join-Path $root 'locales\ja.json'
if (-not (Test-Path $enPath)) { Write-Error "not found: $enPath" }
if (-not (Test-Path $jaPath)) { Write-Error "not found: $jaPath" }
$en = Get-Content -Raw $enPath | ConvertFrom-Json
$ja = Get-Content -Raw $jaPath | ConvertFrom-Json
$enKeys = @($en.PSObject.Properties.Name)
$jaKeys = @($ja.PSObject.Properties.Name)
$missing = $enKeys | Where-Object { $jaKeys -notcontains $_ }
$extra = $jaKeys | Where-Object { $enKeys -notcontains $_ -and $_ -notlike '_help_*' }
if ($missing) {
    Write-Host "ja.json に不足しているキー:" -ForegroundColor Red
    $missing | ForEach-Object { Write-Host "  - $_" }
    exit 1
}
if ($extra) {
    Write-Host "ja.json にのみ存在（_help_* 以外）:" -ForegroundColor Yellow
    $extra | ForEach-Object { Write-Host "  - $_" }
    exit 1
}
Write-Host "OK: en.json の全キーが ja.json に存在します（_help_* は ja のみ可）" -ForegroundColor Green
exit 0
