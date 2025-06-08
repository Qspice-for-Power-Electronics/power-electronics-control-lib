REM *************************** In The Name Of God ***************************
REM * @file    cleanup_code.bat
REM * @brief   Batch script for comprehensive code cleanup and quality improvements
REM * @author  Dr.-Ing. Hossein Abedini
REM * @date    2025-06-08
REM * Performs comprehensive code cleanup on all C++ source files including
REM * const correctness, formatting, include cleanup, and quality improvements.
REM * @note    Designed for real-time signal processing applications.
REM * @license This work is dedicated to the public domain under CC0 1.0.
REM *          Please use it for good and beneficial purposes!
REM ***************************************************************************

@echo off
REM ================================================================================
REM Power Electronics Control Library - Code Cleanup Script
REM ================================================================================
REM 
REM This script performs comprehensive code cleanup and quality improvements on all
REM C++ source files in the project, including const correctness, formatting,
REM include cleanup, and various code quality warnings.
REM
REM WHAT THIS SCRIPT DOES:
REM 1. Validates required tools (clang-format, clang-tidy)
REM 2. Ensures project is built (needed for static analysis)
REM 3. Applies const correctness fixes (adds const where appropriate)
REM 4. Formats all source code using clang-format
REM 5. Removes unnecessary #include statements
REM 6. Fixes modernization issues (C++11 improvements)
REM 7. Corrects performance issues (move semantics, etc.)
REM 8. Addresses readability and maintainability concerns
REM 9. Reports remaining warnings that require manual attention
REM
REM REQUIREMENTS:
REM - LLVM/Clang tools (clang-format, clang-tidy) in PATH
REM - Digital Mars Compiler (dmc) in PATH
REM - config/.clang-format file (formatting rules)
REM - config/.clang-tidy file (static analysis rules)
REM - Compiled project (build artifacts needed for analysis)
REM
REM OUTPUT:
REM - Modified source files with automatic fixes applied
REM - Detailed report of changes made and remaining issues
REM - Backup files (.bak) for all modified files
REM
REM USAGE:
REM   .\scripts\cleanup_code.bat
REM   .\scripts\cleanup_code.bat --dry-run    (preview changes only)
REM
REM ================================================================================

REM Enable delayed expansion for variables that change inside loops
setlocal enabledelayedexpansion

REM Initialize cleanup tracking and configuration
set ERROR_COUNT=0
set FILES_PROCESSED=0
set FILES_MODIFIED=0
set DRY_RUN=false

REM Check for dry-run mode
if "%1"=="--dry-run" (
    set DRY_RUN=true
    echo Running in DRY-RUN mode - no files will be modified
    echo.
)

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

REM Check if clang-tidy is available (used for static analysis and fixes)
where clang-tidy >nul 2>&1
if errorlevel 1 (
    echo Error: clang-tidy not found in PATH
    echo Please install LLVM/Clang and add to PATH
    exit /b 1
)

REM Check if Digital Mars Compiler is available (needed for project building)
where dmc >nul 2>&1
if errorlevel 1 (
    echo Error: Digital Mars Compiler ^(dmc^) not found in PATH
    echo Please install DMC and add to PATH
    exit /b 1
)

REM ================================================================================
REM STEP 2: Validate Project Structure and Configuration
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

REM Check for clang-tidy configuration file
if not exist config\.clang-tidy (
    echo Error: config\.clang-tidy not found
    echo This file defines static analysis rules
    exit /b 1
)

REM Count source files to process
set SOURCE_FILE_COUNT=0
for /r "modules" %%f in (*.cpp *.h) do (
    set /a SOURCE_FILE_COUNT+=1
)

if !SOURCE_FILE_COUNT! equ 0 (
    echo Error: No C++ source files found in modules directory
    exit /b 1
)

echo Found !SOURCE_FILE_COUNT! source files to process
echo.

REM ================================================================================
REM STEP 3: Ensure Project is Built (Required for Static Analysis)
REM ================================================================================

REM Check if project has been compiled (needed for include analysis)
if not exist build\*.obj (
    echo Project not built - building now for static analysis...
    call scripts\build_all.bat
    if errorlevel 1 (
        echo Error: Build failed. Cannot proceed with cleanup.
        echo Static analysis requires compiled project for accurate results.
        exit /b 1
    )
    echo.
)

REM ================================================================================
REM STEP 4: Create Backup Directory
REM ================================================================================

REM Create backup directory for original files (unless dry-run)
if "!DRY_RUN!"=="false" (
    if not exist backup (
        mkdir backup
    )
    REM Clean old backups (keep only current session)
    del /f /q backup\*.bak 2>nul
)

REM ================================================================================
REM STEP 5: Phase 1 - Const Correctness and Core Fixes
REM ================================================================================

echo ================================================================================
echo PHASE 1: Applying const correctness and core improvements...
echo ================================================================================

REM Set up clang-tidy flags for automatic fixes and include paths from config
set CLANG_INCLUDE_PATHS=
for /f "delims=" %%i in ('scripts\project_config.bat --clang-flags') do (
    set CLANG_INCLUDE_PATHS=!CLANG_INCLUDE_PATHS! %%i
)

if "!DRY_RUN!"=="true" (
    set TIDY_FLAGS=--format-style=file --quiet
) else (
    set TIDY_FLAGS=--format-style=file --fix --fix-errors --quiet
)

REM Define core improvement checks (const correctness, basic modernization)
set CORE_CHECKS=misc-const-correctness,cppcoreguidelines-const-correctness,modernize-use-nullptr,modernize-use-override,modernize-use-auto,performance-unnecessary-copy-initialization

REM Process each source file for core improvements
for /r "modules" %%f in (*.cpp *.h) do (
    set /a FILES_PROCESSED+=1
    echo [!FILES_PROCESSED!/!SOURCE_FILE_COUNT!] Processing %%~nxf for const correctness...
    
    if "!DRY_RUN!"=="false" (
        REM Create backup of original file
        copy /Y "%%f" "backup\%%~nxf.bak" >nul 2>&1
    )
      REM Apply core fixes with proper include paths
    clang-tidy !TIDY_FLAGS! --checks="!CORE_CHECKS!" "%%f" -- -std=c++11 !CLANG_INCLUDE_PATHS!
    if errorlevel 1 (
        echo Warning: Issues found in %%f during core cleanup
        set /a ERROR_COUNT+=1
    )
)

echo Phase 1 completed - Core improvements applied
echo.

REM ================================================================================
REM STEP 5.5: Phase 1.5 - Macro Parentheses Safety
REM ================================================================================

echo ================================================================================
echo PHASE 1.5: Adding macro parentheses for safety...
echo ================================================================================

REM Add parentheses around #define values for safer macro definitions
REM This prevents operator precedence issues in macro expansions
echo Adding parentheses to macro definitions...

if "!DRY_RUN!"=="true" (
    echo Running macro parentheses check in preview mode...
    powershell.exe -ExecutionPolicy Bypass -File "scripts\add_macro_parentheses.ps1" -DryRun
) else (
    echo Applying macro parentheses fixes...
    powershell.exe -ExecutionPolicy Bypass -File "scripts\add_macro_parentheses.ps1"
)

if errorlevel 1 (
    echo Warning: Issues found during macro parentheses processing
    set /a ERROR_COUNT+=1
)

echo Phase 1.5 completed - Macro parentheses applied
echo.

REM ================================================================================
REM STEP 6: Phase 2 - Code Formatting
REM ================================================================================

echo ================================================================================
echo PHASE 2: Applying code formatting...
echo ================================================================================

REM Apply consistent formatting to all source files
set FILES_FORMATTED=0
for /r "modules" %%f in (*.cpp *.h) do (
    set /a FILES_FORMATTED+=1
    echo [!FILES_FORMATTED!/!SOURCE_FILE_COUNT!] Formatting %%~nxf...
    
    if "!DRY_RUN!"=="false" (
        clang-format -i -style=file:config/.clang-format "%%f"
        if errorlevel 1 (
            echo Error formatting %%f
            set /a ERROR_COUNT+=1
        )
    ) else (
        REM In dry-run mode, just check formatting
        clang-format --dry-run -Werror -style=file:config/.clang-format "%%f" >nul 2>&1
        if errorlevel 1 (
            echo Would reformat: %%f
        )
    )
)

echo Phase 2 completed - Code formatting applied
echo.

REM ================================================================================
REM STEP 7: Phase 3 - Include Cleanup and Advanced Analysis
REM ================================================================================

echo ================================================================================
echo PHASE 3: Cleaning includes and advanced analysis...
echo ================================================================================

REM Define advanced cleanup checks (includes, performance, readability)
set ADVANCED_CHECKS=misc-include-cleaner,performance-*,readability-redundant-*,modernize-redundant-*,bugprone-*

REM Process files for advanced cleanup
set FILES_ANALYZED=0
for /r "modules" %%f in (*.cpp *.h) do (
    set /a FILES_ANALYZED+=1
    echo [!FILES_ANALYZED!/!SOURCE_FILE_COUNT!] Advanced analysis of %%~nxf...
      REM Apply advanced fixes with proper include paths
    clang-tidy !TIDY_FLAGS! --checks="!ADVANCED_CHECKS!" "%%f" -- -std=c++11 !CLANG_INCLUDE_PATHS!
    if errorlevel 1 (
        echo Warning: Advanced issues found in %%f
        set /a ERROR_COUNT+=1
    )
)

echo Phase 3 completed - Advanced cleanup applied
echo.

REM ================================================================================
REM STEP 8: Phase 4 - Final Quality Report
REM ================================================================================

echo ================================================================================
echo PHASE 4: Generating quality report...
echo ================================================================================

REM Run comprehensive analysis for remaining issues (report only)
echo Analyzing remaining code quality issues...
set REMAINING_ISSUES=0

for /r "modules" %%f in (*.cpp *.h) do (    REM Count remaining issues (don't fix, just report) with proper include paths
    clang-tidy --quiet --checks="-*,clang-diagnostic-*,clang-analyzer-*,cert-*,misc-*,readability-*,performance-*,bugprone-*,modernize-*,portability-*" "%%f" -- -std=c++11 !CLANG_INCLUDE_PATHS! 2>nul | find /c "warning:" >temp_count.txt
    set /p FILE_ISSUES=<temp_count.txt
    if !FILE_ISSUES! gtr 0 (
        echo   %%~nxf: !FILE_ISSUES! remaining issues
        set /a REMAINING_ISSUES+=!FILE_ISSUES!
    )
    del temp_count.txt 2>nul
)

REM ================================================================================
REM STEP 9: Summary and Results
REM ================================================================================

echo.
echo ================================================================================
echo CLEANUP SUMMARY
echo ================================================================================

if "!DRY_RUN!"=="true" (
    echo DRY-RUN MODE - No files were actually modified
    echo To apply changes, run: .\scripts\cleanup_code.bat
) else (
    echo Files processed: !FILES_PROCESSED!
    echo Backup files created in: backup\
)

echo.
echo QUALITY METRICS:
echo - Total source files: !SOURCE_FILE_COUNT!
echo - Files with remaining issues: Files requiring manual review
echo - Remaining warnings: !REMAINING_ISSUES!

if !ERROR_COUNT! gtr 0 (
    echo.
    echo WARNING: !ERROR_COUNT! files had issues during cleanup
    echo Please review the output above for specific problems
)

if "!DRY_RUN!"=="false" (
    echo.
    echo NEXT STEPS:
    echo 1. Review changed files: git diff
    echo 2. Test build: .\build_all.bat
    echo 3. Commit changes: git add . ^&^& git commit -m "Apply automatic code cleanup"
    echo.
    echo NOTE: If issues occur, restore from backup: copy backup\*.bak modules\
)

REM Exit with error count (0 = success, >0 = issues found)
exit /b !ERROR_COUNT!
