# Module Templates

This directory contains standardized templates for creating different types of modules in the Power Electronics Control Library.

## Template Types

### 1. Power Electronics Template (`power_electronics_template/`)
For creating reusable power electronics components (filters, controllers, generators, etc.) that can be used across multiple QSPICE simulations.

**Use for:**
- Signal processing modules (filters, transforms)
- Control algorithms (PI, PID, state machines)
- Power conversion components (rectifiers, inverters)
- Mathematical utilities (integrators, differentiators)
- Hardware abstractions (ADC, PWM, GPIO)

**Key Features:**
- MISRA C compliant structure
- Microcontroller-friendly implementation
- Pure C interface for maximum compatibility
- Standardized parameter/state/output organization
- Ready for integration into QSPICE modules

### 2. QSPICE Template (`qspice_template/`)
For creating QSPICE integration modules that combine multiple power electronics components into simulation-ready DLLs.

**Use for:**
- Complete control systems
- System-level simulations
- Multi-module integrations
- QSPICE-specific interfaces
- Simulation controllers

**Key Features:**
- QSPICE interface boilerplate
- Proper pin mapping patterns
- Module initialization handling
- Integration with power electronics library
- Performance-optimized structure

## Quick Selection Guide

| **I want to create...** | **Use Template** | **Output Location** |
|-------------------------|------------------|---------------------|
| A reusable filter module | `power_electronics_template` | `modules/power_electronics/filters/` |
| A PI controller component | `power_electronics_template` | `modules/power_electronics/control/` |
| A QSPICE motor controller | `qspice_template` | `modules/qspice_modules/` |
| A mathematical function | `power_electronics_template` | `modules/power_electronics/math/` |
| A complete system simulation | `qspice_template` | `modules/qspice_modules/` |

## Usage Instructions

### Creating a Power Electronics Module

```powershell
# 1. Copy template
Copy-Item -Recurse "modules\templates\power_electronics_template" "modules\power_electronics\category\your_module"

# 2. Rename files 
cd "modules\power_electronics\category\your_module"
Rename-Item "module.h" "your_module.h"
Rename-Item "module.c" "your_module.cpp"  
Rename-Item "module.def" "your_module.def"

# 3. Edit files and replace [REPLACE: ...] markers
# 4. Build: scripts\build_all.bat
```

### Creating a QSPICE Module

```powershell  
# 1. Copy template
Copy-Item -Recurse "modules\templates\qspice_template" "modules\qspice_modules\your_module"

# 2. Rename files
cd "modules\qspice_modules\your_module" 
Rename-Item "qspice_module.cpp" "your_module.cpp"
Rename-Item "qspice_module.def" "your_module.def"

# 3. Edit files and replace [REPLACE: ...] markers
# 4. Update project config if needed
# 5. Build: scripts\build_all.bat
```

## Template Contents

### Power Electronics Template Files
- **`module.h`**: Header with type definitions and function prototypes
- **`module.c`**: Implementation with init/reset/step functions
- **`module.def`**: DLL definition for build system
- **`qspice_module_template.cpp`**: Example QSPICE integration
- **`README.md`**: Documentation template
- **`TEMPLATE_USAGE.md`**: Detailed usage instructions

### QSPICE Template Files  
- **`qspice_module.cpp`**: Main QSPICE interface implementation
- **`qspice_module.def`**: DLL export definition
- **`README.md`**: Module documentation template
- **`TEMPLATE_USAGE.md`**: Detailed usage instructions

## Integration Workflow

### Typical Development Flow
1. **Power Electronics Module**: Create reusable component
2. **Test Component**: Build and verify functionality
3. **QSPICE Integration**: Create QSPICE module using component
4. **System Test**: Validate in complete simulation
5. **Documentation**: Update README and usage examples

### Example: Creating a Complete Filter System

```powershell
# Step 1: Create the filter component
Copy-Item -Recurse "modules\templates\power_electronics_template" "modules\power_electronics\filters\butterworth"
# ... implement Butterworth filter logic ...

# Step 2: Create QSPICE integration  
Copy-Item -Recurse "modules\templates\qspice_template" "modules\qspice_modules\filter_system"
# ... integrate Butterworth filter into QSPICE module ...

# Step 3: Build everything
scripts\build_all.bat

# Result: 
# - Reusable butterworth filter component
# - filter_system.dll ready for QSPICE
```

## Best Practices

### Module Design
- **Single Responsibility**: Each module should have one clear purpose
- **Stateless Design**: Minimize persistent state where possible  
- **Parameter Validation**: Always validate input parameters
- **Documentation**: Include usage examples and parameter descriptions

### File Organization
- **Consistent Naming**: Use module name consistently across all files
- **Clear Hierarchy**: Organize by functionality (filters/, control/, math/)
- **Self-Contained**: Each module directory should be independent

### Development Process
- **Template First**: Always start from templates for consistency
- **Replace All Markers**: Ensure no `[REPLACE: ...]` remain in final code
- **Test Early**: Build and test frequently during development
- **Document Changes**: Update README.md with specific module information

## Configuration Integration

### Automatic Detection
The build system automatically detects modules following naming conventions:
- Files named `module_name.cpp` with matching `module_name.def`
- Located in appropriate directory structure
- Headers included automatically

### Explicit Configuration
For complex dependencies, update `config/project_config.json`:
```json
{
  "modules": {
    "power_electronics": {
      "components": {
        "your_module": {
          "path": "modules/power_electronics/category/your_module",
          "sources": ["your_module.cpp"],
          "headers": ["your_module.h"],
          "dependencies": ["other_module"]
        }
      }
    }
  }
}
```

## Troubleshooting

### Common Issues
- **Build Failures**: Check that all `[REPLACE: ...]` markers are removed
- **Missing Dependencies**: Verify includes and configuration
- **Runtime Errors**: Ensure proper module initialization

### Getting Help
- **Template Issues**: Check `TEMPLATE_USAGE.md` in each template
- **Build Problems**: Run `scripts\project_config.py --summary`  
- **Examples**: Study existing modules for patterns
- **Documentation**: Review main project `README.md`

## Contributing

When improving templates:
1. **Test Thoroughly**: Verify templates work with build system
2. **Update Documentation**: Keep usage guides current
3. **Maintain Compatibility**: Ensure changes work with existing modules
4. **Follow Standards**: Maintain MISRA C compliance and coding style

---

**Remember**: These templates are designed to save time and ensure consistency. Always start with a template rather than creating modules from scratch!
