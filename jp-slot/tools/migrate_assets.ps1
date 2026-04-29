# 既存 html/assets を characters/<id>/ 中心の新構造へ移行する（リポの jp-slot ルート想定）
# 使い方: サーバー停止後、jp-slot フォルダで
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools/migrate_assets.ps1
$ErrorActionPreference = 'Stop'
$jpSlotRoot = Split-Path -Parent $PSScriptRoot
$assets = Join-Path $jpSlotRoot 'html\assets'
$lunaDir = Join-Path $assets 'characters\luna'

$subdirs = @(
    'idle', 'win', 'bonus', 'miss', 'cutins',
    'sounds\bgm', 'sounds\se', 'sounds\voice', 'backgrounds'
)
foreach ($d in $subdirs) {
    $p = Join-Path $lunaDir $d
    New-Item -ItemType Directory -Force -Path $p | Out-Null
}

# 移動: @(元, 先)
$moves = @(
    @( (Join-Path $lunaDir 'idle.png'), (Join-Path $lunaDir 'idle\portrait.png') ),
    @( (Join-Path $lunaDir 'win.webm'), (Join-Path $lunaDir 'win\win.webm') ),
    @( (Join-Path $lunaDir 'bigwin.webm'), (Join-Path $lunaDir 'win\bigwin.webm') ),
    @( (Join-Path $assets 'cutins\img_01.png'), (Join-Path $lunaDir 'cutins\cutin_bonus_01.png') ),
    @( (Join-Path $assets 'cutins\img_02.png'), (Join-Path $lunaDir 'cutins\cutin_win_01.png') ),
    @( (Join-Path $assets 'cutins\img_03.png'), (Join-Path $lunaDir 'cutins\cutin_big_01.png') ),
    @( (Join-Path $assets 'back.jpg'), (Join-Path $lunaDir 'backgrounds\back.jpg') )
)

foreach ($pair in $moves) {
    $src = $pair[0]
    $dst = $pair[1]
    if (Test-Path -LiteralPath $src) {
        $dstParent = Split-Path -Parent $dst
        if (-not (Test-Path -LiteralPath $dstParent)) {
            New-Item -ItemType Directory -Force -Path $dstParent | Out-Null
        }
        Move-Item -LiteralPath $src -Destination $dst -Force
        Write-Host "moved: $src -> $dst"
    } else {
        Write-Host "skip (not found): $src" -ForegroundColor Yellow
    }
}

$manifestPath = Join-Path $lunaDir 'manifest.json'
$manifest = @'
{
    "id": "luna",
    "displayName": "\u30eb\u30ca\u30fb\u30bb\u30e9\u30d5\u30a3\u30ca",
    "version": "1.0.0",
    "author": "Rosesanto Casino",
    "assets": {
        "idle": {
            "portrait": "idle/portrait.png",
            "videos": []
        },
        "win": {
            "video": "win/win.webm",
            "bigwin_video": "win/bigwin.webm"
        },
        "bonus": {
            "in_video": "bonus/bonus_in.webm",
            "loop_video": "bonus/bonus_loop.webm",
            "streak_video": "bonus/streak.webm",
            "big_video": "bonus/big.webm"
        },
        "miss": {
            "video": "miss/are.webm"
        },
        "cutins": [
            "cutins/cutin_win_01.png",
            "cutins/cutin_bonus_01.png",
            "cutins/cutin_big_01.png"
        ],
        "sounds": {
            "bgm": {
                "lobby": "sounds/bgm/lobby.mp3",
                "bonus": "sounds/bgm/bonus.mp3",
                "bigbonus": "sounds/bgm/bigbonus.mp3"
            },
            "se": {
                "reel_loop": "sounds/se/reel_loop.wav",
                "reel_stop": "sounds/se/reel_stop.wav",
                "win_chime": "sounds/se/win_chime.wav",
                "bonus_in": "sounds/se/bonus_in.wav",
                "miss_pyon": "sounds/se/miss_pyon.wav"
            },
            "voice": {
                "yatta": "sounds/voice/yatta.wav",
                "kita": "sounds/voice/kita.wav",
                "sugoi": "sounds/voice/sugoi.wav",
                "are": "sounds/voice/are.wav"
            }
        },
        "backgrounds": {
            "default": "backgrounds/back.jpg",
            "bonus": "backgrounds/back_bonus.jpg"
        }
    }
}
'@
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($manifestPath, $manifest, $utf8NoBom)
Write-Host "wrote: $manifestPath"

$legacyCutins = Join-Path $assets 'cutins'
if (Test-Path -LiteralPath $legacyCutins) {
    $left = Get-ChildItem -LiteralPath $legacyCutins -Force -ErrorAction SilentlyContinue
    if (-not $left -or $left.Count -eq 0) {
        Remove-Item -LiteralPath $legacyCutins -Force -ErrorAction SilentlyContinue
        Write-Host "removed empty: $legacyCutins"
    } else {
        Write-Host "legacy cutins still has files; remove manually if obsolete: $legacyCutins" -ForegroundColor Yellow
    }
}

Write-Host "Done."
