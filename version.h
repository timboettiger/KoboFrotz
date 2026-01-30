/*
 * version.h
 *
 * KoboFrotz version information
 * This file is auto-generated during build - do not edit manually
 *
 */

#ifndef KOBOFROTZ_VERSION_H
#define KOBOFROTZ_VERSION_H

// Version components
#define KOBOFROTZ_VERSION_MAJOR 1
#define KOBOFROTZ_VERSION_MINOR 0
#define KOBOFROTZ_VERSION_PATCH 0

// Build number (4-digit hex, auto-incremented during build)
// Format: 0x0001 to 0xFFFF
#define KOBOFROTZ_BUILD_NUMBER 0x0003

// Helper macros for string conversion
#define KOBOFROTZ_STRINGIFY(x) #x
#define KOBOFROTZ_TOSTRING(x) KOBOFROTZ_STRINGIFY(x)

// Version string (e.g., "V1.0.0")
#define KOBOFROTZ_VERSION_STRING "V" KOBOFROTZ_TOSTRING(KOBOFROTZ_VERSION_MAJOR) "." \
                                 KOBOFROTZ_TOSTRING(KOBOFROTZ_VERSION_MINOR) "." \
                                 KOBOFROTZ_TOSTRING(KOBOFROTZ_VERSION_PATCH)

// Application name
#define KOBOFROTZ_APP_NAME "KoboFrotz"

// Note: Build number formatting is done at runtime in main.cpp
// because preprocessor cannot format hex numbers as 4-digit strings

#endif // KOBOFROTZ_VERSION_H
