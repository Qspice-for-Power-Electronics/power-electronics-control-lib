# *************************** In The Name Of God ***************************
# * @file    update_dependencies.ps1
# * @brief   PowerShell script to automatically update module dependencies
# * @author  Dr.-Ing. Hossein Abedini
# * @date    2025-06-22
# * Automatically scans #include statements in source files and updates
# * the dependencies array in project_config.json for accurate build order.
# * @note    Designed for real-time signal processing applications.
# * @license This work is dedicated to the public domain under CC0 1.0.
# *          Please use it for good and beneficial purposes!
# ***************************************************************************

# ================================================================================
# Power Electronics Control Library - Automatic Dependency Updater
# ================================================================================
# 
# This script automatically detects module dependencies by scanning #include
# statements in source files and updates the project_config.json file with
# accurate dependency information.
#
# WHAT THIS SCRIPT DOES:
# 1. Scans all C/C++ source files for #include statements
# 2. Maps header files to their corresponding modules
# 3. Builds dependency graph based on include relationships
# 4. Updates project_config.json with detected dependencies
# 5. Validates dependency cycles and reports issues
#
# DETECTION LOGIC:
# - Scans for #include "module.h" statements (local includes)
# - Maps header names to module names in configuration
# - Excludes system headers and STL includes
# - Handles both relative and absolute include paths
#
# ================================================================================

param(
    [switch]$DryRun,     # Preview changes without modifying files
    [switch]$Verbose     # Show detailed processing information
)

# Enable strict error handling
$ErrorActionPreference = "Stop"

# ================================================================================
# STEP 1: Initialize Configuration and Paths
# ================================================================================

$WorkspaceRoot = Get-Location
$ConfigFile = "config/project_config.json"

Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host "AUTOMATIC DEPENDENCY UPDATER" -ForegroundColor Cyan
Write-Host "===============================================================================" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "DRY RUN MODE - Preview changes only" -ForegroundColor Yellow
} else {
    Write-Host "Scanning includes and updating dependencies" -ForegroundColor Green
}
Write-Host ""

# Check if configuration file exists
if (-not (Test-Path $ConfigFile)) {
    Write-Host "Error: Configuration file '$ConfigFile' not found" -ForegroundColor Red
    exit 1
}

# ================================================================================
# STEP 2: Load and Parse Project Configuration
# ================================================================================

Write-Host "Loading project configuration..." -ForegroundColor Green
try {
    $Config = Get-Content $ConfigFile | ConvertFrom-Json
} catch {
    Write-Host "Error: Failed to parse $ConfigFile" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Build header-to-module mapping
$HeaderToModule = @{}
$AllModules = @{}

foreach ($moduleType in $Config.modules.PSObject.Properties.Name) {
    foreach ($componentName in $Config.modules.$moduleType.components.PSObject.Properties.Name) {
        $component = $Config.modules.$moduleType.components.$componentName
        $AllModules[$componentName] = $component
        
        # Map each header file to its module
        foreach ($header in $component.headers) {
            $headerName = Split-Path $header -Leaf
            $HeaderToModule[$headerName] = $componentName
            if ($Verbose) {
                Write-Host "  Mapping: $headerName -> $componentName" -ForegroundColor Gray
            }
        }
    }
}

Write-Host "Found $($AllModules.Count) modules with $($HeaderToModule.Count) headers" -ForegroundColor Green

# ================================================================================
# STEP 3: Scan Source Files for Include Dependencies
# ================================================================================

Write-Host "`nScanning source files for #include statements..." -ForegroundColor Green

$Dependencies = @{}
$FileCount = 0

# Initialize dependencies for all modules
foreach ($moduleName in $AllModules.Keys) {
    $Dependencies[$moduleName] = @()
}

# Scan all source files
foreach ($moduleType in $Config.modules.PSObject.Properties.Name) {
    foreach ($componentName in $Config.modules.$moduleType.components.PSObject.Properties.Name) {
        $component = $Config.modules.$moduleType.components.$componentName
        $modulePath = $component.path
        
        # Scan each source file
        foreach ($sourceFile in $component.sources) {
            $fullPath = Join-Path $modulePath $sourceFile
            $FileCount++
            
            if (Test-Path $fullPath) {
                if ($Verbose) {
                    Write-Host "  Scanning: $fullPath" -ForegroundColor Gray
                }
                
                $content = Get-Content $fullPath
                foreach ($line in $content) {
                    # Match #include "header.h" statements (local includes)
                    if ($line -match '^\s*#include\s+"([^"]+)"') {
                        $includedHeader = $matches[1]
                        $headerName = Split-Path $includedHeader -Leaf
                        
                        # Check if this header belongs to a known module
                        if ($HeaderToModule.ContainsKey($headerName)) {
                            $dependentModule = $HeaderToModule[$headerName]
                            
                            # Don't add self-dependency
                            if ($dependentModule -ne $componentName) {
                                if ($Dependencies[$componentName] -notcontains $dependentModule) {
                                    $Dependencies[$componentName] += $dependentModule
                                    if ($Verbose) {
                                        Write-Host "    Found dependency: $componentName -> $dependentModule" -ForegroundColor Yellow
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                Write-Host "  Warning: Source file not found: $fullPath" -ForegroundColor Yellow
            }
        }
    }
}

Write-Host "Scanned $FileCount source files" -ForegroundColor Green

# ================================================================================
# STEP 4: Validate Dependencies and Check for Cycles
# ================================================================================

Write-Host "`nValidating dependencies..." -ForegroundColor Green

function Test-CircularDependency {
    param($Dependencies, $StartModule, $Visited = @())
    
    if ($Visited -contains $StartModule) {
        return $true  # Cycle detected
    }
    
    $Visited += $StartModule
    
    foreach ($dep in $Dependencies[$StartModule]) {
        if (Test-CircularDependency $Dependencies $dep $Visited) {
            return $true
        }
    }
    
    return $false
}

$HasCycles = $false
foreach ($module in $Dependencies.Keys) {
    if (Test-CircularDependency $Dependencies $module) {
        Write-Host "  Warning: Circular dependency detected involving module '$module'" -ForegroundColor Yellow
        $HasCycles = $true
    }
}

if (-not $HasCycles) {
    Write-Host "  No circular dependencies detected" -ForegroundColor Green
}

# ================================================================================
# STEP 5: Update Configuration File
# ================================================================================

Write-Host "`nUpdating dependencies in configuration..." -ForegroundColor Green

$ChangesDetected = $false

foreach ($moduleType in $Config.modules.PSObject.Properties.Name) {
    foreach ($componentName in $Config.modules.$moduleType.components.PSObject.Properties.Name) {
        $component = $Config.modules.$moduleType.components.$componentName
        $currentDeps = @()
        if ($component.dependencies) {
            $currentDeps = @($component.dependencies)
        }
        
        $newDeps = @($Dependencies[$componentName] | Sort-Object)
        
        # Compare current vs detected dependencies
        $depsChanged = $false
        if ($currentDeps.Count -ne $newDeps.Count) {
            $depsChanged = $true
        } else {
            for ($i = 0; $i -lt $currentDeps.Count; $i++) {
                if ($currentDeps[$i] -ne $newDeps[$i]) {
                    $depsChanged = $true
                    break
                }
            }
        }
        
        if ($depsChanged) {
            $ChangesDetected = $true
            Write-Host "  Module '$componentName':" -ForegroundColor White
            Write-Host "    Old: [$($currentDeps -join ', ')]" -ForegroundColor Red
            Write-Host "    New: [$($newDeps -join ', ')]" -ForegroundColor Green
            
            if (-not $DryRun) {
                # Update the configuration
                $Config.modules.$moduleType.components.$componentName.dependencies = $newDeps
            }
        } else {
            if ($Verbose) {
                Write-Host "  Module '$componentName': No changes needed" -ForegroundColor Gray
            }
        }
    }
}

# ================================================================================
# STEP 6: Save Updated Configuration
# ================================================================================

if ($ChangesDetected) {
    if ($DryRun) {
        Write-Host "`nDRY RUN: Configuration changes shown above would be applied" -ForegroundColor Yellow
    } else {
        # Save updated configuration with proper formatting
        $JsonOutput = $Config | ConvertTo-Json -Depth 10
        # Replace 4-space indentation with 2-space for consistency
        $JsonOutput = $JsonOutput -replace '    ', '  '
        $JsonOutput | Set-Content $ConfigFile
        Write-Host "`nConfiguration updated: $ConfigFile" -ForegroundColor Green
    }
} else {
    Write-Host "`nNo dependency changes detected - configuration is up to date" -ForegroundColor Green
}

# ================================================================================
# STEP 7: Summary Report
# ================================================================================

Write-Host "`n===============================================================================" -ForegroundColor Cyan
Write-Host "DEPENDENCY UPDATE SUMMARY" -ForegroundColor Cyan
Write-Host "===============================================================================" -ForegroundColor Cyan

Write-Host "Modules processed: $($AllModules.Count)" -ForegroundColor White
Write-Host "Source files scanned: $FileCount" -ForegroundColor White
Write-Host "Headers mapped: $($HeaderToModule.Count)" -ForegroundColor White

if ($ChangesDetected) {
    Write-Host "Dependencies updated: YES" -ForegroundColor Green
} else {
    Write-Host "Dependencies updated: No changes needed" -ForegroundColor Gray
}

if ($HasCycles) {
    Write-Host "Circular dependencies: WARNING - Please review" -ForegroundColor Yellow
} else {
    Write-Host "Circular dependencies: None detected" -ForegroundColor Green
}

if ($DryRun) {
    Write-Host "`nTo apply changes, run: .\scripts\update_dependencies.ps1" -ForegroundColor Yellow
}

Write-Host "===============================================================================" -ForegroundColor Cyan
