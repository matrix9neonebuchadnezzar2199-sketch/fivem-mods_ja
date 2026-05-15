@echo off
SET DEV_ROOT=H:\CURSOR\Dev\fivem-mods_ja
SET SERVER_ROOT=H:\CURSOR\FiveMServer\txData\FiveMBasicServerCFXDefault_EC2B5A.base\resources\[jp-mods]

echo 全MODをデプロイ中...

FOR /D %%d IN ("%DEV_ROOT%\jp-*") DO (
    echo   → %%~nxd
    IF EXIST "%SERVER_ROOT%\%%~nxd" rmdir /s /q "%SERVER_ROOT%\%%~nxd"
    xcopy "%%d" "%SERVER_ROOT%\%%~nxd" /E /I /Q >nul
)

echo 完了！テストサーバーで refresh を実行してください。
