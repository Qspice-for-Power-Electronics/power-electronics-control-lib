/**
 * *************************** In The Name Of God ***************************
 * @file    module.h
 * @brief   [REPLACE: Brief description of module functionality]
 * @author  [REPLACE: Your Name]
 * @date    [REPLACE: Current Date]
 *
 * [REPLACE: Detailed description of what this module does and its purpose]
 *
 * @note    Template for creating MISRA C compliant modules for microcontrollers
 * @license This work is dedicated to the public domain under CC0 1.0.
 *          Please use it for good and beneficial purposes!
 *
 * INSTRUCTIONS FOR USE:
 * 1. Replace all [REPLACE: ...] comments with your specific content
 * 2. Modify the type definitions to match your module's needs
 * 3. Update function prototypes as required
 * 4. Define appropriate constants for your parameters
 * 5. Follow MISRA C guidelines when implementing
 * 6. Remove all instruction comments when implementation is complete
 ***************************************************************************/

#ifndef MODULE_H
#define MODULE_H

#ifdef __cplusplus
extern "C"
{
#endif

    /********************************* INCLUDES **********************************/
#include <stdint.h>

    /***************************** TYPE DEFINITIONS ******************************/

    /**
     * @brief Enumeration for module operation mode/type.
     * [REPLACE: Describe each enum value and when to use it]
     *
     * INSTRUCTIONS:
     * - Modify this enum to include your module's specific modes/types
     * - Use descriptive names with MODULE_ prefix for clarity
     * - Remove this enum entirely if your module doesn't need it
     * - Example: For a filter, use FILTER_LOWPASS, FILTER_HIGHPASS
     */
    typedef enum
    {
        MODULE_MODE1 = 0U, /* [REPLACE: Description of first mode/type] */
        MODULE_MODE2 = 1U, /* [REPLACE: Description of second mode/type] */
        MODULE_MODE3 = 2U, /* [REPLACE: Description of third mode/type] */
        MODULE_MODE4 = 3U, /* [REPLACE: Description of fourth mode/type] */
        MODULE_MODE5 = 4U, /* [REPLACE: Description of fifth mode/type] */
        MODULE_MODE6 = 5U, /* [REPLACE: Description of sixth mode/type] */
        MODULE_MODE7 = 6U, /* [REPLACE: Description of seventh mode/type] */
        MODULE_MODE8 = 7U  /* [REPLACE: Description of eighth mode/type] */
    } module_mode_t;

    /**
     * @brief Parameters for module configuration.
     * [REPLACE: Describe each parameter and its valid range/values]
     *
     * INSTRUCTIONS: Modify this structure to include your module's parameters
     */
    typedef struct
    {
        float param1;         /* [REPLACE: Description of param1 [MIN, MAX]] */
        int   param2;         /* [REPLACE: Description of param2 [MIN, MAX]] */
        bool  enable_feature; /* [REPLACE: Description of feature flag] */
    } module_params_t;

    /**
     * @brief Internal state for module operation.
     * [REPLACE: Describe the state variables and their purpose]
     *
     * INSTRUCTIONS: Add your module's internal state variables here
     */
    typedef struct
    {
        float internal_value; /* [REPLACE: Description of internal value] */
        int   counter;        /* [REPLACE: Description of counter] */
    } module_state_t;

    /**
     * @brief Output signals/data from module processing.
     * [REPLACE: Describe each output and its format/range]
     *
     * INSTRUCTIONS: Define your module's output signals here
     */
    typedef struct
    {
        float output_signal; /* [REPLACE: Description of output signal] */
    } module_outputs_t;

    /**
     * @brief Complete module structure encapsulating all components.
     *
     * INSTRUCTIONS: This structure should not be modified unless absolutely necessary
     */
    typedef struct
    {
        module_params_t  params;
        module_state_t   state;
        module_outputs_t outputs;
    } module_t;

    /************************* FUNCTION PROTOTYPES *******************************/

    /**
     * @brief   Initialize the module with given parameters.
     * @param   p_mod     Pointer to the module instance.
     * @param   p_params  Pointer to initialization parameters.
     *
     * INSTRUCTIONS: This function copies parameters and calls module_reset()
     */
    void module_init(module_t* const p_mod, const module_params_t* const p_params);

    /**
     * @brief   Reset the module to initial state while preserving parameters.
     * @param   p_mod     Pointer to the module instance.
     *
     * INSTRUCTIONS: This function should clear all state variables to default values
     */
    void module_reset(module_t* const p_mod);

    /**
     * @brief   Execute one processing step of the module.
     * @param   p_mod          Pointer to the module instance.
     * @param   input_signal   [REPLACE: Description of input signal]
     *
     * INSTRUCTIONS: Implement your main processing logic in this function
     */
    void module_step(module_t* const p_mod, const float input_signal);

#ifdef __cplusplus
}
#endif

#endif /* MODULE_H */