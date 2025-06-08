# QSPICE Modules

## Overview
QSPICE-specific implementations for the WPT simulation project. These modules provide the interface between the simulation engine and the control algorithms.

## Components
- Controller interface (`ctrl.cpp`)
- Signal routing and processing
- QSPICE-specific data handling

## Usage
The modules in this directory are designed to work with QSPICE simulation environment. They handle:
- Data conversion between QSPICE and internal formats
- Signal routing to appropriate processing modules
- Integration with other modules (PWM, filters, etc.)

## Integration
See `ctrl.cpp` for the main integration point with QSPICE.
