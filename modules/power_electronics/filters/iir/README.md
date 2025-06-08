# IIR Filter Module

## Overview
Digital IIR (Infinite Impulse Response) filter implementation for signal processing in the WPT simulation project.

## Features
- Configurable filter parameters (Ts, fc, type, a)
- Low-pass filter implementation
- Real-time signal processing capability

## Usage
```cpp
// Initialize filter
IirParams params = {
    1e-4f,    // Ts: Sampling time
    100.0f,   // fc: Cutoff frequency
    0,        // type: lowpass
    0.0f      // a: auto
};
IirModule filter;
iir_module_init(&filter, &params);

// Process signal
filter.in.u = input_signal;
iir_module_step(&filter);
float filtered_output = filter.out.y;
```

## API Reference
See `iir.h` for detailed API documentation.
