# Power Electronics Control Library - Troubleshooting Guide

## Overview

Use this guide to diagnose and fix build/runtime issues in this project on Windows.

## **🔍 Quick Diagnosis**

Run this command first to identify the exact issues:
```powershell
powershell -ExecutionPolicy Bypass -File scripts\diagnostics\Check-Dependencies.ps1
```
Or in VS Code: run the "Check Dependencies" task.

## **🚨 Common Issues & Solutions**

### **1. Missing Dependencies**

#### **Problem**: Digital Mars Compiler (DMC) not found
```
❌ ERROR: Digital Mars Compiler (dmc) not found in PATH
```

**Solutions:**
- **Option A (Automatic)**: Run the setup script as Administrator:
   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts\setup\setup_compiler.ps1
   ```
- **Option B (VS Code Task)**: Run the "Setup Compiler" task in VS Code
- **Option C (Manual)**: Download from https://digitalmars.com/download/freecompiler.exe

#### **Problem**: Python not found
```
❌ ERROR: Python not found in PATH
```

**Solution**: Install Python 3.6+ from https://python.org and add to PATH

#### **Problem**: clang-format not found
```
❌ ERROR: clang-format not found in PATH
```

**Solution**: Install LLVM tools from https://releases.llvm.org/ or use Chocolatey:
```powershell
choco install llvm -y
```

### **2. Path and Environment Issues**

#### **Problem**: VS Code can't see newly installed tools
Even after installing DMC/LLVM, VS Code still reports "not found"

**Solutions:**
1. **Restart VS Code completely** (close all windows)
2. **Run VS Code as Administrator** (required for DMC installation)
3. **Refresh environment variables**:
   ```powershell
   $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
   ```

#### **Problem**: Path separator issues (Windows vs Linux/Mac)
Project config uses forward slashes but Windows needs backslashes

Note: `project_config.py` converts separators automatically. If you still see path issues, verify resolved paths:
```powershell
python scripts\config\project_config.py --summary
```

### **3. Project Configuration Issues**

#### **Problem**: JSON parsing errors
```
json.decoder.JSONDecodeError: Expecting value
```

Actions:
- Validate JSON and normalize formatting:
   ```powershell
   python scripts\config\project_config.py --summary
   ```
- If encoding issues are suspected, re-save as UTF-8 (no BOM) or run:
   ```powershell
   scripts\config\format_json.ps1
   ```
- Ensure optional fields (like sources/headers) aren’t null unless supported.
- Confirm required metadata fields exist in `config/project_config.json`.

#### **Problem**: Module files not found
```
❌ ERROR: Source file not found: modules/...
```

**Solutions:**
1. **Check project structure**:
   ```powershell
   Get-ChildItem modules -Recurse -Name "*.cpp"
   ```
2. **Verify config matches actual files**:
   ```powershell
   python scripts\config\project_config.py --source-files
   ```

### **4. File System and Permissions**

#### **Problem**: Permission denied errors
**Solution**: Run VS Code as Administrator

#### **Problem**: Case sensitivity issues (Git on Windows)
**Solution**: Configure Git properly:
```bash
git config --global core.ignorecase false
```

### **5. Working Directory Issues**

#### **Problem**: Scripts fail when run from different directories
**Solution**: Always run scripts from project root:
```powershell
# Correct
cd d:\Projects\WPT\last
scripts\build\build_all.bat

# Wrong
cd scripts
.\build_all.bat
```

## **🛠️ Quick Tasks in VS Code**
Use the Tasks panel for common troubleshooting:
1. "Check Dependencies" — validate environment and tools
2. "Project Cleanup" — clean build artifacts and refresh formatting
3. "Build All Modules" — rebuild after issues are resolved

## **🔧 Validation Commands**

Use these commands to verify your setup:

```powershell
# Check all dependencies
powershell -ExecutionPolicy Bypass -File scripts\diagnostics\Check-Dependencies.ps1

# Check dependencies only (no installation)
powershell -ExecutionPolicy Bypass -File scripts\setup\setup_compiler.ps1 -CheckOnly

# Full setup with options
powershell -ExecutionPolicy Bypass -File scripts\setup\setup_compiler.ps1           # Full setup
powershell -ExecutionPolicy Bypass -File scripts\setup\setup_compiler.ps1 -Force    # Force reinstall
powershell -ExecutionPolicy Bypass -File scripts\setup\setup_compiler.ps1 -SkipDMC  # Skip DMC installation
powershell -ExecutionPolicy Bypass -File scripts\setup\setup_compiler.ps1 -SkipLLVM # Skip LLVM installation

# Test project configuration
python scripts\config\project_config.py --summary

# List include paths
python scripts\config\project_config.py --include-paths

# List source files
python scripts\config\project_config.py --source-files

# Check if tools are in PATH
where python
where dmc
where clang-format

# Verify module files exist
Get-ChildItem modules -Recurse -Name "*.cpp"

# Optional: Clean up artifacts and re-run checks
scripts\maintenance\project_cleanup.bat
powershell -ExecutionPolicy Bypass -File scripts\diagnostics\Check-Dependencies.ps1

# Quick DLL smoke tests (after building)
analysis_modules\test_dlls.bat
python analysis_modules\power_electronics\common\minimal_dll_test.py
```

## **📋 Pre-Build Checklist**

Before building on a new laptop, verify:

- [ ] VS Code running as Administrator
- [ ] Python 3.6+ installed and in PATH
- [ ] Digital Mars Compiler (dmc) installed and in PATH  
- [ ] LLVM/Clang tools installed and in PATH
- [ ] Project config validation passes
- [ ] All module source files exist
- [ ] Working directory is project root

## **🆘 If All Else Fails**

1. **Clean reinstall**:
   ```powershell
   # Remove C:\dm directory
   # Uninstall Python and LLVM
   # Run scripts\setup\setup_compiler.ps1 again
   ```

2. **Manual path verification**:
   ```powershell
   # Check what's actually in PATH
   $env:PATH -split ';' | Sort-Object
   ```

3. **Alternative build method**:
   ```powershell
   # Direct compilation without build script
   cd build
   dmc -mn -w -wx -ws -I"..\modules\power_electronics\common" ..\modules\qspice_modules\ctrl\ctrl.cpp
   ```

 

## **🔗 Related Files**

- `scripts/diagnostics/Check-Dependencies.ps1` - Dependency validation
- `scripts/setup/setup_compiler.ps1` - Enhanced setup with dependency checking  
- `scripts/config/project_config.py` - Configuration parser  
- `config/project_config.json` - Project configuration
- `scripts/build/build_all.bat` - Main build script
