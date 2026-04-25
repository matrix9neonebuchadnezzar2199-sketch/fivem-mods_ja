@echo off
SET MOD_NAME=%1
SET DEV_DIR=H:\CURSOR\Dev\fivem-mods\%MOD_NAME%
SET SERVER_DIR=C:\FiveMServer\server-data\resources\[jp-mods]\%MOD_NAME%

IF "%MOD_NAME%"=="" (
    echo エラー: MOD名を指定してください
    echo 使い方: deploy.bat jp-taxi
    exit /b 1
)

IF NOT EXIST "%DEV_DIR%" (
    echo エラー: %DEV_DIR% が見つかりません
    exit /b 1
)

echo [1/3] 古いファイルを削除中...
IF EXIST "%SERVER_DIR%" rmdir /s /q "%SERVER_DIR%"

echo [2/3] コピー中...
xcopy "%DEV_DIR%" "%SERVER_DIR%" /E /I /Q

echo [3/3] 完了！
echo   → txAdminで: refresh; restart %MOD_NAME%
