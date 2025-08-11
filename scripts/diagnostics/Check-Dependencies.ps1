# *************************** In The Name Of God ***************************
# * @file    Check-Dependencies.ps1
# * @brief   PowerShell script to check all required dependencies
# * @author  Dr.-Ing. Hossein Abedini
# * @date    2025-07-13
# * Validates that all required tools and dependencies are available
# ***************************************************************************

function Refresh-EnvironmentPath {
    param([switch]$Quiet)
    
    try {
        # Get the current PATH from both Machine and User environment variables
        $MachinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
        $UserPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
        
        # Combine them (Machine + User)
        $NewPath = $MachinePath + ";" + $UserPath
        
        # Update the current session's PATH
        $env:PATH = $NewPath
        
        if (-not $Quiet) {
            Write-Host "[INFO] Environment PATH refreshed from system variables" -ForegroundColor Green
        }
        
        return $true
    }
    catch {
        Write-Host "[ERROR] Failed to refresh environment PATH: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "Dependency Checker for Power Electronics Control Library" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""

# Refresh PATH from system environment variables first
Write-Host "Refreshing environment PATH..." -ForegroundColor Yellow
Refresh-EnvironmentPath -Quiet

$ErrorCount = 0

# Check Git
Write-Host "[1/7] Checking Git..." -ForegroundColor Yellow
try {
    $gitVersion = git --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Found: $gitVersion" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Git not found in PATH" -ForegroundColor Red
        Write-Host "   Solution: winget install --id Git.Git -e --source winget" -ForegroundColor Yellow
        $ErrorCount++
    }
} catch {
    Write-Host "[ERROR] Git not found in PATH" -ForegroundColor Red
    $ErrorCount++
}

# Check Python
Write-Host ""
Write-Host "[2/7] Checking Python..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Found: $pythonVersion" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Python not found in PATH" -ForegroundColor Red
        Write-Host "   Solution: winget install -e --id Python.Python.3.11" -ForegroundColor Yellow
        $ErrorCount++
    }
} catch {
    Write-Host "[ERROR] Python not found in PATH" -ForegroundColor Red
    $ErrorCount++
}

# Check Digital Mars Compiler
Write-Host ""
Write-Host "[3/7] Checking Digital Mars Compiler..." -ForegroundColor Yellow
try {
    $dmcPath = Get-Command dmc -ErrorAction SilentlyContinue
    if ($dmcPath) {
        Write-Host "[OK] Found: Digital Mars Compiler at $($dmcPath.Source)" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Digital Mars Compiler (dmc) not found in PATH" -ForegroundColor Red
        Write-Host "   Solution: Run the 'Setup Compiler' task or manually install DMC" -ForegroundColor Yellow
        Write-Host "   Expected location: C:\dm\bin\dmc.exe" -ForegroundColor Yellow
        $ErrorCount++
    }
} catch {
    Write-Host "[ERROR] Digital Mars Compiler not found" -ForegroundColor Red
    $ErrorCount++
}

# Check clang-format
Write-Host ""
Write-Host "[4/7] Checking clang-format..." -ForegroundColor Yellow
try {
    $clangFormatVersion = clang-format --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Found: clang-format" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] clang-format not found in PATH" -ForegroundColor Red
        Write-Host "   Solution: Install LLVM/Clang tools and add to PATH" -ForegroundColor Yellow
        $ErrorCount++
    }
} catch {
    Write-Host "[ERROR] clang-format not found in PATH" -ForegroundColor Red
    $ErrorCount++
}

# Check project structure
Write-Host ""
Write-Host "[5/7] Checking project structure..." -ForegroundColor Yellow

if (Test-Path "config\project_config.json") {
    Write-Host "[OK] Found: config\project_config.json" -ForegroundColor Green
} else {
    Write-Host "[ERROR] config\project_config.json not found" -ForegroundColor Red
    $ErrorCount++
}

if (Test-Path "modules\power_electronics") {
    Write-Host "[OK] Found: modules\power_electronics" -ForegroundColor Green
} else {
    Write-Host "[ERROR] modules\power_electronics directory not found" -ForegroundColor Red
    $ErrorCount++
}

if (Test-Path "modules\qspice_modules") {
    Write-Host "[OK] Found: modules\qspice_modules" -ForegroundColor Green
} else {
    Write-Host "[ERROR] modules\qspice_modules directory not found" -ForegroundColor Red
    $ErrorCount++
}

# Check project configuration
Write-Host ""
Write-Host "[6/7] Checking project configuration..." -ForegroundColor Yellow
try {
    $configTest = python scripts\config\project_config.py --summary 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Project configuration is valid" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Project configuration validation failed" -ForegroundColor Red
        Write-Host "   Try running: python scripts\config\project_config.py --summary" -ForegroundColor Yellow
        $ErrorCount++
    }
} catch {
    Write-Host "[ERROR] Cannot validate project configuration" -ForegroundColor Red
    $ErrorCount++
}

# Check source files
Write-Host ""
Write-Host "[7/7] Checking source files..." -ForegroundColor Yellow
try {
    $sourceFiles = python scripts\config\project_config.py --source-files 2>&1
    if ($LASTEXITCODE -eq 0) {
        $sourceCount = 0
        $sourceFiles -split "`n" | ForEach-Object {
            $file = $_.Trim()
            if ($file -and (Test-Path $file)) {
                $sourceCount++
            } elseif ($file) {
                Write-Host "[ERROR] Source file not found: $file" -ForegroundColor Red
                $ErrorCount++
            }
        }
        Write-Host "[OK] Found $sourceCount source files" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Cannot retrieve source file list" -ForegroundColor Red
        $ErrorCount++
    }
} catch {
    Write-Host "[ERROR] Cannot check source files" -ForegroundColor Red
    $ErrorCount++
}

Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
if ($ErrorCount -eq 0) {
    Write-Host "[SUCCESS] ALL DEPENDENCIES SATISFIED - Ready to build!" -ForegroundColor Green
    Write-Host "   You can now run: scripts\build_all.bat" -ForegroundColor Green
} else {
    Write-Host "[FAILED] FOUND $ErrorCount ISSUES - Please fix before building" -ForegroundColor Red
    Write-Host ""
    Write-Host "COMMON SOLUTIONS:" -ForegroundColor Yellow
    Write-Host "1. Run VS Code as Administrator" -ForegroundColor Yellow
    Write-Host "2. Run 'Setup Compiler' task to install DMC" -ForegroundColor Yellow
    Write-Host "3. Restart VS Code after installing tools" -ForegroundColor Yellow
    Write-Host "4. Check that PATH includes Python and LLVM tools" -ForegroundColor Yellow
}
Write-Host "================================================================================" -ForegroundColor Cyan

exit $ErrorCount
