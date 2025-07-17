/**
 * *************************** In The Name Of God ***************************
 * @file    module.c
 * @brief   [REPLACE: Brief description of module functionality] - Implementation
 * @author  [REPLACE: Your Name]
 * @date    [REPLACE: Current Date]
 * 
 * [REPLACE: Detailed description of the implementation]
 * 
 * @note    Template implementation for MISRA C compliant modules
 * @license This work is dedicated to the public domain under CC0 1.0.
 *          Please use it for good and beneficial purposes!
 ***************************************************************************/

/********************************* INCLUDES **********************************/

#include "module.h"

/********************************* DEFINES ***********************************/

/* [REPLACE: Define your module-specific constants here] */
#define MODULE_PARAM1     (0.0F)        /* [REPLACE: Description for param1] */
#define MODULE_PARAM2     (1)           /* [REPLACE: Description for param2] */

/**************************** PRIVATE FUNCTIONS ******************************/

/**
 * @brief   Clear module state to default values.
 * @param   p_state   Pointer to state structure to clear.
 */
static inline void clear_state(module_state_t * const p_state)
{
    p_state->internal_value = 0.0F;
    p_state->counter = 0;
}

/**
 * @brief   Clear module outputs to default values.
 * @param   p_outputs Pointer to outputs structure to clear.
 */
static inline void clear_outputs(module_outputs_t * const p_outputs)
{
    p_outputs->output_signal = 0.0F;
}

/**************************** PUBLIC FUNCTIONS *******************************/

/**
 * @brief   Initialize the module with given parameters.
 * @param   p_mod     Pointer to the module instance.
 * @param   p_params  Pointer to initialization parameters.
 */
void module_init(module_t * const p_mod, const module_params_t * const p_params)
{
    p_mod->params.param1 = p_params->param1;
    p_mod->params.param2 = p_params->param2;
    p_mod->params.enable_feature = p_params->enable_feature;
    
    module_reset(p_mod);
}

/**
 * @brief   Reset the module to initial state while preserving parameters.
 * @param   p_mod     Pointer to the module instance.
 */
void module_reset(module_t * const p_mod)
{
    clear_state(&p_mod->state);
    clear_outputs(&p_mod->outputs);
}

/**
 * @brief   Execute one processing step of the module.
 * @param   p_mod          Pointer to the module instance.
 * @param   input_signal   Input signal value.
 */
void module_step(module_t * const p_mod, const float input_signal)
{
    if (p_mod->params.enable_feature == true)
    {
        p_mod->outputs.output_signal = input_signal * p_mod->params.param1;
        p_mod->state.internal_value += p_mod->outputs.output_signal;
    }
    else
    {
        p_mod->outputs.output_signal = input_signal;
    }
    
    p_mod->state.counter++;
}