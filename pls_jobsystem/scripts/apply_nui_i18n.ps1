# NOTE: 汎用版が tools/apply_nui_i18n.ps1 にあります。新規 MOD ではそちらを推奨。
<#
.SYNOPSIS
  pls_jobsystem の NUI バンドル(web/dist/assets/index.js) を、
  docs/i18n/nui_replacements.json に基づき日本語化します。

.PARAMETER Mode
  preview : 置換差分を一覧表示するだけ（書き込みなし）
  apply   : 実際に書き込み（事前にバックアップを作成）
  restore : .orig からの復元

.EXAMPLE
  pwsh -File .\scripts\apply_nui_i18n.ps1 -Mode preview
  pwsh -File .\scripts\apply_nui_i18n.ps1 -Mode apply
  pwsh -File .\scripts\apply_nui_i18n.ps1 -Mode restore
#>

param(
    [ValidateSet("preview", "apply", "restore")]
    [string]$Mode = "preview"
)

$ErrorActionPreference = "Stop"
$root       = Split-Path -Parent $PSScriptRoot
$jsPath     = Join-Path $root "web\dist\assets\index.js"
$htmlPath   = Join-Path $root "web\dist\index.html"
$mapPath    = Join-Path $root "docs\i18n\nui_replacements.json"
$jsBackup   = "$jsPath.orig"
$htmlBackup = "$htmlPath.orig"

if (-not (Test-Path $jsPath))  { throw "index.js not found: $jsPath" }
if (-not (Test-Path $mapPath)) { throw "nui_replacements.json not found: $mapPath" }

if ($Mode -eq "restore") {
    if (Test-Path $jsBackup)   { Copy-Item -Force $jsBackup   $jsPath;   Write-Host "Restored index.js" }
    if (Test-Path $htmlBackup) { Copy-Item -Force $htmlBackup $htmlPath; Write-Host "Restored index.html" }
    return
}

$rootObj = Get-Content $mapPath -Raw -Encoding UTF8 | ConvertFrom-Json
$map     = $rootObj.translations

$js   = Get-Content $jsPath -Raw -Encoding UTF8
$html = Get-Content $htmlPath -Raw -Encoding UTF8

$totalHits = 0
$report = New-Object System.Collections.Generic.List[Object]

function Escape-JsStringInDoubleQuotes([string]$s) {
    return $s.Replace('\', '\\').Replace('"', '\"')
}

foreach ($prop in $map.PSObject.Properties) {
    $en = $prop.Name
    $ja = [string]$prop.Value
    if ([string]::IsNullOrEmpty($en) -or $en.StartsWith("_")) { continue }

    $fromDq = '"' + $en + '"'
    $fromSq = "'" + $en + "'"
    $countDq = ([regex]::Matches($js, [regex]::Escape($fromDq))).Count
    $countSq = ([regex]::Matches($js, [regex]::Escape($fromSq))).Count
    $count = $countDq + $countSq

    if ($count -gt 0) {
        $report.Add([pscustomobject]@{ EN = $en; JA = $ja; Hits = $count })
        $totalHits += $count
        if ($Mode -eq "apply") {
            $toDq = '"' + (Escape-JsStringInDoubleQuotes $ja) + '"'
            $toSq = "'" + $ja.Replace("'", "\'") + "'"
            $js = $js.Replace($fromDq, $toDq)
            $js = $js.Replace($fromSq, $toSq)
        }
    }
}

$htmlNew = $html -replace 'lang="[a-zA-Z\-]+"', 'lang="ja"'

Write-Host ""
Write-Host ("Replacement keys with hits: {0} / Total hits: {1}" -f $report.Count, $totalHits)
$report | Sort-Object -Property Hits -Descending | Format-Table -AutoSize

if ($Mode -eq "preview") {
    Write-Host ""
    Write-Host "Preview only (no writes). To apply: powershell -File .\scripts\apply_nui_i18n.ps1 -Mode apply"
    return
}

if (-not (Test-Path $jsBackup))   { Copy-Item -Force $jsPath   $jsBackup }
if (-not (Test-Path $htmlBackup)) { Copy-Item -Force $htmlPath $htmlBackup }

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($jsPath,   $js,   $utf8NoBom)
[System.IO.File]::WriteAllText($htmlPath, $htmlNew, $utf8NoBom)

Write-Host ""
Write-Host "Done. Backups: $jsBackup / $htmlBackup"
Write-Host "To restore: powershell -File .\scripts\apply_nui_i18n.ps1 -Mode restore"
