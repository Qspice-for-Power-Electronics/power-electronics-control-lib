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
#include "math_constants.h"
#include <assert.h>
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
    p_state->cmpa_rising  = 0.0F;
    p_state->cmpa_falling = 0.0F;
    p_state->cmpb_rising  = 0.0F;
    p_state->cmpb_falling = 0.0F;
}

/**
 * @brief   Clear EPWM outputs to default values.
 * @param   p_outputs Pointer to outputs structure to clear.
 */
static inline void clear_outputs(epwm_outputs_t* const p_outputs)
{
    p_outputs->PWMA               = 0.0F;
    p_outputs->PWMB               = 0.0F;
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
static void calculate_counter_state(epwm_t* const p_epwm, const float t, const float phase_offset)
{
    /* Phase offset is applied to the carrier itself - optimized with pre-computed inv_Ts */
    float const carrier_raw = (t + phase_offset) * p_epwm->params.inv_Ts;
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
    float const half_falling_dt = p_epwm->state.dead_time_falling_norm * 0.5F;

    /* Calculate rising edge values (add half of rising dead time) */
    float const cmpa_rising_raw = cmpa + half_rising_dt;
    float const cmpb_rising_raw = cmpb + half_rising_dt;

    /* Calculate falling edge values (subtract half of falling dead time) */
    float const cmpa_falling_raw = cmpa - half_falling_dt;
    float const cmpb_falling_raw = cmpb - half_falling_dt;

    /* Clamp values to [0.0, 1.0] range - optimized clamping */
    p_epwm->state.cmpa_rising  = (cmpa_rising_raw > 1.0F) ? 1.0F : ((cmpa_rising_raw < 0.0F) ? 0.0F : cmpa_rising_raw);
    p_epwm->state.cmpb_rising  = (cmpb_rising_raw > 1.0F) ? 1.0F : ((cmpb_rising_raw < 0.0F) ? 0.0F : cmpb_rising_raw);
    p_epwm->state.cmpa_falling = (cmpa_falling_raw > 1.0F) ? 1.0F : ((cmpa_falling_raw < 0.0F) ? 0.0F : cmpa_falling_raw);
    p_epwm->state.cmpb_falling = (cmpb_falling_raw > 1.0F) ? 1.0F : ((cmpb_falling_raw < 0.0F) ? 0.0F : cmpb_falling_raw);
}

/**
 * @brief   Process PWM actions based on direct comparison logic.
 * @param   p_epwm  Pointer to EPWM module instance.
 * @param   cmpa    Compare A value.
 * @param   cmpb    Compare B value.
 */
static void process_pwm_actions(epwm_t* const p_epwm, const float cmpa, const float cmpb)
{
    /* Use pre-calculated compare values from state */
    float const cmpa_rising  = p_epwm->state.cmpa_rising;
    float const cmpb_rising  = p_epwm->state.cmpb_rising;
    float const cmpa_falling = p_epwm->state.cmpa_falling;
    float const cmpb_falling = p_epwm->state.cmpb_falling;

    p_epwm->outputs.debug_1 = cmpa_rising;                    /* Debug: store CMPA rising */
    p_epwm->outputs.debug_2 = cmpa_falling;                   /* Debug: store CMPA falling */
    p_epwm->outputs.debug_3 = cmpb_rising;                    /* Debug: store CMPB rising */
    p_epwm->outputs.debug_4 = cmpb_falling;                   /* Debug: store
                  
                      /* Current counter value */
    float const counter = p_epwm->outputs.counter_normalized; /* Process PWMA based on action mode */
    switch (p_epwm->params.pwma_mode)
    {
    case EPWM_ACTION_CMPB_DOWN_CMPA_UP:
        /* PWM rising edge on CMPB down-count, falling edge on CMPA up-count */
        if (counter > cmpb_rising)
        {
            p_epwm->outputs.PWMA = p_epwm->params.gate_on_voltage;
        }
        else if (counter < cmpa_falling)
        {
            p_epwm->outputs.PWMA = p_epwm->params.gate_off_voltage;
        }
        /* Keep current state when between CMPA and CMPB */
        break;

    case EPWM_ACTION_CMPA_DOWN_CMPB_UP:
        /* PWM rising edge on CMPA down-count, falling edge on CMPB up-count */
        if (counter > cmpa_rising)
        {
            p_epwm->outputs.PWMA = p_epwm->params.gate_on_voltage;
        }
        else if (counter < cmpb_falling)
        {
            p_epwm->outputs.PWMA = p_epwm->params.gate_off_voltage;
        }
        /* Keep current state when between CMPB and CMPA */
        break;

    default:
        break;
    } /* Process PWMB based on action mode */
    switch (p_epwm->params.pwmb_mode)
    {
    case EPWM_ACTION_CMPB_DOWN_CMPA_UP:
        /* PWM rising edge on CMPB down-count, falling edge on CMPA up-count */
        if (counter > cmpb_rising)
        {
            p_epwm->outputs.PWMB = p_epwm->params.gate_on_voltage;
        }
        else if (counter < cmpa_falling)
        {
            p_epwm->outputs.PWMB = p_epwm->params.gate_off_voltage;
        }
        /* Keep current state when between CMPA and CMPB */
        break;

    case EPWM_ACTION_CMPA_DOWN_CMPB_UP:
        /* PWM rising edge on CMPA down-count, falling edge on CMPB up-count */
        if (counter > cmpa_rising)
        {
            p_epwm->outputs.PWMB = p_epwm->params.gate_on_voltage;
        }
        else if (counter < cmpb_falling)
        {
            p_epwm->outputs.PWMB = p_epwm->params.gate_off_voltage;
        }
        /* Keep current state when between CMPB and CMPA */
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
    /* Validate parameters */
    assert(p_params->Ts > 0.0F);
    assert(p_params->dead_time_rising >= 0.0F);
    assert(p_params->dead_time_falling >= 0.0F);

    p_epwm->params.Ts                = p_params->Ts;
    p_epwm->params.inv_Ts            = 1.0F / p_epwm->params.Ts;
    p_epwm->params.pwma_mode         = p_params->pwma_mode;
    p_epwm->params.pwmb_mode         = p_params->pwmb_mode;
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
    clear_outputs(&p_epwm->outputs);

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
    /* Calculate current counter value with phase offset */
    float phase_offset = p_epwm->params.phase_offset;

    /* Handle synchronization reset */
    if (p_epwm->params.sync_enable && sync_in)
    {
        /* Reset the phase to synchronize with external signal */
        phase_offset = t;
    }

    /* Generate center-aligned counter */
    calculate_counter_state(p_epwm, t, phase_offset);

    /* Calculate compare values with dead time applied */
    calculate_compare_values(p_epwm, cmpa, cmpb);

    /* Process PWM actions */
    process_pwm_actions(p_epwm, cmpa, cmpb);
}
