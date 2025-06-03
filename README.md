# Power Electronics Control Library

A comprehensive collection of control modules and utilities for power electronics applications, designed for integration with QSPICE simulations.

## Features

- **IIR Filters**: Digital filter implementation for signal processing
- **PWM Generation**: Flexible PWM module with phase shift capabilities
- **QSPICE Integration**: Ready-to-use modules for QSPICE simulations
- **Extensible Architecture**: Easy to add new control modules

## Project Structure

```
├── config/               # Configuration files
│   └── .clang-format    # C++ code formatting rules
├── src/                 # Source code
│   └── modules/         # Modular components
│       ├── filters/     # Signal processing filters
│       │   └── iir/     # IIR filter implementation
│       ├── qspice_modules/ # QSPICE-specific modules
│       └── pwm/         # PWM generation modules
├── tests/               # Test files
│   └── modules/         # Module-specific tests
└── build_all.bat       # Build script
```

## Building the Project

To build the project:

1. Make sure Digital Mars C++ compiler (DMC) is installed and in your PATH
2. Make sure LLVM/Clang is installed for code formatting
3. Run `build_all.bat`

## Modules

### IIR Filter
Located in `src/modules/filters/iir/`, implements digital IIR filtering.

### PWM Module
Located in `src/modules/pwm/`, implements modular digital PWM generation.

### QSPICE Modules
Located in `src/modules/qspice_modules/`, contains QSPICE-specific implementations.

## Development

### Code Style
- Code is automatically formatted using clang-format
- Configuration is in `config/.clang-format`

### Testing
Each module has its corresponding test directory under `tests/modules/`

### Contributing
Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests.

### Module Requests
If you need a specific control module, please use our [module request template](.github/ISSUE_TEMPLATE/module_request.md) to submit your request.

## Roadmap

### Phase 1: Core Control Modules (Q3 2025)
- [x] IIR Filter Implementation
- [x] Basic PWM Generation
- [ ] PID Controller
- [ ] State Space Controller
- [ ] Moving Average Filter

### Phase 2: Advanced Control Features (Q4 2025)
- [ ] Adaptive PID with gain scheduling
- [ ] Sliding Mode Controller
- [ ] Phase-Locked Loop (PLL)
- [ ] Clarke/Park Transformations
- [ ] Space Vector PWM

### Phase 3: System Integration (Q1 2026)
- [ ] Real-time parameter tuning interface
- [ ] Automatic code generation for QSPICE
- [ ] Module chaining and composition
- [ ] Performance optimization suite
- [ ] Extended documentation and examples

### Future Considerations
- Hardware-in-the-loop testing support
- FPGA-ready code generation
- Real-time monitoring and debugging tools

## License
[Your license information here]
