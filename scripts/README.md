<!-- ************************** In The Name Of God ************************** -->
<!-- * @file    README.md                                                     -->
<!-- * @brief   Documentation for utility scripts in power electronics        -->
<!-- *          control library                                               -->
<!-- * @author  Dr.-Ing. Hossein Abedini                                     -->
<!-- * @date    2025-06-08                                                    -->
<!-- * Comprehensive documentation for all maintenance and build scripts     -->
<!-- * used in the power electronics control library project.                -->
<!-- * @note    Designed for real-time signal processing applications.       -->
<!-- * @license This work is dedicated to the public domain under CC0 1.0.   -->
<!-- *          Please use it for good and beneficial purposes!              -->
<!-- ************************************************************************* -->

# Power Electronics Control Library - Utility Scripts

This directory contains build, setup, diagnostics, maintenance, and configuration helper scripts.

## Available Scripts

### Build

#### scripts\build\build_all.bat
Build all power electronics and QSPICE modules and produce DLLs.

- Validates required tools (DMC, clang-format)
- Formats source files
- Runs basic quality checks
- Builds modules and outputs DLLs to `output/` (also copied to repo root)

Usage (PowerShell):
```powershell
.\scripts\build\build_all.bat
```

Output:
- DLLs: `output\*.dll` and copies in repo root (e.g., `ctrl.dll`)
- Object files in `output/`

### Maintenance

#### scripts\maintenance\project_cleanup.bat
Comprehensive project cleanup and code-quality improvements.

- Macro safety: add parentheses to `#define` values
- Include cleanup and dependency updates
- Const correctness and modernization
- Formatting with clang-format
- Dry-run mode and detailed logs
- Automatic backups to `backup/` (created when needed)

Usage:
```powershell
# Preview changes
.\scripts\maintenance\project_cleanup.bat --dry-run

# Apply fixes
.\scripts\maintenance\project_cleanup.bat
```

Logs: `logs/` (e.g., `project_cleanup_YYYY-MM-DD_HH-mm-ss.log`)

#### scripts\maintenance\add_macro_parentheses.ps1
Add parentheses around `#define` values to prevent precedence issues.

Usage:
```powershell
# Preview changes
.\scripts\maintenance\add_macro_parentheses.ps1 -DryRun

# Apply fixes
.\scripts\maintenance\add_macro_parentheses.ps1
```

Example:
```cpp
// Before:
#define FREQ_50HZ  50.0f

// After:
#define FREQ_50HZ  (50.0f)
```

#### scripts\maintenance\update_dependencies.ps1
Scan `#include` directives and update `config\project_config.json` dependencies.

Usage:
```powershell
# Preview dependency changes
.\scripts\maintenance\update_dependencies.ps1 -DryRun

# Apply updates
.\scripts\maintenance\update_dependencies.ps1
```

### Diagnostics

#### scripts\diagnostics\Check-Dependencies.ps1
Validate tools and environment (DMC, Python, clang-format, paths).

Usage:
```powershell
.\scripts\diagnostics\Check-Dependencies.ps1
```

Batch wrapper (optional): `scripts\diagnostics\check_dependencies.bat`

### Setup

#### scripts\setup\setup_compiler.ps1
Automated Digital Mars Compiler (DMC) installation and PATH setup.

Usage:
```powershell
# Interactive install
.\scripts\setup\setup_compiler.ps1

# Quiet or force modes
.\scripts\setup\setup_compiler.ps1 -Quiet
.\scripts\setup\setup_compiler.ps1 -Force
```

Batch wrapper: `scripts\setup\setup_compiler.bat`

### Configuration Helpers

#### scripts\config\project_config.py
Query project configuration (include paths, sources, flags, modules).

Examples:
```powershell
python .\scripts\config\project_config.py --summary
python .\scripts\config\project_config.py --include-paths
python .\scripts\config\project_config.py --qspice-modules
```

Batch wrapper: `scripts\config\project_config.bat`

#### scripts\config\format_json.ps1
Format JSON/JSONC files consistently.

Usage:
```powershell
# Preview
.\scripts\config\format_json.ps1 -DryRun

# Apply formatting
.\scripts\config\format_json.ps1
```

## VS Code Tasks Integration

Run from Ctrl+Shift+P → “Tasks: Run Task”:
- Setup Compiler
- Project Cleanup
- Build All Modules (default build)
- Check Dependencies

## Workflow Integration

1. Develop as usual in VS Code
2. Cleanup: `scripts\maintenance\project_cleanup.bat` (use `--dry-run` first)
3. Build: `scripts\build\build_all.bat`
4. Review: `git diff`
5. Commit: clean, formatted, and passing build

## Requirements

- Digital Mars C/C++ (dmc) in PATH
- LLVM tools (clang-format; clang-tidy optional)
- PowerShell 5.0+

## Code Quality Standards (enforced by cleanup)

- Macro safety for `#define` values
- Const correctness
- Modernization (selected C++11 updates)
- Include hygiene
- Consistent formatting per project rules
- Readable, maintainable structure
