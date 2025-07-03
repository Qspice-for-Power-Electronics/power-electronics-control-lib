**In The Name Of God** - May this work contribute to the betterment of humanity and the advancement of science and technology.

# Power Electronics Control Library

A modular C++ library for power electronics control, designed for seamless QSPICE integration with automatic compiler setup and comprehensive development tools.

## 🚀 Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/Qspice-for-Power-Electronics/power-electronics-control-lib.git
   cd power-electronics-control-lib
   ```

2. **Open in VS Code**
   ```bash
   code .
   ```

3. **Setup compiler automatically**
   - Press `Ctrl+Shift+P` → "Tasks: Run Task" → "Setup Compiler"
   - Or run: `scripts\setup_compiler.bat`

4. **Build everything**
   - Press `Ctrl+Shift+B` (default build task)
   - Or press `Ctrl+Shift+P` → "Tasks: Run Task" → "Build All Modules"

5. **Use in QSPICE**
   - Generated `.dll` files are in the `build/` directory
   - Ready for immediate use in your QSPICE simulations

## Project Structure

```
├── modules/                    # All project modules
│   ├── power_electronics/     # Core power electronics components
│   │   ├── common/           # Shared constants and definitions
│   │   │   └── math_constants.h
│   │   ├── filters/          # Signal processing filters
│   │   │   └── iir/         # IIR filter implementation
│   │   │       ├── iir.h
│   │   │       ├── iir.cpp
│   │   │       └── iir.def
│   │   └── pwm/             # PWM generation modules
│   │       ├── bpwm/        # Basic PWM with phase shift
│   │       │   ├── bpwm.h
│   │       │   ├── bpwm.cpp
│   │       │   └── bpwm.def
│   │       ├── cpwm/        # Complementary PWM generation
│   │       │   ├── cpwm.h
│   │       │   ├── cpwm.cpp
│   │       │   └── cpwm.def
│   │       └── epwm/        # Enhanced PWM with advanced features
│   │           ├── epwm.h
│   │           ├── epwm.cpp
│   │           └── epwm.def
│   ├── qspice_modules/        # QSPICE integration modules
│   │   └── ctrl/             # Control module
│   │       ├── ctrl.cpp
│   │       └── ctrl.def
│   └── templates/            # Module templates for rapid development
│       ├── power_electronics_template/  # Template for power electronics modules
│       │   ├── module.h
│       │   ├── module.c
│       │   ├── module.def
│       │   └── TEMPLATE_USAGE.md
│       └── qspice_template/  # Template for QSPICE modules
│           ├── qspice_module.cpp
│           ├── qspice_module.def
│           └── TEMPLATE_USAGE.md
├── analysis_modules/          # Testing and analysis tools
│   ├── power_electronics/     # Power electronics module analysis
│   │   ├── common/           # Shared utilities and basic tests
│   │   └── filters/          # Filter analysis tools
│   │       └── iir/         # IIR filter testing
│   ├── qspice_modules/        # QSPICE-specific module analysis
│   │   └── ctrl/            # Control system analysis
│   ├── test_dlls.bat         # Interactive test launcher
│   └── README.md             # Analysis documentation
├── analysis/                  # Additional analysis tools
│   └── dll_testing/          # DLL testing utilities
├── config/                    # Configuration files
│   ├── .clang-format         # Code formatting rules
│   ├── .clang-tidy          # Static analysis configuration
│   └── project_config.json   # Centralized project configuration
├── scripts/                   # Build and utility scripts
│   ├── build_all.bat         # Main build script
│   ├── project_cleanup.bat   # Comprehensive code cleanup and quality
│   ├── setup_compiler.ps1    # Automatic Digital Mars Compiler installation
│   ├── setup_compiler.bat    # Batch wrapper for compiler setup
│   ├── add_macro_parentheses.ps1  # Macro safety improvements
│   ├── update_dependencies.ps1    # Automatic dependency detection
│   ├── format_json.ps1       # JSON/JSONC formatting utility
│   ├── project_config.py     # Configuration parser (Python)
│   ├── project_config.bat    # Configuration wrapper (Batch)
│   ├── ProjectConfig.psm1    # Configuration module (PowerShell)
│   └── README.md             # Scripts documentation
├── .vscode/                   # VS Code configuration
│   ├── c_cpp_properties.json # IntelliSense settings
│   └── tasks.json            # Build tasks
├── .github/                   # CI/CD workflows
│   └── workflows/
│       └── ci.yml            # Continuous integration workflow
├── build/                     # Build artifacts (auto-generated)
├── logs/                      # Build and cleanup logs
├── Test.qsch                  # QSPICE test schematic
└── backup/                    # Automatic backups during cleanup
```

## Prerequisites

### Digital Mars C++ (DMC) Compiler

**Option 1: Automatic Setup (Recommended)**
```bash
# Run the setup task in VS Code:
# Ctrl+Shift+P → "Tasks: Run Task" → "Setup Compiler"

# Or run directly:
scripts\setup_compiler.bat
```

**Option 2: Manual Installation**
1. **Download and Install**
   - Go to [Digital Mars Compiler](http://ftp.digitalmars.com/dmc.zip)
   - Download it as ZIP
   - Extract to a directory like `C:\dm`

2. **Add to PATH**
   - Open System Properties (Windows key + Pause/Break)
   - Click "Advanced system settings"
   - Click "Environment Variables"
   - Under "System Variables", find and select "Path", click "Edit"
   - Click "New" and add: `C:\dm\bin` (or your installation path)
   - Click "OK" to close all dialogs
   - Restart your terminal/PowerShell

3. **Verify Installation**
   ```powershell
   dmc -v
   ```
   Should display Digital Mars C/C++ Compiler version information.

### 2. LLVM/Clang (for code formatting)

1. **Download and Install**
   - Go to [LLVM releases](https://releases.llvm.org/)
   - Download the latest Windows installer (e.g., LLVM-17.0.6-win64.exe)
   - Run the installer with default settings

2. **Add to PATH (if not automatically added)**
   - Follow the same PATH steps as above
   - Add: `C:\Program Files\LLVM\bin` (or your installation path)

3. **Verify Installation**
   ```powershell
   clang-format --version
   ```
   Should display clang-format version information.

## Building and Development Tools

### Quick Start
```powershell
# Build everything
.\scripts\build_all.bat

# Run comprehensive project cleanup and quality improvements
.\scripts\project_cleanup.bat

# Preview cleanup changes without modifying files  
.\scripts\project_cleanup.bat --dry-run

# View project configuration
python scripts\project_config.py --summary

# Update module dependencies automatically
.\scripts\update_dependencies.ps1

# Format JSON configuration files
.\scripts\format_json.ps1
```

### Build System

#### `scripts\build_all.bat` - Main Build Script
Comprehensive build system for all project modules.

**Features:**
- ✅ Validates required tools (DMC, clang-format)
- ✅ Cleans previous build artifacts
- ✅ Formats all source code automatically
- ✅ Runs code quality checks with clang-tidy
- ✅ Builds power electronics modules (shared components)
- ✅ Dynamically detects and builds QSPICE modules
- ✅ Creates DLLs ready for QSPICE usage
- ✅ Comprehensive error reporting

**Usage:**
```powershell
.\scripts\build_all.bat
```

**Output:**
- Individual DLL files for each QSPICE module (e.g., `ctrl.dll`)
- Build artifacts in `build/` directory
- Formatted and quality-checked source code

### Code Quality and Maintenance Scripts

#### `scripts\project_cleanup.bat` - Comprehensive Project Cleanup
Advanced code cleanup and quality improvement tool with automatic fixes and dependency management.

**Features:**
- ✅ **Build Artifact Cleanup**: Removes all build files and temporary objects
- ✅ **Macro Safety**: Adds parentheses around `#define` values to prevent precedence issues
- ✅ **Include Cleanup**: Removes unnecessary `#include` statements
- ✅ **Dependency Updates**: Automatically scans and updates module dependencies
- ✅ **Const Correctness**: Automatically adds `const` where appropriate
- ✅ **Code Formatting**: Applies consistent style with clang-format
- ✅ **C++11 Modernization**: Updates code to modern C++ standards
- ✅ **Performance Fixes**: Optimizes copy operations and move semantics
- ✅ **Readability**: Improves variable names and code structure
- ✅ **JSON Formatting**: Formats configuration files consistently
- ✅ **Quality Reporting**: Comprehensive analysis of remaining issues
- ✅ **Dry-Run Mode**: Preview changes before applying
- ✅ **Automatic Backups**: Saves original files before modification

**Usage:**
```powershell
# Preview changes without modifying files
.\scripts\project_cleanup.bat --dry-run

# Apply all automatic fixes and improvements
.\scripts\project_cleanup.bat
```

**Phase-by-Phase Processing:**
1. **Phase 1**: Build artifact cleanup and validation
2. **Phase 1.5**: Macro parentheses safety improvements  
3. **Phase 2**: Include cleanup and optimization
4. **Phase 3**: Automatic dependency detection and updates
5. **Phase 4**: Const correctness and core improvements
6. **Phase 5**: Modernization and performance fixes
7. **Phase 6**: Readability and maintainability improvements
8. **Phase 7**: Code formatting with clang-format
9. **Phase 8**: JSON configuration file formatting
10. **Phase 9**: Comprehensive quality reporting
11. **Phase 10**: Final cleanup of build artifacts

**Requirements:**
- LLVM/Clang tools (clang-format, clang-tidy)
- Digital Mars Compiler (dmc)
- PowerShell 5.0+ for advanced features

**Output:**
- Modified source files with fixes applied
- Backup files in `backup/` directory
- Updated `project_config.json` with accurate dependencies
- Detailed quality report showing remaining issues
- Comprehensive logs in `logs/` directory

#### `scripts\add_macro_parentheses.ps1` - Macro Safety Utility
Standalone PowerShell script for adding parentheses around `#define` values.

**Features:**
- ✅ Scans all C/C++ source and header files
- ✅ Adds parentheses around macro values that don't already have them
- ✅ Preserves existing parentheses and string literals
- ✅ Skips header guards and special macros
- ✅ Dry-run mode for safe preview
- ✅ Detailed change reporting

**Usage:**
```powershell
# Preview changes without modifying files
.\scripts\add_macro_parentheses.ps1 -DryRun

# Apply parentheses fixes
.\scripts\add_macro_parentheses.ps1
```

**Example Transformations:**
```cpp
// Before:
#define FREQ_50HZ  50.0f
#define CALC_POWER voltage * current

// After:  
#define FREQ_50HZ  (50.0f)
#define CALC_POWER (voltage * current)
```

#### `scripts\update_dependencies.ps1` - Automatic Dependency Management
PowerShell script that automatically detects and updates module dependencies by scanning `#include` statements.

**Features:**
- ✅ Scans all source files for `#include "header.h"` statements
- ✅ Maps header files to their corresponding modules
- ✅ Updates `dependencies` arrays in `project_config.json`
- ✅ Validates dependency cycles and reports conflicts
- ✅ Dry-run mode for safe preview
- ✅ Verbose logging for debugging

**Usage:**
```powershell
# Preview dependency changes
.\scripts\update_dependencies.ps1 -DryRun

# Update dependencies automatically
.\scripts\update_dependencies.ps1

# Enable detailed logging
.\scripts\update_dependencies.ps1 -Verbose
```

**Detection Logic:**
- Scans for `#include "module.h"` statements (local includes)
- Excludes system headers and STL includes
- Handles both relative and absolute include paths
- Updates build order based on dependency relationships

#### `scripts\format_json.ps1` - JSON Configuration Formatter
PowerShell utility for formatting JSON and JSONC files with consistent indentation.

**Features:**
- ✅ Formats JSON files in `config/` and `.vscode/` directories
- ✅ Preserves comments in JSONC files
- ✅ Consistent tab indentation throughout
- ✅ Maintains all data while improving readability
- ✅ Dry-run mode for preview

**Usage:**
```powershell
# Preview formatting changes
.\scripts\format_json.ps1 -DryRun

# Apply formatting to all JSON files
.\scripts\format_json.ps1
```

#### `scripts\setup_compiler.ps1` - Automatic Compiler Installation
PowerShell script for automatic Digital Mars Compiler installation and configuration.

**Features:**
- ✅ Downloads DMC from official GitHub repository
- ✅ Handles extraction and proper directory structure
- ✅ Adds compiler to system PATH automatically
- ✅ Verifies existing installations
- ✅ Force re-download option available
- ✅ Quiet mode for CI/CD environments

**Usage:**
```powershell
# Interactive installation
.\scripts\setup_compiler.ps1

# Quiet installation for automation
.\scripts\setup_compiler.ps1 -Quiet

# Force re-download even if already installed
.\scripts\setup_compiler.ps1 -Force
```

### Project Configuration System

#### `config\project_config.json` - Centralized Configuration
Single source of truth for all project settings, paths, and module definitions.

**Contains:**
- Project metadata (name, version, author)
- Module structure and dependencies
- Build configuration (compiler flags, include paths)
- Tool configurations (clang-format, clang-tidy settings)
- File patterns and build order

#### `scripts\project_config.py` - Configuration Parser
Python utility for accessing project configuration programmatically.

**Features:**
- Extract include paths for compilation
- Get source/header files by module or component
- Generate compiler flags automatically
- Access clang-tidy configuration
- List QSPICE modules and dependencies

**Usage:**
```powershell
# Show project summary
python scripts\project_config.py --summary

# Get include paths
python scripts\project_config.py --include-paths

# Get all source files
python scripts\project_config.py --source-files

# Get compiler flags
python scripts\project_config.py --compiler-flags

# Get clang-tidy flags
python scripts\project_config.py --clang-flags

# Filter by module type
python scripts\project_config.py --source-files --module-type power_electronics

# Get QSPICE modules
python scripts\project_config.py --qspice-modules
```

#### `scripts\project_config.bat` - Windows Batch Wrapper
Provides easy access to configuration from batch scripts.

**Usage:**
```powershell
# Used internally by build scripts
scripts\project_config.bat --include-paths
scripts\project_config.bat --compiler-flags
```

#### `scripts\ProjectConfig.psm1` - PowerShell Module
Advanced PowerShell integration for configuration access.

**Usage:**
```powershell
# Import module
Import-Module .\scripts\ProjectConfig.psm1

# Show project summary with colors
Show-ProjectSummary

# Get configuration data
$config = Get-ProjectConfig
$includes = Get-IncludePaths
$sources = Get-SourceFiles
$modules = Get-QSpiceModules
```

### VS Code Integration

The project includes VS Code tasks for seamless development:

**Available Tasks** (Ctrl+Shift+P → "Tasks: Run Task"):
1. **Setup Compiler** - Automatically download and install Digital Mars Compiler
2. **Project Cleanup** - Run comprehensive project cleanup including build artifacts, const correctness, and formatting
3. **Build All Modules** - Compile all modules (Default: Ctrl+Shift+B)

**IntelliSense Configuration:**
- Automatic C++ code completion with local compiler headers
- Error detection and highlighting
- Include path resolution for all modules and DMC system headers
- No external dependencies required

### Continuous Integration

The project includes GitHub Actions workflow for automated building and testing:

**CI Features:**
- ✅ Automatic Digital Mars Compiler installation
- ✅ Build verification for all modules
- ✅ DLL output validation against project configuration
- ✅ Cross-platform Windows environment testing
- ✅ Configuration-driven expected output validation

**Workflow Triggers:**
- Push to `master` branch
- Pull requests to `master` branch

**CI Configuration:** `.github/workflows/ci.yml`

### Workflow Recommendations

#### Daily Development
1. **Code normally** in VS Code with IntelliSense
2. **Build frequently:** `Ctrl+Shift+B` or `.\scripts\build_all.bat`
3. **Test in QSPICE** using generated DLL files

#### Before Committing
1. **Preview cleanup:** `.\scripts\project_cleanup.bat --dry-run`
2. **Apply fixes:** `.\scripts\project_cleanup.bat`
3. **Build and test:** `.\scripts\build_all.bat`
4. **Review changes:** `git diff`
5. **Commit:** Clean, formatted, and quality-checked code

#### Adding New Modules
1. **Use templates:** Copy from `modules/templates/` for quick start
2. **Update configuration:** Edit `config\project_config.json` or use auto-detection
3. **Update dependencies:** Run `.\scripts\update_dependencies.ps1`
4. **Build automatically:** Configuration system handles the rest

#### Maintaining Code Quality
1. **Regular cleanup:** Run `.\scripts\project_cleanup.bat` periodically
2. **Monitor logs:** Check `logs/` directory for detailed analysis
3. **Review backups:** Check `backup/` directory before major changes
4. **Validate dependencies:** Use `.\scripts\update_dependencies.ps1 -Verbose`

## Building
## Quick Build

For immediate use, just run:
```powershell
.\scripts\build_all.bat
```

This will automatically:
- Format all source files
- Run code quality checks  
- Build power electronics modules
- Build QSPICE modules with dependencies
- Create DLLs in build directory for QSPICE

See the **Building and Development Tools** section above for detailed information about all available tools and workflows.

## Adding New Modules

The project provides multiple approaches for creating new modules with comprehensive template support and automatic configuration management.

### Quick Start with Templates

The project includes ready-to-use templates for rapid module development:

#### Using Power Electronics Template
```powershell
# 1. Copy the template
Copy-Item -Recurse "modules\templates\power_electronics_template" "modules\power_electronics\your_module_name"

# 2. Rename files
cd "modules\power_electronics\your_module_name"
Rename-Item "module.h" "your_module_name.h"
Rename-Item "module.c" "your_module_name.cpp"
Rename-Item "module.def" "your_module_name.def"

# 3. Replace template markers
# Search and replace all [REPLACE: ...] markers with your specific content

# 4. Update dependencies automatically
.\scripts\update_dependencies.ps1

# 5. Build and test
.\scripts\build_all.bat
```

#### Using QSPICE Template
```powershell
# 1. Copy the template
Copy-Item -Recurse "modules\templates\qspice_template" "modules\qspice_modules\your_module"

# 2. Customize for your needs
# Edit files and replace template markers

# 3. Update configuration and build
.\scripts\update_dependencies.ps1
.\scripts\build_all.bat
```

### Configuration Options

The project uses a centralized configuration system in `config/project_config.json`. When adding modules, you have two options:

### Option A: Automatic Detection (Recommended)
1. **Create module structure following existing patterns**
2. **Build automatically** - the system will detect new modules
3. **Update dependencies** - run `.\scripts\update_dependencies.ps1`
4. **Update configuration** if you want explicit control

### Option B: Explicit Configuration  
1. **Update `config/project_config.json`** with new module details
2. **Create module files** matching the configuration
3. **Build** - everything works automatically

### Adding New Power Electronics Modules

Power electronics modules (like filters, controllers, etc.) are shared components that can be used by QSPICE modules.

**Example: Adding a new filter module**

1. **Create module structure:**
   ```
   modules/power_electronics/filters/lowpass/
   ├── lowpass.h          # Header file with function declarations
   ├── lowpass.cpp        # Implementation file
   ├── lowpass.def        # Module definition file (optional)
   └── README.md          # Module documentation
   ```

2. **Update configuration (optional but recommended):**
   Edit `config/project_config.json` to add:
   ```json
   "lowpass": {
     "path": "modules/power_electronics/filters/lowpass",
     "sources": ["lowpass.cpp"],
     "headers": ["lowpass.h"],
     "dependencies": []
   }
   ```

3. **Build integration:**
   - No manual changes needed to build scripts
   - Module automatically included in all QSPICE builds  
   - Object files linked with QSPICE modules

### Adding New QSPICE Modules

QSPICE modules are the final DLL outputs used in QSPICE simulations.

1. **Create module folder:**
   ```
   modules/qspice_modules/your_module/
   ├── your_module.cpp    # Implementation with QSPICE interface
   ├── your_module.def    # QSPICE interface definition  
   └── README.md          # Module documentation (optional)
   ```

2. **Update configuration (recommended):**
   Edit `config/project_config.json` to add:
   ```json
   "your_module": {
     "path": "modules/qspice_modules/your_module", 
     "sources": ["your_module.cpp"],
     "headers": [],
     "definition_file": "your_module.def",
     "output_dll": "your_module.dll",
     "dependencies": ["iir", "pwm"]  // List required modules
   }
   ```

3. **Build automatically:**
   - Run `.\scripts\build_all.bat`
   - Script detects new module automatically
   - Creates `your_module.dll` in root directory
   - Proper dependency linking handled automatically

### Module Guidelines

**Template Usage:**
- **Recommended:** Start with templates from `modules/templates/` 
- **Power Electronics:** Use `power_electronics_template/` for reusable components
- **QSPICE Integration:** Use `qspice_template/` for simulation modules
- **Documentation:** Each template includes comprehensive usage guides

**Configuration Management:**
- **Preferred:** Update `config/project_config.json` for explicit control
- **Alternative:** Follow naming patterns for automatic detection
- **Dependencies:** Use `.\scripts\update_dependencies.ps1` for automatic updates
- Use configuration system for complex dependencies

**File Naming:**
- Use consistent naming: `modulename.h`, `modulename.cpp`, `modulename.def`
- Match folder name with module name  
- Configuration file overrides automatic detection

**Code Structure:**
- Include necessary headers from power electronics modules
- Export functions in `.def` files for proper linking
- Follow existing examples for QSPICE interface patterns
- Use templates to ensure MISRA C compliance and best practices
- Dependencies automatically resolved via configuration

**Documentation:**
- Templates include comprehensive documentation templates
- Add README.md explaining module purpose and usage
- Document function parameters and return values  
- Include example usage if applicable
- Update main project documentation for significant modules

**Testing Configuration:**
```powershell
# Verify your module is detected
python scripts\project_config.py --summary

# Check include paths
python scripts\project_config.py --include-paths

# Update and verify dependencies  
.\scripts\update_dependencies.ps1 -Verbose

# Verify QSPICE modules  
python scripts\project_config.py --qspice-modules

# Run comprehensive quality check
.\scripts\project_cleanup.bat --dry-run
```

## Modules

### Power Electronics
- **IIR Filter** (`modules/power_electronics/filters/iir/`)
  - Digital IIR filtering implementation for signal processing
  
- **PWM Modules** (`modules/power_electronics/pwm/`)
  - **BPWM Module** (`modules/power_electronics/pwm/bpwm/`) - Basic PWM generation with phase shift capabilities
  - **CPWM Module** (`modules/power_electronics/pwm/cpwm/`) - Complementary PWM generation
  - **EPWM Module** (`modules/power_electronics/pwm/epwm/`) - Enhanced PWM with center-aligned counter support, dead time, and advanced action modes

- **Common Definitions** (`modules/power_electronics/common/`)
  - **Math Constants** (`modules/power_electronics/common/math_constants.h`) - Shared mathematical constants and definitions

### QSPICE Modules
- **Control Module** (`modules/qspice_modules/ctrl/`)
  - Example control module integrating power electronics components
  - Each QSPICE module is self-contained in its folder
  - Automatically detected and built by build script

### Templates
- **Power Electronics Template** (`modules/templates/power_electronics_template/`)
  - Complete template for creating reusable power electronics modules
  - MISRA C:2012 compliant implementation
  - Includes comprehensive usage guide and examples
  
- **QSPICE Template** (`modules/templates/qspice_template/`)
  - Template for creating QSPICE integration modules
  - Complete interface examples and documentation

## Development

### Code Style
- Automatic formatting with clang-format
- Configuration in `config/.clang-format`
- Static analysis with clang-tidy (config in `config/.clang-tidy`)
- Comprehensive quality checks via `.\scripts\project_cleanup.bat`

### Module Structure
- Keep modules self-contained in their directories
- Use provided templates for consistency and best practices
- Include comprehensive documentation in each module folder
- Follow existing naming conventions
- Use automatic dependency detection for accurate build order

### Quality Assurance
- **Macro Safety**: Automatic parentheses around `#define` values
- **MISRA C Compliance**: Templates enforce embedded programming standards
- **Const Correctness**: Automatic detection and correction
- **Modern C++**: Selective C++11 improvements while maintaining compatibility
- **Performance**: Optimization for real-time applications
- **Documentation**: Comprehensive inline and external documentation

### Project Maintenance
- **Logs**: Detailed build and cleanup logs in `logs/` directory
- **Backups**: Automatic backups during cleanup operations in `backup/` directory
- **Dependencies**: Automatic detection and updates of module dependencies
- **Configuration**: Centralized management via `config/project_config.json`

## License

This work is dedicated to the public domain under CC0 1.0.
Please use it for good and beneficial purposes!
