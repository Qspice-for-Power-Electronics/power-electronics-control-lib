/**
 * *************************** In The Name Of God ***************************
 * @file    epwm.cpp
 * @brief   Enhanced PWM module implementation with center-aligned counter
 * @author  Dr.-Ing. Hossein Abedini
 * @date    2025-06-12
 * Implements enhanced PWM generation with center-aligned counter, dead time,
 * and advanced action modes for high-performance power electronics control.
 * @note    Designed for real-time signal processing applications.
 * @license This work is dedicated to the public domain under CC0 1.0.
 *          Please use it for good and beneficial purposes!
 ***************************************************************************/

/********************************* INCLUDES **********************************/
#include "epwm.h"
#include <math.h>

/********************************* DEFINES ***********************************/

/* EPWM module default constants */
#define EPWM_TOLERANCE (1e-4F) /* Tolerance for floating point comparisons */

/**************************** PRIVATE FUNCTIONS ******************************/

/**
 * @brief   Clear EPWM state to default values.
 * @param   p_state   Pointer to state structure to clear.
 */
static inline void clear_state(epwm_state_t* const p_state)
{
    /* Dead time values will be preserved/recalculated by reset function */
    p_state->dead_time_rising_norm  = 0.0F;
    p_state->dead_time_falling_norm = 0.0F;

    /* Initialize compare values */
    p_state->cmpa_lead = 0.0F;
    p_state->cmpa_lag  = 0.0F;
    p_state->cmpb_lead = 0.0F;
    p_state->cmpb_lag  = 0.0F;
}

/**
 * @brief   Clear EPWM outputs to default values.
 * @param   p_outputs Pointer to outputs structure to clear.
 * @param   gate_off_voltage Default off voltage for PWM outputs.
 */
static inline void clear_outputs(epwm_outputs_t* const p_outputs, const float gate_off_voltage)
{
    p_outputs->PWMA               = gate_off_voltage;
    p_outputs->PWMB               = gate_off_voltage;
    p_outputs->counter_normalized = 0.0F;
    p_outputs->counter_direction  = EPWM_COUNT_UP;
    p_outputs->period_sync        = false;
}

/**
 * @brief   Calculate counter state based on center-aligned (triangular) counter.
 * @param   p_epwm          Pointer to EPWM module instance.
 * @param   t               Current time in seconds.
 * @param   phase_offset    Phase offset in seconds.
 */
static void calculate_counter_state(epwm_t* const p_epwm, const float t)
{
    /* Phase offset is applied to the carrier itself - optimized with pre-computed inv_Ts */
    float const carrier_raw = (t + p_epwm->params.phase_offset) * p_epwm->params.inv_Ts;
    float const carrier_mod = carrier_raw - floorf(carrier_raw);

    /* Generate center-aligned (triangular) carrier */
    p_epwm->outputs.counter_normalized = fabsf(2.0F * (carrier_mod - 0.5F));

    /* Determine counter direction based on position in cycle */
    p_epwm->outputs.counter_direction = (carrier_mod < 0.5F) ? EPWM_COUNT_UP : EPWM_COUNT_DOWN;

    /* Set period_sync flag for start of period - reuse carrier_mod instead of fmodf */
    p_epwm->outputs.period_sync = (carrier_mod < EPWM_TOLERANCE);
}

/**
 * @brief   Apply dead time normalization (called only during initialization).
 * @param   p_epwm  Pointer to EPWM module instance.
 */
static void apply_dead_time(epwm_t* const p_epwm)
{
    /* Convert dead time to normalized units */
    p_epwm->state.dead_time_rising_norm  = p_epwm->params.dead_time_rising * p_epwm->params.inv_Ts;
    p_epwm->state.dead_time_falling_norm = p_epwm->params.dead_time_falling * p_epwm->params.inv_Ts;
}

/**
 * @brief   Calculate compare values with dead time applied.
 * @param   p_epwm  Pointer to EPWM module instance.
 * @param   cmpa    Compare A value [0.0, 1.0].
 * @param   cmpb    Compare B value [0.0, 1.0].
 */
static void calculate_compare_values(epwm_t* const p_epwm, const float cmpa, const float cmpb)
{
    /* Pre-calculate half dead time values to avoid repeated multiplication */
    float const half_rising_dt  = p_epwm->state.dead_time_rising_norm * 0.5F;
    float const half_falling_dt = p_epwm->state.dead_time_falling_norm * 0.5F; /* Calculate rising edge values (add half of rising dead time) */
    float const cmpa_lead_raw   = cmpa + half_rising_dt;
    float const cmpb_lead_raw   = cmpb + half_rising_dt;

    /* Calculate falling edge values (subtract half of falling dead time) */
    float const cmpa_lag_raw = cmpa - half_falling_dt;
    float const cmpb_lag_raw = cmpb - half_falling_dt;

    /* Clamp values to [0.0, 1.0] range - optimized clamping */
    p_epwm->state.cmpa_lead = (cmpa_lead_raw > 1.0F) ? 1.0F : ((cmpa_lead_raw < 0.0F) ? 0.0F : cmpa_lead_raw);
    p_epwm->state.cmpb_lead = (cmpb_lead_raw > 1.0F) ? 1.0F : ((cmpb_lead_raw < 0.0F) ? 0.0F : cmpb_lead_raw);
    p_epwm->state.cmpa_lag  = (cmpa_lag_raw > 1.0F) ? 1.0F : ((cmpa_lag_raw < 0.0F) ? 0.0F : cmpa_lag_raw);
    p_epwm->state.cmpb_lag  = (cmpb_lag_raw > 1.0F) ? 1.0F : ((cmpb_lag_raw < 0.0F) ? 0.0F : cmpb_lag_raw);
}

/**
 * @brief   Process PWM actions using comparison logic with dead time.
 * @param   p_epwm  Pointer to EPWM module instance.
 * @param   cmpa    Compare A value.
 * @param   cmpb    Compare B value.
 */
static void process_pwm_actions(epwm_t* const p_epwm, const float cmpa, const float cmpb)
{ /* Use pre-calculated compare values from state */
    float const cmpa_lead = p_epwm->state.cmpa_lead;
    float const cmpb_lead = p_epwm->state.cmpb_lead;
    float const cmpa_lag  = p_epwm->state.cmpa_lag;
    float const cmpb_lag  = p_epwm->state.cmpb_lag;

    /* Current counter value and direction */
    float const counter     = p_epwm->outputs.counter_normalized;
    bool const  is_count_up = (p_epwm->outputs.counter_direction == EPWM_COUNT_UP);

    /* Process PWM based on mode using comparison logic */
    switch (p_epwm->params.pwm_mode)
    {
    case EPWM_MODE_ACTIVE_HIGH_CMPA_FIRST:
        /* Mode 1: PWMA ON when (counter_direction && counter > cmpa_lead) || (!counter_direction && counter > cmpb_lead)
         *         PWMA uses lead values for both turn-on and turn-off */
        if ((is_count_up && counter > cmpa_lead) || (!is_count_up && counter > cmpb_lead))
        {
            p_epwm->outputs.PWMA = p_epwm->params.gate_on_voltage;
        }
        else
        {
            p_epwm->outputs.PWMA = p_epwm->params.gate_off_voltage;
        }
        // for deadtime it use lag
        if ((!is_count_up && counter < cmpb_lag) || (is_count_up && counter < cmpa_lag))
        {
            p_epwm->outputs.PWMB = p_epwm->params.gate_on_voltage;
        }
        else
        {
            p_epwm->outputs.PWMB = p_epwm->params.gate_off_voltage;
        }
        break;
    case EPWM_MODE_ACTIVE_HIGH_CMPA_SECOND:
        /* Mode 2: PWMA ON when (!counter_direction && counter < cmpa_lag) || (counter_direction && counter < cmpb_lag)
         *         Down-count: PWMA ON when counter below CMPA lag threshold
         *         Up-count: PWMA ON when counter below CMPB lag threshold
         *         PWMB is complementary to PWMA for dead-time operation */
        if ((!is_count_up && counter < cmpa_lag) || (is_count_up && counter < cmpb_lag))
        {
            p_epwm->outputs.PWMA = p_epwm->params.gate_on_voltage;
        }
        else
        {
            p_epwm->outputs.PWMA = p_epwm->params.gate_off_voltage;
        }
        // for deadtime it use lead
        if ((is_count_up && counter > cmpb_lead) || (!is_count_up && counter > cmpa_lead))
        {
            p_epwm->outputs.PWMB = p_epwm->params.gate_on_voltage;
        }
        else
        {
            p_epwm->outputs.PWMB = p_epwm->params.gate_off_voltage;
        }
        break;

    default:
        break;
    }
}

/**************************** PUBLIC FUNCTIONS *******************************/

/**
 * @brief   Initialize the EPWM module with given parameters.
 * @param   p_epwm    Pointer to the EPWM module instance.
 * @param   p_params  Pointer to initialization parameters.
 */
void epwm_init(epwm_t* const p_epwm, const epwm_params_t* const p_params)
{
    p_epwm->params.Ts                = p_params->Ts;
    p_epwm->params.inv_Ts            = 1.0F / p_epwm->params.Ts;
    p_epwm->params.pwm_mode          = p_params->pwm_mode;
    p_epwm->params.gate_on_voltage   = p_params->gate_on_voltage;
    p_epwm->params.gate_off_voltage  = p_params->gate_off_voltage;
    p_epwm->params.sync_enable       = p_params->sync_enable;
    p_epwm->params.phase_offset      = p_params->phase_offset;
    p_epwm->params.dead_time_rising  = p_params->dead_time_rising;
    p_epwm->params.dead_time_falling = p_params->dead_time_falling;

    /* Calculate dead time normalization before reset to preserve values */
    apply_dead_time(p_epwm);
    epwm_reset(p_epwm);
}

/**
 * @brief   Reset the EPWM module to initial state while preserving parameters.
 * @param   p_epwm    Pointer to the EPWM module instance.
 */
void epwm_reset(epwm_t* const p_epwm)
{
    /* Store dead time values before clearing */
    float const dead_time_rising_norm  = p_epwm->state.dead_time_rising_norm;
    float const dead_time_falling_norm = p_epwm->state.dead_time_falling_norm;
    clear_state(&p_epwm->state);
    clear_outputs(&p_epwm->outputs, p_epwm->params.gate_off_voltage);

    /* Restore dead time values */
    p_epwm->state.dead_time_rising_norm  = dead_time_rising_norm;
    p_epwm->state.dead_time_falling_norm = dead_time_falling_norm;
}

/**
 * @brief   Execute one processing step of the EPWM module.
 * @param   p_epwm    Pointer to the EPWM module instance.
 * @param   t         Current time in seconds.
 * @param   cmpa      Compare A value [0.0, 1.0].
 * @param   cmpb      Compare B value [0.0, 1.0].
 * @param   sync_in   External synchronization input.
 */
void epwm_step(epwm_t* const p_epwm, const float t, const float cmpa, const float cmpb, const bool sync_in)
{
    /* Handle synchronization reset */
    if (p_epwm->params.sync_enable && sync_in)
    {
        /* Reset the phase to synchronize with external signal */
        p_epwm->params.phase_offset = t;
    }

    /* Generate center-aligned counter */
    calculate_counter_state(p_epwm, t);

    /* Calculate compare values with dead time applied */
    calculate_compare_values(p_epwm, cmpa, cmpb);

    /* Process PWM actions */
    process_pwm_actions(p_epwm, cmpa, cmpb);
}
