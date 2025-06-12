# Enhanced PWM (ePWM) Module

## Overview
Enhanced Digital PWM module with center-aligned counter, dead time control, and advanced action modes for high-performance power electronics control in the WPT simulation project.

## Features
- **Center-Aligned Counter**: Triangular counter waveform for symmetric PWM generation
- **Dead Time Control**: Configurable rising and falling edge dead times
- **Advanced Action Modes**: Flexible compare event-based output control
- **Dual PWM Outputs**: PWMA and PWMB with independent action modes
- **External Synchronization**: Optional sync input for multi-module coordination
- **Phase Offset**: Configurable phase shifting capability
- **Counter Direction Tracking**: Real-time direction indication

## Counter Types

### Center-Aligned Counter (`EPWM_COUNTER_CENTER_ALIGNED`) - Currently Only Supported Mode
- Counter range: 0.0 → 1.0 → 0.0 over full period
- Direction: Alternates between up and down
- Use case: Center-aligned PWM for symmetric switching

## Action Modes

### `EPWM_ACTION_CMPB_DOWN_CMPA_UP`
- PWM goes HIGH on CMPB down-count crossing
- PWM goes LOW on CMPA up-count crossing

### `EPWM_ACTION_CMPA_DOWN_CMPB_UP`
- PWM goes HIGH on CMPA down-count crossing
- PWM goes LOW on CMPB up-count crossing

## Usage Examples

### Basic Center-Aligned PWM
```cpp
// Initialize EPWM with center-aligned counter (only mode currently supported)
epwm_params_t params = {
    .Ts = 10e-6f,                              // 10µs sampling time
    .period = 1000.0f,                         // 1000 samples = 10ms period
    .pwma_mode = EPWM_ACTION_CMPB_DOWN_CMPA_UP,
    .pwmb_mode = EPWM_ACTION_CMPA_DOWN_CMPB_UP, // Complementary
    .gate_on_voltage = 15.0f,
    .gate_off_voltage = 0.0f,
    .sync_enable = false,
    .phase_offset = 0.0f,
    .dead_time_rising = 500e-9f,               // 500ns dead time
    .dead_time_falling = 500e-9f
};

epwm_t epwm;
epwm_init(&epwm, &params);

// Execute PWM step
float cmpa = 0.4f;  // 40% duty cycle reference
float cmpb = 0.6f;  // 60% duty cycle reference  
bool sync_in = false;

epwm_step(&epwm, current_time, cmpa, cmpb, sync_in);

// Access outputs
float pwma_output = epwm.outputs.PWMA;
float pwmb_output = epwm.outputs.PWMB;
bool period_start = epwm.outputs.period_sync;
```

### Phase-Shifted PWM with Synchronization
```cpp
// Module 1: Master
epwm_params_t master_params = {
    .Ts = 10e-6f,
    .period = 1000.0f,
    .pwma_mode = EPWM_ACTION_CMPB_DOWN_CMPA_UP,
    .pwmb_mode = EPWM_ACTION_CMPA_DOWN_CMPB_UP,
    .gate_on_voltage = 15.0f,
    .gate_off_voltage = 0.0f,
    .sync_enable = false,  // Master doesn't use sync
    .phase_offset = 0.0f,  // No phase offset
    .dead_time_rising = 1e-6f,
    .dead_time_falling = 1e-6f
};

// Module 2: Slave with 90° phase shift
epwm_params_t slave_params = master_params;
slave_params.sync_enable = true;              // Enable sync input
slave_params.phase_offset = 2.5e-3f;          // 90° phase shift (quarter period)

epwm_t master_epwm, slave_epwm;
epwm_init(&master_epwm, &master_params);
epwm_init(&slave_epwm, &slave_params);

// Execute steps
epwm_step(&master_epwm, t, 0.5f, 0.5f, false);
epwm_step(&slave_epwm, t, 0.5f, 0.5f, master_epwm.outputs.period_sync);
```

### Dead Time Control Example
```cpp
// High-frequency PWM with precise dead time (center-aligned mode)
epwm_params_t high_freq_params = {
    .Ts = 1e-6f,                               // 1µs sampling time
    .period = 100.0f,                          // 100µs PWM period = 10kHz
    .pwma_mode = EPWM_ACTION_CMPB_DOWN_CMPA_UP,
    .pwmb_mode = EPWM_ACTION_CMPA_DOWN_CMPB_UP,
    .gate_on_voltage = 15.0f,
    .gate_off_voltage = 0.0f,
    .sync_enable = false,
    .phase_offset = 0.0f,
    .dead_time_rising = 200e-9f,               // 200ns rising dead time
    .dead_time_falling = 150e-9f               // 150ns falling dead time
};
```

## Counter Behavior

### Center-Aligned Mode (Only Supported Mode)
- Processes both up-count and down-count events
- Triangular counter waveform: 0→1→0
- Full functionality for all action modes
- Ideal for symmetric PWM generation with minimal ripple
- Provides natural phase balancing and reduced EMI

## API Reference

### Initialization Functions
- `epwm_init()`: Initialize module with parameters
- `epwm_reset()`: Reset to initial state

### Runtime Functions
- `epwm_step()`: Execute one PWM calculation step

### Output Signals
- `PWMA`, `PWMB`: PWM output voltages
- `counter_normalized`: Current counter value [0.0, 1.0]
- `counter_direction`: Current counting direction
- `period_sync`: Period synchronization signal

See `epwm.h` for detailed API documentation and parameter descriptions.

## Integration Notes

### Multi-Module Systems
- Use `period_sync` output from master module as `sync_in` for slaves
- Configure appropriate phase offsets for desired phase relationships
- All modules should use the same `Ts` and `period` values

### Dead Time Considerations
- Dead time is applied symmetrically around compare values
- Normalize dead time values relative to PWM period
- Ensure dead time doesn't exceed compare value separation

### Performance Optimization
- Counter calculations are optimized for real-time execution
- Edge detection uses minimal floating-point operations
- State preservation minimizes computational overhead per step

### Dead Time Implementation
- Dead time is normalized based on PWM period during initialization
- Rising and falling dead time can be configured independently
- Dead time is applied appropriately based on action modes
- Implementation ensures glitch-free operation during transitions

### Parameter Validation
- Sampling time (Ts) must be positive
- PWM period must be positive
- Dead time values must be non-negative
- Gate voltage parameters support values between 0V and 24V
- Compare values (cmpa, cmpb) must be between 0.0 and 1.0

### Synchronization Mechanism
- External sync signal forces counter reset to beginning of period
- When sync_enable is true, counter will reset upon sync_in rising edge
- Phase offset applied relative to synchronized timer
- Periodic sync signal (period_sync) can be used to cascade multiple modules
- Ideal for multi-phase or interleaved converter topologies

## Testing and Verification

### Testing Strategies
- Verify proper PWM generation for all action modes
- Check dead time insertion between complementary outputs
- Test synchronization between multiple modules
- Validate phase offset implementation
- Measure computational performance in target environment

### Sample Test Setup
```cpp
// Test sequence for ePWM validation
float t = 0.0f;
float cmpa = 0.25f;  // 25% duty cycle
float cmpb = 0.75f;  // 75% duty cycle
bool sync = false;

// Run for 10 PWM periods
for (int i = 0; i < 10*params.period; i++) {
    epwm_step(&epwm, t, cmpa, cmpb, sync);
    
    // Log or visualize outputs
    printf("t=%.6f, PWMA=%.1f, PWMB=%.1f, counter=%.3f, dir=%d, sync=%d\n",
           t, epwm.outputs.PWMA, epwm.outputs.PWMB, 
           epwm.outputs.counter_normalized,
           epwm.outputs.counter_direction, epwm.outputs.period_sync);
    
    t += params.Ts;
}
```
