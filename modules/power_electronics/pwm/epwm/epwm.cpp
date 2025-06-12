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
    p_state->counter_direction = EPWM_COUNT_UP;
    p_state->counter_value     = 0.0F;
    p_state->previous_counter  = 0.0F;
    p_state->pwma_state        = false;
    p_state->pwmb_state        = false;
    p_state->first_run         = true;
    /* Dead time values will be preserved/recalculated by reset function */
    p_state->dead_time_rising_norm  = 0.0F;
    p_state->dead_time_falling_norm = 0.0F;
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
    /* Phase offset is applied to the carrier itself */
    float const carrier_raw = t / p_epwm->params.Ts + (phase_offset / p_epwm->params.Ts);
    float const carrier_mod = carrier_raw - floorf(carrier_raw);

    /* Generate center-aligned (triangular) carrier */
    float counter_value = fabsf(2.0F * (carrier_mod - 0.5F));

    /* Determine counter direction based on position in cycle */
    epwm_count_direction_t counter_dir;
    if (carrier_mod < 0.5F)
    {
        counter_dir = EPWM_COUNT_UP;
    }
    else
    {
        counter_dir = EPWM_COUNT_DOWN;
    }

    /* Update state */
    p_epwm->state.counter_value     = counter_value;
    p_epwm->state.counter_direction = counter_dir;

    /* Set period_sync flag for start of period */
    p_epwm->outputs.period_sync = (fmodf(carrier_raw, 1.0F) < EPWM_TOLERANCE);
}

/**
 * @brief   Detect compare crossing events.
 * @param   current_counter   Current counter value.
 * @param   previous_counter  Previous counter value.
 * @param   compare_value     Compare threshold value.
 * @param   current_dir       Current counter direction.
 * @param   trigger_dir       Required trigger direction.
 * @return  true if crossing detected, false otherwise.
 */
static bool detect_compare_crossing(const float current_counter, const float previous_counter, const float compare_value,
                                    const epwm_count_direction_t current_dir, const epwm_count_direction_t trigger_dir)
{
    // Only center-aligned mode supported
    if (trigger_dir == EPWM_COUNT_UP && current_dir == EPWM_COUNT_UP)
    {
        return (previous_counter < compare_value) && (current_counter >= compare_value);
    }
    else if (trigger_dir == EPWM_COUNT_DOWN && current_dir == EPWM_COUNT_DOWN)
    {
        return (previous_counter > compare_value) && (current_counter <= compare_value);
    }
    return false;
}

/**
 * @brief   Apply dead time normalization (called only during initialization).
 * @param   p_epwm  Pointer to EPWM module instance.
 */
static void apply_dead_time(epwm_t* const p_epwm)
{
    /* Convert dead time to normalized units */
    /* Protect against division by zero and numerical instability */
    if (p_epwm->params.Ts > EPWM_TOLERANCE)
    {
        p_epwm->state.dead_time_rising_norm  = p_epwm->params.dead_time_rising / p_epwm->params.Ts;
        p_epwm->state.dead_time_falling_norm = p_epwm->params.dead_time_falling / p_epwm->params.Ts;
    }
    else
    {
        p_epwm->state.dead_time_rising_norm  = 0.0F;
        p_epwm->state.dead_time_falling_norm = 0.0F;
    }
}

/**
 * @brief   Process PWM actions based on compare events.
 * @param   p_epwm  Pointer to EPWM module instance.
 * @param   cmpa    Compare A value.
 * @param   cmpb    Compare B value.
 */
static void process_pwm_actions(epwm_t* const p_epwm, const float cmpa, const float cmpb)
{
    bool pwma_state = p_epwm->state.pwma_state; /* Maintain current state */
    bool pwmb_state = p_epwm->state.pwmb_state;

    /* Apply dead time to compare values and clamp to valid range [0.0, 1.0] */
    float const cmpa_rising  = fminf(1.0F, fmaxf(0.0F, cmpa + (p_epwm->state.dead_time_rising_norm * 0.5F)));
    float const cmpa_falling = fminf(1.0F, fmaxf(0.0F, cmpa - (p_epwm->state.dead_time_falling_norm * 0.5F)));
    float const cmpb_rising  = fminf(1.0F, fmaxf(0.0F, cmpb + (p_epwm->state.dead_time_rising_norm * 0.5F)));
    float const cmpb_falling = fminf(1.0F, fmaxf(0.0F, cmpb - (p_epwm->state.dead_time_falling_norm * 0.5F)));

    /* Process PWMA based on action mode */
    switch (p_epwm->params.pwma_mode)
    {
    case EPWM_ACTION_CMPB_DOWN_CMPA_UP:
        /* Check for rising edge on CMPB down-count */
        if (detect_compare_crossing(p_epwm->state.counter_value, p_epwm->state.previous_counter, cmpb_rising, p_epwm->state.counter_direction,
                                    EPWM_COUNT_DOWN))
        {
            pwma_state = true;
        }
        /* Check for falling edge on CMPA up-count */
        if (detect_compare_crossing(p_epwm->state.counter_value, p_epwm->state.previous_counter, cmpa_falling, p_epwm->state.counter_direction,
                                    EPWM_COUNT_UP))
        {
            pwma_state = false;
        }
        break;

    case EPWM_ACTION_CMPA_DOWN_CMPB_UP:
        /* Check for rising edge on CMPA down-count */
        if (detect_compare_crossing(p_epwm->state.counter_value, p_epwm->state.previous_counter, cmpa_rising, p_epwm->state.counter_direction,
                                    EPWM_COUNT_DOWN))
        {
            pwma_state = true;
        }
        /* Check for falling edge on CMPB up-count */
        if (detect_compare_crossing(p_epwm->state.counter_value, p_epwm->state.previous_counter, cmpb_falling, p_epwm->state.counter_direction,
                                    EPWM_COUNT_UP))
        {
            pwma_state = false;
        }
        break;

    default:
        break;
    }

    /* Process PWMB based on action mode */
    switch (p_epwm->params.pwmb_mode)
    {
    case EPWM_ACTION_CMPB_DOWN_CMPA_UP:
        /* Check for rising edge on CMPB down-count */
        if (detect_compare_crossing(p_epwm->state.counter_value, p_epwm->state.previous_counter, cmpb_rising, p_epwm->state.counter_direction,
                                    EPWM_COUNT_DOWN))
        {
            pwmb_state = true;
        }
        /* Check for falling edge on CMPA up-count */
        if (detect_compare_crossing(p_epwm->state.counter_value, p_epwm->state.previous_counter, cmpa_falling, p_epwm->state.counter_direction,
                                    EPWM_COUNT_UP))
        {
            pwmb_state = false;
        }
        break;

    case EPWM_ACTION_CMPA_DOWN_CMPB_UP:
        /* Check for rising edge on CMPA down-count */
        if (detect_compare_crossing(p_epwm->state.counter_value, p_epwm->state.previous_counter, cmpa_rising, p_epwm->state.counter_direction,
                                    EPWM_COUNT_DOWN))
        {
            pwmb_state = true;
        }
        /* Check for falling edge on CMPB up-count */
        if (detect_compare_crossing(p_epwm->state.counter_value, p_epwm->state.previous_counter, cmpb_falling, p_epwm->state.counter_direction,
                                    EPWM_COUNT_UP))
        {
            pwmb_state = false;
        }
        break;

    default:
        break;
    }

    /* Update states */
    p_epwm->state.pwma_state = pwma_state;
    p_epwm->state.pwmb_state = pwmb_state;
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
    /* Handle first run initialization */
    if (p_epwm->state.first_run)
    {
        p_epwm->state.first_run = false;
        /* Initialize with actual time */
        calculate_counter_state(p_epwm, t, p_epwm->params.phase_offset);
        p_epwm->state.previous_counter = p_epwm->state.counter_value;
        return; /* Skip action processing on first step */
    }

    /* Store previous counter value for edge detection */
    p_epwm->state.previous_counter = p_epwm->state.counter_value;

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

    /* Process PWM actions */
    process_pwm_actions(p_epwm, cmpa, cmpb);

    /* Generate outputs */
    p_epwm->outputs.PWMA = p_epwm->state.pwma_state ? p_epwm->params.gate_on_voltage : p_epwm->params.gate_off_voltage;
    p_epwm->outputs.PWMB = p_epwm->state.pwmb_state ? p_epwm->params.gate_on_voltage : p_epwm->params.gate_off_voltage;

    /* Update output information */
    p_epwm->outputs.counter_normalized = p_epwm->state.counter_value;
    p_epwm->outputs.counter_direction  = p_epwm->state.counter_direction;
}
