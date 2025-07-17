@echo off
REM *************************** In The Name Of God ***************************
REM @file    test_dlls.bat
REM @brief   Simple launcher for minimal DLL test
REM @author  Analysis Team
REM @date    2025-06-26
REM @license This work is dedicated to the public domain under CC0 1.0.
REM **************************************************************************

echo *************************** In The Name Of God ***************************
echo DLL TEST
echo **************************************************************************

cd /d "%~dp0"

echo Available tests:
echo 1. Basic DLL Test (quick verification)
echo 2. IIR Filter Test (step response, Bode plots)
echo.
set /p choice="Enter your choice (1-2): "

REM Try 32-bit Python first
set PYTHON32=%USERPROFILE%\AppData\Local\Programs\Python\Python313-32\python.exe

if "%choice%"=="2" (
    echo Running IIR Filter Test with Plots...
    if exist "%PYTHON32%" (
        "%PYTHON32%" power_electronics\filters\iir\iir_dll_test.py
    ) else (
        echo 32-bit Python not found. Trying default Python...
        python power_electronics\filters\iir\iir_dll_test.py
    )
) else (
    echo Running Basic DLL Test...
    if exist "%PYTHON32%" (
        "%PYTHON32%" power_electronics\common\minimal_dll_test.py
    ) else (
        echo 32-bit Python not found. Trying default Python...
        python power_electronics\common\minimal_dll_test.py
    )
)
