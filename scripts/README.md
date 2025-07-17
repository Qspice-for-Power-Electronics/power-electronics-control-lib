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

This directory contains utility scripts for maintaining and improving the codebase.

## Available Scripts

### `cleanup_code.bat`
Comprehensive code cleanup and quality improvement script.

**Features:**
- ✅ **Macro Parentheses Safety**: Automatically adds parentheses around `#define` values
- ✅ Automatic const correctness enforcement
- ✅ Code formatting with clang-format
- ✅ Unnecessary include removal
- ✅ C++11 modernization fixes
- ✅ Performance optimizations
- ✅ Readability improvements
- ✅ Comprehensive quality reporting
- ✅ Dry-run mode for preview
- ✅ Automatic backups

**Usage:**
```batch
# Apply all fixes
.\scripts\cleanup_code.bat

# Preview changes without modifying files
.\scripts\cleanup_code.bat --dry-run
```

**Requirements:**
- LLVM/Clang tools (clang-format, clang-tidy)
- Digital Mars Compiler (dmc)
- Built project (runs build_all.bat if needed)

**Output:**
- Modified source files with automatic fixes
- Backup files in `backup/` directory
- Detailed quality report
- Remaining issues that need manual attention

### `add_macro_parentheses.ps1`
Standalone script for adding parentheses around `#define` values to prevent operator precedence issues.

**Features:**
- ✅ Scans all source files for `#define` statements
- ✅ Adds parentheses around values that don't already have them
- ✅ Preserves existing parentheses and string literals
- ✅ Skips header guards and other special macros
- ✅ Dry-run mode for preview
- ✅ Detailed change reporting

**Usage:**
```powershell
# Preview changes without modifying files
.\scripts\add_macro_parentheses.ps1 -DryRun

# Apply parentheses fixes
.\scripts\add_macro_parentheses.ps1
```

**Example:**
```cpp
// Before:
#define FREQ_50HZ  50.0f  /**< 50 Hz frequency */

// After:
#define FREQ_50HZ  (50.0f)  /**< 50 Hz frequency */
```

**Note:** This functionality is also integrated into `cleanup_code.bat` as Phase 1.5.

## Workflow Integration

These scripts are designed to work with the main build process:

1. **Development:** Write code normally
2. **Cleanup:** Run `cleanup_code.bat` to apply automatic improvements
3. **Build:** Run `build_all.bat` to compile and test
4. **Review:** Check `git diff` to review automatic changes
5. **Commit:** Commit cleaned and formatted code

## Code Quality Standards

The cleanup script enforces these standards:
- **Macro Safety:** Parentheses around all `#define` values to prevent precedence issues
- Const correctness for all variables and parameters
- Consistent formatting following project .clang-format rules
- Modern C++11 features (nullptr, auto, override)
- Optimal performance (avoid unnecessary copies)
- Clean includes (remove unused headers)
- Readable and maintainable code structure
