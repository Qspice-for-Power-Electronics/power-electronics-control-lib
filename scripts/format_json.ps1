# *************************** In The Name Of God ***************************
# * @file    format_json.ps1
# * @brief   PowerShell script to format JSON and JSONC files consistently
# * @author  Dr.-Ing. Hossein Abedini
# * @date    2025-06-22
# * Formats all JSON and JSONC files in the project with consistent tab indentation
# * @note    Designed for real-time signal processing applications.
# * @license This work is dedicated to the public domain under CC0 1.0.
# *          Please use it for good and beneficial purposes!
# ***************************************************************************

# ================================================================================
# Power Electronics Control Library - JSON Formatter
# ================================================================================
# 
# This script formats all JSON and JSONC files in the project with consistent indentation
# and preserves comments while ensuring proper formatting structure.
#
# WHAT THIS SCRIPT DOES:
# 1. Scans for JSON/JSONC files in config/ and .vscode/ directories
# 2. Preserves comments and structure in JSONC files
# 3. Formats with consistent tab indentation (replacing 4-space groups)
# 4. Maintains all data while improving readability
# 5. Creates clean, professional JSON/JSONC formatting
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
    Write-Host "Formatting JSON and JSONC files with consistent tab indentation" -ForegroundColor Green
}
Write-Host ""

# Define JSON/JSONC file locations to process
$JsonLocations = @(
    "config/*.json",
    ".vscode/*.json"  # JSONC files with comments - now supported
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
        }          try {
            # Read file content line by line for robust formatting
            $lines = Get-Content $file.FullName
            $formattedLines = @()
            $needsFormatting = $false
            $indentLevel = 0
            
            foreach ($line in $lines) {
                $trimmedLine = $line.Trim()
                
                # Skip empty lines and comment lines - preserve as-is
                if ($trimmedLine -eq "" -or $trimmedLine.StartsWith("//") -or $trimmedLine.StartsWith("/*") -or $trimmedLine.StartsWith("*")) {
                    $formattedLines += $line
                    continue
                }
                
                # Determine indentation level based on JSON structure
                # Decrease indent level for closing braces/brackets
                if ($trimmedLine -match '^[\}\]]') {
                    $indentLevel = [Math]::Max(0, $indentLevel - 1)
                }
                
                # Create properly formatted line with tabs
                $newLine = "`t" * $indentLevel + $trimmedLine
                
                # Check if formatting is needed
                if ($line -ne $newLine) {
                    $needsFormatting = $true
                }
                
                $formattedLines += $newLine
                
                # Increase indent level for opening braces/brackets (but not if line also closes)
                if ($trimmedLine -match '[\{\[]$' -and -not ($trimmedLine -match '^[\}\]].*[\{\[]$')) {
                    $indentLevel++
                }
            }
              if ($needsFormatting) {
                if ($DryRun) {
                    Write-Host "  Would format: $($file.Name)" -ForegroundColor Yellow
                    $FilesFormatted++
                } else {
                    try {
                        # Try UTF8NoBOM first (PowerShell 6+)
                        $formattedLines | Set-Content $file.FullName -Encoding UTF8NoBOM
                        Write-Host "  Formatted: $($file.Name)" -ForegroundColor Green
                        $FilesFormatted++
                    } catch {
                        try {
                            # Fallback to UTF8 for PowerShell 5.1
                            $formattedLines | Set-Content $file.FullName -Encoding UTF8
                            Write-Host "  Formatted: $($file.Name) (UTF8 fallback)" -ForegroundColor Green
                            $FilesFormatted++
                        } catch {
                            Write-Host "  Error formatting $($file.Name): $($_.Exception.Message)" -ForegroundColor Red
                            $ErrorCount++
                        }
                    }
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
