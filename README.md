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
│   │   ├── filters/          # Signal processing filters
│   │   │   └── iir/         # IIR filter implementation
│   │   │       ├── iir.h
│   │   │       ├── iir.cpp
│   │   │       ├── iir.def
│   │   │       └── README.md
│   │   └── pwm/             # PWM generation module
│   │       ├── pwm.h
│   │       ├── pwm.cpp
│   │       ├── pwm.def
│   │       └── README.md
│   └── qspice_modules/       # QSPICE integration modules
│       └── ctrl/            # Control module
│           ├── ctrl.cpp
│           ├── ctrl.def
│           └── README.md
├── config/                    # Configuration files
│   ├── .clang-format         # Code formatting rules
│   └── project_config.json   # Centralized project configuration
├── scripts/                   # Build and utility scripts
│   ├── build_all.bat         # Main build script
│   ├── cleanup_code.bat      # Code quality improvement
│   ├── project_config.py     # Configuration parser
│   ├── project_config.bat    # Windows config wrapper
│   ├── ProjectConfig.psm1    # PowerShell config module
│   └── README.md             # Scripts documentation
├── .vscode/                   # VS Code configuration
│   ├── c_cpp_properties.json # IntelliSense settings
│   └── tasks.json            # Build tasks
└── build/                     # Build artifacts (auto-generated)
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
   - Go to [Digital Mars GitHub repository](https://github.com/DigitalMars/dmc)
   - Download the repository as ZIP or clone it
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

# Clean up code quality (preview first)
.\scripts\cleanup_code.bat --dry-run
.\scripts\cleanup_code.bat

# View project configuration
python scripts\project_config.py --summary
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

#### `scripts\cleanup_code.bat` - Comprehensive Code Cleanup
Advanced code quality improvement tool with automatic fixes.

**Features:**
- ✅ **Const Correctness:** Automatically adds `const` where appropriate
- ✅ **Code Formatting:** Applies consistent style with clang-format
- ✅ **Include Cleanup:** Removes unnecessary `#include` statements
- ✅ **C++11 Modernization:** Updates code to modern C++ standards
- ✅ **Performance Fixes:** Optimizes copy operations and move semantics
- ✅ **Readability:** Improves variable names and code structure
- ✅ **Dry-Run Mode:** Preview changes before applying
- ✅ **Automatic Backups:** Saves original files before modification

**Usage:**
```powershell
# Preview changes without modifying files
.\scripts\cleanup_code.bat --dry-run

# Apply all automatic fixes
.\scripts\cleanup_code.bat
```

**Requirements:**
- LLVM/Clang tools (clang-format, clang-tidy)
- Project must be built (runs build automatically if needed)

**Output:**
- Modified source files with fixes applied
- Backup files in `backup/` directory
- Detailed quality report showing remaining issues

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
2. **Clean Build Artifacts** - Remove all build files and temporary objects
3. **Code Cleanup** - Run comprehensive code quality improvements
4. **Build All Modules** - Compile all modules (Default: Ctrl+Shift+B)

**IntelliSense Configuration:**
- Automatic C++ code completion with local compiler headers
- Error detection and highlighting
- Include path resolution for all modules and DMC system headers
- No external dependencies required

### Workflow Recommendations

#### Daily Development
1. **Code normally** in VS Code with IntelliSense
2. **Build frequently:** `Ctrl+Shift+B` or `.\build_all.bat`
3. **Test in QSPICE** using generated DLL files

#### Before Committing
1. **Preview cleanup:** `.\scripts\cleanup_code.bat --dry-run`
2. **Apply fixes:** `.\scripts\cleanup_code.bat`
3. **Build and test:** `.\build_all.bat`
4. **Review changes:** `git diff`
5. **Commit:** Clean, formatted, and quality-checked code

#### Adding New Modules
1. **Update configuration:** Edit `config\project_config.json`
2. **Create files:** Follow existing module structure
3. **Build automatically:** Configuration system handles the rest

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
- Create DLLs in root directory for QSPICE

See the **Building and Development Tools** section above for detailed information about all available tools and workflows.

## Adding New Modules

The project uses a centralized configuration system in `config/project_config.json`. When adding modules, you have two options:

### Option A: Automatic Detection (Recommended)
1. **Create module structure following existing patterns**
2. **Build automatically** - the system will detect new modules
3. **Update configuration** if you want explicit control

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

**Configuration Management:**
- **Preferred:** Update `config/project_config.json` for explicit control
- **Alternative:** Follow naming patterns for automatic detection
- Use configuration system for complex dependencies

**File Naming:**
- Use consistent naming: `modulename.h`, `modulename.cpp`, `modulename.def`
- Match folder name with module name  
- Configuration file overrides automatic detection

**Code Structure:**
- Include necessary headers from power electronics modules
- Export functions in `.def` files for proper linking
- Follow existing examples for QSPICE interface patterns
- Dependencies automatically resolved via configuration

**Documentation:**
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

# Verify QSPICE modules  
python scripts\project_config.py --qspice-modules
```

## Modules

### Power Electronics
- **IIR Filter** (`modules/power_electronics/filters/iir/`)
  - Digital IIR filtering implementation
  
- **PWM Modules** (`modules/power_electronics/pwm/`)
  - **BPWM Module** (`modules/power_electronics/pwm/bpwm/`) - Basic PWM generation with phase shift capabilities
  - **EPWM Module** (`modules/power_electronics/pwm/epwm/`) - Enhanced PWM module (ready for implementation)

### QSPICE Modules
- **Control Module** (`modules/qspice_modules/ctrl/`)
  - Example control module integrating power electronics components
  - Each QSPICE module is self-contained in its folder
  - Automatically detected and built by build script

## Development

### Code Style
- Automatic formatting with clang-format
- Configuration in `config/.clang-format`

### Module Structure
- Keep modules self-contained in their directories
- Include README.md in each module folder
- Follow existing naming conventions

## License

This work is dedicated to the public domain under CC0 1.0.
Please use it for good and beneficial purposes!
