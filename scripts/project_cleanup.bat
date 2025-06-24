@echo off
REM *************************** In The Name Of God ***************************
REM * @file    project_cleanup.bat
REM * @brief   Batch script for comprehensive project cleanup and quality improvements
REM * @author  Dr.-Ing. Hossein Abedini
REM * @date    2025-06-08
REM * Performs comprehensive project cleanup on all C++ source files including
REM * build artifact cleanup, const correctness, formatting, include cleanup, and quality improvements.
REM * @note    Designed for real-time signal processing applications.
REM * @license This work is dedicated to the public domain under CC0 1.0.
REM *          Please use it for good and beneficial purposes!
REM ***************************************************************************

REM ================================================================================
REM Power Electronics Control Library - Project Cleanup Script
REM ================================================================================
REM 
REM This script performs comprehensive project cleanup and quality improvements on all
REM C++ source files in the project, including build artifact cleanup, const correctness, formatting,
REM include cleanup, and various code quality warnings.
REM
REM WHAT THIS SCRIPT DOES (OPTIMIZED ORDER):
REM 1. Validates required tools (clang-format, clang-tidy)
REM 2. Ensures project is built (needed for static analysis)
REM 3. Adds parentheses around #define values for safer macro definitions
REM 4. Removes unnecessary #include statements (do early to reduce dependencies)
REM 5. Updates module dependencies automatically by scanning #include statements
REM 6. Applies const correctness fixes (adds const where appropriate)
REM 7. Fixes modernization issues (C++11 improvements)
REM 8. Corrects performance issues (move semantics, etc.)
REM 9. Addresses readability and maintainability concerns
REM 10. Formats all source code using clang-format (after all content changes)
REM 11. Formats JSON configuration files for consistency
REM 12. Reports remaining warnings that require manual attention
REM 13. Cleans all build artifacts and temporary files
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
REM
REM USAGE:
REM   .\scripts\project_cleanup.bat
REM   .\scripts\project_cleanup.bat --dry-run    (preview changes only)
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
REM STEP 4: Phase 1 - Macro Parentheses Safety
REM ================================================================================

echo ================================================================================
echo PHASE 1: Adding macro parentheses for safety...
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

echo Phase 1 completed - Macro parentheses applied
echo.

REM ================================================================================
REM STEP 5: Phase 2 - Include Cleanup
REM ================================================================================

echo ================================================================================
echo PHASE 2: Cleaning unnecessary includes...
echo ================================================================================

REM Set up clang-tidy flags for automatic fixes and include paths from config
set CLANG_INCLUDE_PATHS=
for /f "delims=" %%i in ('scripts\project_config.bat --clang-flags') do (
    set CLANG_INCLUDE_PATHS=!CLANG_INCLUDE_PATHS! %%i
)

REM Add Digital Mars Compiler include paths for clang-tidy compatibility
if exist "compiler\include" (
    set CLANG_INCLUDE_PATHS=!CLANG_INCLUDE_PATHS! -I"compiler\include"
)
REM Also add system include paths that clang-tidy might need
set CLANG_INCLUDE_PATHS=!CLANG_INCLUDE_PATHS! -isystem compiler\include

if "!DRY_RUN!"=="true" (
    set TIDY_FLAGS=--format-style=file --quiet
) else (
    set TIDY_FLAGS=--format-style=file --fix --fix-errors --quiet
)

REM Define include cleanup checks to remove unnecessary headers
set INCLUDE_CLEANUP_CHECKS=misc-include-cleaner,readability-redundant-preprocessor

REM Process files for include cleanup
set FILES_INCLUDE_CLEANED=0
for /r "modules" %%f in (*.cpp *.h) do (
    set /a FILES_INCLUDE_CLEANED+=1
    echo [!FILES_INCLUDE_CLEANED!/!SOURCE_FILE_COUNT!] Cleaning includes in %%~nxf...
    
    REM Force C++ mode for all files to avoid language detection issues
    REM Use -x c++ to explicitly tell clang-tidy to treat the file as C++
    set LANG_FLAGS=-x c++ -std=c++11
    if /i "%%~xf"==".c" set LANG_FLAGS=-x c -std=c99
    
    REM Apply include cleanup with proper include paths and explicit language mode
    clang-tidy !TIDY_FLAGS! --checks="!INCLUDE_CLEANUP_CHECKS!" "%%f" -- !LANG_FLAGS! !CLANG_INCLUDE_PATHS!
    if errorlevel 1 (
        echo Warning: Include cleanup issues found in %%f
        set /a ERROR_COUNT+=1
    )
)

echo Phase 2 completed - Include cleanup applied
echo.

REM ================================================================================
REM STEP 6: Phase 3 - Update Module Dependencies
REM ================================================================================

echo ================================================================================
echo PHASE 3: Updating module dependencies automatically...
echo ================================================================================

REM Scan #include statements and update dependencies in project_config.json
REM This ensures build order is correct based on actual code dependencies
REM Run AFTER include cleanup to get accurate dependency information
echo Scanning source files for #include dependencies...

if "!DRY_RUN!"=="true" (
    echo Running dependency update in preview mode...
    powershell.exe -ExecutionPolicy Bypass -File "scripts\update_dependencies.ps1" -DryRun
) else (
    echo Updating module dependencies...
    powershell.exe -ExecutionPolicy Bypass -File "scripts\update_dependencies.ps1"
)

if errorlevel 1 (
    echo Warning: Issues found during dependency update
    set /a ERROR_COUNT+=1
)

echo Phase 3 completed - Dependencies updated
echo.

REM ================================================================================
REM STEP 7: Phase 4 - Const Correctness and Core Fixes
REM ================================================================================

echo ================================================================================
echo PHASE 4: Applying const correctness and core improvements...
echo ================================================================================
REM Define core improvement checks (const correctness, selective modernization)
REM Exclude modernize-use-using to preserve typedef struct syntax for C compatibility
set CORE_CHECKS=misc-const-correctness,cppcoreguidelines-const-correctness,modernize-use-nullptr,modernize-use-override,modernize-use-auto,performance-unnecessary-copy-initialization

REM Process each source file for core improvements
for /r "modules" %%f in (*.cpp *.h) do (
    set /a FILES_PROCESSED+=1
    echo [!FILES_PROCESSED!/!SOURCE_FILE_COUNT!] Processing %%~nxf for const correctness...
    
    REM Force C++ mode for all files to avoid language detection issues
    REM Use -x c++ to explicitly tell clang-tidy to treat the file as C++
    set LANG_FLAGS=-x c++ -std=c++11
    if /i "%%~xf"==".c" set LANG_FLAGS=-x c -std=c99
    
    REM Apply core fixes with proper include paths and explicit language mode
    clang-tidy !TIDY_FLAGS! --checks="!CORE_CHECKS!" "%%f" -- !LANG_FLAGS! !CLANG_INCLUDE_PATHS!
    if errorlevel 1 (
        echo Warning: Issues found in %%f during core cleanup
        set /a ERROR_COUNT+=1
    )
)

echo Phase 4 completed - Core improvements applied
echo.

REM ================================================================================
REM STEP 8: Phase 5 - Modernization and Performance Fixes
REM ================================================================================

echo ================================================================================
echo PHASE 5: Applying modernization and performance improvements...
echo ================================================================================

REM Define modernization and performance checks (excluding typedef and trailing return types)
REM Exclude modernize-use-using to keep traditional typedef struct syntax
REM Exclude modernize-use-trailing-return-type to keep traditional function syntax
set MODERNIZATION_CHECKS=modernize-*,-modernize-use-using,-modernize-use-trailing-return-type,performance-*

REM Process files for modernization and performance improvements
set FILES_MODERNIZED=0
for /r "modules" %%f in (*.cpp *.h) do (
    set /a FILES_MODERNIZED+=1
    echo [!FILES_MODERNIZED!/!SOURCE_FILE_COUNT!] Modernizing %%~nxf...
    
    REM Force C++ mode for all files to avoid language detection issues
    REM Use -x c++ to explicitly tell clang-tidy to treat the file as C++
    set LANG_FLAGS=-x c++ -std=c++11
    if /i "%%~xf"==".c" set LANG_FLAGS=-x c -std=c99
    
    REM Apply modernization fixes with proper include paths and explicit language mode
    clang-tidy !TIDY_FLAGS! --checks="!MODERNIZATION_CHECKS!" "%%f" -- !LANG_FLAGS! !CLANG_INCLUDE_PATHS!
    if errorlevel 1 (
        echo Warning: Modernization issues found in %%f
        set /a ERROR_COUNT+=1
    )
)

echo Phase 5 completed - Modernization and performance improvements applied
echo.

REM ================================================================================
REM STEP 9: Phase 6 - Readability and Maintainability
REM ================================================================================

echo ================================================================================
echo PHASE 6: Applying readability and maintainability improvements...
echo ================================================================================

REM Define readability and maintainability checks (preserve const qualifiers and C-style)
REM Focus on readability without forcing modern C++ style conversions
REM Exclude readability-avoid-const-params-in-decls to keep const qualifiers on parameters
set READABILITY_CHECKS=readability-*,-readability-identifier-naming,-readability-avoid-const-params-in-decls,bugprone-*

REM Process files for readability improvements
set FILES_READABILITY=0
for /r "modules" %%f in (*.cpp *.h) do (
    set /a FILES_READABILITY+=1
    echo [!FILES_READABILITY!/!SOURCE_FILE_COUNT!] Improving readability of %%~nxf...
    
    REM Force C++ mode for all files to avoid language detection issues
    REM Use -x c++ to explicitly tell clang-tidy to treat the file as C++
    set LANG_FLAGS=-x c++ -std=c++11
    if /i "%%~xf"==".c" set LANG_FLAGS=-x c -std=c99
    
    REM Apply readability fixes with proper include paths and explicit language mode
    clang-tidy !TIDY_FLAGS! --checks="!READABILITY_CHECKS!" "%%f" -- !LANG_FLAGS! !CLANG_INCLUDE_PATHS!
    if errorlevel 1 (
        echo Warning: Readability issues found in %%f
        set /a ERROR_COUNT+=1
    )
)

echo Phase 6 completed - Readability improvements applied
echo.

REM ================================================================================
REM STEP 10: Phase 7 - Source Code Formatting
REM ================================================================================

echo ================================================================================
echo PHASE 7: Applying source code formatting...
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

echo Phase 7 completed - Source code formatting applied
echo.

REM ================================================================================
REM STEP 11: Phase 8 - JSON File Formatting
REM ================================================================================

echo ================================================================================
echo PHASE 8: Formatting JSON configuration files...
echo ================================================================================

REM Apply consistent formatting to all JSON files in the project
echo Formatting JSON configuration files...

if "!DRY_RUN!"=="true" (
    echo Running JSON formatting in preview mode...
    powershell.exe -ExecutionPolicy Bypass -File "scripts\format_json.ps1" -DryRun
) else (
    echo Applying JSON formatting...
    powershell.exe -ExecutionPolicy Bypass -File "scripts\format_json.ps1"
)

if errorlevel 1 (
    echo Warning: Issues found during JSON formatting
    set /a ERROR_COUNT+=1
) else (
    echo JSON formatting completed successfully
)

echo Phase 8 completed - JSON formatting applied
echo.

REM ================================================================================
REM STEP 12: Phase 9 - Final Quality Report
REM ================================================================================

echo ================================================================================
echo PHASE 9: Generating quality report...
echo ================================================================================

REM Run comprehensive analysis for remaining issues (report only)
echo Analyzing remaining code quality issues...
set REMAINING_ISSUES=0

for /r "modules" %%f in (*.cpp *.h) do (
    REM Force C++ mode for all files to avoid language detection issues
    REM Use -x c++ to explicitly tell clang-tidy to treat the file as C++
    set LANG_FLAGS=-x c++ -std=c++11
    if /i "%%~xf"==".c" set LANG_FLAGS=-x c -std=c99
    
    REM Count remaining issues (don't fix, just report) with proper include paths and explicit language mode
    clang-tidy --quiet --checks="-*,clang-diagnostic-*,clang-analyzer-*,cert-*,misc-*,readability-*,performance-*,bugprone-*,modernize-*,portability-*" "%%f" -- !LANG_FLAGS! !CLANG_INCLUDE_PATHS! 2>nul | find /c "warning:" >temp_count.txt
    set /p FILE_ISSUES=<temp_count.txt
    if !FILE_ISSUES! gtr 0 (
        echo   %%~nxf: !FILE_ISSUES! remaining issues
        set /a REMAINING_ISSUES+=!FILE_ISSUES!
    )
    del temp_count.txt 2>nul
echo Phase 9 completed - Quality report generated
echo.

REM ================================================================================
REM STEP 13: Summary and Results
REM ================================================================================

echo.
echo ================================================================================
echo CLEANUP SUMMARY
echo ================================================================================

if "!DRY_RUN!"=="true" (
    echo DRY-RUN MODE - No files were actually modified
    echo To apply changes, run: .\scripts\project_cleanup.bat
) else (
    echo Files processed: !FILES_PROCESSED!
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
    echo 2. Test build: .\build_all.bat    echo 3. Commit changes: git add . ^&^& git commit -m "Apply automatic code cleanup"
)

REM ================================================================================
REM STEP 14: Clean Build Artifacts
REM ================================================================================

echo.
echo ================================================================================
echo STEP 14: Cleaning build artifacts...
echo ================================================================================

REM Remove all build artifacts and temporary files after processing is complete
echo Cleaning all build artifacts and temporary files...
if exist build (
    rmdir /s /q build
    echo Removed build directory
)

REM Delete DLLs, map files, object files, and backup files from root directory
del /f /q *.dll *.map *.obj *.bak 2>nul
if errorlevel 0 (
    echo Removed build artifacts from root directory
)

echo Build artifacts cleaned successfully

REM Exit with error count (0 = success, >0 = issues found)
exit /b !ERROR_COUNT!
