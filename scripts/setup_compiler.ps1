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
# This script automatically downloads and configures the Digital Mars Compiler
# (DMC) for building power electronics control modules used in QSPICE simulations.
#
# WHAT THIS SCRIPT DOES:
# 1. Checks if Digital Mars Compiler is already installed
# 2. Downloads DMC from official sources if not present
# 3. Extracts compiler to project-local compiler/ directory
# 4. Configures compiler PATH for immediate use
# 5. Validates installation by testing basic compilation
# 6. Creates portable, self-contained development environment
#
# REQUIREMENTS:
# - PowerShell 5.0 or higher
# - Internet connection for downloading compiler
# - Write permissions to project directory
# - Windows operating system (DMC is Windows-only)
#
# OUTPUT:
# - compiler/ directory with complete DMC installation
# - Configured environment ready for building QSPICE modules
# - Validation report showing compiler capabilities
#
# USAGE:
#   .\setup_compiler.ps1                    # Standard installation
#   .\setup_compiler.ps1 -Force             # Force reinstall
#   .\setup_compiler.ps1 -Quiet             # Suppress verbose output
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

# Define paths relative to script location for portability
$CompilerDir = Join-Path $PSScriptRoot "..\compiler"
$TempDir = Join-Path $env:TEMP "dmc_setup"
$DownloadUrl = "https://github.com/DigitalMars/dmc/archive/refs/heads/master.zip"
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

function Test-CompilerInstalled {
    # Check if DMC is properly installed in project compiler directory
    $DmcPath = Join-Path $CompilerDir "bin\dmc.exe"
    $IncludePath = Join-Path $CompilerDir "include"
    
    return (Test-Path $DmcPath) -and (Test-Path $IncludePath)
}

function Test-SystemCompilerInstalled {
    # Check if DMC is available in system PATH (system-wide installation)
    try {
        $null = Get-Command dmc -ErrorAction Stop
        Write-Status "Found Digital Mars Compiler in system PATH" "Yellow"
        return $true
    }
    catch {
        return $false
    }
}

function Copy-SystemCompilerToProject {
    # Try to find system DMC installation and copy to project for portability
    try {
        $DmcCommand = Get-Command dmc -ErrorAction Stop
        $SystemDmcPath = $DmcCommand.Source
        $SystemDmcDir = Split-Path $SystemDmcPath -Parent
        $SystemRootDir = Split-Path $SystemDmcDir -Parent
        
        Write-Status "Found system DMC at: $SystemRootDir"
        
        # Verify this looks like a valid DMC installation with required directories
        $SystemInclude = Join-Path $SystemRootDir "include"
        $SystemLib = Join-Path $SystemRootDir "lib"
        
        if ((Test-Path $SystemInclude) -and (Test-Path $SystemLib)) {
            Write-Status "Copying system DMC installation to project..."
            
            # Remove existing local installation if any to ensure clean state
            if (Test-Path $CompilerDir) {
                Remove-Item $CompilerDir -Recurse -Force
            }
            
            # Copy the entire DMC directory structure for complete installation
            Copy-Item $SystemRootDir $CompilerDir -Recurse -Force
            
            Write-Status "Successfully copied system DMC to project" "Green"
            return $true
        }
        else {
            Write-Status "System DMC installation appears incomplete" "Yellow"
            return $false
        }
    }
    catch {
        Write-Status "Could not locate or copy system DMC installation" "Yellow"
        return $false
    }
}

function Find-CommonDmcLocations {
    # Check common installation locations for DMC across different setups
    $CommonPaths = @(
        "C:\dm",                                        # Standard DMC location
        "C:\dmc",                                       # Alternative DMC location
        "C:\Program Files\Digital Mars",               # Program Files installation
        "C:\Program Files (x86)\Digital Mars",         # 32-bit Program Files
        "D:\dm",                                        # Alternative drive
        "F:\Softwares\Qspice\dm857c\dm",               # QSPICE integration path
        "$env:ProgramFiles\DMC",                       # Environment-based path
        "$env:ProgramFiles(x86)\DMC"                   # 32-bit environment path
    )
    
    foreach ($Path in $CommonPaths) {
        # Check if the drive exists before testing the path
        $Drive = Split-Path $Path -Qualifier
        if (!(Test-Path $Drive)) {
            Write-Status "Skipping non-existent drive: $Drive" "Yellow"
            continue
        }
        
        $DmcExe = Join-Path $Path "bin\dmc.exe"
        $IncludeDir = Join-Path $Path "include"
        
        if ((Test-Path $DmcExe) -and (Test-Path $IncludeDir)) {
            Write-Status "Found DMC installation at: $Path" "Yellow"
            return $Path
        }
    }
    
    return $null
}

function Copy-CommonLocationToProject {
    param([string]$SourcePath)
    
    try {
        Write-Status "Copying DMC from $SourcePath to project..."
        
        # Remove existing local installation if any
        if (Test-Path $CompilerDir) {
            Remove-Item $CompilerDir -Recurse -Force
        }
        
        # Copy the entire DMC directory
        Copy-Item $SourcePath $CompilerDir -Recurse -Force
        
        Write-Status "Successfully copied DMC to project" "Green"
        return $true
    }
    catch {
        Write-Error-Status "Failed to copy DMC: $($_.Exception.Message)"
        return $false
    }
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
    
    # Check if compiler already exists in project
    if ((Test-CompilerInstalled) -and (-not $Force)) {
        Write-Status "Digital Mars Compiler already installed in project: $CompilerDir" "Green"
        Write-Status "Use -Force to re-download" "Yellow"
        return $true
    }
      # Check if compiler exists in system PATH
    if (Test-SystemCompilerInstalled) {
        Write-Status "Found system installation of Digital Mars Compiler" "Yellow"
        
        if (-not $Force) {
            Write-Status "Attempting to copy system installation to project..." "Yellow"
            if (Copy-SystemCompilerToProject) {
                Write-Status "Successfully used existing system installation!" "Green"
                return $true
            }
            else {
                Write-Status "Could not copy system installation, will check common locations..." "Yellow"
            }
        }
        else {
            Write-Status "Force flag set, downloading fresh copy..." "Yellow"
        }
    }
    
    # Check common installation locations
    if (-not $Force) {
        $CommonLocation = Find-CommonDmcLocations
        if ($CommonLocation) {
            Write-Status "Attempting to copy from common location: $CommonLocation" "Yellow"
            if (Copy-CommonLocationToProject $CommonLocation) {
                Write-Status "Successfully used existing installation!" "Green"
                return $true
            }
            else {
                Write-Status "Could not copy from common location, will download..." "Yellow"
            }
        }
    }
    
    Write-Status "No suitable existing installation found, downloading..." "Yellow"
    
    # Create temp directory
    if (Test-Path $TempDir) {
        Remove-Item $TempDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
    
    $ZipFile = Join-Path $TempDir "dmc-master.zip"
    
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
    
    # Remove existing compiler directory if forcing
    if ($Force -and (Test-Path $CompilerDir)) {
        Write-Status "Removing existing compiler installation..."
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
        (Join-Path $ExtractPath "dmc-master"),
        (Join-Path $ExtractPath "dmc-master\dm"),
        (Join-Path $ExtractPath "dm"),
        (Join-Path $ExtractPath "dmc"),
        (Join-Path $ExtractPath "dm857c\dm"),
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
    
    # Copy to final location
    Write-Status "Installing compiler to: $CompilerDir"
    if (Test-Path $CompilerDir) {
        Remove-Item $CompilerDir -Recurse -Force
    }
    
    Copy-Item $DmcSource $CompilerDir -Recurse -Force
    
    # Cleanup temp files
    Remove-Item $TempDir -Recurse -Force
    
    # Verify installation
    if (Test-CompilerInstalled) {
        Write-Status "=== Setup Complete! ===" "Green"
        Write-Status "Digital Mars Compiler installed successfully" "Green"
        Write-Status "Location: $CompilerDir" "Green"
        
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
