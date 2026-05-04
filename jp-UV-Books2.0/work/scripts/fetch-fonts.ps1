# ──────────────────────────────────────────────
# 0) 変数（既存セッションを閉じてしまった場合の再設定）
# ──────────────────────────────────────────────
$work = "H:\CURSOR\Dev\jp-UV-Books2.0"
$mgr  = "H:\CURSOR\Dev\fivem-mods_ja"

# 既存の壊れたフォントフォルダを掃除（4xxエラーで0バイトになっているものがあるため）
if (Test-Path "$work\html\fonts") {
    Get-ChildItem "$work\html\fonts" -File | Where-Object { $_.Length -lt 10000 } | Remove-Item -Force
}
New-Item -ItemType Directory -Path "$work\html\fonts" -Force | Out-Null

# ──────────────────────────────────────────────
# 1) gwfh API からサブセット japanese+latin の woff2 URL を取得して DL
# ──────────────────────────────────────────────
# 取得したいフォント： id（gwfh側） / 出力ファイル名 / variant
$fontList = @(
    @{id='noto-serif-jp';     out='NotoSerifJP-Regular.woff2';    variant='regular'},
    @{id='noto-serif-jp';     out='NotoSerifJP-Bold.woff2';       variant='700'},
    @{id='noto-sans-jp';      out='NotoSansJP-Regular.woff2';     variant='regular'},
    @{id='noto-sans-jp';      out='NotoSansJP-Bold.woff2';        variant='700'},
    @{id='shippori-mincho';   out='ShipporiMincho-Regular.woff2'; variant='regular'},
    @{id='shippori-mincho';   out='ShipporiMincho-Bold.woff2';    variant='700'},
    @{id='klee-one';          out='KleeOne-Regular.woff2';        variant='regular'},
    @{id='klee-one';          out='KleeOne-SemiBold.woff2';       variant='600'},
    @{id='yuji-syuku';        out='YujiSyuku-Regular.woff2';      variant='regular'},
    @{id='yuji-mai';          out='YujiMai-Regular.woff2';        variant='regular'},
    @{id='yuji-boku';         out='YujiBoku-Regular.woff2';       variant='regular'},
    @{id='hina-mincho';       out='HinaMincho-Regular.woff2';     variant='regular'},
    @{id='zen-kurenaido';     out='ZenKurenaido-Regular.woff2';   variant='regular'},
    @{id='yusei-magic';       out='YuseiMagic-Regular.woff2';     variant='regular'},
    @{id='reggae-one';        out='ReggaeOne-Regular.woff2';      variant='regular'}
)

foreach ($f in $fontList) {
    $dest = Join-Path "$work\html\fonts" $f.out
    if ((Test-Path $dest) -and ((Get-Item $dest).Length -gt 50000)) {
        Write-Host "skip (already exists): $($f.out)" -ForegroundColor DarkGray
        continue
    }

    $api = "https://gwfh.mranftl.com/api/fonts/$($f.id)?subsets=japanese,latin&variants=$($f.variant)&formats=woff2"
    Write-Host "→ querying $($f.id) [$($f.variant)] ..." -ForegroundColor Cyan

    try {
        $meta = Invoke-RestMethod -Uri $api -Method GET -ErrorAction Stop
        $variant = $meta.variants | Where-Object { $_.id -eq $f.variant }
        if (-not $variant) {
            Write-Warning "  variant '$($f.variant)' not found for $($f.id)"
            continue
        }
        $woff2Url = $variant.woff2
        if (-not $woff2Url) {
            Write-Warning "  no woff2 URL returned for $($f.id) $($f.variant)"
            continue
        }
        Write-Host "  ↓ $woff2Url" -ForegroundColor DarkGray
        Invoke-WebRequest -Uri $woff2Url -OutFile $dest -UserAgent "Mozilla/5.0" -ErrorAction Stop
        $sz = [math]::Round((Get-Item $dest).Length / 1KB, 1)
        Write-Host "  ✓ $($f.out) ($sz KB)" -ForegroundColor Green
    } catch {
        Write-Warning "  failed: $_"
    }
    Start-Sleep -Milliseconds 200   # API への配慮
}

# ──────────────────────────────────────────────
# 2) OFL.txt を OFL公式から取得
# ──────────────────────────────────────────────
$oflPath = "$work\html\fonts\OFL.txt"
if (-not (Test-Path $oflPath)) {
    try {
        Invoke-WebRequest `
            -Uri 'https://openfontlicense.org/documents/OFL.txt' `
            -OutFile $oflPath -ErrorAction Stop
        Write-Host "✓ OFL.txt 取得" -ForegroundColor Green
    } catch {
        # フォールバック：Noto Sans JP のリポジトリから
        try {
            Invoke-WebRequest `
                -Uri 'https://raw.githubusercontent.com/notofonts/noto-cjk/main/Sans/LICENSE' `
                -OutFile $oflPath -ErrorAction Stop
            Write-Host "✓ OFL.txt 取得（フォールバック）" -ForegroundColor Green
        } catch {
            Write-Warning "OFL.txt 取得失敗。手動で https://openfontlicense.org/ から取得してください。"
        }
    }
}

# ──────────────────────────────────────────────
# 3) 結果サマリ
# ──────────────────────────────────────────────
Write-Host "`n=== Font directory summary ===" -ForegroundColor Yellow
Get-ChildItem "$work\html\fonts" -File | ForEach-Object {
    $kb = [math]::Round($_.Length / 1KB, 1)
    "{0,-40} {1,8} KB" -f $_.Name, $kb
}

$total = (Get-ChildItem "$work\html\fonts" -File | Measure-Object Length -Sum).Sum
$totalMB = [math]::Round($total / 1MB, 2)
Write-Host "`nTotal: $totalMB MB" -ForegroundColor Yellow
