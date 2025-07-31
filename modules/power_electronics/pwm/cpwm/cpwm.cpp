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
#define CPWM_TOLERANCE           (1e-4F) /* Tolerance for floating point comparisons */
#define CPWM_WRAP_HIGH_THRESHOLD (0.9F)  /* Upper threshold for counter wrap detection */
#define CPWM_WRAP_LOW_THRESHOLD  (0.1F)  /* Lower threshold for counter wrap detection */

/**************************** PRIVATE FUNCTIONS ******************************/

/**
 * @brief   Clear CPWM state to default values.
 * @param   p_state   Pointer to state structure to clear.
 */
static inline void clear_state(cpwm_state_t* const p_state)
{
    /* Initialize compare values */
    p_state->cmp_lead = 0.0F;
    p_state->cmp_lag  = 0.0F;

    /* Initialize frequency continuity tracking */
    p_state->current_Fs               = 0.0F;
    p_state->pending_Fs               = 0.0F;
    p_state->frequency_change_pending = false;

    /* Initialize phase tracking */
    p_state->cumulative_phase_applied = 0.0F;

    /* Initialize counter tracking */
    p_state->last_time        = 0.0F;
    p_state->internal_counter = 0.0F;
    p_state->prev_counter     = 0.0F;
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
 * @brief   Calculate counter state based on center-aligned (triangular) counter with continuity.
 * @param   p_cpwm          Pointer to CPWM module instance.
 * @param   t               Current time in seconds.
 */
static void calculate_counter_state(cpwm_t* const p_cpwm, const float t)
{
    /* Handle initial setup on first call */
    if (p_cpwm->state.current_Fs == 0.0F)
    {
        p_cpwm->state.current_Fs       = p_cpwm->params.Fs;
        p_cpwm->state.last_time        = t;
        p_cpwm->state.internal_counter = 0.0F;
    }

    /* Calculate time step with protection against time going backward */
    float dt = t - p_cpwm->state.last_time;
    if (dt < 0.0F)
    {
        dt = 0.0F; /* Protect against time going backward */
    }
    p_cpwm->state.last_time = t;

    /* Update internal counter based on current frequency */
    p_cpwm->state.internal_counter += dt * p_cpwm->state.current_Fs;

    /* Track if counter wrapped around for period_sync detection */
    bool counter_wrapped = false;

    /* Ensure counter stays in [0,1] range - equivalent to modulo 1.0 operation */
    if (p_cpwm->state.internal_counter >= 1.0F)
    {
        counter_wrapped = true;
        p_cpwm->state.internal_counter -= floorf(p_cpwm->state.internal_counter);
    }

    /* Apply temporary frequency for phase shift at period boundaries */
    if (counter_wrapped)
    {
        /* First priority: Restore normal frequency after temporary phase shift cycle */
        if (p_cpwm->state.frequency_change_pending)
        {
            p_cpwm->state.current_Fs               = p_cpwm->state.pending_Fs;
            p_cpwm->state.frequency_change_pending = false;
        }
        /* Second priority: Check if we need to apply a phase shift */
        else
        {
            /* Calculate the phase difference to apply
               Only apply the difference between requested and already applied phase */
            float const phase_difference = p_cpwm->params.phase_offset - p_cpwm->state.cumulative_phase_applied;

            if (fabsf(phase_difference) > 1e-9F) /* Only apply if difference is significant */
            {
                /* Calculate the temporary frequency needed to achieve desired phase shift in one cycle
                   For phase advancement: shorter period = higher frequency
                   For phase delay: longer period = lower frequency

                   Normal period = 1/Fs
                   Phase difference in time = phase_difference (already in seconds)
                   Shifted period = Normal period - phase_difference (subtract for advancement, add for delay)
                   Temp frequency = 1/(Normal period - phase_difference) = Fs/(1 - Fs*phase_difference)

                   HOW THE PHASE SHIFT WORKS:
                   - Normal cycle time: T = 1/Fs = 10μs (for 100kHz)
                   - For +90° phase advance at 100kHz: phase_difference = +2.5μs
                   - Shortened cycle: T_short = 10μs - 2.5μs = 7.5μs
                   - Temp frequency: f_temp = 1/7.5μs = 133.33kHz (33% higher)
                   - After this ONE fast cycle, we return to normal 100kHz
                   - Result: The PWM output is now 90° (2.5μs) ahead of where it would have been
                   - This creates a smooth phase shift without abrupt counter jumps */
                float const normal_freq = p_cpwm->params.Fs;
                float const temp_freq   = normal_freq / (1.0F - normal_freq * phase_difference);

                /* Apply temporary frequency for this cycle */
                p_cpwm->state.current_Fs = temp_freq;

                /* Mark that we need to restore frequency next cycle */
                p_cpwm->state.pending_Fs               = normal_freq;
                p_cpwm->state.frequency_change_pending = true;

                /* Update cumulative phase applied */
                p_cpwm->state.cumulative_phase_applied = p_cpwm->params.phase_offset;
            }
        }
    }

    /* Use the continuous internal counter directly for triangular carrier generation */
    float carrier_mod = p_cpwm->state.internal_counter;

    /* Generate center-aligned (triangular) carrier */
    p_cpwm->outputs.counter_normalized = fabsf(2.0F * (carrier_mod - 0.5F));

    /* Enhanced period_sync detection - will trigger even with large time steps:
       1. If counter wrapped around from one cycle to the next
       2. OR if we're near the start of period (within tolerance)
       3. OR if we crossed over from high to low threshold (handles very large steps) */
    p_cpwm->outputs.period_sync =
        counter_wrapped || (carrier_mod < CPWM_TOLERANCE)
        || (p_cpwm->state.prev_counter > CPWM_WRAP_HIGH_THRESHOLD && p_cpwm->state.internal_counter < CPWM_WRAP_LOW_THRESHOLD);

    /* Store current counter for next iteration */
    p_cpwm->state.prev_counter = p_cpwm->state.internal_counter;
}

/**
 * @brief   Calculate compare values with dead time applied.
 * @param   p_cpwm  Pointer to CPWM module instance.
 * @param   cmp     Compare value [0.0, 1.0].
 */
static void calculate_compare_values(cpwm_t* const p_cpwm, const float cmp)
{
    /* Calculate current normalized dead time based on active frequency */
    /* Dead time in seconds remains constant, but normalized value changes with frequency */
    float const current_dead_time_norm = p_cpwm->params.dead_time * p_cpwm->state.current_Fs;
    float const half_dead_time         = current_dead_time_norm * 0.5F;

    /* Calculate rising edge values (add half of dead time) */
    float const cmp_lead_raw = cmp + half_dead_time;

    /* Calculate falling edge values (subtract half of dead time) */
    float const cmp_lag_raw = cmp - half_dead_time;

    /* Clamp values to [0.0, 1.0] range - optimized clamping */
    p_cpwm->state.cmp_lead = (cmp_lead_raw > 1.0F) ? 1.0F : ((cmp_lead_raw < 0.0F) ? 0.0F : cmp_lead_raw);
    p_cpwm->state.cmp_lag  = (cmp_lag_raw > 1.0F) ? 1.0F : ((cmp_lag_raw < 0.0F) ? 0.0F : cmp_lag_raw);

    /* Handle edge cases first */
    if (p_cpwm->state.cmp_lead <= 0.0F || p_cpwm->state.cmp_lag <= 0.0F)
    {
        /* 0% duty cycle - force both outputs off regardless of dead time */
        p_cpwm->state.cmp_lead = 0.0F;
        p_cpwm->state.cmp_lag  = 0.0F;
    }
    else if (p_cpwm->state.cmp_lead >= 1.0F || p_cpwm->state.cmp_lag >= 1.0F)
    {
        /* 100% duty cycle - force both outputs on regardless of dead time */
        p_cpwm->state.cmp_lead = 1.0F;
        p_cpwm->state.cmp_lag  = 1.0F;
    }
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

    /* Initialize continuity-related state variables */
    p_cpwm->state.current_Fs               = p_params->Fs;
    p_cpwm->state.pending_Fs               = p_params->Fs;
    p_cpwm->state.frequency_change_pending = false;
    p_cpwm->state.cumulative_phase_applied = 0.0F;
    p_cpwm->state.last_time                = 0.0F;
    p_cpwm->state.internal_counter         = 0.0F;
    p_cpwm->state.prev_counter             = 0.0F;

    cpwm_reset(p_cpwm);
}

/**
 * @brief   Reset the CPWM module to initial state while preserving parameters.
 * @param   p_cpwm    Pointer to the CPWM module instance.
 */
void cpwm_reset(cpwm_t* const p_cpwm)
{
    /* Store values that need to be preserved */
    float const current_Fs               = p_cpwm->state.current_Fs;
    float const pending_Fs               = p_cpwm->state.pending_Fs;
    bool const  frequency_change_pending = p_cpwm->state.frequency_change_pending;
    float const cumulative_phase_applied = p_cpwm->state.cumulative_phase_applied;
    float const last_time                = p_cpwm->state.last_time;
    float const internal_counter         = p_cpwm->state.internal_counter;
    float const prev_counter             = p_cpwm->state.prev_counter;

    clear_state(&p_cpwm->state);
    clear_outputs(&p_cpwm->outputs, p_cpwm->params.gate_off_voltage);

    /* Restore preserved values */
    p_cpwm->state.current_Fs               = current_Fs;
    p_cpwm->state.pending_Fs               = pending_Fs;
    p_cpwm->state.frequency_change_pending = frequency_change_pending;
    p_cpwm->state.cumulative_phase_applied = cumulative_phase_applied;
    p_cpwm->state.last_time                = last_time;
    p_cpwm->state.internal_counter         = internal_counter;
    p_cpwm->state.prev_counter             = prev_counter;
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
        /* Reset the internal counter to synchronize with external signal */
        p_cpwm->state.internal_counter = 0.0F;
        p_cpwm->state.last_time        = t;
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
    /* Queue frequency change for period boundary to maintain continuity */
    if (frequency > 0.0F)
    {
        /* Update the parameter for initialization purposes */
        p_cpwm->params.Fs = frequency;

        /* Queue the frequency change to apply at period boundary */
        p_cpwm->state.pending_Fs               = frequency;
        p_cpwm->state.frequency_change_pending = true;

        /* If state is not initialized yet, apply directly */
        if (p_cpwm->state.current_Fs == 0.0F)
        {
            p_cpwm->state.current_Fs               = frequency;
            p_cpwm->state.frequency_change_pending = false;
        }
    }

    /* Update dead time if valid */
    if (dead_time >= 0.0F)
    {
        p_cpwm->params.dead_time = dead_time;
    }

    /* Phase offset changes are applied immediately - always update the target phase */
    if (phase_offset == phase_offset) /* NaN check: NaN != NaN */
    {
        /* Always update the target phase offset - the differential logic is handled in calculate_counter_state */
        p_cpwm->params.phase_offset = phase_offset;
    }

    /* Update duty cycle if valid */
    if (duty_cycle >= 0.0F && duty_cycle <= 1.0F)
    {
        p_cpwm->params.duty_cycle = duty_cycle;
    }
}
