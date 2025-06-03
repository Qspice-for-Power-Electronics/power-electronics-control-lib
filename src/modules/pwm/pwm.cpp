/**
 * @file    pwm.cpp
 * @brief   Digital PWM module implementation for carrier-based PWM generation.
 * @author  Hossein Abedini
 * @date    2025-06-01
 *
 * Implements phase-shifted PWM generation using selectable carrier waveforms.
 */

/********************************* INCLUDES **********************************/
#include "pwm.h"
#include <assert.h>
#include <math.h>

/**************************** PUBLIC FUNCTIONS *******************************/

/**
 * @brief   Advances the PWM module by one step, updating all outputs based on the current state and
 * inputs.
 * @param   mod     Pointer to the PWM module instance.
 */
void pwm_module_step(PwmModule *mod)
{
    // Phase offset is applied to the carrier itself, so all outputs are phase-shifted
    float phase_frac = mod->in.phase / (2.0f * M_PI); // -1..1 for -2pi..2pi
    float carrier_raw = (mod->in.t / mod->params.Ts) + phase_frac;
    float carrier = carrier_raw - floorf(carrier_raw);

    // Carrier selection for PWM (now from params)
    float selected_carrier = 0.0f;
    switch (mod->params.carrier_select)
    {
    case 0:
        selected_carrier = fabsf(2.0f * (carrier - 0.5f));
        break; // CenterAligned
    case 1:
        selected_carrier = carrier;
        break; // SawtoothUp
    case 2:
        selected_carrier = 1.0f - carrier;
        break; // SawtoothDown
    default:
        selected_carrier = fabsf(2.0f * (carrier - 0.5f));
        break;
    }

    mod->out.SawtoothUp = carrier;
    mod->out.CenterAligned = fabsf(2.0f * (carrier - 0.5f));
    mod->out.SawtoothDown = 1.0f - carrier;

    // ClkOut: 1 at counter reset (start of period), else 0 (robust for floating point)
    mod->out.ClkOut = (fmod(carrier_raw, 1.0f) < 1e-4f) ? 1.0f : 0.0f;
    // PWM output: pulse when selected carrier < duty
    mod->out.PWM = (selected_carrier < mod->in.duty) ? mod->params.gate_on_voltage : 0.0f;
}

/**
 * @brief   Initializes the PWM module with the given parameters. Parameters must not be NULL.
 * @param   mod     Pointer to the PWM module instance.
 * @param   params  Pointer to parameters (must not be NULL).
 */
void pwm_module_init(PwmModule *mod, const PwmParams *params)
{
    if (params)
    {
        mod->params = *params;
    }
    else
    {
#ifdef _MSC_VER
        __debugbreak(); // MSVC: trigger a debug break if params is not provided
#else
        assert(params && "pwm_module_init: params must not be NULL");
#endif
        return;
    }
    // PwmState is empty
    mod->in.t = 0.0f;
    mod->in.duty = 0.0f;
    mod->in.phase = 0.0f;
    mod->out.PWM = 0.0f;
    mod->out.SawtoothUp = 0.0f;
    mod->out.CenterAligned = 0.0f;
    mod->out.SawtoothDown = 0.0f;
    mod->out.ClkOut = 0.0f;
}
