# Contributing to Power Electronics Control Library

We love your input! We want to make contributing to this library as easy and transparent as possible, whether it's:

- Reporting a bug
- Discussing the current state of the code
- Submitting a fix
- Proposing new modules
- Becoming a maintainer

## Development Process

We use GitHub to host code, to track issues and feature requests, as well as accept pull requests.

1. Fork the repo and create your branch from `master`
2. If you've added code that should be tested, add tests
3. If you've changed APIs, update the documentation
4. Ensure the test suite passes
5. Make sure your code follows the style guidelines
6. Issue that pull request!

## Module Development Guidelines

### Code Style
- Follow the C++ style guide enforced by clang-format
- Use meaningful variable and function names
- Add comprehensive comments for complex algorithms
- Keep functions focused and modular

### Module Structure
Each module should have:
1. Clear parameter structure for configuration
2. Well-defined input/output interfaces
3. Initialization function
4. Step function for processing
5. Comprehensive unit tests
6. Documentation including:
   - Mathematical model
   - Usage examples
   - Performance characteristics

### Example Module Template
```cpp
struct ModuleParams {
    float param1;
    float param2;
    // ... other parameters
};

struct ModuleInputs {
    float input1;
    float input2;
    // ... other inputs
};

struct ModuleOutputs {
    float output1;
    float output2;
    // ... other outputs
};

struct Module {
    ModuleParams params;
    ModuleInputs in;
    ModuleOutputs out;
};

int module_init(Module* mod, const ModuleParams* params);
void module_step(Module* mod);
```

## Testing Requirements
- Each module must have unit tests
- Tests should cover:
  - Initialization
  - Normal operation
  - Edge cases
  - Error conditions
- Use test_module.cpp template in tests directory

## Documentation Requirements
1. README.md in module directory
2. API documentation in header files
3. Usage examples
4. Performance benchmarks

## Pull Request Process
1. Update the README.md with details of changes if needed
2. Update the development roadmap if adding new features
3. The PR will be merged once you have the sign-off of at least one maintainer

## Any contributions you make will be under the Software License
In short, when you submit code changes, your submissions are understood to be under the same [LICENSE](LICENSE) that covers the project. Feel free to contact the maintainers if that's a concern.
