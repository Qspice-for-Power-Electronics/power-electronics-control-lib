/**
 * *************************** In The Name Of God ***************************
 * @file    iir.h
 * @brief   Digital IIR filter module interface for lowpass/highpass filtering
 * @author  Dr.-Ing. Hossein Abedini
 * @date    2025-06-01
 * Provides types and functions for a configurable first-order IIR filter
 * (lowpass/highpass).
 * @note    Designed for real-time signal processing applications.
 *
 * S-Domain Transfer Functions:
 * - Lowpass:  H(s) = ωc / (s + ωc)  where ωc = 2π * fc
 * - Highpass: H(s) = s / (s + ωc)   where ωc = 2π * fc
 *
 * Digital Implementation (Tustin/Bilinear Transform):
 * - Filter coefficient: a = 1 / (1 + 2*fc*Ts)
 * - Lowpass:  y[n] = a*u[n] + (1-a)*y[n-1]
 * - Highpass: y[n] = a*(u[n] - u[n-1]) + (1-a)*y[n-1]
 *
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
     * @brief IIR filter type enumeration.
     */
    typedef enum
    {
        IIR_LOWPASS  = 0, /* Lowpass filter */
        IIR_HIGHPASS = 1  /* Highpass filter */
    } iir_filter_type_t;

    /**
     * @brief Parameters for IIR filter configuration.
     * Ts: sample time in seconds [1e-6, 1.0]
     * fc: cutoff frequency in Hz [0.1, 10000.0]
     * type: filter type (IIR_LOWPASS or IIR_HIGHPASS)
     * a: filter coefficient (0 < a <= 1), computed from Ts and fc if
     * not set directly
     */
    typedef struct
    {
        float             Ts;   /* Sample time in seconds [1e-6, 1.0] */
        float             fc;   /* Cutoff frequency in Hz [0.1, 10000.0] */
        iir_filter_type_t type; /* Filter type: IIR_LOWPASS or IIR_HIGHPASS */
        float             a;    /* Filter coefficient (0 < a <= 1) */
    } iir_params_t;

    /**
     * @brief Internal state for IIR filter operation.
     * y_prev: previous output sample
     * u_prev: previous input sample
     */
    typedef struct
    {
        float y_prev; /* Previous output sample */
        float u_prev; /* Previous input sample */
    } iir_state_t;

    /**
     * @brief Output signals from IIR filter processing.
     * y: current filtered output signal
     */
    typedef struct
    {
        float y; /* Current filtered output signal */
    } iir_outputs_t;

    /**
     * @brief Complete IIR filter module structure encapsulating all components.
     */
    typedef struct
    {
        iir_params_t  params;
        iir_state_t   state;
        iir_outputs_t outputs;
    } iir_t;

    /************************* FUNCTION PROTOTYPES *******************************/

    /**
     * @brief   Initialize the IIR filter module with given parameters.
     * @param   p_mod     Pointer to the IIR filter module instance.
     * @param   p_params  Pointer to initialization parameters.
     */
    void iir_init(iir_t* const p_mod, const iir_params_t* const p_params);

    /**
     * @brief   Reset the IIR filter to initial state while preserving parameters.
     * @param   p_mod     Pointer to the IIR filter module instance.
     */
    void iir_reset(iir_t* const p_mod);

    /**
     * @brief   Execute one processing step of the IIR filter.
     * @param   p_mod          Pointer to the IIR filter module instance.
     * @param   input_signal   Input signal value to be filtered.
     */
    void iir_step(iir_t* const p_mod, const float input_signal);

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
