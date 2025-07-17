# Power Electronics Control Library - Troubleshooting Guide

## **Why Build Fails to Find Modules on Different Laptops**

This guide explains the common reasons why the build system might fail to find modules from project config on a different laptop and provides step-by-step solutions.

## **🔍 Quick Diagnosis**

Run this command first to identify the exact issues:
```powershell
powershell -ExecutionPolicy Bypass -File scripts\Check-Dependencies.ps1
```

## **🚨 Common Issues & Solutions**

### **1. Missing Dependencies**

#### **Problem**: Digital Mars Compiler (DMC) not found
```
❌ ERROR: Digital Mars Compiler (dmc) not found in PATH
```

**Solutions:**
- **Option A (Automatic)**: Run the setup script as Administrator:
  ```powershell
  powershell -ExecutionPolicy Bypass -File scripts\Setup-NewLaptop.ps1
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

**Solution**: ✅ **FIXED** - The `project_config.py` script now automatically converts path separators

### **3. Project Configuration Issues**

#### **Problem**: JSON parsing errors
```
json.decoder.JSONDecodeError: Expecting value
```

**Causes & Solutions:**
- **BOM encoding**: ✅ **FIXED** - Script now handles UTF-8 with/without BOM
- **Null values**: ✅ **FIXED** - Script now handles `null` sources/headers properly
- **Missing author field**: ✅ **FIXED** - Script now reads author from metadata

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
   python scripts\project_config.py --source-files
   ```

### **4. File System and Permissions**

#### **Problem**: Permission denied errors
**Solution**: Run VS Code as Administrator

#### **Problem**: Case sensitivity issues (Git on Windows)
**Solution**: Configure Git properly:
```bash
git config core.ignorecase false
```

### **5. Working Directory Issues**

#### **Problem**: Scripts fail when run from different directories
**Solution**: Always run scripts from project root:
```powershell
# Correct
cd d:\Projects\WPT\last
scripts\build_all.bat

# Wrong
cd scripts
.\build_all.bat
```

## **🛠️ Step-by-Step Setup for New Laptop**

### **Method 1: Automated Setup (Recommended)**
```powershell
# 1. Run VS Code as Administrator
# 2. Open project in VS Code
# 3. Check dependencies first
powershell scripts\setup_compiler.ps1 -CheckOnly

# 4. Run full setup if needed
powershell scripts\setup_compiler.ps1

# 5. Restart VS Code completely
# 6. Verify setup
powershell scripts\Check-Dependencies.ps1

# 7. Build project
scripts\build_all.bat
```

### **Method 2: Manual Setup**
```powershell
# 1. Install Python 3.6+ (add to PATH)
# 2. Install Digital Mars Compiler
# 3. Install LLVM/Clang tools
# 4. Restart VS Code as Administrator
# 5. Run dependency check
powershell scripts\Check-Dependencies.ps1
```

### **Method 3: VS Code Tasks**
1. Run "Setup Compiler" task (includes dependency check and full setup)
2. Restart VS Code completely
3. Run "Check Dependencies" task to verify
4. Run "Build All Modules" task

## **🔧 Validation Commands**

Use these commands to verify your setup:

```powershell
# Check all dependencies
powershell scripts\Check-Dependencies.ps1

# Check dependencies only (no installation)
powershell scripts\setup_compiler.ps1 -CheckOnly

# Full setup with options
powershell scripts\setup_compiler.ps1          # Full setup
powershell scripts\setup_compiler.ps1 -Force   # Force reinstall
powershell scripts\setup_compiler.ps1 -SkipDMC # Skip DMC installation
powershell scripts\setup_compiler.ps1 -SkipLLVM # Skip LLVM installation

# Test project configuration
python scripts\project_config.py --summary

# List include paths
python scripts\project_config.py --include-paths

# List source files
python scripts\project_config.py --source-files

# Check if tools are in PATH
where python
where dmc
where clang-format

# Verify module files exist
Get-ChildItem modules -Recurse -Name "*.cpp"
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
   # Run Setup-NewLaptop.ps1 again
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

## **💡 Prevention Tips**

- Always use the dependency checker before building
- Keep setup scripts updated for new team members
- Document any manual installation steps
- Use version control for configuration files
- Test setup process on clean virtual machines

## **🔗 Related Files**

- `scripts/Check-Dependencies.ps1` - Dependency validation
- `scripts/setup_compiler.ps1` - Enhanced setup with dependency checking  
- `scripts/project_config.py` - Configuration parser  
- `config/project_config.json` - Project configuration
- `scripts/build_all.bat` - Main build script
