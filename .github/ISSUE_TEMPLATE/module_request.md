<!-- ************************** In The Name Of God ************************** -->
<!-- * @file    module_request.md                                             -->
<!-- * @brief   GitHub issue template for requesting new power electronics    -->
<!-- *          modules                                                       -->
<!-- * @author  Dr.-Ing. Hossein Abedini                                     -->
<!-- * @date    2025-06-08                                                    -->
<!-- * Template for standardized module requests to ensure consistency       -->
<!-- * in module development and documentation.                              -->
<!-- * @note    Designed for real-time signal processing applications.       -->
<!-- * @license This work is dedicated to the public domain under CC0 1.0.   -->
<!-- *          Please use it for good and beneficial purposes!              -->
<!-- ************************************************************************* -->

---
name: Module Request
about: Suggest a new control module for the library
title: '[MODULE] '
labels: 'enhancement, new module'
assignees: ''
---

**Module Description**
A clear and concise description of what the module should do.

**Use Case**
Describe the power electronics application where this module would be useful.

**Expected Interface**
```cpp
// Describe the expected input/output interface
struct ModuleParams {
    // Configuration parameters
};

struct ModuleInputs {
    // Input signals
};

struct ModuleOutputs {
    // Output signals
};
```

**Additional Context**
- [ ] Mathematical model or equations
- [ ] Reference to academic papers or designs
- [ ] Example application circuit
- [ ] Performance requirements
