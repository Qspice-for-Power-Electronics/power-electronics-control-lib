/**
 * *************************** In The Name Of God ***************************
 * @file    pwm.cpp
 * @brief   Digital PWM module implementation for carrier-based PWM generation
 * @author  Dr.-Ing. Hossein Abedini
 * @date    2025-06-01
 * Implements phase-shifted PWM generation using selectable carrier waveforms.
 * @note    Designed for real-time signal processing applications.
 * @license This work is dedicated to the public domain under CC0 1.0.
 *          Please use it for good and beneficial purposes!
 ***************************************************************************/

/********************************* INCLUDES **********************************/
#include "pwm.h"
#include "math_constants.h"
#include <assert.h>
#include <math.h>

/********************************* DEFINES ***********************************/

/* PWM module default constants */
#define PWM_PHASE_TOLERANCE (1e-4F) /* Tolerance for floating point comparisons */

/**************************** PRIVATE FUNCTIONS ******************************/

/**
 * @brief   Clear PWM state to default values.
 * @param   p_state   Pointer to state structure to clear.
 */
// static inline void clear_state(pwm_state_t* const p_state)
// {
//     p_state->unused = 0; /* No state needed for stateless PWM implementation */
// }

/**
 * @brief   Clear PWM outputs to default values.
 * @param   p_outputs Pointer to outputs structure to clear.
 */
static inline void clear_outputs(pwm_outputs_t* const p_outputs)
{
    p_outputs->PWM           = 0.0F;
    p_outputs->SawtoothUp    = 0.0F;
    p_outputs->CenterAligned = 0.0F;
    p_outputs->SawtoothDown  = 0.0F;
    p_outputs->ClkOut        = false;
}

/**************************** PUBLIC FUNCTIONS *******************************/

/**
 * @brief   Initialize the PWM module with given parameters.
 * @param   p_pwm     Pointer to the PWM module instance.
 * @param   p_params  Pointer to initialization parameters.
 */
void pwm_init(pwm_t* const p_pwm, const pwm_params_t* const p_params)
{
    p_pwm->params.Ts               = p_params->Ts;
    p_pwm->params.carrier_select   = p_params->carrier_select;
    p_pwm->params.gate_on_voltage  = p_params->gate_on_voltage;
    p_pwm->params.gate_off_voltage = p_params->gate_off_voltage;

    pwm_reset(p_pwm);
}

/**
 * @brief   Reset the PWM module to initial state while preserving parameters.
 * @param   p_pwm     Pointer to the PWM module instance.
 */
void pwm_reset(pwm_t* const p_pwm)
{
    // clear_state(&p_pwm->state); /* No state needed for stateless PWM implementation */
    clear_outputs(&p_pwm->outputs);
}

/**
 * @brief   Execute one processing step of the PWM module.
 * @param   p_pwm        Pointer to the PWM module instance.
 * @param   t            Current time in seconds.
 * @param   duty         Duty cycle [0.0, 1.0].
 * @param   phase        Phase offset in radians [-2π, 2π].
 */
void pwm_step(pwm_t* const p_pwm, const float t, const float duty, const float phase)
{
    /* Phase offset is applied to the carrier itself, so all outputs are phase-shifted */
    float const phase_frac  = phase / (2.0F * M_PI); /* -1..1 for -2pi..2pi */
    float       carrier_raw = (t / p_pwm->params.Ts) + phase_frac;
    float       carrier     = carrier_raw - floorf(carrier_raw);

    /* Generate all carrier waveforms */
    p_pwm->outputs.SawtoothUp    = carrier;
    p_pwm->outputs.CenterAligned = fabsf(2.0F * (carrier - 0.5F));
    p_pwm->outputs.SawtoothDown  = 1.0F - carrier;

    /* Select carrier based on configuration */
    float selected_carrier = 0.0F;
    switch (p_pwm->params.carrier_select)
    {
    case PWM_CARRIER_CENTER_ALIGNED:
        selected_carrier = p_pwm->outputs.CenterAligned;
        break;
    case PWM_CARRIER_SAWTOOTH_UP:
        selected_carrier = p_pwm->outputs.SawtoothUp;
        break;
    case PWM_CARRIER_SAWTOOTH_DOWN:
        selected_carrier = p_pwm->outputs.SawtoothDown;
        break;
    default:
        selected_carrier = p_pwm->outputs.CenterAligned; /* Default to center-aligned */
        break;
    }

    /* ClkOut: true at counter reset (start of period), else false */
    p_pwm->outputs.ClkOut = (fmodf(carrier_raw, 1.0F) < PWM_PHASE_TOLERANCE) ? true : false; /* PWM output: pulse when selected carrier < duty */
    p_pwm->outputs.PWM    = (selected_carrier < duty) ? p_pwm->params.gate_on_voltage : p_pwm->params.gate_off_voltage;
}
