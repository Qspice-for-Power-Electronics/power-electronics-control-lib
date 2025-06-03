// ***************************************************************************
// * @file    iir.cpp
// * @brief   Digital IIR filter module implementation for lowpass/highpass filtering.
// * @author  Hossein Abedini
// * @date    2025-06-01
// *
// * Implements a configurable first-order IIR filter (lowpass/highpass).
// ***************************************************************************

/********************************* INCLUDES **********************************/
#include "iir.h"
#include <assert.h>
#include <math.h>

/**************************** PUBLIC FUNCTIONS *******************************/

/**
 * @brief   Calculate the IIR filter coefficient 'a' for a given sample time and cutoff frequency.
 * @param   Ts  Sample time (seconds)
 * @param   fc  Cutoff frequency (Hz)
 * @return  Filter coefficient a (0 < a <= 1)
 */
float iir_calc_a(float Ts, float fc)
{
    float x = 2.0f * (float)M_PI * Ts * fc;
    return x / (x + 1.0f);
}

/**
 * @brief   Initialize the IIR filter module with the given parameters (or defaults if params is
 * null).
 * @param   mod     Pointer to the IIR filter module instance.
 * @param   params  Pointer to parameters, or NULL for defaults.
 */
void iir_module_init(IirModule *mod, const IirParams *params)
{
    if (params)
    {
        mod->params = *params;
        if (mod->params.a <= 0.0f && mod->params.fc > 0.0f && mod->params.Ts > 0.0f)
            mod->params.a = iir_calc_a(mod->params.Ts, mod->params.fc);
    }
    else
    {
#ifdef _MSC_VER
        __debugbreak(); // MSVC: trigger a debug break if params is not provided
#else
        assert(params && "iir_module_init: params must not be NULL");
#endif
        return;
    }
    mod->state.y_prev = 0.0f;
    mod->state.u_prev = 0.0f;
    mod->in.u = 0.0f;
    mod->out.y = 0.0f;
}

/**
 * @brief   Advances the IIR filter module by one step, updating the output based on the current
 * state and inputs.
 * @param   mod     Pointer to the IIR filter module instance.
 */
void iir_module_step(IirModule *mod)
{
    float a = mod->params.a;
    float u = mod->in.u;
    float y = 0.0f;
    if (mod->params.type == 0)
    {
        // Lowpass: y(k) = a*u(k) + (1-a)*y(k-1)
        y = a * u + (1.0f - a) * mod->state.y_prev;
    }
    else
    {
        // Highpass: y(k) = (1-a)*(u(k)-u(k-1)+y(k-1))
        y = (1.0f - a) * (u - mod->state.u_prev + mod->state.y_prev);
    }
    mod->out.y = y;
    mod->state.y_prev = y;
    mod->state.u_prev = u;
}
