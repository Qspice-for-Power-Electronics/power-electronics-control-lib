# *************************** In The Name Of God ***************************
# * @file    ProjectConfig.psm1
# * @brief   PowerShell module for project configuration management
# * @author  Dr.-Ing. Hossein Abedini
# * @date    2025-06-08
# * Provides easy access to project configuration for VS Code and PowerShell
# * users working with the power electronics control library.
# * @note    Designed for real-time signal processing applications.
# * @license This work is dedicated to the public domain under CC0 1.0.
# *          Please use it for good and beneficial purposes!
# ***************************************************************************

# ================================================================================
# Power Electronics Control Library - PowerShell Configuration Module
# ================================================================================
# 
# This PowerShell module provides easy access to project configuration data
# stored in config/project_config.json. It offers functions for retrieving
# compilation settings, file paths, and build configuration information.
#
# WHAT THIS MODULE PROVIDES:
# 1. Get-ProjectConfig - Loads and parses the main configuration file
# 2. Get-IncludePaths - Returns compiler include paths
# 3. Get-SourceFiles - Lists all C/C++ source files in the project
# 4. Get-BuildOrder - Returns the correct module build sequence
# 5. Get-CompilerFlags - Provides compiler flags for DMC
# 6. Test-ProjectStructure - Validates project directory structure
#
# REQUIREMENTS:
# - PowerShell 5.0 or higher
# - config/project_config.json file in project root
# - Properly structured modules/ directory
#
# USAGE:
#   Import-Module .\scripts\ProjectConfig.psm1
#   $config = Get-ProjectConfig
#   $includePaths = Get-IncludePaths
#   $sourceFiles = Get-SourceFiles
#
# ================================================================================

# ================================================================================
# STEP 1: Core Configuration Loading Functions
# ================================================================================

# Load project configuration from JSON file with comprehensive error handling
function Get-ProjectConfig {
    <#
    .SYNOPSIS
    Loads and parses the project configuration JSON file
    
    .DESCRIPTION
    Reads the project configuration from config/project_config.json and returns
    a PowerShell object with all configuration data including paths, build settings,
    and module definitions.
    
    .PARAMETER ConfigFile
    Path to the configuration file (default: config/project_config.json)
    
    .EXAMPLE
    $config = Get-ProjectConfig
    Write-Host "Project: $($config.project.name)"
    #>
    param(
        [string]$ConfigFile = "config/project_config.json"
    )
    
    if (-not (Test-Path $ConfigFile)) {
        throw "Configuration file '$ConfigFile' not found. Expected location: $((Resolve-Path .).Path)\$ConfigFile"
    }
    
    try {
        return Get-Content $ConfigFile | ConvertFrom-Json
    }
    catch {
        throw "Failed to parse configuration file '$ConfigFile': $($_.Exception.Message)"
    }
}

# ================================================================================
# STEP 2: Path and File Discovery Functions
# ================================================================================

# Get include paths for compilation with proper path resolution
function Get-IncludePaths {
    <#
    .SYNOPSIS
    Returns all include paths needed for compilation
    
    .DESCRIPTION
    Extracts include paths from the project configuration and returns them
    as a list suitable for compiler command-line arguments.
    
    .EXAMPLE
    $includes = Get-IncludePaths
    $includeFlags = $includes | ForEach-Object { "-I$_" }
    #>
    $config = Get-ProjectConfig
    $paths = @()
    
    foreach ($path in $config.build_config.include_paths) {
        $paths += $path
    }
    
    return $paths
}

# Get all source files
function Get-SourceFiles {
    param(
        [string]$ModuleType = $null,
        [string]$Component = $null
    )
    
    $config = Get-ProjectConfig
    $files = @()
    
    foreach ($moduleType in $config.modules.PSObject.Properties.Name) {
        if ($ModuleType -and $moduleType -ne $ModuleType) { continue }
        
        foreach ($componentName in $config.modules.$moduleType.components.PSObject.Properties.Name) {
            if ($Component -and $componentName -ne $Component) { continue }
            
            $component = $config.modules.$moduleType.components.$componentName
            foreach ($sourceFile in $component.sources) {
                $fullPath = Join-Path $component.path $sourceFile
                $files += $fullPath
            }
        }
    }
    
    return $files
}

# Get compiler flags
function Get-CompilerFlags {
    $config = Get-ProjectConfig
    $flags = $config.build_config.common_flags
    
    # Add include paths
    foreach ($path in (Get-IncludePaths)) {
        $flags += "-I`"$path`""
    }
    
    return $flags
}

# Get QSPICE modules
function Get-QSpiceModules {
    $config = Get-ProjectConfig
    $modules = @()
    
    if ($config.modules.qspice_modules) {
        foreach ($componentName in $config.modules.qspice_modules.components.PSObject.Properties.Name) {
            $component = $config.modules.qspice_modules.components.$componentName
            $modules += @{
                Name = $componentName
                Path = $component.path
                Sources = $component.sources
                DefinitionFile = $component.definition_file
                OutputDll = $component.output_dll
                Dependencies = $component.dependencies
            }
        }
    }
    
    return $modules
}

# Display project summary
function Show-ProjectSummary {
    $config = Get-ProjectConfig
    
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "PROJECT: $($config.project.name)" -ForegroundColor Green
    Write-Host "VERSION: $($config.project.version)" -ForegroundColor Green
    Write-Host "AUTHOR:  $($config.project.author)" -ForegroundColor Green
    Write-Host "================================================================================" -ForegroundColor Cyan
      Write-Host "`nMODULES:" -ForegroundColor Yellow
    foreach ($moduleType in $config.modules.PSObject.Properties.Name) {
        Write-Host "  ${moduleType}:" -ForegroundColor White
        foreach ($componentName in $config.modules.$moduleType.components.PSObject.Properties.Name) {
            $component = $config.modules.$moduleType.components.$componentName
            $sourceCount = $component.sources.Count
            $headerCount = $component.headers.Count
            Write-Host "    - ${componentName}: $sourceCount sources, $headerCount headers" -ForegroundColor Gray
        }
    }
    
    Write-Host "`nINCLUDE PATHS:" -ForegroundColor Yellow
    foreach ($path in (Get-IncludePaths)) {
        Write-Host "  - $path" -ForegroundColor Gray
    }
}

# Export functions for module use
Export-ModuleMember -Function Get-ProjectConfig, Get-IncludePaths, Get-SourceFiles, Get-CompilerFlags, Get-QSpiceModules, Show-ProjectSummary
