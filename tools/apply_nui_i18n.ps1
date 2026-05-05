<#
.SYNOPSIS
  fivem-mods_ja 汎用 NUI i18n 適用ツール

.DESCRIPTION
  指定された MOD ディレクトリ配下の web/dist/assets/index.js を、
  docs/i18n/<ModName>_replacements.json (なければ docs/i18n/nui_replacements.json) に従って
  日本語化します。PowerShell 5.1 互換。コンソール出力は ASCII のみ。

.PARAMETER ModName
  対象 MOD のディレクトリ名 (例: pls_jobsystem)

.PARAMETER Mode
  preview : 置換差分を一覧表示するだけ (書き込みなし、既定)
  apply   : 実際に書き込み (事前にバックアップ *.orig を作成)
  restore : *.orig からの復元

.PARAMETER MapPath
  置換マップを明示指定したい場合のフルパス (省略可)

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\apply_nui_i18n.ps1 -ModName pls_jobsystem -Mode preview
  powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\apply_nui_i18n.ps1 -ModName pls_jobsystem -Mode apply
  powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\apply_nui_i18n.ps1 -ModName pls_jobsystem -Mode restore
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ModName,

    [ValidateSet("preview","apply","restore")]
    [string]$Mode = "preview",

    [string]$MapPath = ""
)

$ErrorActionPreference = "Stop"

# --- パス解決 -----------------------------------------------------------------
$repoRoot = Split-Path -Parent $PSScriptRoot
$modRoot  = Join-Path $repoRoot $ModName

if (-not (Test-Path $modRoot)) {
    throw "Mod directory not found: $modRoot"
}

$jsPath     = Join-Path $modRoot "web\dist\assets\index.js"
$htmlPath   = Join-Path $modRoot "web\dist\index.html"
$jsBackup   = "$jsPath.orig"
$htmlBackup = "$htmlPath.orig"

# 置換マップの自動解決順:
#  1) -MapPath で明示指定
#  2) docs/i18n/<ModName>_replacements.json
#  3) docs/i18n/nui_replacements.json (旧式・MOD固有)
if ([string]::IsNullOrEmpty($MapPath)) {
    $candidate1 = Join-Path $modRoot ("docs\i18n\{0}_replacements.json" -f $ModName)
    $candidate2 = Join-Path $modRoot "docs\i18n\nui_replacements.json"
    if (Test-Path $candidate1) {
        $MapPath = $candidate1
    } elseif (Test-Path $candidate2) {
        $MapPath = $candidate2
    } else {
        throw "Replacement map not found. Tried: `n  $candidate1`n  $candidate2"
    }
}

if (-not (Test-Path $jsPath))  { throw "index.js not found: $jsPath" }
if (-not (Test-Path $MapPath)) { throw "Map file not found: $MapPath" }

Write-Host ("[i18n] Mod      : {0}" -f $ModName)
Write-Host ("[i18n] Mode     : {0}" -f $Mode)
Write-Host ("[i18n] Map      : {0}" -f $MapPath)
Write-Host ("[i18n] Target JS: {0}" -f $jsPath)

# --- restore モード -----------------------------------------------------------
if ($Mode -eq "restore") {
    if (Test-Path $jsBackup)   { Copy-Item -Force $jsBackup   $jsPath;   Write-Host "[i18n] Restored: index.js" }
    if (Test-Path $htmlBackup) { Copy-Item -Force $htmlBackup $htmlPath; Write-Host "[i18n] Restored: index.html" }
    return
}

# --- 入力読込 -----------------------------------------------------------------
$mapJson = Get-Content $MapPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($null -eq $mapJson.translations) {
    throw "Map JSON has no 'translations' object: $MapPath"
}
$map = $mapJson.translations

$js   = Get-Content $jsPath -Raw -Encoding UTF8
$html = $null
if (Test-Path $htmlPath) { $html = Get-Content $htmlPath -Raw -Encoding UTF8 }

$totalHits = 0
$report = New-Object System.Collections.Generic.List[Object]

foreach ($prop in $map.PSObject.Properties) {
    $en = $prop.Name
    $ja = [string]$prop.Value
    if ([string]::IsNullOrEmpty($en) -or $en.StartsWith("_")) { continue }

    # 文字列リテラル境界 (" / ') 込みでマッチング
    $dq_old = '"' + $en + '"'
    $sq_old = "'" + $en + "'"
    $dq_new = '"' + $ja + '"'
    $sq_new = "'" + $ja + "'"

    $countDQ = ([regex]::Matches($js, [regex]::Escape($dq_old))).Count
    $countSQ = ([regex]::Matches($js, [regex]::Escape($sq_old))).Count
    $count   = $countDQ + $countSQ

    if ($count -gt 0) {
        $report.Add([pscustomobject]@{ EN=$en; JA=$ja; Hits=$count })
        $totalHits += $count
        if ($Mode -eq "apply") {
            # 正規表現を使わず、リテラル置換 (PS 5.1 互換)
            $js = $js.Replace($dq_old, $dq_new)
            $js = $js.Replace($sq_old, $sq_new)
        }
    }
}

# index.html の lang 属性
$htmlNew = $null
if ($null -ne $html) {
    $htmlNew = [regex]::Replace($html, 'lang="[a-zA-Z\-]+"', 'lang="ja"')
}

Write-Host ""
Write-Host ("[i18n] Matched keys : {0}" -f $report.Count)
Write-Host ("[i18n] Total hits   : {0}" -f $totalHits)
$report | Sort-Object -Property Hits -Descending | Format-Table -AutoSize

if ($Mode -eq "preview") {
    Write-Host ""
    Write-Host "[i18n] Preview only. No files were written."
    Write-Host ("[i18n] To apply: powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\apply_nui_i18n.ps1 -ModName {0} -Mode apply" -f $ModName)
    return
}

# --- バックアップ -------------------------------------------------------------
if (-not (Test-Path $jsBackup))                              { Copy-Item -Force $jsPath   $jsBackup }
if ($null -ne $html -and -not (Test-Path $htmlBackup))       { Copy-Item -Force $htmlPath $htmlBackup }

# --- 書き込み (BOM なし UTF-8) ------------------------------------------------
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($jsPath, $js, $utf8NoBom)
if ($null -ne $htmlNew) {
    [System.IO.File]::WriteAllText($htmlPath, $htmlNew, $utf8NoBom)
}

Write-Host ""
Write-Host ("[i18n] Applied. Backups: {0} / {1}" -f $jsBackup, $htmlBackup)
Write-Host ("[i18n] To rollback: powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\apply_nui_i18n.ps1 -ModName {0} -Mode restore" -f $ModName)
