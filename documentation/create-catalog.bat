@echo off
setlocal

set "NPX_CMD=%ProgramFiles%\nodejs\npx.cmd"
if not exist "%NPX_CMD%" set "NPX_CMD=C:\Program Files\nodejs\npx.cmd"
if not exist "%NPX_CMD%" set "NPX_CMD=C:\Progra~1\nodejs\npx.cmd"

if not exist "%NPX_CMD%" (
	echo Node.js and npx were not found. Install Node.js 18 or newer, then reopen Command Prompt.
	exit /b 1
)

set "CATALOG_DIR=%~dp0catalog"
echo Creating EventCatalog project in "%CATALOG_DIR%"
call "%NPX_CMD%" --yes @eventcatalog/create-eventcatalog@latest "%CATALOG_DIR%" --use-npm
exit /b %errorlevel%