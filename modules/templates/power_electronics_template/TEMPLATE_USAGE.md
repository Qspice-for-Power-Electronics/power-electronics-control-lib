# Power Electronics Template Usage Guide

## Overview
This template provides a standardized structure for creating reusable power electronics modules that can be used across multiple QSPICE simulations.

## Features
- MISRA C:2012 compliant implementation
- Configurable parameters
- State management with reset capability
- Real-time processing capability
- Simple void function interface
- Direct input parameters to step function
- C-compatible interface optimized for microcontrollers
- Minimal memory footprint

## Template Structure
```
power_electronics_template/
├── module.h                    # Header with type definitions and function prototypes
├── module.c                    # Implementation file
├── module.def                  # Module definition for DLL creation
├── qspice_module_template.cpp  # QSPICE integration example
└── TEMPLATE_USAGE.md          # This usage guide
```

## Quick Start

### 1. Copy the Template
```powershell
Copy-Item -Recurse "modules\templates\power_electronics_template" "modules\power_electronics\your_module_name"
```

### 2. Rename Files
```powershell
cd "modules\power_electronics\your_module_name"
Rename-Item "module.h" "your_module_name.h"
Rename-Item "module.c" "your_module_name.cpp"
Rename-Item "module.def" "your_module_name.def"
```

### 3. Replace Template Markers
Search and replace all `[REPLACE: ...]` markers with your specific content:

- **File headers**: Update author, date, brief description
- **Module name**: Replace "module" with your actual module name
- **Parameters**: Define your specific configuration parameters
- **State variables**: Add your internal state requirements
- **Outputs**: Define your module's output signals
- **Constants**: Add module-specific #define values

### 4. Update Build Configuration
Add your module to `config/project_config.json`:
```json
"your_module_name": {
  "path": "modules/power_electronics/your_module_name",
  "sources": ["your_module_name.cpp"],
  "headers": ["your_module_name.h"],
  "dependencies": []
}
```

## Implementation Guidelines

### MISRA C Compliance
- Use `const` qualifiers appropriately
- Avoid dynamic memory allocation
- Use explicit type casting
- Initialize all variables
- Limit function parameters

### Naming Conventions
- **Types**: `your_module_params_t`, `your_module_state_t`, `your_module_t`
- **Functions**: `your_module_init()`, `your_module_reset()`, `your_module_step()`
- **Constants**: `YOUR_MODULE_PARAM_MAX`, `YOUR_MODULE_DEFAULT_VALUE`

### Module Structure
1. **Parameters**: Configuration values set at initialization
2. **State**: Internal variables that persist between calls
3. **Outputs**: Results of processing that external code can access
4. **Functions**: 
   - `init()`: Copy parameters and call reset
   - `reset()`: Clear state to default values
   - `step()`: Execute one processing iteration

### Testing Your Module
1. Build with the main project: `scripts\build_all.bat`
2. Create a simple QSPICE integration using the provided template
3. Test in QSPICE simulation environment

## Example Workflow

### Creating a Low-Pass Filter Module
```powershell
# 1. Copy template
Copy-Item -Recurse "modules\templates\power_electronics_template" "modules\power_electronics\filters\lpf"

# 2. Rename files
cd "modules\power_electronics\filters\lpf"
Rename-Item "module.h" "lpf.h"
Rename-Item "module.c" "lpf.cpp"
Rename-Item "module.def" "lpf.def"

# 3. Edit files to implement low-pass filter logic
# 4. Update project configuration
# 5. Build and test
```

### Key Replacements for LPF Example
- `module` → `lpf`
- `MODULE` → `LPF`
- `param1` → `cutoff_frequency`
- `param2` → `sample_time`
- `internal_value` → `previous_output`
- `output_signal` → `filtered_value`

## Integration with QSPICE

Use the included `qspice_module_template.cpp` as a starting point for creating QSPICE modules that use your power electronics module:

1. Include your module header
2. Map QSPICE pins to your module inputs/outputs
3. Handle initialization and step execution
4. Create corresponding `.def` file for DLL export

## Best Practices

- **Testing**: Create unit tests for critical functionality
- **Dependencies**: Minimize external dependencies
- **Performance**: Optimize for real-time execution
- **Portability**: Avoid platform-specific code

## Troubleshooting

### Common Issues
1. **Build Errors**: Check that all `[REPLACE: ...]` markers are removed
2. **Linking Issues**: Verify `.def` file exports correct functions
3. **Runtime Errors**: Ensure proper initialization in QSPICE integration

### Getting Help
- Check existing modules in `modules/power_electronics/` for examples
- Review project documentation in main `README.md`
- Use project configuration tools: `scripts\project_config.py --help`