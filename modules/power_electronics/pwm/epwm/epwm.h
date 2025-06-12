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
        EPWM_COUNT_UP   = 0, /* Counter is incrementing */
        EPWM_COUNT_DOWN = 1  /* Counter is decrementing */
    } epwm_count_direction_t;

    /**
     * @brief Enumeration for PWM action modes.
     * Defines when PWM outputs change state relative to compare events.
     */
    typedef enum
    {
        EPWM_ACTION_CMPB_DOWN_CMPA_UP = 0, /* Set on CMPB down-count, Clear on CMPA up-count */
        EPWM_ACTION_CMPA_DOWN_CMPB_UP = 1  /* Set on CMPA down-count, Clear on CMPB up-count */
    } epwm_action_mode_t;

    /**
     * @brief Parameters for EPWM module configuration.
     * Ts: carrier period in seconds [1e-6, 1e-3]
     * pwma_mode: action mode for PWMA output
     * pwmb_mode: action mode for PWMB output
     * gate_on_voltage: output voltage when PWM is ON [0.0, 24.0]
     * gate_off_voltage: output voltage when PWM is OFF [0.0, 24.0]
     * sync_enable: enable external synchronization
     * phase_offset: phase offset in seconds
     * dead_time_rising: dead time for rising edges in seconds
     * dead_time_falling: dead time for falling edges in seconds
     */
    typedef struct
    {
        float              Ts;                /* Carrier period in seconds [1e-6, 1e-3] */
        epwm_action_mode_t pwma_mode;         /* Action mode for PWMA output */
        epwm_action_mode_t pwmb_mode;         /* Action mode for PWMB output */
        float              gate_on_voltage;   /* Output voltage when PWM is ON [0.0, 24.0] */
        float              gate_off_voltage;  /* Output voltage when PWM is OFF [0.0, 24.0] */
        bool               sync_enable;       /* Enable external synchronization */
        float              phase_offset;      /* Phase offset in seconds */
        float              dead_time_rising;  /* Dead time for rising edges in seconds */
        float              dead_time_falling; /* Dead time for falling edges in seconds */
    } epwm_params_t;

    /**
     * @brief Internal state for EPWM module operation.
     */
    typedef struct
    {
        epwm_count_direction_t counter_direction; /* Current counter direction */
        float                  counter_value;     /* Current counter value [0.0, 1.0] */
        float                  previous_counter;  /* Previous counter value for edge detection */
        bool                   pwma_state;        /* Current PWMA output state */
        bool                   pwmb_state;        /* Current PWMB output state */
        bool                   first_run;         /* Flag for first execution step */
        /* Normalized dead time values (calculated once during init) */
        float dead_time_rising_norm;  /* Normalized dead time rising */
        float dead_time_falling_norm; /* Normalized dead time falling */
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
