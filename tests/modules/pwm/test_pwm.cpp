#include "pwm/pwm.h"
#include <assert.h>
#include <math.h>

void test_pwm_init() {
    PwmModule pwm;
    PwmParams params = {10e-6f, 0, 15.0f};
    
    int result = pwm_module_init(&pwm, &params);
    assert(result == 0);
}

void test_pwm_step() {
    PwmModule pwm;
    PwmParams params = {10e-6f, 0, 15.0f};
    pwm_module_init(&pwm, &params);

    // Test 50% duty cycle
    pwm.in.t = 0.0f;
    pwm.in.duty = 0.5f;
    pwm.in.phase = 0.0f;
    
    for(int i = 0; i < 100; i++) {
        pwm_module_step(&pwm);
        pwm.in.t += params.Ts;
    }
    
    // Output should be either 0 or gate_on_voltage
    assert(pwm.out.PWM == 0.0f || pwm.out.PWM == params.gate_on_voltage);
}

int main() {
    test_pwm_init();
    test_pwm_step();
    printf("All PWM tests passed!\n");
    return 0;
}
