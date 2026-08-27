@echo off
setlocal EnableExtensions

REM Purpose: Verify Terraform project configuration.
REM Usage:
REM   verify-terraform.bat
REM   verify-terraform.bat .\terraform

set "TERRAFORM_DIR=%~1"
if not defined TERRAFORM_DIR set "TERRAFORM_DIR=.\terraform"

echo Verifying Terraform in: %TERRAFORM_DIR%

where terraform >nul 2>&1
if errorlevel 1 (
    echo ERROR: terraform is not installed or not in PATH
    exit /b 1
)

if not exist "%TERRAFORM_DIR%\" (
    echo ERROR: Terraform directory does not exist: %TERRAFORM_DIR%
    exit /b 1
)

pushd "%TERRAFORM_DIR%"

if errorlevel 1 (
    echo ERROR: Cannot enter Terraform directory: %TERRAFORM_DIR%
    exit /b 1
)

echo.
echo == Terraform version ==

terraform version
if errorlevel 1 goto :error

echo.
echo == Formatting ==

terraform fmt -check -recursive
if errorlevel 1 goto :error

echo.
echo == Initialization ==

terraform init ^
    -backend=false ^
    -input=false ^
    -lockfile=readonly

if errorlevel 1 goto :error

echo.
echo == Validation ==

terraform validate
if errorlevel 1 goto :error

echo.
echo Terraform verification SUCCESS

popd
exit /b 0


:error

set "EXIT_CODE=%ERRORLEVEL%"

echo.
echo ERROR: Terraform verification failed.

popd
exit /b %EXIT_CODE%