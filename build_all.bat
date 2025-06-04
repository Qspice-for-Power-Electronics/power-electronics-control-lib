@echo off
REM Build all .cpp files in the src directory into ctrl.dll using Digital Mars C++

REM Enable delayed expansion for !variables!
setlocal enabledelayedexpansion

REM Set error counter and build directory
set ERROR_COUNT=0
set BUILD_DIR=build

REM Check for required tools
where clang-format >nul 2>&1
if errorlevel 1 (
    echo Error: clang-format not found in PATH
    exit /b 1
)

where dmc >nul 2>&1
if errorlevel 1 (
    echo Error: Digital Mars Compiler ^(dmc^) not found in PATH
    exit /b 1
)

REM Check for required files and directories
if not exist src\modules (
    echo Error: src\modules directory not found
    exit /b 1
)

if not exist config\.clang-format (
    echo Error: config\.clang-format not found
    exit /b 1
)

if not exist src\modules\qspice_modules\ctrl.def (
    echo Error: ctrl.def not found
    exit /b 1
)

REM Create and clean build directory
if not exist %BUILD_DIR% mkdir %BUILD_DIR%
del /q %BUILD_DIR%\*.* 2>nul

REM Save current directory
pushd %CD%

REM Format all .cpp and .h files using clang-format
echo Formatting source files...
for /r "src\modules" %%f in (*.cpp *.h) do (
    echo Formatting %%f
    clang-format -i -style=file:config/.clang-format "%%f"
    if errorlevel 1 (
        echo Error formatting %%f
        set /a ERROR_COUNT+=1
    )
)

REM Find all module directories for include paths
set INCLUDE_PATHS=
for /d /r "src\modules" %%d in (*) do (
    if exist "%%d\*.h" set INCLUDE_PATHS=!INCLUDE_PATHS! -I"%%~dpnxd"
)

REM Compile all .cpp files to .obj
cd %BUILD_DIR%
set OBJ_FILES=
for /r "..\src\modules" %%f in (*.cpp) do (
    echo Compiling %%~nxf
    dmc -mn -c !INCLUDE_PATHS! "%%f"
    if errorlevel 1 (
        echo Error compiling %%f
        set /a ERROR_COUNT+=1
    ) else (
        set OBJ_FILES=!OBJ_FILES! %%~nf.obj
    )
)

REM Check if any object files were created
if "!OBJ_FILES!"=="" (
    echo Error: No object files were created
    set /a ERROR_COUNT+=1
)

REM Only proceed with linking if we have object files and no errors
if !ERROR_COUNT! equ 0 (
    REM Link all .obj files into ctrl.dll
    copy /Y ..\src\modules\qspice_modules\ctrl.def . > nul
    echo Linking DLL...
    link !OBJ_FILES!,ctrl.dll,nul,kernel32+user32,ctrl/noi;
    if errorlevel 1 (
        echo Error during linking
        set /a ERROR_COUNT+=1
    )
)

REM Return to original directory
popd

REM Copy the resulting DLL only if build succeeded
if !ERROR_COUNT! equ 0 (
    if exist %BUILD_DIR%\ctrl.dll (
        copy /Y %BUILD_DIR%\ctrl.dll . > nul
        echo Build completed successfully
    ) else (
        echo Error: DLL not created
        set /a ERROR_COUNT+=1
    )
) else (
    echo Build failed with !ERROR_COUNT! errors
)

exit /b !ERROR_COUNT!
