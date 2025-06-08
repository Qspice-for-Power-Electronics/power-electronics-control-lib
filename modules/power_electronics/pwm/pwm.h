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
     * @brief Parameters for PWM generation.
     * Ts: carrier period (seconds)
     * carrier_select: 0 = CenterAligned, 1 = SawtoothUp, 2 = SawtoothDown
     * gate_on_voltage: output voltage when PWM is ON (e.g., gate drive voltage)
     */
    typedef struct
    {
        float Ts;
        int   carrier_select;
        float gate_on_voltage;  // Output voltage when PWM is ON
    } PwmParams;

    /**
     * @brief State for PWM module.
     * (No fields needed for stateless operation)
     */
    typedef struct
    {
        // Empty for now
    } PwmState;

    /**
     * @brief Inputs for PWM generation.
     * t: current time (seconds)
     * duty: duty cycle (0..1)
     * phase: phase offset in radians (−2π..2π), applied to carrier and all outputs
     */
    typedef struct
    {
        float t;
        float duty;
        float phase;
    } PwmInputs;

    /**
     * @brief Outputs for PWM generation.
     * PWM: output pulse (0 or gate_on_voltage)
     * SawtoothUp: rising sawtooth carrier (0..1)
     * CenterAligned: triangle carrier (0..1)
     * SawtoothDown: falling sawtooth carrier (1..0)
     * ClkOut: 1 at start of each carrier period, 0 otherwise
     */
    typedef struct
    {
        float PWM;
        float SawtoothUp;
        float CenterAligned;
        float SawtoothDown;
        float ClkOut;
    } PwmOutputs;

    /**
     * @brief PWM module encapsulating all parameters, state, inputs, and outputs.
     */
    typedef struct
    {
        PwmParams  params;
        PwmState   state;
        PwmInputs  in;
        PwmOutputs out;
    } PwmModule;

    /************************* FUNCTION PROTOTYPES *******************************/
    /**
     * @brief   Initializes the PWM module with the given parameters. Parameters must not be NULL.
     * @param   mod     Pointer to the PWM module instance.
     * @param   params  Pointer to parameters (must not be NULL).
     */
    void pwm_module_init(PwmModule* mod, const PwmParams* params);

    /**
     * @brief   Advances the PWM module by one step, updating all outputs based on the current state
     * and inputs.
     * @param   mod     Pointer to the PWM module instance.
     */
    void pwm_module_step(PwmModule* mod);

#ifdef __cplusplus
}
#endif

#endif  // PWM_H
