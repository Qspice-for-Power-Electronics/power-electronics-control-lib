# Run all tests in the test directory
param(
    [Parameter(Mandatory=$false)]
    [string]$Module = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$ShowOutput
)

# Initialize counters
$testsPassed = 0
$testsFailed = 0
$testsSkipped = 0

function Write-TestLog {
    param(
        [string]$Message,
        [string]$Level = "Info"
    )
    
    $color = switch($Level) {
        "Error" { "Red" }
        "Warning" { "Yellow" }
        "Success" { "Green" }
        default { "White" }
    }
    
    if ($Level -eq "Error" -or $ShowOutput) {
        Write-Host $Message -ForegroundColor $color
    }
}

function Get-TestConfig {
    param(
        [string]$TestPath
    )
    
    $configPath = Join-Path (Split-Path $TestPath) ".testconfig"
    if (Test-Path $configPath) {
        try {
            return Get-Content $configPath | ConvertFrom-Json
        } catch {
            Write-TestLog "Failed to parse test configuration: $_" -Level "Error"
            return $null
        }
    }
    return $null
}

function Build-TestExecutable {
    param(
        [string]$TestFile,
        [PSObject]$Config
    )
    
    $testName = [System.IO.Path]::GetFileNameWithoutExtension($TestFile)
    $outFile = Join-Path (Split-Path $TestFile) "$testName.exe"    # Build include paths relative to project root
    $projectRoot = (Get-Item $PSScriptRoot).Parent.FullName
    $includeArgs = @()
    $includeArgs += "-I`"$projectRoot\src`""  # Add base src directory
    
    if ($Config -and $Config.include_paths) {
        foreach($path in $Config.include_paths) {
            $fullPath = Join-Path $projectRoot $path
            $includeArgs += "-I`"$fullPath`""
        }
    }
    
    Write-TestLog "Compiling $testName..." -Level "Info"
    Write-TestLog "Include paths: $($includeArgs -join ' ')" -Level "Info"
    
    # Build the command array
    $dmc_args = @("-mn")
    $dmc_args += $includeArgs
    $dmc_args += $TestFile
    
    # Run DMC with all arguments properly separated
    $compileResult = & dmc $dmc_args 2>&1
    if ($LASTEXITCODE -eq 0) {
        return $true
    } else {
        Write-TestLog "Compilation failed: $compileResult" -Level "Error"
        return $false
    }
}

function Run-Test {
    param(
        [string]$TestFile
    )
    
    $testName = [System.IO.Path]::GetFileNameWithoutExtension($TestFile)
    $testDir = Split-Path $TestFile
    $config = Get-TestConfig -TestPath $TestFile
    
    # Skip if no config found
    if (-not $config) {
        Write-TestLog "Skipping $testName - No test configuration found" -Level "Warning"
        $script:testsSkipped++
        return
    }
    
    # Build test
    if (-not (Build-TestExecutable -TestFile $TestFile -Config $config)) {
        Write-TestLog "Failed to build $testName" -Level "Error"
        $script:testsFailed++
        return
    }
    
    # Run test
    Write-TestLog "Running $testName..." -Level "Info"
    $exePath = Join-Path $testDir "$testName.exe"
    $testOutput = & $exePath 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-TestLog "$testName PASSED" -Level "Success"
        if ($ShowOutput) {
            Write-TestLog $testOutput -Level "Info"
        }
        $script:testsPassed++
    } else {
        Write-TestLog "$testName FAILED" -Level "Error"
        Write-TestLog $testOutput -Level "Error"
        $script:testsFailed++
    }
}

# Main execution
$testDir = "tests\modules"
if ($Module) {
    $testDir = Join-Path $testDir $Module
}

Write-TestLog "Looking for tests in $testDir..." -Level "Info"

# Run all tests
Get-ChildItem -Path $testDir -Filter "test_*.cpp" -Recurse | ForEach-Object {
    Run-Test -TestFile $_.FullName
}

# Print summary
Write-Host "`nTest Summary:"
Write-Host "Passed: $testsPassed" -ForegroundColor Green
if ($testsFailed -gt 0) {
    Write-Host "Failed: $testsFailed" -ForegroundColor Red
}
if ($testsSkipped -gt 0) {
    Write-Host "Skipped: $testsSkipped" -ForegroundColor Yellow
}

# Set exit code
if ($testsFailed -gt 0) {
    exit 1
} else {
    exit 0
}
