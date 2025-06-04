# Power Electronics Control Library API Documentation

## Core Modules

### IIR Filter Module
The IIR (Infinite Impulse Response) filter module provides digital filtering capabilities for signal processing in power electronics applications.

#### Types
- `IirParams`: Configuration parameters for the IIR filter
- `IirModule`: Main filter module structure
- `IirInputs`: Filter input signals
- `IirOutputs`: Filter output signals

#### Functions
- `iir_module_init`: Initialize the IIR filter module
- `iir_module_step`: Process one step of filtering

### PWM Module
The PWM (Pulse Width Modulation) module generates flexible PWM signals with phase shift capabilities.

#### Types
- `PwmParams`: Configuration parameters for PWM generation
- `PwmModule`: Main PWM module structure
- `PwmInputs`: PWM input signals
- `PwmOutputs`: PWM output signals

#### Functions
- `pwm_module_init`: Initialize the PWM module
- `pwm_module_step`: Generate one step of PWM output

## Examples
See the `examples/` directory for practical usage examples of each module.
