# QSPICE Template Usage Guide

## Overview
This template provides a standardized structure for creating QSPICE integration modules that use power electronics components from the project library.

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
qspice_template/
├── qspice_module.cpp     # Main QSPICE integration implementation
├── qspice_module.def     # DLL export definition file
└── TEMPLATE_USAGE.md     # This usage guide
```

## Quick Start

### 1. Copy the Template
```powershell
Copy-Item -Recurse "modules\templates\qspice_template" "modules\qspice_modules\your_module_name"
```

### 2. Rename Files
```powershell
cd "modules\qspice_modules\your_module_name"
Rename-Item "qspice_module.cpp" "your_module_name.cpp"
Rename-Item "qspice_module.def" "your_module_name.def"
```

### 3. Update Export Definition
Edit `your_module_name.def`:
```
LIBRARY "your_module_name.dll"
DESCRIPTION 'Your Module Description as a DLL'
EXETYPE NT
SUBSYSTEM WINDOWS
CODE SHARED EXECUTE
DATA WRITE
EXPORTS
your_module_name
```

### 4. Replace Template Markers
Search and replace all `[REPLACE: ...]` markers with your specific content:

- **File headers**: Update author, date, brief description
- **Function names**: Replace "qspice_module" with your actual function name
- **Pin mappings**: Update input/output pin assignments
- **Dependencies**: Include required power electronics module headers
- **Logic**: Implement your specific control algorithm

### 5. Update Build Configuration
Add your module to `config/project_config.json`:
```json
"your_module_name": {
  "path": "modules/qspice_modules/your_module_name",
  "sources": ["your_module_name.cpp"],
  "headers": [],
  "definition_file": "your_module_name.def",
  "output_dll": "your_module_name.dll",
  "dependencies": ["iir", "pwm"]  // List your power electronics dependencies
}
```

### 6. Handle Include Paths for Dependencies

#### Automatic Method (Recommended)
The project includes automatic dependency detection. After adding your module to the configuration:

1. **Run Project Cleanup** (automatically updates dependencies):
   ```powershell
   .\scripts\project_cleanup.bat
   ```
   
   This script will:
   - Scan your source files for `#include` statements
   - Automatically detect which power electronics modules you're using
   - Update the `dependencies` array in `project_config.json`
   - Ensure proper include paths are available during compilation

2. **Manual Update** (if needed):
   ```powershell
   .\scripts\update_dependencies.ps1
   ```

#### Manual Method
If you need to manually specify dependencies, update the `dependencies` array in your module configuration:

```json
"your_module_name": {
  "dependencies": [
    "cpwm",      // For PWM generation
    "iir",       // For filtering
    "bpwm",      // For bipolar PWM
    "epwm"       // For enhanced PWM
  ]
}
```

#### Common Include Path Issues
- **Error**: `fatal error: 'cpwm.h' file not found`
- **Solution**: Add `cpwm` to your dependencies array
- **Verification**: Check that the dependency module exists in `project_config.json`

#### Available Power Electronics Modules
Current modules you can depend on:
- `cpwm` - Complementary PWM generation
- `bpwm` - Bipolar PWM control  
- `epwm` - Enhanced PWM with advanced features
- `iir` - Infinite Impulse Response filters
- Add more as they become available in the project

## Implementation Guidelines

### Pin Mapping Strategy
1. **Count your pins** in QSPICE schematic symbol
2. **Map inputs first** (data[0], data[1], ...)
3. **Map outputs next** (data[N], data[N+1], ...)
4. **Use const for inputs**, references for outputs:
   ```cpp
   float const  input1  = data[0].f;   // Read-only input
   float&       output1 = data[5].f;   // Read-write output
   ```

### Module Initialization Pattern
```cpp
// Static instances persist across calls
static YourModule module;
static int initialized = 0;

if (!initialized) {
    YourModuleParams params = { /* your parameters */ };
    your_module_init(&module, &params);
    initialized = 1;
}
```

### Timing Considerations
- **Continuous logic**: Executes every simulation timestep
- **Digital logic**: Use edge detection for periodic execution:
  ```cpp
  static bool prev_clk = false;
  if (clock_signal && !prev_clk) {
      // Digital controller code here
  }
  prev_clk = clock_signal;
  ```

### Error Handling
- QSPICE modules should never crash
- Handle invalid inputs gracefully
- Use bounds checking for parameters
- Initialize all outputs to safe values

## Step-by-Step Example: Creating a PI Controller Module

### 1. Setup
```powershell
Copy-Item -Recurse "modules\templates\qspice_template" "modules\qspice_modules\pi_controller"
cd "modules\qspice_modules\pi_controller"
Rename-Item "qspice_module.cpp" "pi_controller.cpp"
Rename-Item "qspice_module.def" "pi_controller.def"
```

### 2. Key Replacements
- `qspice_module` → `pi_controller`
- Add PI controller logic and state variables
- Include appropriate headers (maybe custom PI module)

### 3. Pin Configuration
```cpp
// Inputs
float const reference = data[0].f;  // Reference signal
float const feedback  = data[1].f;  // Feedback signal
float const enable    = data[2].f;  // Enable signal

// Outputs  
float& control_output = data[3].f;  // PI controller output
float& error_signal   = data[4].f;  // Error for monitoring
```

### 4. Implementation
```cpp
// PI controller logic
float error = reference - feedback;
if (enable > 0.5f) {
    // PI calculation here
    control_output = pi_calculate(&pi_module, error);
} else {
    control_output = 0.0f;
    pi_reset(&pi_module);  // Reset integrator when disabled
}
error_signal = error;
```

## Advanced Features

### Multiple Module Integration
```cpp
static iir_t      lpf;      // Low-pass filter
static PwmModule  pwm;      // PWM generator  
static PiModule   pi_ctrl;  // PI controller

// Chain modules together
pi_ctrl.in.error = reference - feedback;
pi_step(&pi_ctrl);

iir_step(&lpf, pi_ctrl.out.control);

pwm.in.duty = lpf.outputs.y;
pwm_module_step(&pwm);
```

### Debug Outputs
Use unused output pins for debugging:
```cpp
float& debug1 = data[10].f;  // Debug output 1
float& debug2 = data[11].f;  // Debug output 2

debug1 = internal_state_variable;
debug2 = static_cast<float>(step_counter);
```

### Performance Optimization
- Minimize floating-point operations in tight loops
- Use static variables to avoid repeated initialization
- Consider fixed-point arithmetic for high-frequency operations
- Profile execution time if real-time performance is critical

## Testing Your Module

### 1. Build Test
```powershell
scripts\build_all.bat
```

### 2. QSPICE Integration Test
1. Create simple test circuit in QSPICE
2. Connect basic inputs (step, ramp, sine wave)
3. Monitor outputs with probes
4. Verify expected behavior

### 3. Performance Test
- Check execution time with QSPICE's profiling
- Verify numerical stability over long simulations
- Test edge cases (zero inputs, maximum values)

## Common Patterns

### State Machine Implementation
```cpp
enum ControlState { INIT, RUNNING, FAULT };
static ControlState state = INIT;

switch (state) {
    case INIT:
        // Initialization logic
        if (start_signal > 0.5f) state = RUNNING;
        break;
    case RUNNING:
        // Normal operation
        if (fault_signal > 0.5f) state = FAULT;
        break;
    case FAULT:
        // Fault handling
        if (reset_signal > 0.5f) state = INIT;
        break;
}
```

### Hysteresis Control
```cpp
static bool output_state = false;
float threshold_high = 1.0f;
float threshold_low  = 0.0f;

if (!output_state && input > threshold_high) {
    output_state = true;
} else if (output_state && input < threshold_low) {
    output_state = false;
}
output = output_state ? 1.0f : 0.0f;
```

## Troubleshooting

### Build Issues
- **Missing dependencies**: Check `#include` statements and project config
- **Include path errors**: Run `.\scripts\project_cleanup.bat` to auto-update dependencies
- **Module not found**: Verify the dependency module exists in `config/project_config.json`
- **Export errors**: Verify function name matches .def file
- **Linking errors**: Ensure all required power electronics modules are built

### Runtime Issues
- **Module not loading**: Check DLL dependencies with Dependency Walker
- **Incorrect behavior**: Verify pin mappings with QSPICE symbol
- **Performance issues**: Profile and optimize critical code paths

### QSPICE Integration Issues
- **Symbol mismatch**: Ensure pin count matches between symbol and code
- **Data type errors**: Use `.f` for float access in uData union
- **Simulation instability**: Check for numerical issues or uninitialized outputs

## Best Practices

### Code Organization
- Keep QSPICE interface minimal, implement logic in power electronics modules
- Use clear variable names that match schematic labels
- Comment pin mappings clearly
- Separate initialization from runtime logic

### Documentation
- Document parameter ranges and units
- Include typical use cases and examples
- Maintain version history

### Version Control
- Commit working versions before major changes
- Tag releases with version numbers
- Keep backup of working configurations

## Getting Help

- **Examples**: Study existing modules in `modules/qspice_modules/`
- **Build system**: Check `scripts/project_config.py --help`
- **Power electronics**: Review modules in `modules/power_electronics/`
- Review project documentation in main `README.md`
- **QSPICE docs**: Refer to QSPICE documentation for interface details

## Frequently Asked Questions

### Q: Do I need to manually manage include paths?
**A: No!** The project includes automatic dependency detection. Simply:
1. Add your `#include` statements to your source files
2. Run `.\scripts\project_cleanup.bat` 
3. The script will automatically scan your includes and update dependencies

### Q: What if I get "file not found" errors during compilation?
**A: This usually means missing dependencies.** Solutions:
1. **First try**: Run `.\scripts\project_cleanup.bat` (fixes 90% of cases)
2. **If that fails**: Check that the header file exists in the project
3. **Manual fix**: Add the missing module to your `dependencies` array

### Q: How often should I run project cleanup?
**A: Run it whenever you add new #include statements or dependencies.** 
- Safe to run anytime (it only improves code quality)
- Automatically run by the build process
- Good practice: run before committing changes

### Q: Can project cleanup break my code?
**A: No, it only makes safe improvements:**
- Adds `const` where appropriate
- Formats code consistently  
- Updates dependencies automatically
- Removes unused includes
- All changes improve code quality without changing functionality
