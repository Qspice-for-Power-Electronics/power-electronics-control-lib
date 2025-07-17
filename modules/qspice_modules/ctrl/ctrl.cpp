/**
 * *************************** In The Name Of God ***************************
 * @file    ctrl.cpp
 * @brief   Controller using 5 CPWM modules for PWM generation and timing
 * @author  Dr.-Ing. Hossein Abedini
 * @date    2025-07-02
 * Implementation using 5 CPWM modules: 1 for digital controller timing,
 * and 4 for test PWM generation without synchronization.
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
    (void)V_1;
    (void)I_1;
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
    static cpwm_t cpwm_clk;  // Clock generator CPWM
    static cpwm_t cpwm1;     // Test CPWM 1
    static cpwm_t cpwm2;     // Test CPWM 2
    static cpwm_t cpwm3;     // Test CPWM 3
    static cpwm_t cpwm4;     // Test CPWM 4
    static bool   mod_initialized = false;
    if (!mod_initialized)
    {
        // Initialize clock generator CPWM (for digital controller timing)
        cpwm_params_t const cpwm_clk_params = {
            .Fs               = 50000.0F,  // 50kHz frequency
            .gate_on_voltage  = 0.0F,
            .gate_off_voltage = 0.0F,
            .sync_enable      = false,
            .phase_offset     = 0.0F,
            .dead_time        = 0.0F  // 0ns dead time
        };
        cpwm_init(&cpwm_clk, &cpwm_clk_params);

        // Initialize test CPWM modules (no synchronization)
        cpwm_params_t const cpwm_test_params = {
            .Fs               = 100000.0F,  // 100kHz frequency
            .gate_on_voltage  = 1.0F,
            .gate_off_voltage = 0.0F,
            .sync_enable      = false,
            .phase_offset     = 0.0F,
            .dead_time        = 200e-9F  // 200ns dead time
        };
        cpwm_init(&cpwm1, &cpwm_test_params);
        cpwm_init(&cpwm2, &cpwm_test_params);
        cpwm_init(&cpwm3, &cpwm_test_params);
        cpwm_init(&cpwm4, &cpwm_test_params);

        mod_initialized = true;
    }

    // Update clock generator CPWM
    cpwm_step(&cpwm_clk, static_cast<float>(t), 0.5F, false);  // 50% duty cycle for clock

    // Update test CPWM modules with different duty cycles (no synchronization)
    float const cmp1 = 0.25F;  // 25% duty cycle for CPWM1
    float const cmp2 = 0.35F;  // 35% duty cycle for CPWM2
    float const cmp3 = 0.45F;  // 45% duty cycle for CPWM3
    float const cmp4 = 0.55F;  // 55% duty cycle for CPWM4

    cpwm_step(&cpwm1, static_cast<float>(t), cmp1, false);
    cpwm_step(&cpwm2, static_cast<float>(t), cmp2, false);
    cpwm_step(&cpwm3, static_cast<float>(t), cmp3, false);
    cpwm_step(&cpwm4, static_cast<float>(t), cmp4, false);

    // Rising edge detection for ClkOut for digital controller
    static bool prev_clk = false;
    if (cpwm_clk.outputs.period_sync && !prev_clk)
    {
        /* digital controller code */
        // Example: Simple control logic can be added here
        Out6 = In1 * 0.8F;  // Example: scaled input to output
    }
    prev_clk = cpwm_clk.outputs.period_sync;

    // Assign outputs to data union
    // Clock generator CPWM outputs
    Out1 = cpwm_clk.outputs.PWMA;
    Out2 = cpwm_clk.outputs.PWMB;
    Out3 = cpwm_clk.outputs.counter_normalized;
    Out4 = static_cast<float>(cpwm_clk.outputs.period_sync);
    Out5 = 0.0F;  // Reserved

    // Connect CPWM outputs to QSPICE pins:
    // CPWM1: Q1A, Q1B
    Q1A = cpwm1.outputs.PWMA;
    Q1B = cpwm1.outputs.PWMB;

    // CPWM2: Q2A, Q2B
    Q2A = cpwm2.outputs.PWMA;
    Q2B = cpwm2.outputs.PWMB;

    // CPWM3: Q3A, Q3B
    Q3A = cpwm3.outputs.PWMA;
    Q3B = cpwm3.outputs.PWMB;

    // CPWM4: Q4A, Q4B
    Q4A = cpwm4.outputs.PWMA;
    Q4B = cpwm4.outputs.PWMB;

    // Debug outputs from CPWM1 to monitor its behavior
    Out7  = cpwm1.outputs.counter_normalized;               // Counter value [0.0, 1.0]
    Out8  = static_cast<float>(cpwm1.outputs.period_sync);  // Period sync signal
    Out9  = cpwm1.state.cmp_lead;                           // Compare leading edge value
    Out10 = cpwm1.state.cmp_lag;                            // Compare lagging edge value

    // Debug outputs from CPWM2 to monitor its behavior
    Out11 = cpwm2.outputs.counter_normalized;               // Counter value [0.0, 1.0]
    Out12 = static_cast<float>(cpwm2.outputs.period_sync);  // Period sync signal
    Out13 = cpwm2.state.cmp_lead;                           // Compare leading edge value
    Out14 = cpwm2.state.cmp_lag;                            // Compare lagging edge value
}
