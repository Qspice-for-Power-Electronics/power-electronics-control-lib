# *************************** In The Name Of God ***************************
# * @file    format_json.ps1
# * @brief   PowerShell script to format JSON files consistently
# * @author  Dr.-Ing. Hossein Abedini
# * @date    2025-06-22
# * Formats all JSON files in the project with consistent 2-space indentation
# * @note    Designed for real-time signal processing applications.
# * @license This work is dedicated to the public domain under CC0 1.0.
# *          Please use it for good and beneficial purposes!
# ***************************************************************************

# ================================================================================
# Power Electronics Control Library - JSON Formatter
# ================================================================================
# 
# This script formats all JSON files in the project with consistent indentation
# and validates JSON syntax to ensure configuration files are properly formatted.
#
# WHAT THIS SCRIPT DOES:
# 1. Scans for JSON files in config/ and .vscode/ directories
# 2. Validates JSON syntax and reports errors
# 3. Formats JSON with consistent 2-space indentation
# 4. Preserves all data while improving readability
# 5. Creates clean, professional JSON formatting
#
# ================================================================================

param(
    [switch]$DryRun,     # Preview changes without modifying files
    [switch]$Verbose     # Show detailed processing information
)

# Enable strict error handling
$ErrorActionPreference = "Stop"

Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host "JSON FORMATTER" -ForegroundColor Cyan
Write-Host "===============================================================================" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "DRY RUN MODE - Preview changes only" -ForegroundColor Yellow
} else {
    Write-Host "Formatting JSON files with consistent indentation" -ForegroundColor Green
}
Write-Host ""

# Define JSON file locations to process
$JsonLocations = @(
    "config/*.json",
    ".vscode/*.json"
)

$FilesProcessed = 0
$FilesFormatted = 0
$ErrorCount = 0

# Process each location
foreach ($location in $JsonLocations) {
    $files = Get-ChildItem -Path $location -ErrorAction SilentlyContinue
    
    foreach ($file in $files) {
        $FilesProcessed++
        
        if ($Verbose) {
            Write-Host "Processing: $($file.FullName)" -ForegroundColor Gray
        } else {
            Write-Host "[$FilesProcessed] Formatting $($file.Name)..." -ForegroundColor Green
        }
        
        try {
            # Load and validate JSON
            $jsonContent = Get-Content $file.FullName -Raw
            $jsonObject = $jsonContent | ConvertFrom-Json
            
            # Format with consistent indentation
            $formattedJson = $jsonObject | ConvertTo-Json -Depth 10
            $formattedJson = $formattedJson -replace '    ', '  '  # Convert 4-space to 2-space
            
            # Compare with original to see if changes are needed
            $originalFormatted = $jsonContent | ConvertFrom-Json | ConvertTo-Json -Depth 10
            $originalFormatted = $originalFormatted -replace '    ', '  '
            
            if ($formattedJson -ne $originalFormatted) {
                if ($DryRun) {
                    Write-Host "  Would format: $($file.Name)" -ForegroundColor Yellow
                } else {
                    $formattedJson | Set-Content $file.FullName -Encoding UTF8
                    Write-Host "  Formatted: $($file.Name)" -ForegroundColor Green
                    $FilesFormatted++
                }
            } else {
                if ($Verbose) {
                    Write-Host "  No changes needed: $($file.Name)" -ForegroundColor Gray
                }
            }
            
        } catch {
            Write-Host "  Error processing $($file.Name): $($_.Exception.Message)" -ForegroundColor Red
            $ErrorCount++
        }
    }
}

# Summary
Write-Host "`n===============================================================================" -ForegroundColor Cyan
Write-Host "JSON FORMATTING SUMMARY" -ForegroundColor Cyan
Write-Host "===============================================================================" -ForegroundColor Cyan

Write-Host "Files processed: $FilesProcessed" -ForegroundColor White

if ($DryRun) {
    Write-Host "Files that would be formatted: $FilesFormatted" -ForegroundColor Yellow
    Write-Host "`nTo apply changes, run: .\scripts\format_json.ps1" -ForegroundColor Yellow
} else {
    Write-Host "Files formatted: $FilesFormatted" -ForegroundColor Green
}

if ($ErrorCount -gt 0) {
    Write-Host "Errors encountered: $ErrorCount" -ForegroundColor Red
} else {
    Write-Host "No errors detected" -ForegroundColor Green
}

Write-Host "===============================================================================" -ForegroundColor Cyan

# Exit with error count
exit $ErrorCount
