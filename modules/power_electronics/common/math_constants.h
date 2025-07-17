/**
 * ************************** In The Name Of God **************************
 * @file    math_constants.h
 * @brief   Common mathematical constants and definitions for power electronics modules
 * @author  Dr.-Ing. Hossein Abedini
 * @date    2025-06-08
 * This header provides mathematical constants that are commonly used across
 * power electronics control modules. Include this file when you need standard
 * mathematical constants like PI, E, etc.
 * @note    Designed for real-time signal processing applications.
 * @license This work is dedicated to the public domain under CC0 1.0.
 *          Please use it for good and beneficial purposes!
 *************************************************************************/

// NOLINTBEGIN(misc-include-cleaner) - This file provides its own math constants
#ifndef MATH_CONSTANTS_H
    #define MATH_CONSTANTS_H

    #ifdef __cplusplus
extern "C"
{
    #endif

    /********************************* MATHEMATICAL CONSTANTS ***********************************/

    #ifndef M_PI
        #define M_PI (3.14159265358979323846264338327950288) /**< Pi */
    #endif

    #ifndef M_PI_2
        #define M_PI_2 (1.57079632679489661923132169163975144) /**< Pi/2 */
    #endif

    #ifndef M_PI_4
        #define M_PI_4 (0.78539816339744830961566084581987572) /**< Pi/4 */
    #endif

    #ifndef M_2_PI
        #define M_2_PI (0.63661977236758134307553505349005744) /**< 2/Pi */
    #endif

    #ifndef M_1_PI
        #define M_1_PI (0.31830988618379067153776752674502872) /**< 1/Pi */
    #endif

    #ifndef M_E
        #define M_E (2.71828182845904523536028747135266250) /**< Euler's number e */
    #endif

    #ifndef M_LOG2E
        #define M_LOG2E (1.44269504088896340735992468100189214) /**< log_2(e) */
    #endif

    #ifndef M_LOG10E
        #define M_LOG10E (0.43429448190325182765112891891660508) /**< log_10(e) */
    #endif

    #ifndef M_LN2
        #define M_LN2 (0.69314718055994530941723212145817657) /**< ln(2) */
    #endif

    #ifndef M_LN10
        #define M_LN10 (2.30258509299404568401799145468436421) /**< ln(10) */
    #endif

    #ifndef M_SQRT2
        #define M_SQRT2 (1.41421356237309504880168872420969808) /**< sqrt(2) */
    #endif

    #ifndef M_SQRT1_2
        #define M_SQRT1_2 (0.70710678118654752440084436210484904) /**< sqrt(1/2) */
    #endif

    /********************************* POWER ELECTRONICS CONSTANTS *************************/

    /** Common frequency values used in power electronics */
    #define FREQ_50HZ  (50.0f)  /**< 50 Hz mains frequency */
    #define FREQ_60HZ  (60.0f)  /**< 60 Hz mains frequency */
    #define FREQ_400HZ (400.0f) /**< 400 Hz aircraft frequency */

    /** Common angular frequencies (rad/s) */
    #define OMEGA_50HZ  (2.0f * M_PI * FREQ_50HZ)  /**< 50 Hz in rad/s */
    #define OMEGA_60HZ  (2.0f * M_PI * FREQ_60HZ)  /**< 60 Hz in rad/s */
    #define OMEGA_400HZ (2.0f * M_PI * FREQ_400HZ) /**< 400 Hz in rad/s */

    /** Conversion factors */
    #define DEG_TO_RAD         (M_PI / 180.0f) /**< Convert degrees to radians */
    #define RAD_TO_DEG         (180.0f / M_PI) /**< Convert radians to degrees */
    #define RPM_TO_RAD_PER_SEC (M_PI / 30.0f)  /**< Convert RPM to rad/s */
    #define RAD_PER_SEC_TO_RPM (30.0f / M_PI)  /**< Convert rad/s to RPM */

    /** Numerical limits and tolerances */
    #define EPSILON_FLOAT  (1e-6f) /**< Small float value for comparisons */
    #define EPSILON_DOUBLE (1e-12) /**< Small double value for comparisons */

    /********************************* MATH FUNCTIONS *********************************/

    /**
     * @brief   Return the maximum of two float values
     * @param   x   First value
     * @param   y   Second value
     * @return  Maximum of x and y
     */
    #ifndef fmaxf
    static inline float fmaxf(float x, float y)
    {
        return (x > y) ? x : y;
    }
    #endif

    /**
     * @brief   Return the minimum of two float values
     * @param   x   First value
     * @param   y   Second value
     * @return  Minimum of x and y
     */
    #ifndef fminf
    static inline float fminf(float x, float y)
    {
        return (x < y) ? x : y;
    }
    #endif

    #ifdef __cplusplus
}
    #endif

#endif /* MATH_CONSTANTS_H */
// NOLINTEND(misc-include-cleaner)
