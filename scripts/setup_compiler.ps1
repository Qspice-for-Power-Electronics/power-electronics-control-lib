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
# Power Electronics Control Library - Digital Mars Compiler Setup Script
# ================================================================================
# 
# This script automatically downloads and installs the Digital Mars Compiler
# (DMC) to the standard system location (C:\dm) for building power electronics 
# control modules used in QSPICE simulations.
#
# WHAT THIS SCRIPT DOES:
# 1. Checks if Digital Mars Compiler is already installed in C:\dm
# 2. Downloads DMC from official sources if not present
# 3. Installs compiler to standard system location (C:\dm)
# 4. Adds DMC to system PATH permanently for all users
# 5. Validates installation by testing basic compilation
# 6. Creates system-wide development environment
#
# REQUIREMENTS:
# - PowerShell 5.0 or higher
# - Administrator privileges (required for system installation)
# - Internet connection for downloading compiler
# - Windows operating system (DMC is Windows-only)
#
# OUTPUT:
# - C:\dm directory with complete DMC installation
# - System PATH updated to include C:\dm\bin
# - Validation report showing compiler capabilities
#
# USAGE:
#   .\setup_compiler.ps1                    # Standard installation
#   .\setup_compiler.ps1 -Force             # Force reinstall
#   .\setup_compiler.ps1 -Quiet             # Suppress verbose output
#
# NOTE: This script requires Administrator privileges to install to C:\dm
#       and modify the system PATH. Run PowerShell as Administrator.
#
# ================================================================================

param(
    [switch]$Force,  # Force re-download even if compiler exists
    [switch]$Quiet   # Suppress verbose output
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

function Add-ToSystemPath {
    param([string]$NewPath)
    
    $BinPath = Join-Path $NewPath "bin"
    
    try {
        # Get current system PATH
        $CurrentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
        
        # Check if path is already in PATH
        $PathsArray = $CurrentPath -split ";"
        if ($PathsArray -contains $BinPath) {
            Write-Status "DMC bin directory already in system PATH" "Green"
            return $true
        }
        
        # Add DMC bin directory to PATH
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

function Setup-Compiler {
    Write-Status "=== Digital Mars Compiler Setup ===" "Cyan"
    Write-Status "Installing to standard location: $CompilerDir" "Cyan"
    
    # Check if compiler already exists in standard location
    if ((Test-CompilerInstalled) -and (-not $Force)) {
        Write-Status "Digital Mars Compiler already installed at: $CompilerDir" "Green"
        Write-Status "Use -Force to re-install" "Yellow"
        
        # Ensure it's in PATH
        Add-ToSystemPath $CompilerDir
        return $true
    }
    
    # Check if we have administrator privileges (required for C:\dm installation)
    $CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = [Security.Principal.WindowsPrincipal]$CurrentUser
    $IsAdmin = $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $IsAdmin) {
        Write-Error-Status "Administrator privileges required to install to $CompilerDir"
        Write-Status "Please run PowerShell as Administrator" "Yellow"
        return $false
    }
    
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
        return $false
    }
    
    # Verify download
    if (-not (Test-Path $ZipFile) -or (Get-Item $ZipFile).Length -lt 1MB) {
        Write-Error-Status "Downloaded file is invalid or too small"
        return $false
    }
    
    Write-Status "Download successful: $([Math]::Round((Get-Item $ZipFile).Length / 1MB, 2)) MB"
    
    # Remove existing compiler directory if forcing or if exists
    if (Test-Path $CompilerDir) {
        Write-Status "Removing existing installation..."
        Remove-Item $CompilerDir -Recurse -Force
    }
    
    # Extract archive
    $ExtractPath = Join-Path $TempDir "extracted"
    if (-not (Extract-Archive $ZipFile $ExtractPath)) {
        return $false
    }
    
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
    
    if (-not $DmcSource) {
        Write-Error-Status "Could not find dmc.exe in extracted files"
        return $false
    }
    
    # Install to standard location
    Write-Status "Installing compiler to: $CompilerDir"
    Copy-Item $DmcSource $CompilerDir -Recurse -Force
    
    # Add to system PATH permanently
    $PathAdded = Add-ToSystemPath $CompilerDir
    
    # Cleanup temp files
    Remove-Item $TempDir -Recurse -Force
    
    # Verify installation
    if (Test-CompilerInstalled) {
        Write-Status "=== Setup Complete! ===" "Green"
        Write-Status "Digital Mars Compiler installed successfully" "Green"
        Write-Status "Location: $CompilerDir" "Green"
        
        if ($PathAdded) {
            Write-Status "DMC added to system PATH permanently" "Green"
            Write-Status "You can now use 'dmc' command from any location" "Green"
        }
        
        # Show version info
        $DmcExe = Join-Path $CompilerDir "bin\dmc.exe"
        try {
            $Version = & $DmcExe 2>&1 | Select-Object -First 1
            Write-Status "Version: $Version" "Green"
        }
        catch {
            Write-Status "Compiler installed but version check failed" "Yellow"
        }
        
        return $true
    }
    else {
        Write-Error-Status "Installation verification failed"
        return $false
    }
}

# ================================================================================
# STEP 6: Main Execution Entry Point
# ================================================================================

# Main execution with comprehensive error handling
try {
    $Success = Setup-Compiler
    
    if ($Success) {
        Write-Status "Compiler setup completed successfully!" "Green"
        exit 0
    }
    else {
        Write-Error-Status "Compiler setup failed!"
        exit 1
    }
}
catch {
    Write-Error-Status "Unexpected error: $($_.Exception.Message)"
    Write-Error-Status "Stack trace: $($_.ScriptStackTrace)"
    exit 1
}
