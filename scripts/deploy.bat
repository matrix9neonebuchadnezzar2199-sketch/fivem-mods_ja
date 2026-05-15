@echo off
SET MOD_NAME=%1
SET DEV_DIR=H:\CURSOR\Dev\fivem-mods_ja\%MOD_NAME%
SET SERVER_DIR=H:\CURSOR\FiveMServer\txData\FiveMBasicServerCFXDefault_EC2B5A.base\resources\[jp-mods]\%MOD_NAME%

IF "%MOD_NAME%"=="" (
    echo ERROR: Specify MOD name as argument
    echo Usage: deploy.bat jp-taxi
    exit /b 1
)

IF NOT EXIST "%DEV_DIR%" (
    echo ERROR: %DEV_DIR% not found
    exit /b 1
)

echo [1/3] Removing old files...
IF EXIST "%SERVER_DIR%" rmdir /s /q "%SERVER_DIR%"

echo [2/3] Copying...
xcopy "%DEV_DIR%" "%SERVER_DIR%" /E /I /Q

echo [3/3] Done. In txAdmin: refresh; restart %MOD_NAME%