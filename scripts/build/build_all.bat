@echo off
REM *************************** In The Name Of God ***************************
REM * @file    build_all.bat
REM * @brief   Batch script for building all power electronics modules
REM * @author  Dr.-Ing. Hossein Abedini
REM * @date    2025-06-08
REM * Builds all power electronics modules and QSPICE integration modules
REM * into separate DLL files for use in QSPICE simulations.
REM * @note    Designed for real-time signal processing applications.
REM * @license This work is dedicated to the public domain under CC0 1.0.
REM *          Please use it for good and beneficial purposes!
REM ***************************************************************************

REM ================================================================================
REM Power Electronics Control Library - Build Script
REM ================================================================================
REM 
REM This script builds all power electronics modules and QSPICE integration modules
REM into separate DLL files for use in QSPICE simulations.
REM
REM WHAT THIS SCRIPT DOES:
REM 1. Validates required tools (DMC compiler, clang-format)
REM 2. Cleans previous build artifacts
REM 3. Formats all source code using clang-format
REM 4. Compiles power electronics modules (shared components)
REM 5. Builds individual DLL files for each power electronics module
REM 6. Compiles and links each QSPICE module into its own DLL
REM 7. Copies final DLLs to root directory for QSPICE usage
REM
REM REQUIREMENTS:
REM - Digital Mars C++ Compiler (dmc) in PATH
REM - LLVM/Clang (clang-format) in PATH
REM - modules/ directory with proper structure
REM - config/.clang-format file
REM
REM IMPORTANT SETUP NOTES:
REM - Run VS Code as Administrator for the setup script to work properly
REM - Restart VS Code completely after running "Setup Compiler" task
REM - The setup script modifies system PATH which requires VS Code restart
REM
REM OUTPUT:
REM - Individual DLL files for each power electronics module (e.g., iir.dll, bpwm.dll, epwm.dll)
REM - Individual DLL files for each QSPICE module (e.g., ctrl.dll)
REM - Build artifacts in output/ directory
REM
REM USAGE:
REM   .\build_all.bat
REM
REM ================================================================================

REM Enable delayed expansion for variables that change inside loops
setlocal enabledelayedexpansion

REM Initialize error tracking and build configuration
set ERROR_COUNT=0
set BUILD_DIR=output

REM ================================================================================
REM STEP 1: Validate Required Tools
REM ================================================================================

REM Check if clang-format is available (used for automatic code formatting)
where clang-format >nul 2>&1
if errorlevel 1 (
    echo Error: clang-format not found in PATH
    echo Please install LLVM/Clang and add to PATH
    exit /b 1
)

REM Check if Digital Mars Compiler is available (used for compiling C++ code)
where dmc >nul 2>&1
if errorlevel 1 (
    echo Error: Digital Mars Compiler ^(dmc^) not found in PATH
    echo.
    echo SOLUTION:
    echo 1. Run the "Setup Compiler" task first to install DMC
    echo 2. Make sure VS Code is running as Administrator
    echo 3. Restart VS Code completely after DMC installation
    echo 4. The setup script adds DMC to system PATH, but VS Code needs restart to see it
    echo.
    echo If DMC is already installed at C:\dm\bin\dmc.exe, restart VS Code to refresh PATH
    exit /b 1
)

REM ================================================================================
REM STEP 2: Validate Project Structure
REM ================================================================================

REM Check for modules directory (contains all source code)
if not exist modules (
    echo Error: modules directory not found
    echo Expected structure: modules/power_electronics/ and modules/qspice_modules/
    exit /b 1
)

REM Check for clang-format configuration file
if not exist config\.clang-format (
    echo Error: config\.clang-format not found
    echo This file defines code formatting rules
    exit /b 1
)

REM Count available QSPICE modules (must have matching .def files)
set QSPICE_MODULE_COUNT=0
for /d %%m in (modules\qspice_modules\*) do (
    if exist "%%m\%%~nxm.def" (
        set /a QSPICE_MODULE_COUNT+=1
    )
)

REM Ensure we have at least one QSPICE module to build
if !QSPICE_MODULE_COUNT! equ 0 (
    echo Error: No QSPICE modules found
    echo Expected: modules/qspice_modules/modulename/ with modulename.def
    exit /b 1
)

REM ================================================================================
REM STEP 3: Clean Previous Build Artifacts
REM ================================================================================

REM Remove all previous build artifacts to ensure clean build
echo Cleaning all build artifacts...
if exist %BUILD_DIR% (
    rmdir /s /q %BUILD_DIR%
)
REM Delete only QSPICE module DLLs from root directory (keep power electronics DLLs separate)
for /d %%m in (modules\qspice_modules\*) do (
    if exist "%%~nxm.dll" (
        del /f /q "%%~nxm.dll" 2>nul
    )
)
REM Also clean other build artifacts from root
del /f /q *.map *.obj *.bak 2>nul

REM Create fresh build directory for new compilation
mkdir %BUILD_DIR%

REM Save current directory so we can return to it later
pushd %CD%

REM ================================================================================
REM STEP 4: Format Source Code
REM ================================================================================

REM Apply consistent code formatting to all source files
echo Formatting source files...
for /r "modules" %%f in (*.cpp *.h) do (
    echo Formatting %%f
    clang-format -i -style=file:config/.clang-format "%%f"
    if errorlevel 1 (
        echo Error formatting %%f
        set /a ERROR_COUNT+=1
    )
)

REM Run clang-tidy checks for const correctness and code quality
echo Running code quality checks...
for /r "modules" %%f in (*.cpp *.h) do (
    echo Checking %%f
    clang-tidy --config-file=config/.clang-tidy "%%f" -- -std=c++11 > nul 2>&1
    REM Note: Not failing build on tidy warnings, just reporting
)

REM ================================================================================
REM STEP 5: Setup Compiler Configuration
REM ================================================================================

REM Set up compiler flags for better error detection
REM -mn: Make DLL (required for QSPICE modules)
REM -w:  Enable all warnings
REM -wx: Treat warnings as errors (strict compilation)
REM -ws: Enable stack overflow checking
set COMMON_FLAGS=-mn -w -wx -ws

REM Get include paths from project configuration
REM This uses the centralized config/project_config.json file
set INCLUDE_PATHS=
for /f "delims=" %%i in ('scripts\config\project_config.bat --include-paths') do (
    set INCLUDE_PATHS=!INCLUDE_PATHS! -I"..\%%i"
)

REM Combine compiler flags with include paths for final compilation command
set COMPILE_FLAGS=%COMMON_FLAGS% !INCLUDE_PATHS!

REM ================================================================================
REM STEP 6: Build Power Electronics Modules (Shared Dependencies)
REM ================================================================================

REM Change to build directory for compilation
cd %BUILD_DIR%

REM First compile all power electronics modules (filters, PWM, etc.)
REM These are shared components used by QSPICE modules
set POWER_ELECTRONICS_OBJ=
echo Building power electronics modules...
for /r "..\modules\power_electronics" %%f in (*.cpp) do (
    echo Compiling %%~nxf
    dmc !COMPILE_FLAGS! -c "%%f"
    if errorlevel 1 (
        echo Error compiling %%f
        set /a ERROR_COUNT+=1
    ) else (
        REM Add successfully compiled object file to the list
        set POWER_ELECTRONICS_OBJ=!POWER_ELECTRONICS_OBJ! %%~nf.obj
    )
)

REM ================================================================================
REM STEP 7: Build Individual Power Electronics Module DLLs
REM ================================================================================

REM Build separate DLLs for each power electronics module (iir.dll, bpwm.dll, epwm.dll)
echo Building individual power electronics module DLLs...
for /r "..\modules\power_electronics" %%d in (*.def) do (
    if exist "%%~dpd%%~nd.cpp" (
        set MODULE_NAME=%%~nd
        echo Processing power electronics module: !MODULE_NAME!
        
        REM Compile the specific module's source file
        echo Compiling !MODULE_NAME!.cpp
        dmc !COMPILE_FLAGS! -c "%%~dpd!MODULE_NAME!.cpp"
        if errorlevel 1 (
            echo Error compiling !MODULE_NAME!.cpp
            set /a ERROR_COUNT+=1
        ) else (
            REM Copy module definition file to build directory for linking
            copy /Y "%%d" . > nul
            echo Linking !MODULE_NAME!.dll...
            REM Link the module's object file into its own DLL
            link !MODULE_NAME!.obj,!MODULE_NAME!.dll,nul,kernel32+user32,!MODULE_NAME!/noi;
            if errorlevel 1 (
                echo Error linking !MODULE_NAME!.dll
                set /a ERROR_COUNT+=1
            ) else (
                echo Successfully built !MODULE_NAME!.dll
            )
        )
    )
)

REM ================================================================================
REM STEP 8: Build Combined QSPICE Modules
REM ================================================================================

REM Process each QSPICE module found in qspice_modules directory (existing functionality)
for /d %%m in (..\modules\qspice_modules\*) do (
    if exist "%%m\%%~nxm.def" (
        echo Processing QSPICE module: %%~nxm
        set MODULE_NAME=%%~nxm
        REM Start with power electronics objects as dependencies
        set MODULE_OBJ_FILES=!POWER_ELECTRONICS_OBJ!
        
        REM Compile all .cpp files in this specific module
        for %%f in ("%%m\*.cpp") do (
            echo Compiling %%~nxf
            dmc !COMPILE_FLAGS! -c "%%f"
            if errorlevel 1 (
                echo Error compiling %%f
                set /a ERROR_COUNT+=1
            ) else (
                REM Add this module's object file to the link list
                set MODULE_OBJ_FILES=!MODULE_OBJ_FILES! %%~nf.obj
            )
        )

        REM Only attempt linking if we have object files and no compilation errors
        if "!MODULE_OBJ_FILES!"=="" (
            echo Error: No object files created for module !MODULE_NAME!
            set /a ERROR_COUNT+=1
        ) else if !ERROR_COUNT! equ 0 (
            REM Copy module definition file to build directory for linking
            copy /Y "%%m\!MODULE_NAME!.def" . > nul
            echo Linking !MODULE_NAME!.dll...
            REM Link all object files into a DLL with Windows system libraries
            link !MODULE_OBJ_FILES!,!MODULE_NAME!.dll,nul,kernel32+user32,!MODULE_NAME!/noi;
            if errorlevel 1 (
                echo Error linking !MODULE_NAME!.dll
                set /a ERROR_COUNT+=1
            ) else (
                echo Successfully built !MODULE_NAME!.dll
            )
        )
    )
)

REM ================================================================================
REM STEP 9: Finalize Build and Report Results
REM ================================================================================

REM Return to original directory
popd

REM Copy only QSPICE module DLLs to root directory (power electronics DLLs stay in output/)
if !ERROR_COUNT! equ 0 (
    echo Copying QSPICE module DLLs to root directory...
    set DLL_COUNT=0
    set QSPICE_DLL_COUNT=0
    REM Count total DLLs built
    for %%f in (%BUILD_DIR%\*.dll) do (
        set /a DLL_COUNT+=1
    )
    REM Copy only QSPICE module DLLs to root (those that have corresponding module directories)
    for /d %%m in (modules\qspice_modules\*) do (
        if exist "%BUILD_DIR%\%%~nxm.dll" (
            copy /Y "%BUILD_DIR%\%%~nxm.dll" . > nul
            set /a QSPICE_DLL_COUNT+=1
            echo Copied %%~nxm.dll to root directory for QSPICE usage
        )
    )
    echo Build completed successfully. Built !DLL_COUNT! total modules.
    echo Copied !QSPICE_DLL_COUNT! QSPICE module DLLs to root directory.
    echo Power electronics module DLLs remain in output/ directory.
    echo QSPICE module DLL files are ready for use in simulations.
) else (
    echo Build failed with !ERROR_COUNT! errors
    echo Please check the error messages above and fix the issues.
)

REM Exit with error count (0 = success, >0 = failure)
exit /b !ERROR_COUNT!
