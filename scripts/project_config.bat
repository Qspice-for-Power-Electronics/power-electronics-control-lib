@echo off
REM *************************** In The Name Of God ***************************
REM * @file    project_config.bat
REM * @brief   Batch wrapper for project configuration management
REM * @author  Dr.-Ing. Hossein Abedini
REM * @date    2025-06-08
REM * Windows batch wrapper around the Python configuration parser for easy
REM * access to project configuration data.
REM * @note    Designed for real-time signal processing applications.
REM * @license This work is dedicated to the public domain under CC0 1.0.
REM *          Please use it for good and beneficial purposes!
REM ***************************************************************************

@echo off
REM ================================================================================
REM Project Configuration Helper for Power Electronics Control Library
REM ================================================================================
REM 
REM This script provides easy access to project configuration data stored in
REM config/project_config.json. It acts as a Windows batch wrapper around the
REM Python configuration parser.
REM
REM WHAT THIS SCRIPT DOES:
REM 1. Validates Python availability
REM 2. Calls the Python configuration parser with specified options
REM 3. Returns configuration data for use in other batch scripts
REM
REM USAGE:
REM   .\scripts\project_config.bat --include-paths     (get include paths)
REM   .\scripts\project_config.bat --source-files      (get source files)
REM   .\scripts\project_config.bat --compiler-flags    (get compiler flags)
REM   .\scripts\project_config.bat --clang-flags       (get clang-tidy flags)
REM   .\scripts\project_config.bat --summary           (show project summary)
REM
REM EXAMPLES:
REM   REM Get include paths for compiler
REM   for /f %%i in ('scripts\project_config.bat --include-paths') do set INCLUDE_PATH=%%i
REM   
REM   REM Get all source files for processing
REM   for /f %%f in ('scripts\project_config.bat --source-files') do echo Processing %%f
REM
REM ================================================================================

setlocal enabledelayedexpansion

REM Check if Python is available
where python >nul 2>&1
if errorlevel 1 (
    echo Error: Python not found in PATH
    echo Please install Python 3.x and add to PATH
    echo The project configuration system requires Python for JSON parsing
    exit /b 1
)

REM Check if configuration file exists
if not exist "config\project_config.json" (
    echo Error: Project configuration file not found
    echo Expected: config\project_config.json
    echo Please ensure the configuration file exists
    exit /b 1
)

REM Check if Python parser exists
if not exist "scripts\project_config.py" (
    echo Error: Project configuration parser not found
    echo Expected: scripts\project_config.py
    echo Please ensure the parser script exists
    exit /b 1
)

REM Call Python parser with all arguments
python scripts\project_config.py %*
exit /b %errorlevel%
