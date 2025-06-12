/**
 * *************************** In The Name Of God ***************************
 * @file    ctrl.cpp
 * @brief   Example controller for modular digital PWM implementation
 * @author  Dr.-Ing. Hossein Abedini
 * @date    2025-06-01
 * Example usage of the PwmModule for generating phase-shifted PWM signals.
 * @note    Designed for real-time signal processing applications.
 * @license This work is dedicated to the public domain under CC0 1.0.
 *          Please use it for good and beneficial purposes!
 ***************************************************************************/

/********************************* INCLUDES **********************************/
#include "bpwm.h"
#include "epwm.h"
#include "iir.h"

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
#undef V_ac
#undef I_ac
#undef Itank_ac
#undef In1
#undef In2
#undef In3
#undef In4
#undef In5
#undef In6
#undef In7
#undef Itank_dc
#undef V_dc
#undef I_dc
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
    float const  V_ac     = data[0].f;   // input
    float const  I_ac     = data[1].f;   // input
    float const  Itank_ac = data[2].f;   // input
    float const  In1      = data[3].f;   // input
    float const  In2      = data[4].f;   // input
    float const  In3      = data[5].f;   // input
    float const  In4      = data[6].f;   // input
    float const  In5      = data[7].f;   // input
    float const  In6      = data[8].f;   // input
    float const  In7      = data[9].f;   // input
    float const  Itank_dc = data[10].f;  // input
    float const  V_dc     = data[11].f;  // input
    float const  I_dc     = data[12].f;  // input
    float&       Q1A      = data[13].f;  // output
    float&       Q1B      = data[14].f;  // output
    float&       Q2A      = data[15].f;  // output
    float&       Q2B      = data[16].f;  // output
    float&       Q3A      = data[17].f;  // output
    float&       Q3B      = data[18].f;  // output
    float&       Q4A      = data[19].f;  // output
    float&       Q4B      = data[20].f;  // output
    float&       Q5       = data[21].f;  // output
    float&       Q6       = data[22].f;  // output
    float&       Q7       = data[23].f;  // output
    float&       Q8       = data[24].f;  // output
    float&       Out1     = data[25].f;  // output
    float&       Out2     = data[26].f;  // output
    float&       Out3     = data[27].f;  // output
    float&       Out4     = data[28].f;  // output
    float&       Out5     = data[29].f;  // output
    float&       Out6     = data[30].f;  // output
    float&       Out7     = data[31].f;  // output
    float&       Out8     = data[32].f;  // output
    float&       Out9     = data[33].f;  // output
    float const& Out10    = data[34].f;  // output
    float const& Out11    = data[35].f;  // output
    float const& Out12    = data[36].f;  // output
    float const& Out13    = data[37].f;  // output
    float const& Out14    = data[38].f;  // output
    float const& Out15    = data[39].f;  // output
    float const& Out16    = data[40].f;  // output
    float const& Out17    = data[41].f;  // output
    float const& Out18    = data[42].f;  // output
    float const& Out19    = data[43].f;  // output
    float const& Out20    = data[44].f;  // output
    float const& Out21    = data[45].f;  // output
    float const& Out22    = data[46].f;  // output
    float const& Out23    = data[47].f;  // output
    float const& Out24    = data[48].f;  // output
    float const& Out25    = data[49].f;  // output
    float const& Out26    = data[50].f;  // output
    float const& Out27    = data[51].f;  // output
    float const& Out28    = data[52].f;  // output

    // Module initialization code
    static bpwm_t bpwm_mod;
    static iir_t  lpf;
    // Add four ePWM modules
    static epwm_t epwm1;
    static epwm_t epwm2;
    static epwm_t epwm3;
    static epwm_t epwm4;
    static int    mod_initialized = 0;
    if (!mod_initialized)
    {
        // Initialize BPWM module (original)
        bpwm_params_t const bpwm_params = {10e-6f, BPWM_CARRIER_CENTER_ALIGNED, 15.0f,
                                           0.0f};  // Ts, carrier_select, gate_on_voltage, gate_off_voltage
        bpwm_init(&bpwm_mod, &bpwm_params);

        // Initialize IIR filter
        iir_params_t const lpf_params = {1e-4f, 100.0f, IIR_LOWPASS, 0.0f};  // Ts, fc, type=lowpass, a=auto
        iir_init(&lpf, &lpf_params);

        // Initialize ePWM modules        // Common ePWM parameters
        epwm_params_t base_epwm_params = {
            .Ts                = 10e-6f,  // 10µs sampling time (equivalent to 100kHz carrier)
            .pwma_mode         = EPWM_ACTION_CMPB_DOWN_CMPA_UP,
            .pwmb_mode         = EPWM_ACTION_CMPA_DOWN_CMPB_UP,  // Complementary output
            .gate_on_voltage   = 15.0f,
            .gate_off_voltage  = 0.0f,
            .sync_enable       = false,
            .phase_offset      = 0.0f,
            .dead_time_rising  = 200e-9f,  // 200ns rising dead time
            .dead_time_falling = 150e-9f   // 150ns falling dead time
        };

        // ePWM1 (Master): No phase offset
        epwm_init(&epwm1, &base_epwm_params);  // ePWM2: 90° phase shift (quarter period)
        epwm_params_t epwm2_params = base_epwm_params;
        epwm2_params.sync_enable   = true;
        epwm2_params.phase_offset  = 0.25f * base_epwm_params.Ts;  // 90° phase shift (quarter period)
        epwm_init(&epwm2, &epwm2_params);

        // ePWM3: 180° phase shift (half period)
        epwm_params_t epwm3_params = base_epwm_params;
        epwm3_params.sync_enable   = true;
        epwm3_params.phase_offset  = 0.5f * base_epwm_params.Ts;  // 180° phase shift (half period)
        epwm_init(&epwm3, &epwm3_params);

        // ePWM4: 270° phase shift (three-quarter period)
        epwm_params_t epwm4_params = base_epwm_params;
        epwm4_params.sync_enable   = true;
        epwm4_params.phase_offset  = 0.75f * base_epwm_params.Ts;  // 270° phase shift
        epwm_init(&epwm4, &epwm4_params);

        mod_initialized = 1;
    }

    // Update BPWM module (original)
    bpwm_step(&bpwm_mod, static_cast<float>(t), 0.5f, 0.0f);  // Example: 50% duty cycle, 0 phase offset

    // Update ePWM modules with different duty cycles
    float cmpa1 = 0.25f;  // 25% duty cycle for ePWM1
    float cmpb1 = 0.75f;

    float cmpa2 = 0.30f;  // 30% duty cycle for ePWM2
    float cmpb2 = 0.70f;

    float cmpa3 = 0.35f;  // 35% duty cycle for ePWM3
    float cmpb3 = 0.65f;

    float cmpa4 = 0.40f;  // 40% duty cycle for ePWM4
    float cmpb4 = 0.60f;

    // Execute PWM steps (epwm1 is master, others are synchronized with its period_sync signal)
    epwm_step(&epwm1, static_cast<float>(t), cmpa1, cmpb1, false);
    epwm_step(&epwm2, static_cast<float>(t), cmpa2, cmpb2, epwm1.outputs.period_sync);
    epwm_step(&epwm3, static_cast<float>(t), cmpa3, cmpb3, epwm1.outputs.period_sync);
    epwm_step(&epwm4, static_cast<float>(t), cmpa4, cmpb4, epwm1.outputs.period_sync);

    // Rising edge detection for ClkOut for digital controller
    static bool prev_clk = false;
    if (bpwm_mod.outputs.ClkOut && !prev_clk)
    {
        /* digital controller code */
        // --- Example: Lowpass filter In1 using iir_t ---
        iir_step(&lpf, In1);
        Out6 = lpf.outputs.y;  // Example: filtered output to Out6
    }
    prev_clk = bpwm_mod.outputs.ClkOut;

    // Assign outputs to data union
    Out1 = bpwm_mod.outputs.PWM;
    Out2 = bpwm_mod.outputs.CenterAligned;
    Out3 = bpwm_mod.outputs.SawtoothUp;
    Out4 = bpwm_mod.outputs.SawtoothDown;
    Out5 = bpwm_mod.outputs.ClkOut ? 1.0f : 0.0f; /* Convert boolean to float for QSPICE */

    // Connect ePWM outputs to QSPICE pins:
    // ePWM1: Q1A, Q2A
    Q1A = epwm1.outputs.PWMA;
    Q2A = epwm1.outputs.PWMB;

    // ePWM2: Q3A, Q4A
    Q3A = epwm2.outputs.PWMA;
    Q4A = epwm2.outputs.PWMB;

    // ePWM3: Q5, Q6
    Q5 = epwm3.outputs.PWMA;
    Q6 = epwm3.outputs.PWMB;

    // ePWM4: Q7, Q8
    Q7 = epwm4.outputs.PWMA;
    Q8 = epwm4.outputs.PWMB;

    // Debug outputs from ePWM1 to monitor its behavior
    Out7 = epwm1.outputs.counter_normalized;                     // Counter value [0.0, 1.0]
    Out8 = static_cast<float>(epwm1.outputs.counter_direction);  // Counter direction
    Out9 = epwm1.outputs.period_sync ? 15.0f : 0.0f;             // Period sync signal
}
