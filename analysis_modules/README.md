# Analysis Modules

Testing and analysis tools for compiled power electronics modules, organized to match the `modules/` directory structure.

## Structure

```
analysis_modules/
├── power_electronics/           # Power electronics module analysis
│   ├── common/                  # Shared utilities and basic tests
│   │   ├── minimal_dll_test.py  # Essential DLL verification
│   │   └── README.md
│   ├── filters/                 # Filter analysis tools
│   │   └── iir/                 # IIR filter testing
│   │       ├── iir_dll_test.py  # Comprehensive IIR analysis
│   │       └── README.md
│   └── pwm/                     # PWM module analysis
│       ├── bpwm/                # Bipolar PWM analysis
│       ├── epwm/                # Enhanced PWM analysis
│       └── README.md
├── qspice_modules/              # QSPICE-specific module analysis
│   ├── ctrl/                    # Control system analysis
│   └── README.md
├── test_dlls.bat                # Interactive test launcher
└── README.md                    # This file
```

## Quick Start

Run the interactive test launcher:
```bash
test_dlls.bat
```

Options:
1. **Basic DLL Test** - Quick verification that all DLLs load correctly
2. **IIR Filter Test** - Comprehensive testing with step response and Bode plots

## Direct Testing

```bash
# Basic DLL verification
python power_electronics\common\minimal_dll_test.py

# IIR filter analysis
python power_electronics\filters\iir\iir_dll_test.py
```

## Requirements

- Python (32-bit recommended for DMC-compiled DLLs)
- Built DLL files in `../build/` directory
- Optional: matplotlib (for plots in advanced tests)

## Philosophy

This directory mirrors the structure of `modules/` to provide corresponding analysis tools for each module type. Each subdirectory contains testing tools specific to that module category, making it easy to locate and run appropriate tests.

Build DLLs first using VS Code task: "Build All Modules"
