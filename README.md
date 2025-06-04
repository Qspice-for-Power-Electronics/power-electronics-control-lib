# Power Electronics Control Library

A comprehensive collection of control modules and utilities for power electronics applications, designed for integration with QSPICE simulations.

## Features

- **IIR Filters**: Digital filter implementation for signal processing
- **PWM Generation**: Flexible PWM module with phase shift capabilities
- **QSPICE Integration**: Ready-to-use modules for QSPICE simulations
- **Extensible Architecture**: Easy to add new control modules

## Project Structure

```
├── build/              # Build artifacts
├── config/             # Configuration files
│   └── .clang-format  # Code formatting rules
├── docs/              # Documentation
│   └── api/          # API documentation
├── src/              # Source code
│   └── modules/      # Modular components
│       ├── filters/  # Signal processing filters
│       │   └── iir/  # IIR filter module
│       │       ├── iir.h
│       │       ├── iir.cpp
│       │       └── iir.def
│       ├── pwm/      # PWM generation module
│       │   ├── pwm.h
│       │   ├── pwm.cpp
│       │   └── pwm.def
│       └── qspice_modules/ # QSPICE integration
│           ├── ctrl.cpp
│           └── ctrl.def
├── tests/           # Test files
│   └── modules/     # Module tests
└── build_all.bat   # Build script
```

## Building the Project

### Prerequisites

1. **Digital Mars C++ (DMC) Compiler**
   - Download from [Digital Mars website](https://digitalmars.com/download/freecompiler.html)
   - Add the DMC bin directory to your system PATH
   - Verify installation: Run `dmc -v` in terminal

2. **LLVM/Clang**
   - Download LLVM from [LLVM releases](https://releases.llvm.org/)
   - Add LLVM bin directory to your system PATH
   - Verify installation: Run `clang-format --version` in terminal

### Building

1. Open PowerShell in the project directory
2. Run the build script:
   ```powershell
   .\build_all.bat
   ```
3. The script will:
   - Format all source files using clang-format
   - Compile all .cpp files into object files
   - Link them into ctrl.dll
   - Place build artifacts in the `build` directory
   - Copy the final DLL to the root directory

### Build Output
- `ctrl.dll`: The main library file (in root directory)
- Build artifacts (in `build` directory):
  - `.obj` files: Compiled object files
  - `.map` file: Linker map file
  - `.def` file: Module definition file

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

#### PowerShell Execution Policy
Before running tests, you may need to adjust PowerShell's execution policy. You have two options:

1. **Temporary Policy Override (Recommended)**
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\scripts\run_tests.ps1
   ```

2. **Permanent Policy Change** (Administrative PowerShell)
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

#### Running Tests

1. **Run All Tests**
   ```powershell
   .\scripts\run_tests.ps1
   ```
   Or with execution policy bypass:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\scripts\run_tests.ps1
   ```

2. **Test Specific Module**
   ```powershell
   .\scripts\run_tests.ps1 -Module pwm
   ```

3. **Show Detailed Output**
   ```powershell
   .\scripts\run_tests.ps1 -ShowOutput
   ```

#### Test Structure
- Each module has its own test directory under `tests/modules/`
- Test files are named `test_*.cpp`
- Module tests are configured via `.testconfig` files

#### Available Test Suites
- **PWM Tests**: Verify PWM signal generation and timing
- **IIR Filter Tests**: Validate filter response and stability
- **Power Electronics Tests**: Integration tests for complete system

#### Test Configuration
Each module's `.testconfig` file specifies:
- Include paths
- Source files
- Dependencies
- Test files

#### CI/CD Integration
- Tests run automatically on push to master
- Test results available in GitHub Actions
- Artifacts uploaded for successful builds

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
