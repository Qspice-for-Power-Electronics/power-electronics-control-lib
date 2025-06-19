/**
 * *************************** In The Name Of God ***************************
 * @file    epwm.h * @brief   Enhanced PWM module interface with center-aligned mode
 * @author  Dr.-Ing. Hossein Abedini
 * @date    2025-06-12
 * Provides enhanced PWM generation with center-aligned counter, dead time,
 * and advanced action modes for high-performance power electronics control.
 * @note    Designed for real-time signal processing applications.
 * @license This work is dedicated to the public domain under CC0 1.0.
 *          Please use it for good and beneficial purposes!
 ***************************************************************************/

#ifndef EPWM_H
#define EPWM_H

#ifdef __cplusplus
extern "C"
{
#endif

    /********************************* INCLUDES **********************************/

#include <stdint.h>

    /***************************** TYPE DEFINITIONS ******************************/

    /**
     * Only center-aligned (triangular) mode is supported for
     * simplicity and reliability.
     */

    /**
     * @brief Enumeration for counter direction.
     */
    typedef enum
    {
        EPWM_COUNT_UP   = 0,  /* Counter is incrementing */
        EPWM_COUNT_DOWN = 1   /* Counter is decrementing */
    } epwm_count_direction_t; /**
                               * @brief Enumeration for PWM action modes.
                               * Defines complementary PWM behavior for both outputs.
                               */
    typedef enum
    {
        EPWM_MODE_ACTIVE_HIGH_CMPA_FIRST  = 0, /* PWMA active high on up-count CMPA, PWMB complementary */
        EPWM_MODE_ACTIVE_HIGH_CMPA_SECOND = 1  /* PWMA active high on down-count CMPA, PWMB complementary */
    } epwm_mode_t;                             /**
                                                * @brief Parameters for EPWM module configuration.
                                                * Ts: carrier period in seconds [1e-6, 1e-3]
                                                * pwm_mode: PWM mode defining complementary output behavior
                                                * gate_on_voltage: output voltage when PWM is ON [0.0, 24.0]
                                                * gate_off_voltage: output voltage when PWM is OFF [0.0, 24.0]
                                                * sync_enable: enable external synchronization
                                                * phase_offset: phase offset in seconds
                                                * dead_time_rising: dead time for rising edges in seconds
                                                * dead_time_falling: dead time for falling edges in seconds
                                                */
    typedef struct
    {
        float       Ts;                /* Carrier period in seconds [1e-6, 1e-3] */
        float       inv_Ts;            /* Inverse of carrier period (1/Ts) */
        epwm_mode_t pwm_mode;          /* PWM mode defining complementary output behavior */
        float       gate_on_voltage;   /* Output voltage when PWM is ON [0.0, 24.0] */
        float       gate_off_voltage;  /* Output voltage when PWM is OFF [0.0, 24.0] */
        bool        sync_enable;       /* Enable external synchronization */
        float       phase_offset;      /* Phase offset in seconds */
        float       dead_time_rising;  /* Dead time for rising edges in seconds */
        float       dead_time_falling; /* Dead time for falling edges in seconds */
    } epwm_params_t;

    /**
     * @brief Internal state for EPWM module operation.
     */
    typedef struct
    {
        /* Normalized dead time values (calculated once during init) */
        float dead_time_rising_norm;  /* Normalized dead time rising */
        float dead_time_falling_norm; /* Normalized dead time falling */

        /* Pre-calculated compare values with dead time applied */
        float cmpa_lead; /* CMPA leading edge compare value */
        float cmpa_lag;  /* CMPA lagging edge compare value */
        float cmpb_lead; /* CMPB leading edge compare value */
        float cmpb_lag;  /* CMPB lagging edge compare value */
    } epwm_state_t;

    /**
     * @brief Output signals from EPWM module processing.
     * PWMA: first PWM output channel
     * PWMB: second PWM output channel (typically complementary)
     * counter_normalized: current counter value [0.0, 1.0]
     * counter_direction: current counting direction
     * period_sync: true at start of each PWM period
     */
    typedef struct
    {
        float                  PWMA;               /* PWM output A signal [0, gate_on_voltage] */
        float                  PWMB;               /* PWM output B signal [0, gate_on_voltage] */
        float                  counter_normalized; /* Current counter value [0.0, 1.0] */
        epwm_count_direction_t counter_direction;  /* Current counter direction */
        bool                   period_sync;        /* Clock output at start of PWM period */
    } epwm_outputs_t;

    /**
     * @brief Complete EPWM module structure encapsulating all components.
     */
    typedef struct
    {
        epwm_params_t  params;
        epwm_state_t   state;
        epwm_outputs_t outputs;
    } epwm_t;

    /************************* FUNCTION PROTOTYPES *******************************/

    /**
     * @brief   Initialize the EPWM module with given parameters.
     * @param   p_epwm    Pointer to the EPWM module instance.
     * @param   p_params  Pointer to initialization parameters.
     */
    void epwm_init(epwm_t* const p_epwm, const epwm_params_t* const p_params);

    /**
     * @brief   Reset the EPWM module to initial state while preserving parameters.
     * @param   p_epwm    Pointer to the EPWM module instance.
     */
    void epwm_reset(epwm_t* const p_epwm);

    /**
     * @brief   Execute one processing step of the EPWM module.
     * @param   p_epwm    Pointer to the EPWM module instance.
     * @param   t         Current time in seconds.
     * @param   cmpa      Compare A value [0.0, 1.0].
     * @param   cmpb      Compare B value [0.0, 1.0].
     * @param   sync_in   External synchronization input.
     */
    void epwm_step(epwm_t* const p_epwm, const float t, const float cmpa, const float cmpb, const bool sync_in);

#ifdef __cplusplus
}
#endif

#endif  // EPWM_H
