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
#include "iir.h"
#include "pwm.h"

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
    float const& Q1A      = data[13].f;  // output
    float const& Q1B      = data[14].f;  // output
    float const& Q2A      = data[15].f;  // output
    float const& Q2B      = data[16].f;  // output
    float const& Q3A      = data[17].f;  // output
    float const& Q3B      = data[18].f;  // output
    float const& Q4A      = data[19].f;  // output
    float const& Q4B      = data[20].f;  // output
    float const& Q5       = data[21].f;  // output
    float const& Q6       = data[22].f;  // output
    float const& Q7       = data[23].f;  // output
    float const& Q8       = data[24].f;  // output
    float&       Out1     = data[25].f;  // output
    float&       Out2     = data[26].f;  // output
    float&       Out3     = data[27].f;  // output
    float&       Out4     = data[28].f;  // output
    float&       Out5     = data[29].f;  // output
    float&       Out6     = data[30].f;  // output
    float const& Out7     = data[31].f;  // output
    float const& Out8     = data[32].f;  // output
    float const& Out9     = data[33].f;  // output
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

    // Module initalization code
    static PwmModule mod;
    static IirModule lpf;
    static int       mod_initialized = 0;
    if (!mod_initialized)
    {
        PwmParams const pwm_params = {10e-6f, 0, 15.0f};  // Ts, carrier_select, gate_on_voltage
        pwm_module_init(&mod, &pwm_params);
        IirParams const lpf_params = {1e-4f, 100.0f, 0, 0.0f};  // Ts, fc, type=lowpass, a=auto
        iir_module_init(&lpf, &lpf_params);
        mod_initialized = 1;
    }

    // Update PWM module inputs
    mod.in.t = static_cast<float>(t);
    pwm_module_step(&mod);

    // Rising edge detection for ClkOut for digital controller
    static float prev_clk = 0.0f;
    if (mod.out.ClkOut && !prev_clk)
    {
        /* digital controller code */
        // --- Example: Lowpass filter In1 using IirModule ---
        lpf.in.u = In1;
        iir_module_step(&lpf);
        Out6         = lpf.out.y;  // Example: filtered output to Out6
        mod.in.duty  = 0.5f;       // Test: 50% duty cycle
        mod.in.phase = 0.0f;       // Test: 0 phase offset
    }
    prev_clk = mod.out.ClkOut;

    // Assign outputs to data union
    Out1 = mod.out.PWM;
    Out2 = mod.out.CenterAligned;
    Out3 = mod.out.SawtoothUp;
    Out4 = mod.out.SawtoothDown;
    Out5 = mod.out.ClkOut;
}
