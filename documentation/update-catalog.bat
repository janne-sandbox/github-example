@echo off
setlocal

set "NPX_CMD=%ProgramFiles%\nodejs\npx.cmd"
if not exist "%NPX_CMD%" set "NPX_CMD=C:\Program Files\nodejs\npx.cmd"
if not exist "%NPX_CMD%" set "NPX_CMD=C:\Progra~1\nodejs\npx.cmd"
set "NPM_CMD=%ProgramFiles%\nodejs\npm.cmd"
if not exist "%NPM_CMD%" set "NPM_CMD=C:\Program Files\nodejs\npm.cmd"
if not exist "%NPM_CMD%" set "NPM_CMD=C:\Progra~1\nodejs\npm.cmd"

if not exist "%NPX_CMD%" (
    echo Node.js and npx were not found. Install Node.js 18 or newer, then reopen Command Prompt.
    exit /b 1
)
if not exist "%NPM_CMD%" (
    echo Node.js and npm were not found. Install Node.js 18 or newer, then reopen Command Prompt.
    exit /b 1
)

set "CATALOG_DIR=%~dp0catalog"
if not exist "%CATALOG_DIR%\package.json" goto create_catalog
goto install_catalog

:create_catalog
    echo Creating EventCatalog project in "%CATALOG_DIR%"
    call "%NPX_CMD%" --yes @eventcatalog/create-eventcatalog@latest "%CATALOG_DIR%" --use-npm
    set "EXIT_CODE=%ERRORLEVEL%"
    if not "%EXIT_CODE%"=="0" exit /b %EXIT_CODE%

:install_catalog
call node "%~dp0update-catalog-source.mjs"
set "EXIT_CODE=%ERRORLEVEL%"
if not "%EXIT_CODE%"=="0" exit /b %EXIT_CODE%

pushd "%CATALOG_DIR%"
echo Installing EventCatalog dependencies...
call "%NPM_CMD%" install
set "EXIT_CODE=%ERRORLEVEL%"
if not "%EXIT_CODE%"=="0" goto update_failed

echo Building EventCatalog from the current catalog source...
call "%NPM_CMD%" run build
set "EXIT_CODE=%errorlevel%"
popd
exit /b %EXIT_CODE%

:update_failed
popd
exit /b %EXIT_CODE%
