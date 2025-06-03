@echo off
REM Build all .cpp files in the src directory into ctrl.dll using Digital Mars C++

REM Create and clean build directory
if not exist build mkdir build
del /q build\*.* 2>nul

REM Use delayed variable expansion
setlocal enabledelayedexpansion

REM Set output directories
set BUILD_DIR=build

REM Format all .cpp and .h files using clang-format
echo Formatting source files...
for /r "src" %%f in (*.cpp *.h) do (
    echo Formatting %%f
    clang-format -i -style=file:config/.clang-format "%%f"
)

REM Compile all .cpp files to .obj
cd %BUILD_DIR%
for /r "..\src\modules" %%f in (*.cpp) do (
    echo Compiling %%~nxf
    dmc -mn -c -I"..\src\modules\filters\iir" -I"..\src\modules\pwm" -I"..\src\modules\qspice_modules" "%%f"
)
cd ..

REM Link all .obj files into ctrl.dll
cd %BUILD_DIR%
copy /Y ..\src\modules\qspice_modules\ctrl.def . > nul
dmc -mn -WD ctrl.obj iir.obj pwm.obj kernel32.lib ctrl.def
cd ..

REM Copy the resulting DLL to the main directory
copy /Y %BUILD_DIR%\ctrl.dll . > nul

endlocal
