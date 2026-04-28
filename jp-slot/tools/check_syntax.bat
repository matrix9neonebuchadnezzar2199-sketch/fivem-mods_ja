@echo off
setlocal
cd /d "%~dp0.."
for %%f in (html\js\*.js) do (
  echo checking %%f
  node --check "%%f" || exit /b 1
)
echo All JS files OK
exit /b 0
