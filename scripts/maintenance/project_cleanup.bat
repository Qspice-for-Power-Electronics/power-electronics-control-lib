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

REM ================================================================================
REM STEP 0: Setup Logging
REM ================================================================================

REM Remove existing logs folder and create fresh one
if exist logs (
    rmdir /s /q logs
)
mkdir logs

REM Create timestamped log file
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "YY=%dt:~2,2%" & set "YYYY=%dt:~0,4%" & set "MM=%dt:~4,2%" & set "DD=%dt:~6,2%"
set "HH=%dt:~8,2%" & set "Min=%dt:~10,2%" & set "Sec=%dt:~12,2%"
set "datestamp=%YYYY%-%MM%-%DD%_%HH%-%Min%-%Sec%"
set "LOG_FILE=logs\project_cleanup_%datestamp%.log"

REM Initialize cleanup tracking and configuration
set ERROR_COUNT=0
set FILES_PROCESSED=0
set FILES_MODIFIED=0
set DRY_RUN=false

REM Check for dry-run mode
if "%1"=="--dry-run" (
    set DRY_RUN=true
    call :log "Running in DRY-RUN mode - no files will be modified"
    call :log ""
)

REM Create a function to log both to console and file
call :log "Starting project cleanup at %datestamp%"
call :log "Log file: %LOG_FILE%"
call :log ""

goto :main

:log
if "%~1"=="" (
    echo.
    echo. >> "%LOG_FILE%"
) else (
    echo %~1
    echo %~1 >> "%LOG_FILE%"
)
goto :eof

:main

REM ================================================================================
REM STEP 1: Validate Required Tools
REM ================================================================================

call :log "================================================================================"
call :log "STEP 1: Validating required tools..."
call :log "================================================================================"

REM Check if clang-format is available (used for automatic code formatting)
where clang-format >nul 2>&1
if errorlevel 1 (
    call :log "Error: clang-format not found in PATH"
    call :log "Please install LLVM/Clang and add to PATH"
    exit /b 1
)
call :log "✓ clang-format found"

REM Check if clang-tidy is available (used for static analysis and fixes)
where clang-tidy >nul 2>&1
if errorlevel 1 (
    call :log "Error: clang-tidy not found in PATH"
    call :log "Please install LLVM/Clang and add to PATH"
    exit /b 1
)
call :log "✓ clang-tidy found"

REM Check if Digital Mars Compiler is available (needed for project building)
where dmc >nul 2>&1
if errorlevel 1 (
    call :log "Error: Digital Mars Compiler (dmc) not found in PATH"
    call :log "Please install DMC and add to PATH"
    exit /b 1
)
call :log "✓ Digital Mars Compiler found"

REM ================================================================================
REM STEP 2: Validate Project Structure and Configuration
REM ================================================================================

REM Check for modules directory (contains all source code)
if not exist modules (
    call :log "Error: modules directory not found"
    call :log "Expected structure: modules/power_electronics/ and modules/qspice_modules/"
    exit /b 1
)

REM Check for clang-format configuration file
if not exist config\.clang-format (
    call :log "Error: config\.clang-format not found"
    call :log "This file defines code formatting rules"
    exit /b 1
)

REM Check for clang-tidy configuration file
if not exist config\.clang-tidy (
    call :log "Error: config\.clang-tidy not found"
    call :log "This file defines static analysis rules"
    exit /b 1
)

REM Count source files to process
set SOURCE_FILE_COUNT=0
for /r "modules" %%f in (*.cpp *.h) do (
    set /a SOURCE_FILE_COUNT+=1
)

if !SOURCE_FILE_COUNT! equ 0 (
    call :log "Error: No C++ source files found in modules directory"
    exit /b 1
)

call :log "Found !SOURCE_FILE_COUNT! source files to process"
call :log ""

REM ================================================================================
REM STEP 3: Ensure Project is Built (Required for Static Analysis)
REM ================================================================================

REM Check if project has been compiled (needed for include analysis)
if not exist output\*.obj (
    call :log "Project not built - building now for static analysis..."
    call scripts\build\build_all.bat
    if errorlevel 1 (
        call :log "Error: Build failed. Cannot proceed with cleanup."
        call :log "Static analysis requires compiled project for accurate results."
        exit /b 1
    )
    call :log ""
)

REM ================================================================================
REM STEP 4: Phase 1 - Macro Parentheses Safety
REM ================================================================================

call :log "================================================================================"
call :log "PHASE 1: Adding macro parentheses for safety..."
call :log "================================================================================"

REM Add parentheses around #define values for safer macro definitions
REM This prevents operator precedence issues in macro expansions
call :log "Adding parentheses to macro definitions..."

if "!DRY_RUN!"=="true" (
    call :log "Running macro parentheses check in preview mode..."
    powershell.exe -ExecutionPolicy Bypass -File "scripts\maintenance\add_macro_parentheses.ps1" -DryRun
) else (
    call :log "Applying macro parentheses fixes..."
    powershell.exe -ExecutionPolicy Bypass -File "scripts\maintenance\add_macro_parentheses.ps1"
)

if errorlevel 1 (
    call :log "Warning: Issues found during macro parentheses processing"
    set /a ERROR_COUNT+=1
)

call :log "Phase 1 completed - Macro parentheses applied"
call :log ""

REM ================================================================================
REM STEP 5: Phase 2 - Include Cleanup
REM ================================================================================

call :log "================================================================================"
call :log "PHASE 2: Cleaning unnecessary includes..."
call :log "================================================================================"

REM Set up clang-tidy flags for automatic fixes and include paths from config
set CLANG_INCLUDE_PATHS=
for /f "delims=" %%i in ('scripts\config\project_config.bat --clang-flags') do (
    set CLANG_INCLUDE_PATHS=!CLANG_INCLUDE_PATHS! %%i
)

REM Add Digital Mars Compiler include paths for clang-tidy compatibility
if exist "compiler\include" (
    set CLANG_INCLUDE_PATHS=!CLANG_INCLUDE_PATHS! -I"compiler\include"
)
REM Also add system include paths that clang-tidy might need
set CLANG_INCLUDE_PATHS=!CLANG_INCLUDE_PATHS! -isystem compiler\include

if "!DRY_RUN!"=="true" (
    set TIDY_FLAGS=--format-style=file
) else (
    set TIDY_FLAGS=--format-style=file --fix --fix-errors
)

REM Define include cleanup checks to remove unnecessary headers
set INCLUDE_CLEANUP_CHECKS=misc-include-cleaner,readability-redundant-preprocessor

REM Process files for include cleanup
set FILES_INCLUDE_CLEANED=0
for /r "modules" %%f in (*.cpp *.h) do (
    set /a FILES_INCLUDE_CLEANED+=1
    call :log "[!FILES_INCLUDE_CLEANED!/!SOURCE_FILE_COUNT!] Cleaning includes in %%~nxf..."
    
    REM Force C++ mode for all files to avoid language detection issues
    REM Use -x c++ to explicitly tell clang-tidy to treat the file as C++
    set LANG_FLAGS=-x c++ -std=c++11
    if /i "%%~xf"==".c" set LANG_FLAGS=-x c -std=c99
    
    REM Apply include cleanup with proper include paths and explicit language mode
    clang-tidy !TIDY_FLAGS! --checks="!INCLUDE_CLEANUP_CHECKS!" "%%f" -- !LANG_FLAGS! !CLANG_INCLUDE_PATHS! >temp_clang_output.txt 2>&1
    if errorlevel 1 (
        call :log "Warning: Include cleanup issues found in %%f"
        call :log "--- Detailed Error Output ---"
        for /f "usebackq delims=" %%l in ("temp_clang_output.txt") do (
            call :log "  %%l"
        )
        call :log "--- End Error Output ---"
        set /a ERROR_COUNT+=1
    )
    del temp_clang_output.txt 2>nul
)

call :log "Phase 2 completed - Include cleanup applied"
call :log ""

REM ================================================================================
REM STEP 6: Phase 3 - Update Module Dependencies
REM ================================================================================

call :log "================================================================================"
call :log "PHASE 3: Updating module dependencies automatically..."
call :log "================================================================================"

REM Scan #include statements and update dependencies in project_config.json
REM This ensures build order is correct based on actual code dependencies
REM Run AFTER include cleanup to get accurate dependency information
call :log "Scanning source files for #include dependencies..."

if "!DRY_RUN!"=="true" (
    call :log "Running dependency update in preview mode..."
    powershell.exe -ExecutionPolicy Bypass -File "scripts\maintenance\update_dependencies.ps1" -DryRun
) else (
    call :log "Updating module dependencies..."
    powershell.exe -ExecutionPolicy Bypass -File "scripts\maintenance\update_dependencies.ps1"
)

if errorlevel 1 (
    call :log "Warning: Issues found during dependency update"
    set /a ERROR_COUNT+=1
)

call :log "Phase 3 completed - Dependencies updated"
call :log ""

REM ================================================================================
REM STEP 7: Phase 4 - Const Correctness and Core Fixes
REM ================================================================================

call :log "================================================================================"
call :log "PHASE 4: Applying const correctness and core improvements..."
call :log "================================================================================"
REM Define core improvement checks (const correctness, selective modernization)
REM Exclude modernize-use-using to preserve typedef struct syntax for C compatibility
REM Exclude modernize-use-auto to preserve explicit type declarations
set CORE_CHECKS=misc-const-correctness,cppcoreguidelines-const-correctness,modernize-use-nullptr,modernize-use-override,performance-unnecessary-copy-initialization

REM Process each source file for core improvements
for /r "modules" %%f in (*.cpp *.h) do (
    set /a FILES_PROCESSED+=1
    call :log "[!FILES_PROCESSED!/!SOURCE_FILE_COUNT!] Processing %%~nxf for const correctness..."
    
    REM Force C++ mode for all files to avoid language detection issues
    REM Use -x c++ to explicitly tell clang-tidy to treat the file as C++
    set LANG_FLAGS=-x c++ -std=c++11
    if /i "%%~xf"==".c" set LANG_FLAGS=-x c -std=c99
    
    REM Apply core fixes with proper include paths and explicit language mode
    clang-tidy !TIDY_FLAGS! --checks="!CORE_CHECKS!" "%%f" -- !LANG_FLAGS! !CLANG_INCLUDE_PATHS! >temp_clang_output.txt 2>&1
    if errorlevel 1 (
        call :log "Warning: Issues found in %%f during core cleanup"
        call :log "--- Detailed Error Output ---"
        for /f "usebackq delims=" %%l in ("temp_clang_output.txt") do (
            call :log "  %%l"
        )
        call :log "--- End Error Output ---"
        set /a ERROR_COUNT+=1
    )
    del temp_clang_output.txt 2>nul
)

call :log "Phase 4 completed - Core improvements applied"
call :log ""

REM ================================================================================
REM STEP 8: Phase 5 - Modernization and Performance Fixes
REM ================================================================================

call :log "================================================================================"
call :log "PHASE 5: Applying modernization and performance improvements..."
call :log "================================================================================"

REM Define modernization and performance checks (excluding typedef and trailing return types)
REM Exclude modernize-use-using to keep traditional typedef struct syntax
REM Exclude modernize-use-trailing-return-type to keep traditional function syntax
REM Exclude modernize-deprecated-headers to preserve C-style headers like math.h
REM Exclude modernize-use-auto to preserve explicit type declarations
set MODERNIZATION_CHECKS=modernize-*,-modernize-use-using,-modernize-use-trailing-return-type,-modernize-deprecated-headers,-modernize-use-auto,performance-*

REM Process files for modernization and performance improvements
set FILES_MODERNIZED=0
for /r "modules" %%f in (*.cpp *.h) do (
    set /a FILES_MODERNIZED+=1
    call :log "[!FILES_MODERNIZED!/!SOURCE_FILE_COUNT!] Modernizing %%~nxf..."
    
    REM Force C++ mode for all files to avoid language detection issues
    REM Use -x c++ to explicitly tell clang-tidy to treat the file as C++
    set LANG_FLAGS=-x c++ -std=c++11
    if /i "%%~xf"==".c" set LANG_FLAGS=-x c -std=c99
    
    REM Apply modernization fixes with proper include paths and explicit language mode
    clang-tidy !TIDY_FLAGS! --checks="!MODERNIZATION_CHECKS!" "%%f" -- !LANG_FLAGS! !CLANG_INCLUDE_PATHS! >temp_clang_output.txt 2>&1
    if errorlevel 1 (
        call :log "Warning: Modernization issues found in %%f"
        call :log "--- Detailed Error Output ---"
        for /f "usebackq delims=" %%l in ("temp_clang_output.txt") do (
            call :log "  %%l"
        )
        call :log "--- End Error Output ---"
        set /a ERROR_COUNT+=1
    )
    del temp_clang_output.txt 2>nul
)

call :log "Phase 5 completed - Modernization and performance improvements applied"
call :log ""

REM ================================================================================
REM STEP 9: Phase 6 - Readability and Maintainability
REM ================================================================================

call :log "================================================================================"
call :log "PHASE 6: Applying readability and maintainability improvements..."
call :log "================================================================================"

REM Define readability and maintainability checks (preserve const qualifiers and C-style)
REM Focus on readability without forcing modern C++ style conversions
REM Exclude readability-avoid-const-params-in-decls to keep const qualifiers on parameters
set READABILITY_CHECKS=readability-*,-readability-identifier-naming,-readability-avoid-const-params-in-decls,bugprone-*

REM Process files for readability improvements
set FILES_READABILITY=0
for /r "modules" %%f in (*.cpp *.h) do (
    set /a FILES_READABILITY+=1
    call :log "[!FILES_READABILITY!/!SOURCE_FILE_COUNT!] Improving readability of %%~nxf..."
    
    REM Force C++ mode for all files to avoid language detection issues
    REM Use -x c++ to explicitly tell clang-tidy to treat the file as C++
    set LANG_FLAGS=-x c++ -std=c++11
    if /i "%%~xf"==".c" set LANG_FLAGS=-x c -std=c99
    
    REM Apply readability fixes with proper include paths and explicit language mode
    clang-tidy !TIDY_FLAGS! --checks="!READABILITY_CHECKS!" "%%f" -- !LANG_FLAGS! !CLANG_INCLUDE_PATHS! >temp_clang_output.txt 2>&1
    if errorlevel 1 (
        call :log "Warning: Readability issues found in %%f"
        call :log "--- Detailed Error Output ---"
        for /f "usebackq delims=" %%l in ("temp_clang_output.txt") do (
            call :log "  %%l"
        )
        call :log "--- End Error Output ---"
        set /a ERROR_COUNT+=1
    )
    del temp_clang_output.txt 2>nul
)

call :log "Phase 6 completed - Readability improvements applied"
call :log ""

REM ================================================================================
REM STEP 10: Phase 7 - Source Code Formatting
REM ================================================================================

call :log "================================================================================"
call :log "PHASE 7: Applying source code formatting..."
call :log "================================================================================"

REM Apply consistent formatting to all source files
set FILES_FORMATTED=0
for /r "modules" %%f in (*.cpp *.h) do (
    set /a FILES_FORMATTED+=1
    call :log "[!FILES_FORMATTED!/!SOURCE_FILE_COUNT!] Formatting %%~nxf..."
    
    if "!DRY_RUN!"=="false" (
        clang-format -i -style=file:config/.clang-format "%%f"
        if errorlevel 1 (
            call :log "Error formatting %%f"
            set /a ERROR_COUNT+=1
        )
    ) else (
        REM In dry-run mode, just check formatting
        clang-format --dry-run -Werror -style=file:config/.clang-format "%%f" >nul 2>&1
        if errorlevel 1 (
            call :log "Would reformat: %%f"
        )
    )
)

call :log "Phase 7 completed - Source code formatting applied"
call :log ""

REM ================================================================================
REM STEP 11: Phase 8 - JSON File Formatting
REM ================================================================================

call :log "================================================================================"
call :log "PHASE 8: Formatting JSON configuration files..."
call :log "================================================================================"

REM Apply consistent formatting to all JSON files in the project
call :log "Formatting JSON configuration files..."

if "!DRY_RUN!"=="true" (
    call :log "Running JSON formatting in preview mode..."
    powershell.exe -ExecutionPolicy Bypass -File "scripts\config\format_json.ps1" -DryRun 2>&1 > temp_json_output.txt
    for /f "delims=" %%i in (temp_json_output.txt) do call :log "  %%i"
    del temp_json_output.txt 2>nul
) else (
    call :log "Applying JSON formatting..."
    powershell.exe -ExecutionPolicy Bypass -File "scripts\config\format_json.ps1" 2>&1 > temp_json_output.txt
    for /f "delims=" %%i in (temp_json_output.txt) do call :log "  %%i"
    del temp_json_output.txt 2>nul
)

if errorlevel 1 (
    call :log "Warning: Issues found during JSON formatting"
    call :log "Check the logged output above for specific error details"
    set /a ERROR_COUNT+=1
) else (
    call :log "JSON formatting completed successfully"
)

call :log "Phase 8 completed - JSON formatting applied"
call :log ""

REM ================================================================================
REM STEP 12: Phase 9 - Final Quality Report
REM ================================================================================

call :log "================================================================================"
call :log "PHASE 9: Generating quality report..."
call :log "================================================================================"

REM Run comprehensive analysis for remaining issues (report only)
call :log "Analyzing remaining code quality issues..."
set REMAINING_ISSUES=0

for /r "modules" %%f in (*.cpp *.h) do (
    REM Force C++ mode for all files to avoid language detection issues
    REM Use -x c++ to explicitly tell clang-tidy to treat the file as C++
    set LANG_FLAGS=-x c++ -std=c++11
    if /i "%%~xf"==".c" set LANG_FLAGS=-x c -std=c99
    
    REM Count remaining issues (don't fix, just report) with proper include paths and explicit language mode
    clang-tidy --checks="-*,clang-diagnostic-*,clang-analyzer-*,cert-*,misc-*,readability-*,performance-*,bugprone-*,modernize-*,portability-*" "%%f" -- !LANG_FLAGS! !CLANG_INCLUDE_PATHS! >temp_issues.txt 2>&1
    
    REM Count warnings in the output
    find /c "warning:" temp_issues.txt >temp_count.txt 2>nul
    set /p FILE_ISSUES=<temp_count.txt
    if !FILE_ISSUES! gtr 0 (
        call :log "  %%~nxf: !FILE_ISSUES! remaining issues"
        call :log "    --- Issue Details ---"
        for /f "usebackq delims=" %%l in ("temp_issues.txt") do (
            echo %%l | find "warning:" >nul && call :log "    %%l"
            echo %%l | find "error:" >nul && call :log "    %%l"
        )
        call :log "    --- End Issue Details ---"
        set /a REMAINING_ISSUES+=!FILE_ISSUES!
    )
    del temp_count.txt 2>nul
    del temp_issues.txt 2>nul
)

call :log "Phase 9 completed - Quality report generated"
call :log ""

REM ================================================================================
REM STEP 13: Summary and Results
REM ================================================================================

call :log ""
call :log "================================================================================"
call :log "CLEANUP SUMMARY"
call :log "================================================================================"

if "!DRY_RUN!"=="true" (
    call :log "DRY-RUN MODE - No files were actually modified"
    call :log "To apply changes, run: .\scripts\project_cleanup.bat"
) else (
    call :log "Files processed: !FILES_PROCESSED!"
)

call :log ""
call :log "QUALITY METRICS:"
call :log "- Total source files !SOURCE_FILE_COUNT!"
call :log "- Files requiring manual review !ERROR_COUNT!"
call :log "- Remaining warnings !REMAINING_ISSUES!"

if !ERROR_COUNT! gtr 0 (
    call :log ""
    call :log "WARNING: !ERROR_COUNT! files had issues during cleanup"
    call :log "Please review the output above for specific problems"
)

if "!DRY_RUN!"=="false" (
    call :log ""
    call :log "NEXT STEPS:"
    call :log "1 Review changed files - git diff"
    call :log "2 Test build - PowerShell - scripts\build_all.bat"
    call :log "   Or use VS Code task Ctrl+Shift+P -> Tasks: Run Task -> Build All Modules"
    call :log "3 Commit changes - git add . and git commit"
)

call :log ""
call :log "LOGGING:"
call :log "- Complete log saved to %LOG_FILE%"
call :log "- Log folder excluded from git tracking"

REM ================================================================================
REM STEP 14: Clean Build Artifacts
REM ================================================================================

call :log ""
call :log "================================================================================"
call :log "STEP 14: Cleaning build artifacts..."
call :log "================================================================================"

REM Remove all build artifacts and temporary files after processing is complete
call :log "Cleaning all build artifacts and temporary files..."
if exist output (
    rmdir /s /q output
    call :log "Removed output directory"
)

REM Delete only QSPICE module DLLs from root directory (keep power electronics DLLs in output/)
for /d %%m in (modules\qspice_modules\*) do (
    if exist "%%~nxm.dll" (
        del /f /q "%%~nxm.dll" 2>nul
    )
)
REM Also clean other build artifacts from root
del /f /q *.map *.obj *.bak 2>nul
if errorlevel 0 (
    call :log "Removed QSPICE module DLLs and build artifacts from root directory"
)

call :log "Build artifacts cleaned successfully"

REM Exit with error count (0 = success, >0 = issues found)
exit /b !ERROR_COUNT!
