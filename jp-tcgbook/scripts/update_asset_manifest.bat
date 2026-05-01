@echo off
chcp 65001 >nul
REM PNG を増やしたあとに実行 → html/assets/cards/asset_manifest.json を再生成
REM 用法: ダブルクリック、または deploy の直前にこのバッチを実行

cd /d "%~dp0\.."

where python >nul 2>nul
if errorlevel 1 (
  echo [エラー] python が PATH にありません。Python 3 を入れるか、py ランチャーを使ってください。
  exit /b 1
)

python scripts\generate_asset_manifest.py
if errorlevel 1 exit /b 1

echo OK: asset_manifest.json を更新しました。続けて jp-tcgbook を refresh/restart してください。
exit /b 0
