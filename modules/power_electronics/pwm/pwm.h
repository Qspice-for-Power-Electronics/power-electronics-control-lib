/**
 * *************************** In The Name Of God ***************************
 * @file    pwm.h
 * @brief   Digital PWM module interface for carrier-based PWM generation
 * @author  Dr.-Ing. Hossein Abedini
 * @date    2025-06-01
 * Provides types and functions for generating phase-shifted PWM signals using
 * selectable carrier waveforms.
 * @note    Designed for real-time signal processing applications.
 * @license This work is dedicated to the public domain under CC0 1.0.
 *          Please use it for good and beneficial purposes!
 ***************************************************************************/

#ifndef PWM_H
#define PWM_H

#ifdef __cplusplus
extern "C"
{
#endif

/********************************* INCLUDES **********************************/
#include <stdint.h>

    /***************************** TYPE DEFINITIONS ******************************/

    /**
     * @brief Enumeration for PWM carrier waveform selection.
     * Defines the type of carrier waveform used for PWM generation.
     */
    typedef enum
    {
        PWM_CARRIER_CENTER_ALIGNED = 0, /* Triangle carrier (0..1) for center-aligned PWM */
        PWM_CARRIER_SAWTOOTH_UP    = 1, /* Rising sawtooth carrier (0..1) for edge-aligned PWM */
        PWM_CARRIER_SAWTOOTH_DOWN  = 2  /* Falling sawtooth carrier (1..0) for edge-aligned PWM */
    } pwm_carrier_t;

    /**
     * @brief Parameters for PWM module configuration.
     * Ts: carrier period in seconds [1e-6, 1e-3]
     * carrier_select: carrier waveform type selection
     * gate_on_voltage: output voltage when PWM is ON [0.0, 24.0]
     * gate_off_voltage: output voltage when PWM is OFF [0.0, 24.0]
     */
    typedef struct
    {
        float         Ts;               /* Carrier period in seconds [1e-6, 1e-3] */
        pwm_carrier_t carrier_select;   /* Carrier waveform selection */
        float         gate_on_voltage;  /* Output voltage when PWM is ON [0.0, 24.0] */
        float         gate_off_voltage; /* Output voltage when PWM is OFF [0.0, 24.0] */
    } pwm_params_t;

    /**
     * @brief Internal state for PWM module operation.
     * No internal state is required for this stateless PWM implementation.
     */
    // typedef struct
    // {
    //     int unused; /* No state needed for stateless PWM implementation */
    // } pwm_state_t;

    /**
     * @brief Output signals from PWM module processing.
     * PWM: output pulse (0 or gate_on_voltage)
     * SawtoothUp: rising sawtooth carrier (0..1)
     * CenterAligned: triangle carrier (0..1)
     * SawtoothDown: falling sawtooth carrier (1..0)
     * ClkOut: true at start of each carrier period, false otherwise
     */
    typedef struct
    {
        float PWM;           /* PWM output signal [0, gate_on_voltage] */
        float SawtoothUp;    /* Rising sawtooth carrier [0.0, 1.0] */
        float CenterAligned; /* Triangle carrier [0.0, 1.0] */
        float SawtoothDown;  /* Falling sawtooth carrier [0.0, 1.0] */
        bool  ClkOut;        /* Clock output at start of carrier period */
    } pwm_outputs_t;

    /**
     * @brief Complete PWM module structure encapsulating all components.
     */
    typedef struct
    {
        pwm_params_t params;
        // pwm_state_t   state; /* No state needed for stateless PWM implementation */
        pwm_outputs_t outputs;
    } pwm_t;

    /************************* FUNCTION PROTOTYPES *******************************/

    /**
     * @brief   Initialize the PWM module with given parameters.
     * @param   p_pwm     Pointer to the PWM module instance.
     * @param   p_params  Pointer to initialization parameters.
     */
    void pwm_init(pwm_t* const p_pwm, const pwm_params_t* const p_params);

    /**
     * @brief   Reset the PWM module to initial state while preserving parameters.
     * @param   p_pwm     Pointer to the PWM module instance.
     */
    void pwm_reset(pwm_t* const p_pwm);

    /**
     * @brief   Execute one processing step of the PWM module.
     * @param   p_pwm        Pointer to the PWM module instance.
     * @param   t            Current time in seconds.
     * @param   duty         Duty cycle [0.0, 1.0].
     * @param   phase        Phase offset in radians [-2π, 2π].
     */
    void pwm_step(pwm_t* const p_pwm, const float t, const float duty, const float phase);

#ifdef __cplusplus
}
#endif

#endif  // PWM_H
