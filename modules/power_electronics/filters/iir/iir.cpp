/**
 * *************************** In The Name Of God ***************************
 * @file    iir.cpp
 * @brief   Digital IIR filter module implementation for lowpass/highpass filtering
 * @author  Dr.-Ing. Hossein Abedini
 * @date    2025-06-01
 * Implements a configurable first-order IIR filter (lowpass/highpass).
 * @note    Designed for real-time signal processing applications.
 *
 * S-Domain Transfer Functions:
 * - Lowpass:  H(s) = ωc / (s + ωc)  where ωc = 2π * fc
 * - Highpass: H(s) = s / (s + ωc)   where ωc = 2π * fc
 *
 * Digital Implementation (Tustin/Bilinear Transform):
 * - Filter coefficient: a = 1 / (1 + 2*fc*Ts)
 * - Lowpass:  y[n] = a*u[n] + (1-a)*y[n-1]
 * - Highpass: y[n] = a*(u[n] - u[n-1]) + (1-a)*y[n-1]
 *
 * @license This work is dedicated to the public domain under CC0 1.0.
 *          Please use it for good and beneficial purposes!
 ***************************************************************************/

/********************************* INCLUDES **********************************/
#include "iir.h"
#include "math_constants.h"

/********************************* DEFINES ***********************************/

/**************************** PRIVATE FUNCTIONS ******************************/

/**
 * @brief   Clear IIR filter state to default values.
 * @param   p_state   Pointer to state structure to clear.
 */
static inline void clear_state(iir_state_t* const p_state)
{
    p_state->y_prev = 0.0F;
    p_state->u_prev = 0.0F;
}

/**
 * @brief   Clear IIR filter outputs to default values.
 * @param   p_outputs Pointer to outputs structure to clear.
 */
static inline void clear_outputs(iir_outputs_t* const p_outputs)
{
    p_outputs->y = 0.0F;
}

/**************************** PUBLIC FUNCTIONS *******************************/

/**
 * @brief   Calculate the IIR filter coefficient 'a' for a given sample time and cutoff frequency.
 * @param   Ts  Sample time (seconds)
 * @param   fc  Cutoff frequency (Hz)
 * @return  Filter coefficient a (0 < a <= 1)
 */
float iir_calc_a(float Ts, float fc)
{
    float const x = 2.0F * (float)M_PI * Ts * fc;
    return x / (x + 1.0F);
}

/**
 * @brief   Initialize the IIR filter module with given parameters.
 * @param   p_mod     Pointer to the IIR filter module instance.
 * @param   p_params  Pointer to initialization parameters.
 */
void iir_init(iir_t* const p_mod, const iir_params_t* const p_params)
{
    p_mod->params.Ts   = p_params->Ts;
    p_mod->params.fc   = p_params->fc;
    p_mod->params.type = p_params->type;
    p_mod->params.a    = p_params->a;

    // Auto-calculate coefficient if not provided or invalid
    if (p_mod->params.a <= 0.0F && p_mod->params.fc > 0.0F && p_mod->params.Ts > 0.0F)
    {
        p_mod->params.a = iir_calc_a(p_mod->params.Ts, p_mod->params.fc);
    }

    iir_reset(p_mod);
}

/**
 * @brief   Reset the IIR filter to initial state while preserving parameters.
 * @param   p_mod     Pointer to the IIR filter module instance.
 */
void iir_reset(iir_t* const p_mod)
{
    clear_state(&p_mod->state);
    clear_outputs(&p_mod->outputs);
}

/**
 * @brief   Execute one processing step of the IIR filter.
 * @param   p_mod          Pointer to the IIR filter module instance.
 * @param   input_signal   Input signal value to be filtered.
 */
void iir_step(iir_t* const p_mod, const float input_signal)
{
    float const a = p_mod->params.a;
    float const u = input_signal;
    float       y = 0.0F;
    if (p_mod->params.type == IIR_LOWPASS)
    {
        // Lowpass: y(k) = a*u(k) + (1-a)*y(k-1)
        y = a * u + (1.0F - a) * p_mod->state.y_prev;
    }
    else
    {
        // Highpass: y(k) = (1-a)*(u(k)-u(k-1)+y(k-1))
        y = (1.0F - a) * (u - p_mod->state.u_prev + p_mod->state.y_prev);
    }

    p_mod->outputs.y    = y;
    p_mod->state.y_prev = y;
    p_mod->state.u_prev = u;
}
