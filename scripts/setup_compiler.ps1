# *************************** In The Name Of God ***************************
# * @file    setup_compiler.ps1
# * @brief   PowerShell script to setup Digital Mars Compiler for QSPICE
# * @author  Dr.-Ing. Hossein Abedini
# * @date    2025-06-08
# * Downloads and installs DMC if not present in the project for building
# * power electronics control modules.
# * @note    Designed for real-time signal processing applications.
# * @license This work is dedicated to the public domain under CC0 1.0.
# *          Please use it for good and beneficial purposes!
# ***************************************************************************

# ================================================================================
# Power Electronics Control Library - Digital Mars Compiler & LLVM Setup Script
# ================================================================================
# 
# This script automatically downloads and installs the Digital Mars Compiler
# (DMC) and LLVM/Clang toolchain to standard system locations for building power 
# electronics control modules used in QSPICE simulations.
#
# WHAT THIS SCRIPT DOES:
# 1. Installs LLVM/Clang toolchain using winget (provides clang-format)
# 2. Adds LLVM to system PATH permanently
# 3. Checks if Digital Mars Compiler is already installed in C:\dm
# 4. Downloads DMC from official sources if not present
# 5. Installs compiler to standard system location (C:\dm)
# 6. Adds DMC to system PATH permanently for all users
# 7. Validates installation by testing basic compilation tools
# 8. Creates system-wide development environment
#
# REQUIREMENTS:
# - PowerShell 5.0 or higher
# - Administrator privileges (required for system installation)
# - Internet connection for downloading compiler
# - Windows operating system (DMC is Windows-only)
# - App Installer (winget) for LLVM installation
#
# OUTPUT:
# - C:\Program Files\LLVM directory with LLVM/Clang toolchain
# - C:\dm directory with complete DMC installation
# - System PATH updated to include both tool locations
# - Validation report showing compiler capabilities
#
# USAGE:
#   .\setup_compiler.ps1                    # Standard installation
#   .\setup_compiler.ps1 -Force             # Force reinstall
#   .\setup_compiler.ps1 -Quiet             # Suppress verbose output
#   .\setup_compiler.ps1 -CheckOnly         # Only run dependency check
#   .\setup_compiler.ps1 -SkipDMC           # Skip Digital Mars Compiler setup
#   .\setup_compiler.ps1 -SkipLLVM          # Skip LLVM/Clang setup
#
# NOTE: This script requires Administrator privileges to install to system
#       locations and modify the system PATH. Run PowerShell as Administrator.
#
# ================================================================================

param(
    [switch]$Force,      # Force re-download even if compiler exists
    [switch]$Quiet,      # Suppress verbose output
    [switch]$CheckOnly,  # Only run dependency check
    [switch]$SkipDMC,    # Skip Digital Mars Compiler setup
    [switch]$SkipLLVM    # Skip LLVM/Clang setup
)

# Enable strict error handling for reliable operation
$ErrorActionPreference = "Stop"

# ================================================================================
# STEP 1: Initialize Configuration and Paths
# ================================================================================

# Define paths for system-wide installation
$CompilerDir = "C:\dm"  # Standard DMC location
$TempDir = Join-Path $env:TEMP "dmc_setup"
$DownloadUrl = "http://ftp.digitalmars.com/dmc.zip"
$BackupUrl = "http://ftp.digitalmars.com/dm857c.zip"

# ================================================================================
# STEP 2: Define Utility Functions
# ================================================================================

function Write-Status {
    param([string]$Message, [string]$Color = "Green")
    if (-not $Quiet) {
        Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] $Message" -ForegroundColor $Color
    }
}

function Write-Error-Status {
    param([string]$Message)
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] ERROR: $Message" -ForegroundColor Red
}

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
            Write-Status "Environment PATH refreshed from system variables" "Green"
        }
        
        return $true
    }
    catch {
        Write-Error-Status "Failed to refresh environment PATH: $($_.Exception.Message)"
        return $false
    }
}

function Add-ToSystemPath {
    param([string]$NewPath, [string]$Description = "directory")
    
    $BinPath = Join-Path $NewPath "bin"
    
    try {
        # Get current system PATH
        $CurrentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
        
        # Check if path is already in PATH
        $PathsArray = $CurrentPath -split ";"
        if ($PathsArray -contains $BinPath) {
            Write-Status "$Description bin directory already in system PATH" "Green"
            return $true
        }
        
        # Add bin directory to PATH
        $NewSystemPath = $CurrentPath + ";" + $BinPath
        [Environment]::SetEnvironmentVariable("PATH", $NewSystemPath, "Machine")
        
        # Also update current session PATH
        $env:PATH += ";" + $BinPath
        
        Write-Status "Successfully added $BinPath to system PATH" "Green"
        return $true
    }
    catch {
        Write-Error-Status "Failed to add to system PATH: $($_.Exception.Message)"
        return $false
    }
}

function Test-Dependencies {
    Write-Status "=== Dependency Check ===" "Cyan"
    
    # Refresh PATH from system environment variables first
    Write-Status "Refreshing environment PATH..." "Yellow"
    Refresh-EnvironmentPath -Quiet
    
    $ErrorCount = 0
    
    # Check Git
    Write-Status "[1/6] Checking Git..." "Yellow"
    try {
        $gitVersion = git --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Status "[OK] Found: $gitVersion" "Green"
        }
        else {
            Write-Status "[ERROR] Git not found" "Red"
            Write-Status "   Will install using: winget install --id Git.Git -e --source winget" "Yellow"
            $ErrorCount++
        }
    }
    catch {
        Write-Status "[ERROR] Git not available" "Red"
        $ErrorCount++
    }
    
    # Check PowerShell (modern version)
    Write-Status "[2/6] Checking PowerShell..." "Yellow"
    try {
        $pwshVersion = pwsh --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Status "[OK] Found: PowerShell Core $pwshVersion" "Green"
        }
        else {
            Write-Status "[ERROR] PowerShell Core not found" "Red"
            Write-Status "   Will install using: winget install -e --id Microsoft.PowerShell" "Yellow"
            $ErrorCount++
        }
    }
    catch {
        Write-Status "[ERROR] PowerShell Core not available" "Red"
        Write-Status "   Note: Using Windows PowerShell, consider upgrading to PowerShell Core" "Yellow"
        $ErrorCount++
    }
    
    # Check Python
    Write-Status "[3/6] Checking Python..." "Yellow"
    try {
        $pythonVersion = python --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Status "[OK] Found: $pythonVersion" "Green"
        }
        else {
            Write-Status "[ERROR] Python not found" "Red"
            Write-Status "   Solution: winget install -e --id Python.Python.3.11" "Yellow"
            $ErrorCount++
        }
    }
    catch {
        Write-Status "[ERROR] Python not available" "Red"
        $ErrorCount++
    }
    
    # Check Digital Mars Compiler
    Write-Status "[4/6] Checking Digital Mars Compiler..." "Yellow"
    $dmcPath = "C:\dm\bin\dmc.exe"
    if (Test-Path $dmcPath) {
        Write-Status "[OK] Found: Digital Mars Compiler at C:\dm\bin" "Green"
    }
    else {
        Write-Status "[ERROR] Digital Mars Compiler (dmc) not found" "Red"
        Write-Status "   Run without -CheckOnly to install automatically" "Yellow"
        $ErrorCount++
    }
    
    # Check clang-format
    Write-Status "[5/6] Checking clang-format..." "Yellow"
    try {
        $clangFormat = Get-Command clang-format -ErrorAction SilentlyContinue
        if ($clangFormat) {
            Write-Status "[OK] Found: clang-format at $($clangFormat.Source)" "Green"
        }
        else {
            Write-Status "[ERROR] clang-format not found in PATH" "Red"
            Write-Status "   Run without -CheckOnly to install LLVM tools" "Yellow"
            $ErrorCount++
        }
    }
    catch {
        Write-Status "[ERROR] clang-format not available" "Red"
        $ErrorCount++
    }
    
    # Check project configuration
    Write-Status "[6/6] Checking project configuration..." "Yellow"
    try {
        $configFile = "config\project_config.json"
        if (Test-Path $configFile) {
            Write-Status "[OK] Found: project_config.json" "Green"
            
            # Test Python config parser
            $configTest = python scripts\project_config.py --summary 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Status "[OK] Project configuration is valid" "Green"
            }
            else {
                Write-Status "[ERROR] Project configuration validation failed" "Red"
                $ErrorCount++
            }
        }
        else {
            Write-Status "[ERROR] config\project_config.json not found" "Red"
            $ErrorCount++
        }
    }
    catch {
        Write-Status "[ERROR] Cannot validate project configuration" "Red"
        $ErrorCount++
    }
    
    Write-Status "" 
    if ($ErrorCount -eq 0) {
        Write-Status "[SUCCESS] ALL DEPENDENCIES SATISFIED - Ready to build!" "Green"
        Write-Status "   You can now run: scripts\build_all.bat" "Green"
    }
    else {
        Write-Status "[ERROR] FOUND $ErrorCount ISSUES - Setup required" "Red"
        Write-Status "   Run this script without -CheckOnly to fix automatically" "Yellow"
    }
    
    return $ErrorCount -eq 0
}

function Install-LLVM {
    Write-Status "=== LLVM/Clang Installation ===" "Cyan"
    
    # Check if LLVM is already installed
    $LLVMPath = "C:\Program Files\LLVM"
    $ClangFormatPath = Join-Path $LLVMPath "bin\clang-format.exe"
    
    if ((Test-Path $ClangFormatPath) -and (-not $Force)) {
        Write-Status "LLVM/Clang already installed at: $LLVMPath" "Green"
        Write-Status "Use -Force to re-install" "Yellow"
        
        # Ensure it's in PATH
        Add-ToSystemPath $LLVMPath "LLVM"
        return $true
    }
    
    # Check if winget is available
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Status "winget is not available, trying Chocolatey..." "Yellow"
        
        # Try Chocolatey as fallback
        try {
            # Check if Chocolatey is installed
            $choco = Get-Command choco -ErrorAction SilentlyContinue
            if (-not $choco) {
                Write-Status "Installing Chocolatey..." "Yellow"
                Set-ExecutionPolicy Bypass -Scope Process -Force
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
                Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            }
            
            Write-Status "Installing LLVM via Chocolatey..." "Yellow"
            & choco install llvm -y
            
            # Refresh environment variables
            $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
            
            # Verify installation
            if (Test-Path $ClangFormatPath) {
                Write-Status "LLVM installed successfully via Chocolatey" "Green"
                Add-ToSystemPath $LLVMPath "LLVM"
                return $true
            }
            else {
                Write-Error-Status "LLVM installation via Chocolatey failed"
                return $false
            }
        }
        catch {
            Write-Error-Status "Failed to install LLVM via Chocolatey: $($_.Exception.Message)"
            Write-Status "Please install LLVM manually from https://releases.llvm.org/" "Yellow"
            return $false
        }
    }
    
    try {
        Write-Status "Installing LLVM/Clang using winget..." "Yellow"
        
        # Install LLVM using winget
        $InstallResult = & winget install LLVM.LLVM --accept-source-agreements --accept-package-agreements 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Status "LLVM/Clang installed successfully" "Green"
            
            # Add LLVM to system PATH
            $PathAdded = Add-ToSystemPath $LLVMPath "LLVM"
            
            # Verify installation
            if (Test-Path $ClangFormatPath) {
                Write-Status "LLVM installation verified" "Green"
                
                # Show version info
                try {
                    $ClangVersion = & "$LLVMPath\bin\clang-format.exe" --version 2>&1
                    Write-Status "clang-format version: $ClangVersion" "Green"
                }
                catch {
                    Write-Status "LLVM installed but version check failed" "Yellow"
                }
                
                return $true
            }
            else {
                Write-Error-Status "LLVM installation verification failed"
                return $false
            }
        }
        else {
            Write-Error-Status "LLVM installation failed with exit code: $LASTEXITCODE"
            Write-Status "Output: $InstallResult" "Yellow"
            return $false
        }
    }
    catch {
        Write-Error-Status "Failed to install LLVM: $($_.Exception.Message)"
        return $false
    }
}

function Install-Git {
    Write-Status "=== Git Installation ===" "Cyan"
    
    # Check if Git is already installed
    try {
        $gitVersion = git --version 2>&1
        if ($LASTEXITCODE -eq 0 -and (-not $Force)) {
            Write-Status "Git already installed: $gitVersion" "Green"
            return $true
        }
    }
    catch {
        # Git not found, proceed with installation
    }
    
    # Check if winget is available
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Error-Status "winget is not available. Please install Git manually from https://git-scm.com/"
        return $false
    }
    
    try {
        Write-Status "Installing Git using winget..." "Yellow"
        
        # Install Git using winget
        $InstallResult = & winget install --id Git.Git -e --source winget --accept-source-agreements --accept-package-agreements 2>&1
        
        if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1978335189) {
            Write-Status "Git installed successfully" "Green"
            
            # Refresh environment variables
            $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
            
            # Verify installation
            try {
                $gitVersionNew = git --version 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Status "Git installation verified: $gitVersionNew" "Green"
                    return $true
                }
                else {
                    Write-Error-Status "Git installation verification failed"
                    return $false
                }
            }
            catch {
                Write-Error-Status "Git installed but verification failed"
                return $false
            }
        }
        else {
            Write-Error-Status "Git installation failed with exit code: $LASTEXITCODE"
            Write-Status "Output: $InstallResult" "Yellow"
            return $false
        }
    }
    catch {
        Write-Error-Status "Failed to install Git: $($_.Exception.Message)"
        return $false
    }
}

function Install-PowerShell {
    Write-Status "=== PowerShell Core Installation ===" "Cyan"
    
    # Check if PowerShell Core is already installed
    try {
        $pwshVersion = pwsh --version 2>&1
        if ($LASTEXITCODE -eq 0 -and (-not $Force)) {
            Write-Status "PowerShell Core already installed: $pwshVersion" "Green"
            return $true
        }
    }
    catch {
        # PowerShell Core not found, proceed with installation
    }
    
    # Check if winget is available
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Error-Status "winget is not available. Please install PowerShell Core manually from https://github.com/PowerShell/PowerShell"
        return $false
    }
    
    try {
        Write-Status "Installing PowerShell Core using winget..." "Yellow"
        
        # Install PowerShell Core using winget
        $InstallResult = & winget install -e --id Microsoft.PowerShell --accept-source-agreements --accept-package-agreements 2>&1
        
        if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1978335189) {
            Write-Status "PowerShell Core installed successfully" "Green"
            
            # Refresh environment variables
            $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
            
            # Verify installation
            try {
                $pwshVersionNew = pwsh --version 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Status "PowerShell Core installation verified: $pwshVersionNew" "Green"
                    return $true
                }
                else {
                    Write-Error-Status "PowerShell Core installation verification failed"
                    return $false
                }
            }
            catch {
                Write-Error-Status "PowerShell Core installed but verification failed"
                return $false
            }
        }
        else {
            Write-Error-Status "PowerShell Core installation failed with exit code: $LASTEXITCODE"
            Write-Status "Output: $InstallResult" "Yellow"
            return $false
        }
    }
    catch {
        Write-Error-Status "Failed to install PowerShell Core: $($_.Exception.Message)"
        return $false
    }
}

function Install-Python {
    Write-Status "=== Python Installation ===" "Cyan"
    
    # Check if Python is already installed
    try {
        $pythonVersion = python --version 2>&1
        if ($LASTEXITCODE -eq 0 -and (-not $Force)) {
            Write-Status "Python already installed: $pythonVersion" "Green"
            return $true
        }
    }
    catch {
        # Python not found, proceed with installation
    }
    
    # Check if winget is available
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Error-Status "winget is not available. Please install Python manually from https://python.org/"
        return $false
    }
    
    try {
        Write-Status "Installing Python 3.11 using winget..." "Yellow"
        
        # Install Python using winget
        $InstallResult = & winget install -e --id Python.Python.3.11 --accept-source-agreements --accept-package-agreements 2>&1
        
        if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1978335189) {
            Write-Status "Python 3.11 installed successfully" "Green"
            
            # Refresh environment variables
            $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
            
            # Verify installation
            try {
                $pythonVersionNew = python --version 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Status "Python installation verified: $pythonVersionNew" "Green"
                    return $true
                }
                else {
                    Write-Error-Status "Python installation verification failed"
                    return $false
                }
            }
            catch {
                Write-Error-Status "Python installed but verification failed"
                return $false
            }
        }
        else {
            Write-Error-Status "Python installation failed with exit code: $LASTEXITCODE"
            Write-Status "Output: $InstallResult" "Yellow"
            return $false
        }
    }
    catch {
        Write-Error-Status "Failed to install Python: $($_.Exception.Message)"
        return $false
    }
}

function Test-CompilerInstalled {
    # Check if DMC is properly installed in standard system location
    $DmcPath = Join-Path $CompilerDir "bin\dmc.exe"
    $IncludePath = Join-Path $CompilerDir "include"
    
    return (Test-Path $DmcPath) -and (Test-Path $IncludePath)
}

function Download-File {
    param([string]$Url, [string]$Destination)
    
    try {
        Write-Status "Downloading from: $Url"
        
        # Try with Invoke-WebRequest first (PowerShell 3.0+)
        if (Get-Command Invoke-WebRequest -ErrorAction SilentlyContinue) {
            # Add progress tracking
            $ProgressPreference = 'Continue'
            Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing
        }
        # Fallback to WebClient
        else {
            $WebClient = New-Object System.Net.WebClient
            # Add progress handler
            Register-ObjectEvent -InputObject $WebClient -EventName DownloadProgressChanged -Action {
                $Global:DownloadProgress = $Event.SourceEventArgs.ProgressPercentage
                Write-Progress -Activity "Downloading" -Status "Progress: $Global:DownloadProgress%" -PercentComplete $Global:DownloadProgress
            } | Out-Null
            $WebClient.DownloadFile($Url, $Destination)
            Write-Progress -Activity "Downloading" -Completed
            $WebClient.Dispose()
        }
        
        return $true
    }
    catch {
        Write-Error-Status "Failed to download from $Url : $($_.Exception.Message)"
        return $false
    }
}

function Extract-Archive {
    param([string]$ZipPath, [string]$Destination)
    
    try {
        Write-Status "Extracting to: $Destination"
        
        # Create destination directory
        if (-not (Test-Path $Destination)) {
            New-Item -ItemType Directory -Path $Destination -Force | Out-Null
        }
        
        # Try with Expand-Archive (PowerShell 5.0+)
        if (Get-Command Expand-Archive -ErrorAction SilentlyContinue) {
            Expand-Archive -Path $ZipPath -DestinationPath $Destination -Force
        }
        # Fallback to COM object
        else {
            $Shell = New-Object -ComObject Shell.Application
            $Zip = $Shell.NameSpace($ZipPath)
            $DestFolder = $Shell.NameSpace($Destination)
            $DestFolder.CopyHere($Zip.Items(), 4)
        }
        
        return $true
    }
    catch {
        Write-Error-Status "Failed to extract archive: $($_.Exception.Message)"
        return $false
    }
}

function Test-PythonInstallation {
    Write-Status "=== Python Validation ===" "Cyan"
    
    try {
        $pythonVersion = python --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Status "[OK] Found: $pythonVersion" "Green"
            
            # Test if we can run the project config script
            try {
                $configTest = python scripts\project_config.py --summary 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Status "[OK] Python can run project configuration scripts" "Green"
                    return $true
                }
                else {
                    Write-Status "[ERROR] Python found but project scripts fail" "Red"
                    Write-Status "   Check if scripts/project_config.py exists" "Yellow"
                    return $false
                }
            }
            catch {
                Write-Status "[ERROR] Cannot test project configuration script" "Red"
                return $false
            }
        }
        else {
            Write-Status "[ERROR] Python not found" "Red"
            Write-Status "   Solution: winget install -e --id Python.Python.3.11" "Yellow"
            Write-Status "   Make sure to add Python to PATH during installation" "Yellow"
            return $false
        }
    }
    catch {
        Write-Status "[ERROR] Python not available" "Red"
        Write-Status "   Solution: winget install -e --id Python.Python.3.11" "Yellow"
        return $false
    }
}

function Setup-Compiler {
    Write-Status "=== Power Electronics Control Library Setup ===" "Cyan"
    Write-Status "Installing development tools to standard locations" "Cyan"
    Write-Status ""
    
    $SetupErrors = 0
    
    # Check if running as Administrator (required for system installation)
    $CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = [Security.Principal.WindowsPrincipal]$CurrentUser
    $IsAdmin = $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
      if (-not $IsAdmin) {
        Write-Error-Status "Administrator privileges required for system installation"
        Write-Status "Please run PowerShell as Administrator" "Yellow"
        return $false
    }
    
    # Install Git if not present
    Write-Status "[1/5] Installing Git..." "Cyan"
    $GitInstalled = Install-Git
    if (-not $GitInstalled) {
        Write-Error-Status "Git installation failed"
        Write-Status "Git is required for version control and development workflow" "Yellow"
        $SetupErrors++
    } else {
        # Refresh PATH after Git installation
        Refresh-EnvironmentPath -Quiet
    }
    Write-Status ""
    
    # Install PowerShell Core if not present
    Write-Status "[2/5] Installing PowerShell Core..." "Cyan"
    $PowerShellInstalled = Install-PowerShell
    if (-not $PowerShellInstalled) {
        Write-Error-Status "PowerShell Core installation failed"
        Write-Status "PowerShell Core provides better cross-platform compatibility" "Yellow"
        $SetupErrors++
    } else {
        # Refresh PATH after PowerShell installation
        Refresh-EnvironmentPath -Quiet
    }
    Write-Status ""

    # Install Python if not present (required for project configuration)
    Write-Status "[3/5] Installing Python..." "Cyan"
    $PythonInstalled = Install-Python
    if (-not $PythonInstalled) {
        Write-Error-Status "Python installation failed"
        Write-Status "Python is required for project configuration and build scripts" "Yellow"
        $SetupErrors++
    } else {
        # Refresh PATH after Python installation
        Refresh-EnvironmentPath -Quiet
        
        # Validate Python installation
        $PythonValid = Test-PythonInstallation
        if (-not $PythonValid) {
            Write-Status "[ERROR] Python validation failed after installation" "Red"
            $SetupErrors++
        }
    }
    Write-Status ""
    
    # Setup LLVM/Clang (provides clang-format for code formatting)
    if (-not $SkipLLVM) {
        Write-Status "[4/5] Setting up LLVM/Clang tools..." "Cyan"
        $LLVMInstalled = Install-LLVM
        if (-not $LLVMInstalled) {
            Write-Error-Status "LLVM/Clang installation failed"
            Write-Status "Build process requires clang-format for code formatting" "Yellow"
            $SetupErrors++
        } else {
            # Refresh PATH after LLVM installation
            Refresh-EnvironmentPath -Quiet
        }
    }
    else {
        Write-Status "[4/5] Skipping LLVM/Clang setup (as requested)..." "Yellow"
    }
    Write-Status ""
    
    # Setup Digital Mars Compiler
    if (-not $SkipDMC) {
        Write-Status "[5/5] Setting up Digital Mars Compiler..." "Cyan"
        
        # Check if compiler already exists in standard location
        if ((Test-CompilerInstalled) -and (-not $Force)) {
            Write-Status "Digital Mars Compiler already installed at: $CompilerDir" "Green"
            Write-Status "Use -Force to re-install" "Yellow"
            
            # Ensure it's in PATH
            Add-ToSystemPath $CompilerDir "DMC"
        }
        else {
            Write-Status "Downloading and installing Digital Mars Compiler to $CompilerDir..." "Yellow"
            
            # Create temp directory
            if (Test-Path $TempDir) {
                Remove-Item $TempDir -Recurse -Force
            }
            New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
            
            $ZipFile = Join-Path $TempDir "dmc.zip"
            
            # Try primary download URL
            Write-Status "Downloading Digital Mars Compiler..."
            $Downloaded = Download-File $DownloadUrl $ZipFile
            
            # Try backup URL if primary fails
            if (-not $Downloaded) {
                Write-Status "Trying backup download URL..." "Yellow"
                $Downloaded = Download-File $BackupUrl $ZipFile
            }
            
            if (-not $Downloaded) {
                Write-Error-Status "Failed to download Digital Mars Compiler from all sources"
                $SetupErrors++
            }
            else {
                # Verify download
                if (-not (Test-Path $ZipFile) -or (Get-Item $ZipFile).Length -lt 1MB) {
                    Write-Error-Status "Downloaded file is invalid or too small"
                    $SetupErrors++
                }
                else {
                    Write-Status "Download successful: $([Math]::Round((Get-Item $ZipFile).Length / 1MB, 2)) MB"
                    
                    # Remove existing compiler directory if forcing or if exists
                    if (Test-Path $CompilerDir) {
                        Write-Status "Removing existing installation..."
                        Remove-Item $CompilerDir -Recurse -Force
                    }
                    
                    # Extract archive
                    $ExtractPath = Join-Path $TempDir "extracted"
                    if (Extract-Archive $ZipFile $ExtractPath) {
                        # Find the actual compiler directory (might be nested)
                        $DmcSource = $null
                        $PossiblePaths = @(
                            (Join-Path $ExtractPath "dm"),
                            (Join-Path $ExtractPath "dmc"),
                            (Join-Path $ExtractPath "dm857c\dm"),
                            (Join-Path $ExtractPath "dmc-master\dm"),
                            (Join-Path $ExtractPath "dmc-master"),
                            $ExtractPath
                        )
                        
                        foreach ($Path in $PossiblePaths) {
                            $TestDmc = Join-Path $Path "bin\dmc.exe"
                            if (Test-Path $TestDmc) {
                                $DmcSource = $Path
                                break
                            }
                        }
                        
                        if ($DmcSource) {
                            # Install to standard location
                            Write-Status "Installing compiler to: $CompilerDir"
                            Copy-Item $DmcSource $CompilerDir -Recurse -Force
                            
                            # Add to system PATH permanently
                            Add-ToSystemPath $CompilerDir "DMC"
                            
                            Write-Status "[SUCCESS] Digital Mars Compiler installed successfully" "Green"
                        }
                        else {
                            Write-Error-Status "Could not find dmc.exe in extracted files"
                            $SetupErrors++
                        }
                    }
                    else {
                        $SetupErrors++
                    }
                }
            }
            
            # Cleanup temp files
            if (Test-Path $TempDir) {
                Remove-Item $TempDir -Recurse -Force
            }
        }
    }
    else {
        Write-Status "[3/3] Skipping Digital Mars Compiler setup (as requested)..." "Yellow"
    }
    
    Write-Status ""
    Write-Status "=== Setup Summary ===" "Cyan"
    
    if ($SetupErrors -eq 0) {
        Write-Status "[SUCCESS] SETUP COMPLETED SUCCESSFULLY!" "Green"
        
        # Final verification of all tools
        Write-Status ""
        Write-Status "=== Tool Verification ===" "Cyan"
        
        # Test Python
        if (Get-Command python -ErrorAction SilentlyContinue) {
            Write-Status "[OK] Python is available" "Green"
        }
        else {
            Write-Status "[WARNING] Python not found in PATH" "Yellow"
        }
        
        # Test DMC
        if (Get-Command dmc -ErrorAction SilentlyContinue) {
            Write-Status "[OK] Digital Mars Compiler (dmc) is available" "Green"
        }
        else {
            Write-Status "[WARNING] Digital Mars Compiler (dmc) not found in PATH" "Yellow"
        }
        
        # Test clang-format
        if (Get-Command clang-format -ErrorAction SilentlyContinue) {
            Write-Status "[OK] clang-format is available" "Green"
        }
        else {
            Write-Status "[WARNING] clang-format not found in PATH" "Yellow"
        }
        
        Write-Status ""
        Write-Status "Next steps:" "Yellow"
        Write-Status "1. Restart VS Code completely to refresh PATH" "Yellow"
        Write-Status "2. Run dependency check: powershell scripts\Check-Dependencies.ps1" "Yellow"
        Write-Status "3. Build the project: scripts\build_all.bat" "Yellow"
        
        return $true
    }
    else {
        Write-Status "[ERROR] SETUP COMPLETED WITH $SetupErrors ERRORS" "Red"
        Write-Status ""
        Write-Status "Please review the errors above and try again." "Yellow"
        Write-Status "You can use these options to skip problematic components:" "Yellow"
        Write-Status "  -SkipDMC    : Skip Digital Mars Compiler setup" "Yellow"
        Write-Status "  -SkipLLVM   : Skip LLVM/Clang setup" "Yellow"
        Write-Status "  -CheckOnly  : Only run dependency check" "Yellow"
        
        return $false
    }
}

# ================================================================================
# STEP 6: Main Execution Entry Point
# ================================================================================

# Main execution with comprehensive error handling
try {
    # Handle CheckOnly parameter first
    if ($CheckOnly) {
        Write-Status "Running dependency check only..." "Cyan"
        $DepsOK = Test-Dependencies
        exit $(if ($DepsOK) { 0 } else { 1 })
    }
    
    # Run full setup
    $Success = Setup-Compiler
    
    if ($Success) {
        Write-Status "Setup completed successfully!" "Green"
        exit 0
    }
    else {
        Write-Error-Status "Setup failed!"
        exit 1
    }
}
catch {
    Write-Error-Status "Unexpected error: $($_.Exception.Message)"
    Write-Error-Status "Stack trace: $($_.ScriptStackTrace)"
    exit 1
}
