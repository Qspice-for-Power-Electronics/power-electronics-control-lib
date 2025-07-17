/**
 * *************************** In The Name Of God ***************************
 * @file    bpwm.cpp
 * @brief   Basic Digital PWM module implementation for carrier-based PWM generation
 * @author  Dr.-Ing. Hossein Abedini
 * @date    2025-06-01
 * Implements phase-shifted PWM generation using selectable carrier waveforms.
 * @note    Designed for real-time signal processing applications.
 * @license This work is dedicated to the public domain under CC0 1.0.
 *          Please use it for good and beneficial purposes!
 ***************************************************************************/

/********************************* INCLUDES **********************************/
#include "bpwm.h"
#include "math_constants.h"
#include <math.h>

/********************************* DEFINES ***********************************/

/* BPWM module default constants */
#define BPWM_PHASE_TOLERANCE (1e-4F) /* Tolerance for floating point comparisons */

/**************************** PRIVATE FUNCTIONS ******************************/

/**
 * @brief   Clear BPWM state to default values.
 * @param   p_state   Pointer to state structure to clear.
 */
// static inline void clear_state(bpwm_state_t* const p_state)
// {
//     p_state->unused = 0; /* No state needed for stateless PWM implementation */
// }

/**
 * @brief   Clear BPWM outputs to default values.
 * @param   p_outputs Pointer to outputs structure to clear.
 */
static inline void clear_outputs(bpwm_outputs_t* const p_outputs)
{
    p_outputs->PWM           = 0.0F;
    p_outputs->SawtoothUp    = 0.0F;
    p_outputs->CenterAligned = 0.0F;
    p_outputs->SawtoothDown  = 0.0F;
    p_outputs->ClkOut        = false;
}

/**************************** PUBLIC FUNCTIONS *******************************/

/**
 * @brief   Initialize the BPWM module with given parameters.
 * @param   p_bpwm    Pointer to the BPWM module instance.
 * @param   p_params  Pointer to initialization parameters.
 */
void bpwm_init(bpwm_t* const p_bpwm, const bpwm_params_t* const p_params)
{
    p_bpwm->params.Ts               = p_params->Ts;
    p_bpwm->params.carrier_select   = p_params->carrier_select;
    p_bpwm->params.gate_on_voltage  = p_params->gate_on_voltage;
    p_bpwm->params.gate_off_voltage = p_params->gate_off_voltage;

    bpwm_reset(p_bpwm);
}

/**
 * @brief   Reset the BPWM module to initial state while preserving parameters.
 * @param   p_bpwm    Pointer to the BPWM module instance.
 */
void bpwm_reset(bpwm_t* const p_bpwm)
{
    // clear_state(&p_bpwm->state); /* No state needed for stateless PWM implementation */
    clear_outputs(&p_bpwm->outputs);
}

/**
 * @brief   Execute one processing step of the BPWM module.
 * @param   p_bpwm       Pointer to the BPWM module instance.
 * @param   t            Current time in seconds.
 * @param   duty         Duty cycle [0.0, 1.0].
 * @param   phase        Phase offset in radians [-2π, 2π].
 */
void bpwm_step(bpwm_t* const p_bpwm, const float t, const float duty, const float phase)
{
    /* Phase offset is applied to the carrier itself, so all outputs are phase-shifted */
    float const phase_frac  = phase / (2.0F * (float)M_PI); /* -1..1 for -2pi..2pi */
    float const carrier_raw = (t / p_bpwm->params.Ts) + phase_frac;
    float const carrier     = carrier_raw - floorf(carrier_raw);

    /* Generate all carrier waveforms */
    p_bpwm->outputs.SawtoothUp    = carrier;
    p_bpwm->outputs.CenterAligned = fabsf(2.0F * (carrier - 0.5F));
    p_bpwm->outputs.SawtoothDown  = 1.0F - carrier;

    /* Select carrier based on configuration */
    float selected_carrier = 0.0F;
    switch (p_bpwm->params.carrier_select)
    {
    case BPWM_CARRIER_CENTER_ALIGNED:
        selected_carrier = p_bpwm->outputs.CenterAligned;
        break;
    case BPWM_CARRIER_SAWTOOTH_UP:
        selected_carrier = p_bpwm->outputs.SawtoothUp;
        break;
    case BPWM_CARRIER_SAWTOOTH_DOWN:
        selected_carrier = p_bpwm->outputs.SawtoothDown;
        break;
    default:
        selected_carrier = p_bpwm->outputs.CenterAligned; /* Default to center-aligned */
        break;
    }

    /* ClkOut: true at counter reset (start of period), else false */
    p_bpwm->outputs.ClkOut = static_cast<bool>(fmodf(carrier_raw, 1.0F) < BPWM_PHASE_TOLERANCE); /* PWM output: pulse when selected carrier < duty */
    p_bpwm->outputs.PWM    = (selected_carrier < duty) ? p_bpwm->params.gate_on_voltage : p_bpwm->params.gate_off_voltage;
}
