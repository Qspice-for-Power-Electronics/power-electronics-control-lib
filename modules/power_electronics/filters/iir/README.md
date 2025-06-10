# IIR Filter Module

## Overview
Digital IIR (Infinite Impulse Response) filter implementation for signal processing in the WPT simulation project.

## Features
- Configurable filter parameters (Ts, fc, type, a)
- Low-pass filter implementation
- Real-time signal processing capability

## Usage
```cpp
// Initialize IIR filter
iir_params_t params = {
    1e-4f,  // Ts: Sampling time (100 µs)
    100.0f, // fc: Cutoff frequency (100 Hz)
    0,      // type: 0 = lowpass, 1 = highpass
    0.0f    // a: Auto-calculated from Ts and fc
};
iir_t filter;
iir_init(&filter, &params);

// Process signal
float input_signal = 1.0f;
iir_step(&filter, input_signal);
float filtered_output = filter.outputs.y;

// Reset filter (preserves parameters)
iir_reset(&filter);
```

## API Reference
See `iir.h` for detailed API documentation.
