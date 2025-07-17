/**
 * *************************** In The Name Of God ***************************
 * @file    cpwm.cpp
 * @brief   Center-aligned PWM module implementation with single compare and dead time
 * @author  Dr.-Ing. Hossein Abedini
 * @date    2025-07-02
 * Implements center-aligned PWM generation with single compare value, dead time,
 * and complementary outputs for power electronics control applications.
 * @note    Designed for real-time signal processing applications.
 * @license This work is dedicated to the public domain under CC0 1.0.
 *          Please use it for good and beneficial purposes!
 ***************************************************************************/

/********************************* INCLUDES **********************************/
#include "cpwm.h"
#include <math.h>

/********************************* DEFINES ***********************************/

/* CPWM module default constants */
#define CPWM_TOLERANCE (1e-4F) /* Tolerance for floating point comparisons */

/**************************** PRIVATE FUNCTIONS ******************************/

/**
 * @brief   Clear CPWM state to default values.
 * @param   p_state   Pointer to state structure to clear.
 */
static inline void clear_state(cpwm_state_t* const p_state)
{
    /* Dead time value will be preserved/recalculated by reset function */
    p_state->dead_time_norm = 0.0F;

    /* Initialize compare values */
    p_state->cmp_lead = 0.0F;
    p_state->cmp_lag  = 0.0F;
}

/**
 * @brief   Clear CPWM outputs to default values.
 * @param   p_outputs Pointer to outputs structure to clear.
 * @param   gate_off_voltage Default off voltage for PWM outputs.
 */
static inline void clear_outputs(cpwm_outputs_t* const p_outputs, const float gate_off_voltage)
{
    p_outputs->PWMA               = gate_off_voltage;
    p_outputs->PWMB               = gate_off_voltage;
    p_outputs->counter_normalized = 0.0F;
    p_outputs->period_sync        = false;
}

/**
 * @brief   Calculate counter state based on center-aligned (triangular) counter.
 * @param   p_cpwm          Pointer to CPWM module instance.
 * @param   t               Current time in seconds.
 */
static void calculate_counter_state(cpwm_t* const p_cpwm, const float t)
{
    /* Phase offset is applied to the carrier itself */
    float const carrier_raw = (t + p_cpwm->params.phase_offset) * p_cpwm->params.Fs;
    float const carrier_mod = carrier_raw - floorf(carrier_raw);

    /* Generate center-aligned (triangular) carrier */
    p_cpwm->outputs.counter_normalized = fabsf(2.0F * (carrier_mod - 0.5F));

    /* Set period_sync flag for start of period - reuse carrier_mod instead of fmodf */
    p_cpwm->outputs.period_sync = (carrier_mod < CPWM_TOLERANCE);
}

/**
 * @brief   Apply dead time normalization (called only during initialization).
 * @param   p_cpwm  Pointer to CPWM module instance.
 */
static void apply_dead_time(cpwm_t* const p_cpwm)
{
    /* Convert dead time to normalized units */
    p_cpwm->state.dead_time_norm = p_cpwm->params.dead_time * p_cpwm->params.Fs;
}

/**
 * @brief   Calculate compare values with dead time applied.
 * @param   p_cpwm  Pointer to CPWM module instance.
 * @param   cmp     Compare value [0.0, 1.0].
 */
static void calculate_compare_values(cpwm_t* const p_cpwm, const float cmp)
{
    /* Pre-calculate half dead time value to avoid repeated multiplication */
    float const half_dead_time = p_cpwm->state.dead_time_norm * 0.5F;

    /* Calculate rising edge values (add half of dead time) */
    float const cmp_lead_raw = cmp + half_dead_time;

    /* Calculate falling edge values (subtract half of dead time) */
    float const cmp_lag_raw = cmp - half_dead_time;

    /* Clamp values to [0.0, 1.0] range - optimized clamping */
    p_cpwm->state.cmp_lead = (cmp_lead_raw > 1.0F) ? 1.0F : ((cmp_lead_raw < 0.0F) ? 0.0F : cmp_lead_raw);
    p_cpwm->state.cmp_lag  = (cmp_lag_raw > 1.0F) ? 1.0F : ((cmp_lag_raw < 0.0F) ? 0.0F : cmp_lag_raw);
}

/**
 * @brief   Process PWM actions using simplified comparison logic with dead time.
 * @param   p_cpwm  Pointer to CPWM module instance.
 * @param   cmp     Compare value.
 */
static void process_pwm_actions(cpwm_t* const p_cpwm, const float cmp)
{
    /* Use pre-calculated compare values from state */
    float const cmp_lead = p_cpwm->state.cmp_lead;
    float const cmp_lag  = p_cpwm->state.cmp_lag;

    /* Current counter value */
    float const counter = p_cpwm->outputs.counter_normalized;

    /* Simple logic: PWMA active when counter > cmp considering dead time */
    if (counter > cmp_lead)
    {
        p_cpwm->outputs.PWMA = p_cpwm->params.gate_on_voltage;
    }
    else
    {
        p_cpwm->outputs.PWMA = p_cpwm->params.gate_off_voltage;
    }

    /* PWMB complementary with dead time - active when counter < cmp_lag */
    if (counter < cmp_lag)
    {
        p_cpwm->outputs.PWMB = p_cpwm->params.gate_on_voltage;
    }
    else
    {
        p_cpwm->outputs.PWMB = p_cpwm->params.gate_off_voltage;
    }
}

/**************************** PUBLIC FUNCTIONS *******************************/

/**
 * @brief   Initialize the CPWM module with given parameters.
 * @param   p_cpwm    Pointer to the CPWM module instance.
 * @param   p_params  Pointer to initialization parameters.
 */
void cpwm_init(cpwm_t* const p_cpwm, const cpwm_params_t* const p_params)
{
    p_cpwm->params.Fs               = p_params->Fs;
    p_cpwm->params.gate_on_voltage  = p_params->gate_on_voltage;
    p_cpwm->params.gate_off_voltage = p_params->gate_off_voltage;
    p_cpwm->params.sync_enable      = p_params->sync_enable;
    p_cpwm->params.phase_offset     = p_params->phase_offset;
    p_cpwm->params.dead_time        = p_params->dead_time;
    p_cpwm->params.duty_cycle       = p_params->duty_cycle;

    /* Calculate dead time normalization before reset to preserve values */
    apply_dead_time(p_cpwm);
    cpwm_reset(p_cpwm);
}

/**
 * @brief   Reset the CPWM module to initial state while preserving parameters.
 * @param   p_cpwm    Pointer to the CPWM module instance.
 */
void cpwm_reset(cpwm_t* const p_cpwm)
{
    /* Store dead time value before clearing */
    float const dead_time_norm = p_cpwm->state.dead_time_norm;

    clear_state(&p_cpwm->state);
    clear_outputs(&p_cpwm->outputs, p_cpwm->params.gate_off_voltage);

    /* Restore dead time value */
    p_cpwm->state.dead_time_norm = dead_time_norm;
}

/**
 * @brief   Execute one processing step of the CPWM module using stored duty cycle.
 * @param   p_cpwm    Pointer to the CPWM module instance.
 * @param   t         Current time in seconds.
 * @param   sync_in   External synchronization input.
 */
void cpwm_step(cpwm_t* const p_cpwm, const float t, const bool sync_in)
{
    /* Handle synchronization reset */
    if (p_cpwm->params.sync_enable && sync_in)
    {
        /* Reset the phase to synchronize with external signal */
        p_cpwm->params.phase_offset = t;
    }

    /* Generate center-aligned counter */
    calculate_counter_state(p_cpwm, t);

    /* Calculate compare values with dead time applied using stored duty cycle */
    calculate_compare_values(p_cpwm, p_cpwm->params.duty_cycle);

    /* Process PWM actions */
    process_pwm_actions(p_cpwm, p_cpwm->params.duty_cycle);
}

/**
 * @brief   Update all PWM parameters at runtime in a single call.
 * @param   p_cpwm      Pointer to the CPWM module instance.
 * @param   frequency   New carrier frequency in Hz (set to 0 to keep current).
 * @param   dead_time   New dead time in seconds (set to negative to keep current).
 * @param   phase_offset New phase offset in seconds (set to NaN to keep current).
 * @param   duty_cycle  New duty cycle [0.0, 1.0] (set to negative to keep current).
 */
void update_parameters(cpwm_t* const p_cpwm, const float frequency, const float dead_time, const float phase_offset, const float duty_cycle)
{
    bool recalc_dead_time = false;

    /* Update frequency if valid */
    if (frequency > 0.0F)
    {
        p_cpwm->params.Fs = frequency;
        recalc_dead_time  = true;
    }

    /* Update dead time if valid */
    if (dead_time >= 0.0F)
    {
        p_cpwm->params.dead_time = dead_time;
        recalc_dead_time         = true;
    }

    /* Update phase offset if not NaN */
    if (phase_offset == phase_offset) /* NaN check: NaN != NaN */
    {
        p_cpwm->params.phase_offset = phase_offset;
    }

    /* Update duty cycle if valid */
    if (duty_cycle >= 0.0F && duty_cycle <= 1.0F)
    {
        p_cpwm->params.duty_cycle = duty_cycle;
    }

    /* Recalculate normalized dead time if frequency or dead time changed */
    if (recalc_dead_time)
    {
        apply_dead_time(p_cpwm);
    }
}
