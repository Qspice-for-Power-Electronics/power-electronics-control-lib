# BPWM Module

## Overview
Basic Digital PWM (Pulse Width Modulation) generation module for power electronics control in the WPT simulation project.

## Features
- Configurable PWM parameters
- Center-aligned and edge-aligned modes
- Phase shift capability
- Clock output for synchronization

## Usage
```cpp
// Initialize BPWM
bpwm_params_t params = {
    10e-6f,                        // Ts: Sampling time
    BPWM_CARRIER_CENTER_ALIGNED,   // carrier_select
    15.0f,                         // gate_on_voltage
    0.0f                           // gate_off_voltage
};
bpwm_t bpwm;
bpwm_init(&bpwm, &params);

// Execute BPWM step
bpwm_step(&bpwm, current_time, 0.5f, 0.0f);  // 50% duty cycle, no phase shift
```

## API Reference
See `bpwm.h` for detailed API documentation.
