@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM Purpose:
REM   Install, optionally upgrade, initialize, format and validate Terraform.
REM
REM Usage:
REM   install-terraform.bat
REM   install-terraform.bat .\terraform
REM
REM Default Terraform directory:
REM   .\terraform

set "TERRAFORM_DIR=%~1"
if not defined TERRAFORM_DIR set "TERRAFORM_DIR=.\terraform"

set "PACKAGE_ID=Hashicorp.Terraform"

echo ========================================
echo  Terraform Windows setup
echo ========================================
echo.

REM ------------------------------------------------------------
REM WinGet
REM ------------------------------------------------------------

where winget >nul 2>&1
if errorlevel 1 (
    echo ERROR: winget is required.
    echo.
    echo Install or update "App Installer" from Microsoft Store.
    exit /b 1
)

echo == WinGet ==
echo Package: %PACKAGE_ID%

REM ------------------------------------------------------------
REM Terraform installation
REM ------------------------------------------------------------

where terraform >nul 2>&1
if errorlevel 1 (
    echo.
    echo Terraform is not installed.
    echo Installing %PACKAGE_ID%...
    echo.

    winget install ^
        --id "%PACKAGE_ID%" ^
        --exact ^
        --source winget ^
        --accept-package-agreements ^
        --accept-source-agreements

    if errorlevel 1 (
        echo.
        echo ERROR: Terraform installation failed.
        exit /b 1
    )

    REM WinGet may have modified PATH, but current CMD process
    REM might not see the change yet.
    call :RefreshPath
)

where terraform >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: Terraform was installed but terraform.exe
    echo is not available in the current PATH.
    echo.
    echo Close this Command Prompt and open a new one,
    echo then run this script again.
    exit /b 1
)

echo.
echo Terraform is installed:
terraform version

REM ------------------------------------------------------------
REM Terraform upgrade
REM ------------------------------------------------------------

echo.
echo == Checking for Terraform upgrade ==

set "UPGRADE_AVAILABLE="

for /f "usebackq delims=" %%A in (`winget upgrade --id "%PACKAGE_ID%" --exact --source winget 2^>nul`) do (
    echo %%A | findstr /I /C:"%PACKAGE_ID%" >nul
    if not errorlevel 1 (
        set "UPGRADE_AVAILABLE=1"
    )
)

if defined UPGRADE_AVAILABLE (
    echo.
    echo A newer Terraform version appears to be available.
    echo.

    set /p "ANSWER=Upgrade Terraform now? [y/N] "

    if /I "!ANSWER!"=="y" goto UpgradeTerraform
    if /I "!ANSWER!"=="yes" goto UpgradeTerraform

    echo Terraform upgrade skipped.
    goto AfterUpgrade
)

echo Terraform is up to date.
goto AfterUpgrade


:UpgradeTerraform

echo.
echo Upgrading Terraform...

winget upgrade ^
    --id "%PACKAGE_ID%" ^
    --exact ^
    --source winget ^
    --accept-package-agreements ^
    --accept-source-agreements

if errorlevel 1 (
    echo.
    echo ERROR: Terraform upgrade failed.
    exit /b 1
)

call :RefreshPath

:AfterUpgrade

REM ------------------------------------------------------------
REM Locate Terraform
REM ------------------------------------------------------------

echo.
echo == Terraform binary ==

where terraform

if errorlevel 1 (
    echo ERROR: terraform.exe cannot be found.
    exit /b 1
)

REM ------------------------------------------------------------
REM Verify Terraform executable
REM ------------------------------------------------------------

echo.
echo == Terraform version ==

terraform version

if errorlevel 1 (
    echo ERROR: Terraform could not be executed.
    exit /b 1
)

REM ------------------------------------------------------------
REM Terraform project
REM ------------------------------------------------------------

echo.
echo == Terraform project ==

if not exist "%TERRAFORM_DIR%\" (
    echo ERROR: Terraform directory does not exist:
    echo   %TERRAFORM_DIR%
    exit /b 1
)

pushd "%TERRAFORM_DIR%"

if errorlevel 1 (
    echo ERROR: Cannot enter Terraform directory:
    echo   %TERRAFORM_DIR%
    exit /b 1
)

dir /b "*.tf" >nul 2>&1

if errorlevel 1 (
    echo ERROR: No .tf files found in:
    cd
    popd
    exit /b 1
)

echo Terraform directory:
cd

REM ------------------------------------------------------------
REM Detect Windows architecture
REM ------------------------------------------------------------

echo.
echo == Platform ==

set "ARCH=%PROCESSOR_ARCHITECTURE%"

if /I "%ARCH%"=="AMD64" (
    set "WINDOWS_PLATFORM=windows_amd64"
    goto ArchitectureOK
)

if /I "%ARCH%"=="ARM64" (
    set "WINDOWS_PLATFORM=windows_arm64"
    goto ArchitectureOK
)

if /I "%ARCH%"=="x86" (
    set "WINDOWS_PLATFORM=windows_386"
    goto ArchitectureOK
)

echo ERROR: Unsupported Windows architecture: %ARCH%
popd
exit /b 1

:ArchitectureOK

echo Detected platform: %WINDOWS_PLATFORM%

REM ------------------------------------------------------------
REM Clean provider installation
REM ------------------------------------------------------------

echo.
echo == Cleaning Terraform provider cache ==

if exist ".terraform\" (
    echo Removing existing .terraform directory...
    rmdir /s /q ".terraform"

    if exist ".terraform\" (
        echo ERROR: Failed to remove .terraform directory.
        popd
        exit /b 1
    )
)

REM ------------------------------------------------------------
REM Repair dependency lock file
REM ------------------------------------------------------------

echo.
echo == Updating Terraform provider lock file ==

REM Include:
REM
REM   - Windows AMD64
REM   - Windows ARM64
REM   - macOS Intel
REM   - macOS Apple Silicon
REM   - Linux AMD64, commonly used by CI/CD
REM
REM This makes .terraform.lock.hcl portable across
REM developer machines and CI/CD environments.

terraform providers lock ^
    -platform=windows_amd64 ^
    -platform=darwin_arm64 ^
    -platform=darwin_amd64 ^
    -platform=linux_amd64

if errorlevel 1 (
    echo.
    echo ERROR: terraform providers lock failed.
    popd
    exit /b 1
)

REM ------------------------------------------------------------
REM Initialize Terraform
REM ------------------------------------------------------------

echo.
echo == Initializing Terraform ==

terraform init ^
    -backend=false ^
    -input=false ^
    -lockfile=readonly ^
    -upgrade=false

if errorlevel 1 (
    echo.
    echo ERROR: terraform init failed.
    popd
    exit /b 1
)

REM ------------------------------------------------------------
REM Formatting
REM ------------------------------------------------------------

echo.
echo == Checking formatting ==

terraform fmt -check -recursive

if errorlevel 1 (
    echo.
    echo Terraform formatting is incorrect.
    echo.
    echo Fixing formatting automatically...

    terraform fmt -recursive

    if errorlevel 1 (
        echo ERROR: terraform fmt failed.
        popd
        exit /b 1
    )
)

REM ------------------------------------------------------------
REM Validation
REM ------------------------------------------------------------

echo.
echo == Validation ==

terraform validate

if errorlevel 1 (
    echo.
    echo ERROR: terraform validate failed.
    popd
    exit /b 1
)

REM ------------------------------------------------------------
REM Final result
REM ------------------------------------------------------------

echo.
echo ========================================
echo  Terraform installation SUCCESS
echo ========================================
echo.

echo Terraform:
terraform version

echo.
echo Platform:
echo   %WINDOWS_PLATFORM%

echo.
echo Terraform directory:
cd

echo.
echo Provider dependency lock:
echo   .terraform.lock.hcl

echo.
echo Provider cache:
echo   .terraform\providers

echo.
echo Validation:
echo   SUCCESS

popd
exit /b 0


REM ------------------------------------------------------------
REM Refresh PATH from registry
REM ------------------------------------------------------------

:RefreshPath

set "NEW_SYSTEM_PATH="
set "NEW_USER_PATH="

for /f "tokens=2,*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul ^| findstr /I "Path"') do (
    set "NEW_SYSTEM_PATH=%%B"
)

for /f "tokens=2,*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul ^| findstr /I "Path"') do (
    set "NEW_USER_PATH=%%B"
)

if defined NEW_SYSTEM_PATH (
    set "PATH=!NEW_SYSTEM_PATH!;!NEW_USER_PATH!"
)

exit /b 0