/**
 * *************************** In The Name Of God ***************************
 * @file    bool_compat.h
 * @brief   Boolean type compatibility for Digital Mars Compiler (DMC)
 * @author  Dr.-Ing. Hossein Abedini
 * @date    2025-06-09
 * Provides C99-style boolean types and constants for older compilers that
 * don't support the native bool type (like DMC).
 * @note    Designed for real-time signal processing applications.
 * @license This work is dedicated to the public domain under CC0 1.0.
 *          Please use it for good and beneficial purposes!
 ***************************************************************************/

#ifndef BOOL_COMPAT_H
#define BOOL_COMPAT_H

/********************************* INCLUDES **********************************/
/* No includes needed for basic type definitions */

/****************************** COMPATIBILITY *******************************/
/*
 * Digital Mars Compiler (DMC) doesn't support C99 bool type.
 * This provides compatible definitions for modern boolean semantics.
 */

#ifndef __cplusplus
    /* C mode: Define bool, true, false if not already defined */
    #ifndef bool
typedef int bool;
    #endif

    #ifndef true
        #define true (1)
    #endif

    #ifndef false
        #define false (0)
    #endif
#else
    /* C++ mode: Include standard boolean support if available */
    #if defined(_MSC_VER) || defined(__GNUC__)
        /* Modern C++ compilers have native bool support */
        /* No additional definitions needed */
    #elif defined(__DMC__)
        /* Digital Mars Compiler specific handling */
        /* DMC has partial bool support but may conflict with typedef */
        #ifndef __cplusplus
            /* In C mode, define bool as int */
            #ifndef bool
                #define bool (int)
            #endif
            #ifndef true
                #define true (1)
            #endif
            #ifndef false
                #define false (0)
            #endif
        #else
            /* In C++ mode, DMC should have bool support */
            /* If it doesn't, we'll use macros instead of typedef */
            #ifndef true
                #define true (1)
            #endif
            #ifndef false
                #define false (0)
            #endif
        #endif
    #else
        /* Other older C++ compilers might need compatibility */
        #ifndef bool
typedef int bool;
        #endif

        #ifndef true
            #define true (1)
        #endif

        #ifndef false
            #define false (0)
        #endif
    #endif
#endif

/*************************** USAGE GUIDELINES ********************************/
/*
 * USAGE:
 *   #include "bool_compat.h"
 *
 *   bool flag = true;
 *   if (flag == false) {
 *       // Do something
 *   }
 *
 * NOTES:
 *   - Always use 'true' and 'false' constants, never 1/0 directly
 *   - Boolean functions should return 'true' or 'false'
 *   - Comparisons with booleans should use == or != explicitly
 *   - Compatible with both C and C++ compilation modes
 */

#endif /* BOOL_COMPAT_H */
