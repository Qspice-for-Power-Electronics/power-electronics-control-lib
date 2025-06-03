# PWM Module

## Overview
Digital PWM (Pulse Width Modulation) generation module for power electronics control in the WPT simulation project.

## Features
- Configurable PWM parameters
- Center-aligned and edge-aligned modes
- Phase shift capability
- Clock output for synchronization

## Usage
```cpp
// Initialize PWM
PwmParams params = {
    10e-6f,   // Ts: Sampling time
    0,        // carrier_select
    15.0f     // gate_on_voltage
};
PwmModule pwm;
pwm_module_init(&pwm, &params);

// Update PWM
pwm.in.t = current_time;
pwm.in.duty = 0.5f;    // 50% duty cycle
pwm.in.phase = 0.0f;   // No phase shift
pwm_module_step(&pwm);
```

## API Reference
See `pwm.h` for detailed API documentation.
