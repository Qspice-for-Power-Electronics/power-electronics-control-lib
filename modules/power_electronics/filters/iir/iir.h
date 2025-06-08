/**
 * *************************** In The Name Of God ***************************
 * @file    iir.h
 * @brief   Digital IIR filter module interface for lowpass/highpass filtering
 * @author  Dr.-Ing. Hossein Abedini
 * @date    2025-06-01
 * Provides types and functions for a configurable first-order IIR filter
 * (lowpass/highpass).
 * @note    Designed for real-time signal processing applications.
 * @license This work is dedicated to the public domain under CC0 1.0.
 *          Please use it for good and beneficial purposes!
 ***************************************************************************/

#ifndef IIR_H
#define IIR_H

#ifdef __cplusplus
extern "C"
{
#endif

/********************************* INCLUDES **********************************/
#include <stdint.h>

    /***************************** TYPE DEFINITIONS ******************************/
    /**
     * @brief Parameters for IIR filter.
     * Ts: sample time (seconds)
     * fc: cutoff frequency (Hz)
     * type: 0 = lowpass, 1 = highpass
     * a: filter coefficient (0 < a <= 1), computed from Ts and fc if not set directly
     */
    typedef struct
    {
        float Ts;
        float fc;
        int   type;  // 0 = lowpass, 1 = highpass
        float a;     // filter coefficient
    } IirParams;

    /**
     * @brief State for IIR filter.
     * y_prev: previous output
     * u_prev: previous input
     */
    typedef struct
    {
        float y_prev;
        float u_prev;
    } IirState;

    /**
     * @brief Inputs for IIR filter.
     * u: current input
     */
    typedef struct
    {
        float u;
    } IirInputs;

    /**
     * @brief Outputs for IIR filter.
     * y: current output
     */
    typedef struct
    {
        float y;
    } IirOutputs;

    /**
     * @brief IIR filter module encapsulating all parameters, state, inputs, and outputs.
     */
    typedef struct
    {
        IirParams  params;
        IirState   state;
        IirInputs  in;
        IirOutputs out;
    } IirModule;

    /************************* FUNCTION PROTOTYPES *******************************/
    /**
     * @brief   Initialize the IIR filter module with the given parameters. Parameters must not be
     * NULL.
     * @param   mod     Pointer to the IIR filter module instance.
     * @param   params  Pointer to parameters (must not be NULL).
     */
    void iir_module_init(IirModule* mod, const IirParams* params);

    /**
     * @brief   Advances the IIR filter module by one step, updating the output based on the current
     * state and inputs.
     * @param   mod     Pointer to the IIR filter module instance.
     */
    void iir_module_step(IirModule* mod);

    /**
     * @brief   Calculate the IIR filter coefficient 'a' for a given sample time and cutoff
     * frequency.
     * @param   Ts  Sample time (seconds)
     * @param   fc  Cutoff frequency (Hz)
     * @return  Filter coefficient a (0 < a <= 1)
     */
    float iir_calc_a(float Ts, float fc);

#ifdef __cplusplus
}
#endif

#endif  // IIR_H
