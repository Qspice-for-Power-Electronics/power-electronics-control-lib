# Run all tests in the test directory
param(
    [Parameter(Mandatory=$false)]
    [string]$Module = ""
)

$testDir = "tests\modules"
if ($Module) {
    $testDir = Join-Path $testDir $Module
}

# Compile and run tests
Write-Host "Compiling and running tests in $testDir..."

Get-ChildItem -Path $testDir -Filter "test_*.cpp" -Recurse | ForEach-Object {
    $testFile = $_.FullName
    $testName = $_.BaseName
    $outFile = "$($_.DirectoryName)\$($_.BaseName).exe"
    
    Write-Host "Compiling $testName..."
    
    # Compile test
    & dmc -mn -I"src\modules\filters\iir" -I"src\modules\pwm" -I"src\modules\qspice_modules" $testFile
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Running $testName..."
        & $outFile
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$testName PASSED" -ForegroundColor Green
        } else {
            Write-Host "$testName FAILED" -ForegroundColor Red
        }
    } else {
        Write-Host "Compilation of $testName FAILED" -ForegroundColor Red
    }
}
