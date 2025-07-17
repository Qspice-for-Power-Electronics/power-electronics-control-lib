/**
 * *************************** In The Name Of God ***************************
 * @file    ctrl.cpp
 * @brief   Controller using 2 CPWM modules for PWM generation and timing
 * @author  Dr.-Ing. Hossein Abedini
 * @date    2025-07-02
 * Implementation using 2 CPWM modules: 1 for digital controller timing,
 * and 1 for single PWM generation with sampling and filtering test.
 * @note    Designed for real-time signal processing applications.
 * @license This work is dedicated to the public domain under CC0 1.0.
 *          Please use it for good and beneficial purposes!
 ***************************************************************************/

/********************************* INCLUDES **********************************/
#include "cpwm.h"

/***************************** TYPE DEFINITIONS ******************************/

// Union for generic data exchange (do not remove)
union uData
{
    bool                   b;
    char                   c;
    unsigned char          uc;
    short                  s;
    unsigned short         us;
    int                    i;
    unsigned int           ui;
    float                  f;
    double                 d;
    long long int          i64;
    unsigned long long int ui64;
    char*                  str;
    unsigned char*         bytes;
};

/**************************** MACRO UNDEFINES *******************************/

// #undef pin names lest they collide with names in any header file(s) you might include.
#undef V_1
#undef I_1
#undef I_1_2
#undef In1
#undef In2
#undef In3
#undef In4
#undef In5
#undef In6
#undef In7
#undef I_2_2
#undef V_2
#undef I_2
#undef Q1A
#undef Q1B
#undef Q2A
#undef Q2B
#undef Q3A
#undef Q3B
#undef Q4A
#undef Q4B
#undef Q5
#undef Q6
#undef Q7
#undef Q8
#undef Out1
#undef Out2
#undef Out3
#undef Out4
#undef Out5
#undef Out6
#undef Out7
#undef Out8
#undef Out9
#undef Out10
#undef Out11
#undef Out12
#undef Out13
#undef Out14
#undef Out15
#undef Out16
#undef Out17
#undef Out18
#undef Out19
#undef Out20
#undef Out21
#undef Out22
#undef Out23
#undef Out24
#undef Out25
#undef Out26
#undef Out27
#undef Out28

/**************************** FUNCTION DECLARATIONS ***********************/

/**
 * @brief Samples input signals (simulates ADC sampling in ISR)
 *
 * This function samples all analog input signals that would typically be
 * sampled by ADCs in a microcontroller interrupt service routine.
 */
static void sample_input_signals(float V_1, float I_1, float I_1_2, float V_2, float I_2, float I_2_2, float& sampled_V_1, float& sampled_I_1,
                                 float& sampled_I_1_2, float& sampled_V_2, float& sampled_I_2, float& sampled_I_2_2);

/**
 * @brief Handles time-based PWM parameter updates and module stepping
 *
 * This function implements delayed PWM parameter updates to simulate microcontroller
 * processing delay, then steps the PWM module with the updated parameters.
 */
static void handle_pwm_update_and_step(double t, bool& pwm_update_pending, float control_calculation_time, float PWM_UPDATE_DELAY_TIME,
                                       float calculated_duty, cpwm_t& pwm_module);

/**************************** PUBLIC FUNCTIONS *******************************/
// int DllMain() must exist and return 1 for a process to load the .DLL
// See https://docs.microsoft.com/en-us/windows/win32/dlls/dllmain for more information.
int __stdcall DllMain(void* module, unsigned int reason, void* reserved)
{
    return 1;
}

// --- Modular Digital PWM Implementation ---
extern "C" __declspec(dllexport) void ctrl(void** opaque, double t, union uData* data)
{
    float const  V_1   = data[0].f;   // input
    float const  I_1   = data[1].f;   // input
    float const  I_1_2 = data[2].f;   // input
    float const  In1   = data[3].f;   // input
    float const  In2   = data[4].f;   // input
    float const  In3   = data[5].f;   // input
    float const  In4   = data[6].f;   // input
    float const  In5   = data[7].f;   // input
    float const  In6   = data[8].f;   // input
    float const  In7   = data[9].f;   // input
    float const  I_2_2 = data[10].f;  // input
    float const  V_2   = data[11].f;  // input
    float const  I_2   = data[12].f;  // input
    float&       Q1A   = data[13].f;  // output
    float&       Q1B   = data[14].f;  // output
    float&       Q2A   = data[15].f;  // output
    float&       Q2B   = data[16].f;  // output
    float&       Q3A   = data[17].f;  // output
    float&       Q3B   = data[18].f;  // output
    float&       Q4A   = data[19].f;  // output
    float&       Q4B   = data[20].f;  // output
    float const& Q5    = data[21].f;  // output
    float const& Q6    = data[22].f;  // output
    float const& Q7    = data[23].f;  // output
    float const& Q8    = data[24].f;  // output
    float&       Out1  = data[25].f;  // output
    float&       Out2  = data[26].f;  // output
    float&       Out3  = data[27].f;  // output
    float&       Out4  = data[28].f;  // output
    float&       Out5  = data[29].f;  // output
    float&       Out6  = data[30].f;  // output
    float&       Out7  = data[31].f;  // output
    float&       Out8  = data[32].f;  // output
    float&       Out9  = data[33].f;  // output
    float&       Out10 = data[34].f;  // output
    float&       Out11 = data[35].f;  // output
    float&       Out12 = data[36].f;  // output
    float&       Out13 = data[37].f;  // output
    float&       Out14 = data[38].f;  // output
    float const& Out15 = data[39].f;  // output
    float const& Out16 = data[40].f;  // output
    float const& Out17 = data[41].f;  // output
    float const& Out18 = data[42].f;  // output
    float const& Out19 = data[43].f;  // output
    float const& Out20 = data[44].f;  // output
    float const& Out21 = data[45].f;  // output
    float const& Out22 = data[46].f;  // output
    float const& Out23 = data[47].f;  // output
    float const& Out24 = data[48].f;  // output
    float const& Out25 = data[49].f;  // output
    float const& Out26 = data[50].f;  // output
    float const& Out27 = data[51].f;  // output
    float const& Out28 = data[52].f;  // output

    // Suppress unused variable warnings for inputs not currently used
    (void)I_1;
    (void)V_1;
    (void)I_1_2;
    (void)In2;
    (void)In3;
    (void)In4;
    (void)In5;
    (void)In6;
    (void)In7;
    (void)I_2_2;
    (void)V_2;
    (void)I_2;

    // Module initialization code
    static cpwm_t cpwm_clk;    // Clock generator CPWM
    static cpwm_t pwm_module;  // Single PWM module for testing
    static bool   mod_initialized = false;

    // Initialize clock generator CPWM (for digital controller timing)
    cpwm_params_t const cpwm_clk_params = {
        .Fs               = 50000.0F,  // 50kHz frequency
        .gate_on_voltage  = 0.0F,
        .gate_off_voltage = 0.0F,
        .sync_enable      = false,
        .phase_offset     = 0.0F,
        .dead_time        = 0.0F,  // 0ns dead time
        .duty_cycle       = 0.5F   // 50% duty cycle
    };

    if (!mod_initialized)
    {
        cpwm_init(&cpwm_clk, &cpwm_clk_params);

        // Initialize single test CPWM module
        cpwm_params_t const cpwm_test_params = {
            .Fs               = 250e3F,  // 250kHz frequency
            .gate_on_voltage  = 1.0F,
            .gate_off_voltage = 0.0F,
            .sync_enable      = false,
            .phase_offset     = 0.0F,
            .dead_time        = 100e-9F,  // 100ns dead time
            .duty_cycle       = 0.5F      // 50% initial duty cycle
        };
        cpwm_init(&pwm_module, &cpwm_test_params);

        mod_initialized = true;
    }

    // Update clock generator CPWM
    cpwm_step(&cpwm_clk, static_cast<float>(t), false);

    // Static frequency and dead time values for PWM module
    static float const freq       = 250e3F;   // Base switching frequency
    static float const dead_time  = 100e-9F;  // Dead time for PWM
    static float const duty_cycle = 0.5F;     // Duty cycle (0.0 to 1.0)
    static float const theta_deg  = 30.0F;    // Phase angle in degrees

    // Calculate phase offset from theta parameter
    static float const phase_offset = DEGREES_TO_PHASE_OFFSET(theta_deg, freq);

    // Rising edge detection for ClkOut - simulates microcontroller interrupt
    static bool  prev_clk      = false;
    static float sampled_V_1   = 0.0F;  // Sampled V_1 voltage
    static float sampled_I_1   = 0.0F;  // Sampled I_1 current
    static float sampled_I_1_2 = 0.0F;  // Sampled I_1_2 current
    static float sampled_V_2   = 0.0F;  // Sampled V_2 voltage
    static float sampled_I_2   = 0.0F;  // Sampled I_2 current
    static float sampled_I_2_2 = 0.0F;  // Sampled I_2_2 current

    // PWM update delay configuration
    // Change PWM_UPDATE_DELAY_TIME to adjust the delay between control calculation and PWM update
    // Delay is specified in seconds (e.g., 60e-6F = 60 microseconds)
    static const float PWM_UPDATE_DELAY_TIME    = 0.5F / cpwm_clk_params.Fs;  // 10 microseconds delay (0.5x the 20μs period)
    static float       control_calculation_time = 0.0F;                       // Timestamp when control was last calculated
    static bool        pwm_update_pending       = false;                      // Flag to track if PWM update is pending

    if (cpwm_clk.outputs.period_sync && !prev_clk)
    {
        /* === INTERRUPT SERVICE ROUTINE SIMULATION === */

        // 1. SAMPLING: Sample input signals (simulates ADC sampling in ISR)
        sample_input_signals(V_1, I_1, I_1_2, V_2, I_2, I_2_2, sampled_V_1, sampled_I_1, sampled_I_1_2, sampled_V_2, sampled_I_2, sampled_I_2_2);

        // 2. CONTROL: Execute control algorithms based on sampled values
        // Example: Simple control logic using sampled input In1
        Out6 = In1 * 0.8F;  // Example: scaled input to output

        // 3. TIMESTAMP: Record when this control calculation was made
        control_calculation_time = static_cast<float>(t);
        pwm_update_pending       = true;  // Set flag indicating PWM update is pending
    }
    prev_clk = cpwm_clk.outputs.period_sync;

    float calculated_duty = sampled_V_1;  // Example duty cycle, replace with your control logic

    // Handle PWM parameter updates and module stepping
    handle_pwm_update_and_step(t, pwm_update_pending, control_calculation_time, PWM_UPDATE_DELAY_TIME, calculated_duty, pwm_module);

    // Assign PWM outputs
    Q1A = pwm_module.outputs.PWMA;  // PWM channel A
    Q1B = pwm_module.outputs.PWMB;  // PWM channel B

    // Assign outputs to data union
    // Clock generator CPWM outputs
    Out1 = cpwm_clk.outputs.counter_normalized;
    Out2 = static_cast<float>(cpwm_clk.outputs.period_sync);
    Out3 = sampled_V_1;                             // Sampled V_1 voltage for debugging
    Out4 = static_cast<float>(pwm_update_pending);  // PWM update pending flag

    // Debug timing information
    Out5 = static_cast<float>(t);               // Current time for debugging
    Out6 = control_calculation_time;            // Time when control was calculated
    Out7 = PWM_UPDATE_DELAY_TIME * 1000000.0F;  // PWM delay time in microseconds for debugging

    // Debug outputs from PWM module to monitor its behavior
    Out8  = pwm_module.outputs.counter_normalized;                            // Counter value [0.0, 1.0]
    Out9  = static_cast<float>(pwm_module.outputs.period_sync);               // Period sync signal
    Out10 = (static_cast<float>(t) - control_calculation_time) * 1000000.0F;  // Time since last control calculation (microseconds)
    Out11 = pwm_module.state.cmp_lead;                                        // Compare leading edge value
    Out12 = pwm_module.state.cmp_lag;                                         // Compare lagging edge value
}

/**************************** PRIVATE FUNCTIONS *****************************/

/**
 * @brief Samples input signals (simulates ADC sampling in ISR)
 *
 * This function samples all analog input signals that would typically be
 * sampled by ADCs in a microcontroller interrupt service routine.
 * In a real implementation, this would include:
 * - ADC conversion triggering
 * - Anti-aliasing filtering
 * - Gain and offset calibration
 * - Digital filtering for noise reduction
 *
 * @param V_1 AC voltage input
 * @param I_1 AC current input
 * @param I_1_2 Tank AC current input
 * @param V_2 DC voltage input
 * @param I_2 DC current input
 * @param I_2_2 Tank DC current input
 * @param sampled_V_1 Reference to store sampled V_1 voltage
 * @param sampled_I_1 Reference to store sampled I_1 current
 * @param sampled_I_1_2 Reference to store sampled I_1_2 current
 * @param sampled_V_2 Reference to store sampled V_2 voltage
 * @param sampled_I_2 Reference to store sampled I_2 current
 * @param sampled_I_2_2 Reference to store sampled I_2_2 current
 */
static void sample_input_signals(float V_1, float I_1, float I_1_2, float V_2, float I_2, float I_2_2, float& sampled_V_1, float& sampled_I_1,
                                 float& sampled_I_1_2, float& sampled_V_2, float& sampled_I_2, float& sampled_I_2_2)
{
    // Sample all analog input signals
    // In a real microcontroller, these would be ADC readings with proper scaling
    sampled_V_1   = V_1;    // V_1 voltage
    sampled_I_1   = I_1;    // I_1 current
    sampled_I_1_2 = I_1_2;  // I_1_2 current
    sampled_V_2   = V_2;    // V_2 voltage
    sampled_I_2   = I_2;    // I_2 current
    sampled_I_2_2 = I_2_2;  // I_2_2 current

    // Note: In a real implementation, you might add:
    // - Gain/offset calibration
    // - Range checking and saturation limiting
    // - Conversion from ADC counts to engineering units
}

/**
 * @brief Handles time-based PWM parameter updates and module stepping
 *
 * This function implements delayed PWM parameter updates to simulate microcontroller
 * processing delay, then steps the PWM module with the updated parameters.
 *
 * @param t Current simulation time
 * @param pwm_update_pending Reference to flag indicating if PWM update is pending
 * @param control_calculation_time Time when control calculation was performed
 * @param PWM_UPDATE_DELAY_TIME Delay time before applying PWM updates
 * @param calculated_duty The newly calculated duty cycle to apply
 * @param pwm_module PWM module reference
 */
static void handle_pwm_update_and_step(double t, bool& pwm_update_pending, float control_calculation_time, float PWM_UPDATE_DELAY_TIME,
                                       float calculated_duty, cpwm_t& pwm_module)
{
    // 4. TIME-BASED DELAY IMPLEMENTATION: Apply parameters after specified delay time
    // Check if enough time has passed since the control calculation AND update is pending
    float const current_time = static_cast<float>(t);
    if (pwm_update_pending && ((current_time - control_calculation_time) >= PWM_UPDATE_DELAY_TIME))
    {
        // 5. UPDATE: Update PWM parameters with delayed duty cycle (executed once per control cycle)
        // This simulates updating PWM registers in the microcontroller with processing delay
        // Use the new update_parameters function to update duty cycle at runtime
        update_parameters(&pwm_module, 0.0F, -1.0F, 0.0F/0.0F, calculated_duty);  // Update only duty cycle (NaN for phase_offset)
        pwm_update_pending = false;            // Clear flag after successful update
    }

    // Step the CPWM module (duty cycle is now stored internally)
    // This ensures the delay is properly simulated - PWM continues with old duty until delay expires
    cpwm_step(&pwm_module, static_cast<float>(t), false);
}
