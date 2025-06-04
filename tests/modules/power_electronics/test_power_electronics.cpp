#include "pecl/pwm.h"
#include "pecl/iir.h"
#include <assert.h>
#include <math.h>

// Test the integration between PWM and IIR filter
void test_pwm_iir_integration() {
    // Initialize PWM
    PwmModule pwm;
    PwmParams pwm_params = {10e-6f, 0, 15.0f};
    pwm_module_init(&pwm, &pwm_params);
    
    // Initialize IIR filter
    IirModule iir;
    IirParams iir_params = {0.1f}; // Simple low-pass filter
    iir_module_init(&iir, &iir_params);
    
    // Test signal chain
    float t = 0.0f;
    float dt = 10e-6f;
    
    for(int i = 0; i < 1000; i++) {
        // Generate PWM signal
        pwm.in.t = t;
        pwm.in.duty = 0.5f + 0.5f * sinf(2 * M_PI * 50 * t); // 50Hz modulation
        pwm_module_step(&pwm);
        
        // Filter PWM output
        iir.in.x = pwm.out.PWM;
        iir_module_step(&iir);
        
        // Verify output bounds
        assert(iir.out.y >= 0.0f && iir.out.y <= pwm_params.gate_on_voltage);
        
        t += dt;
    }
}

// Test power stage behavior
void test_power_stage() {
    PwmModule pwm;
    PwmParams pwm_params = {10e-6f, 0, 15.0f};
    pwm_module_init(&pwm, &pwm_params);
    
    // Test different duty cycles
    float duty_cycles[] = {0.0f, 0.25f, 0.5f, 0.75f, 1.0f};
    
    for(int i = 0; i < sizeof(duty_cycles)/sizeof(float); i++) {
        pwm.in.t = 0.0f;
        pwm.in.duty = duty_cycles[i];
        
        float avg_output = 0.0f;
        int samples = 100;
        
        for(int j = 0; j < samples; j++) {
            pwm_module_step(&pwm);
            avg_output += pwm.out.PWM;
            pwm.in.t += pwm_params.Ts;
        }
        
        avg_output /= samples;
        
        // Verify average output matches duty cycle within 5% tolerance
        float expected = duty_cycles[i] * pwm_params.gate_on_voltage;
        assert(fabs(avg_output - expected) <= 0.05f * pwm_params.gate_on_voltage);
    }
}

int main() {
    test_pwm_iir_integration();
    test_power_stage();
    printf("All power electronics tests passed!\n");
    return 0;
}
