@echo off
setlocal

set "NPX_CMD=%ProgramFiles%\nodejs\npx.cmd"
if not exist "%NPX_CMD%" set "NPX_CMD=C:\Program Files\nodejs\npx.cmd"
if not exist "%NPX_CMD%" set "NPX_CMD=C:\Progra~1\nodejs\npx.cmd"

if not exist "%NPX_CMD%" (
	echo Node.js and npx were not found. Install Node.js 18 or newer, then reopen Command Prompt.
	exit /b 1
)

call "%NPX_CMD%" @eventcatalog/create-eventcatalog@latest catalog