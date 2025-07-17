/**
 * *************************** In The Name Of God ***************************
 * @file    cpwm.h
 * @brief   Center-aligned PWM module interface with single compare and dead time
 * @author  Dr.-Ing. Hossein Abedini
 * @date    2025-07-02
 * Provides center-aligned PWM generation with single compare value, dead time,
 * and complementary outputs for power electronics control applications.
 * @note    Designed for real-time signal processing applications.
 * @license This work is dedicated to the public domain under CC0 1.0.
 *          Please use it for good and beneficial purposes!
 ***************************************************************************/

#ifndef CPWM_H
#define CPWM_H

#ifdef __cplusplus
extern "C"
{
#endif

    /********************************* INCLUDES **********************************/

#include <stdint.h>

/********************************* MACROS ************************************/

/**
 * @brief Helper macro to convert degrees to phase offset in seconds for the given frequency
 * @param degrees Phase offset in degrees (0-360)
 * @param frequency PWM frequency in Hz
 * @return Phase offset in seconds
 */
#define DEGREES_TO_PHASE_OFFSET(degrees, frequency) ((degrees) / 360.0F / (frequency))

    /***************************** TYPE DEFINITIONS ******************************/

    /**
     * @brief Parameters for CPWM module configuration.
     * Fs: carrier frequency in Hz [1000, 1000000]
     * gate_on_voltage: output voltage when PWM is ON [0.0, 24.0]
     * gate_off_voltage: output voltage when PWM is OFF [0.0, 24.0]
     * sync_enable: enable external synchronization
     * phase_offset: phase offset in seconds
     * dead_time: dead time in seconds
     */
    typedef struct
    {
        float Fs;               /* Carrier frequency in Hz [1000, 1000000] */
        float gate_on_voltage;  /* Output voltage when PWM is ON [0.0, 24.0] */
        float gate_off_voltage; /* Output voltage when PWM is OFF [0.0, 24.0] */
        bool  sync_enable;      /* Enable external synchronization */
        float phase_offset;     /* Phase offset in seconds */
        float dead_time;        /* Dead time in seconds */
        float duty_cycle;       /* Duty cycle [0.0, 1.0] */
    } cpwm_params_t;

    /**
     * @brief Internal state for CPWM module operation.
     */
    typedef struct
    {
        /* Normalized dead time value (calculated once during init) */
        float dead_time_norm; /* Normalized dead time */

        /* Pre-calculated compare values with dead time applied */
        float cmp_lead; /* Compare leading edge value */
        float cmp_lag;  /* Compare lagging edge value */
    } cpwm_state_t;

    /**
     * @brief Output signals from CPWM module processing.
     * PWMA: first PWM output channel
     * PWMB: second PWM output channel (complementary with dead time)
     * counter_normalized: current counter value [0.0, 1.0]
     * period_sync: true at start of each PWM period
     */
    typedef struct
    {
        float PWMA;               /* PWM output A signal [0, gate_on_voltage] */
        float PWMB;               /* PWM output B signal [0, gate_on_voltage] */
        float counter_normalized; /* Current counter value [0.0, 1.0] */
        bool  period_sync;        /* Clock output at start of PWM period */
    } cpwm_outputs_t;

    /**
     * @brief Complete CPWM module structure encapsulating all components.
     */
    typedef struct
    {
        cpwm_params_t  params;
        cpwm_state_t   state;
        cpwm_outputs_t outputs;
    } cpwm_t;

    /************************* FUNCTION PROTOTYPES *******************************/

    /**
     * @brief   Initialize the CPWM module with given parameters.
     * @param   p_cpwm    Pointer to the CPWM module instance.
     * @param   p_params  Pointer to initialization parameters.
     */
    void cpwm_init(cpwm_t* const p_cpwm, const cpwm_params_t* const p_params);

    /**
     * @brief   Reset the CPWM module to initial state while preserving parameters.
     * @param   p_cpwm    Pointer to the CPWM module instance.
     */
    void cpwm_reset(cpwm_t* const p_cpwm);

    /**
     * @brief   Execute one processing step of the CPWM module using stored duty cycle.
     * @param   p_cpwm    Pointer to the CPWM module instance.
     * @param   t         Current time in seconds.
     * @param   sync_in   External synchronization input.
     */
    void cpwm_step(cpwm_t* const p_cpwm, const float t, const bool sync_in);

    /**
     * @brief   Update all PWM parameters at runtime in a single call.
     * @param   p_cpwm      Pointer to the CPWM module instance.
     * @param   frequency   New carrier frequency in Hz (set to 0 to keep current).
     * @param   dead_time   New dead time in seconds (set to negative to keep current).
     * @param   phase_offset New phase offset in seconds (set to NaN to keep current).
     * @param   duty_cycle  New duty cycle [0.0, 1.0] (set to negative to keep current).
     */
    void update_parameters(cpwm_t* const p_cpwm, const float frequency, const float dead_time, const float phase_offset, const float duty_cycle);

#ifdef __cplusplus
}
#endif

#endif  // CPWM_H
