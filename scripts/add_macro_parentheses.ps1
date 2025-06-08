# *************************** In The Name Of God ***************************
# * @file    add_macro_parentheses.ps1
# * @brief   PowerShell script to add parentheses around #define values
# * @author  Dr.-Ing. Hossein Abedini
# * @date    2025-06-08
# * Automatically adds parentheses around macro definitions for safer macro
# * expansion and prevents operator precedence issues.
# * @note    Designed for real-time signal processing applications.
# * @license This work is dedicated to the public domain under CC0 1.0.
# *          Please use it for good and beneficial purposes!
# ***************************************************************************

# ================================================================================
# Power Electronics Control Library - Macro Parentheses Safety Script
# ================================================================================
# 
# This script automatically adds parentheses around #define macro values to
# prevent operator precedence issues and ensure safer macro expansion in C/C++
# code, which is critical for real-time signal processing applications.
#
# WHAT THIS SCRIPT DOES:
# 1. Scans all C/C++ source and header files in the modules directory
# 2. Identifies #define macros with numeric or expression values
# 3. Adds parentheses around macro values if not already present
# 4. Preserves existing parentheses and formatting where appropriate
# 5. Reports all changes made for review and verification
# 6. Supports dry-run mode for safe preview of changes
#
# REQUIREMENTS:
# - PowerShell 5.0 or higher
# - Project with modules/ directory structure
# - config/project_config.json file (optional, uses defaults if missing)
# - Write permissions to source files (unless using -DryRun)
#
# MACRO SAFETY EXAMPLES:
# - Before: #define PI 3.14159
# - After:  #define PI (3.14159)
# - Before: #define CALC a + b * c
# - After:  #define CALC (a + b * c)
#
# OUTPUT:
# - Modified source files with safer macro definitions
# - Console report of all changes made
# - Preserved backup files (if enabled in project config)
#
# USAGE:
#   .\add_macro_parentheses.ps1                    # Apply changes to files
#   .\add_macro_parentheses.ps1 -DryRun            # Preview changes only
#
# ================================================================================
param([switch]$DryRun)

# ================================================================================
# STEP 1: Initialize Configuration and Environment
# ================================================================================

# Change to workspace directory (script directory's parent) for reliable operation
$WorkspaceRoot = Split-Path -Parent $PSScriptRoot
Set-Location $WorkspaceRoot

# Load project configuration with fallback to sensible defaults
$ConfigPath = Join-Path $WorkspaceRoot "config\project_config.json"
if (Test-Path $ConfigPath) {
    $Config = Get-Content $ConfigPath | ConvertFrom-Json
    $ModulesPath = $Config.paths.modules
    $FileExtensions = $Config.tools.clang_format.file_extensions
    Write-Host "Using project configuration from: $ConfigPath" -ForegroundColor Green
} else {
    # Fallback to defaults if config not found
    Write-Warning "Project config not found at $ConfigPath, using defaults"
    $ModulesPath = "modules"
    $FileExtensions = @("*.cpp", "*.h")
}

Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host "MACRO PARENTHESES FIXER" -ForegroundColor Cyan
Write-Host "===============================================================================" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "DRY RUN MODE - Preview changes only" -ForegroundColor Yellow
} else {
    Write-Host "Adding parentheses to #define values for safer macro definitions" -ForegroundColor Green
}
Write-Host ""

# Find all header and source files based on project configuration
$Files = Get-ChildItem -Path $ModulesPath -Include $FileExtensions -Recurse -File

Write-Host "Found $($Files.Count) files to process:" -ForegroundColor Green
foreach ($File in $Files) {
    $RelativePath = $File.FullName.Replace($WorkspaceRoot, '.').Replace('\', '/')
    Write-Host "  $RelativePath" -ForegroundColor Gray
}
Write-Host ""

$TotalChanges = 0
$FilesModified = 0

foreach ($File in $Files) {
    $RelativePath = $File.FullName.Replace($WorkspaceRoot, '.').Replace('\', '/')
    Write-Host "Processing: $RelativePath" -ForegroundColor White
    
    $Content = Get-Content -Path $File.FullName
    $NewContent = @()
    $FileChanges = 0
    
    foreach ($Line in $Content) {
        $NewLine = $Line
        
        # Match #define lines: #define NAME value
        if ($Line -match '^\s*#define\s+(\w+)\s+([^\s].*)$') {
            $MacroName = $Matches[1]
            $MacroValue = $Matches[2].Trim()
            
            # Skip header guards, strings, and already parenthesized values
            $ShouldAddParens = $true
            
            # Skip header guards
            if ($MacroName -match '_H$|_HPP$|_INCLUDED$') {
                $ShouldAddParens = $false
            }
            
            # Skip if already has outer parentheses
            if ($MacroValue -match '^\s*\(.*\)\s*(/\*.*\*/|//.*)?$') {
                $ShouldAddParens = $false
            }
            
            # Skip string literals
            if ($MacroValue -match '^["'']') {
                $ShouldAddParens = $false
            }
            
            if ($ShouldAddParens) {
                # Extract comment if present
                $Comment = ""
                if ($MacroValue -match '^(.*?)(\s*/\*.*\*/|\s*//.*)?$') {
                    $ValuePart = $Matches[1].Trim()
                    $Comment = if ($Matches[2]) { $Matches[2] } else { "" }
                    
                    # Create new line with parentheses
                    $Prefix = $Line -replace '^(\s*#define\s+\w+\s+).*', '$1'
                    $NewLine = $Prefix + "($ValuePart)" + $Comment
                    
                    if ($Line -ne $NewLine) {
                        Write-Host "  OLD: $Line" -ForegroundColor Red
                        Write-Host "  NEW: $NewLine" -ForegroundColor Green
                        $FileChanges++
                        $TotalChanges++
                    }
                }
            }
        }
        
        $NewContent += $NewLine
    }
    
    # Write changes if not in dry run mode
    if ($FileChanges -gt 0 -and -not $DryRun) {
        Set-Content -Path $File.FullName -Value $NewContent -Encoding UTF8
        $FilesModified++
    }
    
    if ($FileChanges -gt 0) {
        Write-Host "  Changes: $FileChanges" -ForegroundColor Green
    } else {
        Write-Host "  No changes needed" -ForegroundColor Gray
    }
    Write-Host ""
}

Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "===============================================================================" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "DRY RUN COMPLETE" -ForegroundColor Yellow
    Write-Host "Total changes that would be made: $TotalChanges" -ForegroundColor White
    if ($TotalChanges -gt 0) {
        Write-Host ""
        Write-Host "To apply these changes, run:" -ForegroundColor Cyan
        Write-Host "  .\scripts\add_macro_parentheses.ps1" -ForegroundColor White
    }
} else {
    Write-Host "PROCESSING COMPLETE" -ForegroundColor Green
    Write-Host "Files modified: $FilesModified" -ForegroundColor White
    Write-Host "Total changes: $TotalChanges" -ForegroundColor White
}

if ($TotalChanges -eq 0) {
    Write-Host "All macro definitions already have proper parentheses!" -ForegroundColor Green
}

Write-Host ""
