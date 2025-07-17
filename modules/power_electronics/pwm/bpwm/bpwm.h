/**
 * *************************** In The Name Of God ***************************
 * @file    bpwm.h
 * @brief   Basic Digital PWM module interface for carrier-based PWM generation
 * @author  Dr.-Ing. Hossein Abedini
 * @date    2025-06-01
 * Provides types and functions for generating phase-shifted PWM signals using
 * selectable carrier waveforms.
 * @note    Designed for real-time signal processing applications.
 * @license This work is dedicated to the public domain under CC0 1.0.
 *          Please use it for good and beneficial purposes!
 ***************************************************************************/

#ifndef BPWM_H
#define BPWM_H

#ifdef __cplusplus
extern "C"
{
#endif

/********************************* INCLUDES **********************************/
#include <stdint.h>

    /***************************** TYPE DEFINITIONS ******************************/

    /**
     * @brief Enumeration for BPWM carrier waveform selection.
     * Defines the type of carrier waveform used for PWM generation.
     */

    typedef enum
    {
        BPWM_CARRIER_CENTER_ALIGNED = 0, /* Triangle carrier (0..1) for center-aligned PWM */
        BPWM_CARRIER_SAWTOOTH_UP    = 1, /* Rising sawtooth carrier (0..1) for edge-aligned PWM */
        BPWM_CARRIER_SAWTOOTH_DOWN  = 2  /* Falling sawtooth carrier (1..0) for edge-aligned PWM */
    } bpwm_carrier_t;

    /**
     * @brief Parameters for BPWM module configuration.
     * Ts: carrier period in seconds [1e-6, 1e-3]
     * carrier_select: carrier waveform type selection
     * gate_on_voltage: output voltage when PWM is ON [0.0, 24.0]
     * gate_off_voltage: output voltage when PWM is OFF [0.0, 24.0]
     */
    typedef struct
    {
        float          Ts;               /* Carrier period in seconds [1e-6, 1e-3] */
        bpwm_carrier_t carrier_select;   /* Carrier waveform selection */
        float          gate_on_voltage;  /* Output voltage when PWM is ON [0.0, 24.0] */
        float          gate_off_voltage; /* Output voltage when PWM is OFF [0.0, 24.0] */
    } bpwm_params_t;

    /**
     * @brief Internal state for BPWM module operation.
     * No internal state is required for this stateless PWM implementation.
     */

    // typedef struct
    // {
    //     int unused; /* No state needed for stateless PWM implementation */
    // } bpwm_state_t;

    /**
     * @brief Output signals from BPWM module processing.
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
    } bpwm_outputs_t;

    /**
     * @brief Complete BPWM module structure encapsulating all components.
     */
    typedef struct
    {
        bpwm_params_t params;
        // bpwm_state_t   state; /* No state needed for stateless PWM implementation */
        bpwm_outputs_t outputs;
    } bpwm_t;

    /************************* FUNCTION PROTOTYPES *******************************/

    /**
     * @brief   Initialize the BPWM module with given parameters.
     * @param   p_bpwm    Pointer to the BPWM module instance.
     * @param   p_params  Pointer to initialization parameters.
     */
    void bpwm_init(bpwm_t* const p_bpwm, const bpwm_params_t* const p_params);

    /**
     * @brief   Reset the BPWM module to initial state while preserving parameters.
     * @param   p_bpwm    Pointer to the BPWM module instance.
     */
    void bpwm_reset(bpwm_t* const p_bpwm);

    /**
     * @brief   Execute one processing step of the BPWM module.
     * @param   p_bpwm       Pointer to the BPWM module instance.
     * @param   t            Current time in seconds.
     * @param   duty         Duty cycle [0.0, 1.0].
     * @param   phase        Phase offset in radians [-2π, 2π].
     */
    void bpwm_step(bpwm_t* const p_bpwm, const float t, const float duty, const float phase);

#ifdef __cplusplus
}
#endif

#endif  // BPWM_H
