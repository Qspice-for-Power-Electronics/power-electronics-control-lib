REM *************************** In The Name Of God ***************************
REM * @file    setup_compiler.bat
REM * @brief   Batch wrapper for Digital Mars Compiler setup
REM * @author  Dr.-Ing. Hossein Abedini
REM * @date    2025-06-08
REM * Simple batch wrapper to run the PowerShell compiler setup script for
REM * users who prefer batch file execution.
REM * @note    Designed for real-time signal processing applications.
REM * @license This work is dedicated to the public domain under CC0 1.0.
REM *          Please use it for good and beneficial purposes!
REM ***************************************************************************

@echo off
REM ================================================================================
REM Power Electronics Control Library - Digital Mars Compiler Setup (Batch Wrapper)
REM ================================================================================
REM 
REM This script provides a simple Windows batch wrapper for the PowerShell-based
REM Digital Mars Compiler setup script, making it accessible to users who prefer
REM batch file execution or have PowerShell execution policy restrictions.
REM
REM WHAT THIS SCRIPT DOES:
REM 1. Validates PowerShell availability on the system
REM 2. Executes the PowerShell setup script with appropriate execution policy
REM 3. Provides user-friendly error messages and status reporting
REM 4. Handles script execution policy bypassing for automation
REM
REM REQUIREMENTS:
REM - Windows operating system with PowerShell available
REM - Internet connection for downloading compiler (if needed)
REM - Write permissions to project directory
REM - setup_compiler.ps1 PowerShell script in same directory
REM
REM OUTPUT:
REM - Configured Digital Mars Compiler in project compiler/ directory
REM - Status messages indicating setup progress and results
REM - Error messages if setup fails with troubleshooting guidance
REM
REM USAGE:
REM   .\setup_compiler.bat                    # Standard setup
REM   .\setup_compiler.bat                    # (All options passed to PowerShell script)
REM
REM ================================================================================

echo.
echo ====================================================
echo   Digital Mars Compiler Setup for QSPICE
echo ====================================================
echo.

REM ================================================================================
REM STEP 1: Validate System Requirements
REM ================================================================================

REM Check if PowerShell is available for script execution
where powershell >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: PowerShell is required but not found in PATH
    echo Please ensure PowerShell is installed and try again.
    echo.
    echo PowerShell is included with Windows 7 SP1 and later.
    echo For older systems, download from: https://microsoft.com/powershell
    pause
    exit /b 1
)

REM Run the PowerShell setup script
echo Running PowerShell setup script...
echo.

powershell.exe -ExecutionPolicy Bypass -File "%~dp0setup_compiler.ps1" %*

REM Check result
if %errorlevel% equ 0 (
    echo.
    echo ====================================================
    echo   Setup completed successfully!
    echo ====================================================
    echo.
    echo You can now use the "Build All Modules" task in VS Code
    echo or run scripts\build_all.bat to compile your modules.
    echo.
) else (
    echo.
    echo ====================================================
    echo   Setup failed with error code %errorlevel%
    echo ====================================================
    echo.
    echo Please check the error messages above and try again.
    echo.
)

if "%1"=="" pause
