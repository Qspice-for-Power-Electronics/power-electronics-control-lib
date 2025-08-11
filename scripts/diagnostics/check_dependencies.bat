@echo off
REM *************************** In The Name Of God ***************************
REM * @file    check_dependencies.bat
REM * @brief   Check all required dependencies for building the project
REM * @author  Dr.-Ing. Hossein Abedini
REM * @date    2025-07-13
REM * Validates that all required tools and dependencies are available
REM * before attempting to build the project.
REM ***************************************************************************

echo ================================================================================
echo Dependency Checker for Power Electronics Control Library
echo ================================================================================
echo.

set ERROR_COUNT=0

REM Check Python
echo [1/6] Checking Python...
where python >nul 2>&1
if errorlevel 1 (
    echo ❌ ERROR: Python not found in PATH
    set /a ERROR_COUNT+=1
) else (
    echo ✅ Found: Python
)

REM Check Digital Mars Compiler
echo.
echo [2/6] Checking Digital Mars Compiler...
where dmc >nul 2>&1
if errorlevel 1 (
    echo ❌ ERROR: Digital Mars Compiler (dmc) not found in PATH
    echo    Solution: Run the "Setup Compiler" task or manually install DMC
    set /a ERROR_COUNT+=1
) else (
    echo ✅ Found: Digital Mars Compiler
)

REM Check clang-format
echo.
echo [3/6] Checking clang-format...
where clang-format >nul 2>&1
if errorlevel 1 (
    echo ❌ ERROR: clang-format not found in PATH
    echo    Solution: Install LLVM/Clang tools and add to PATH
    set /a ERROR_COUNT+=1
) else (
    echo ✅ Found: clang-format
)

REM Check project structure
echo.
echo [4/6] Checking project structure...
if not exist "config\project_config.json" (
    echo ❌ ERROR: config\project_config.json not found
    set /a ERROR_COUNT+=1
) else (
    echo ✅ Found: config\project_config.json
)

if not exist "modules\power_electronics" (
    echo ❌ ERROR: modules\power_electronics directory not found
    set /a ERROR_COUNT+=1
) else (
    echo ✅ Found: modules\power_electronics
)

if not exist "modules\qspice_modules" (
    echo ❌ ERROR: modules\qspice_modules directory not found
    set /a ERROR_COUNT+=1
) else (
    echo ✅ Found: modules\qspice_modules
)

REM Check project configuration
echo.
echo [5/6] Checking project configuration...
python scripts\config\project_config.py --summary >nul 2>&1
if errorlevel 1 (
    echo ❌ ERROR: Project configuration validation failed
    echo    Try running: python scripts\config\project_config.py --summary
    set /a ERROR_COUNT+=1
) else (
    echo ✅ Project configuration is valid
)

REM Check source files
echo.
echo [6/6] Checking source files...
set SOURCE_COUNT=0
for /f "delims=" %%f in ('python scripts\config\project_config.py --source-files 2^>nul') do (
    if exist "%%f" (
        set /a SOURCE_COUNT+=1
    ) else (
        echo ❌ ERROR: Source file not found: %%f
        set /a ERROR_COUNT+=1
    )
)
echo ✅ Found %SOURCE_COUNT% source files

echo.
echo ================================================================================
if %ERROR_COUNT% equ 0 (
    echo ✅ ALL DEPENDENCIES SATISFIED - Ready to build!
    echo    You can now run: scripts\build_all.bat
) else (
    echo ❌ FOUND %ERROR_COUNT% ISSUES - Please fix before building
    echo.
    echo COMMON SOLUTIONS:
    echo 1. Run VS Code as Administrator
    echo 2. Run "Setup Compiler" task to install DMC
    echo 3. Restart VS Code after installing tools
    echo 4. Check that PATH includes Python and LLVM tools
)
echo ================================================================================

exit /b %ERROR_COUNT%
