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

// Build number (hex, auto-incremented during build)
#define KOBOFROTZ_BUILD_NUMBER 0x0001

// Version string macros
#define KOBOFROTZ_STRINGIFY(x) #x
#define KOBOFROTZ_TOSTRING(x) KOBOFROTZ_STRINGIFY(x)

#define KOBOFROTZ_VERSION_STRING "V" KOBOFROTZ_TOSTRING(KOBOFROTZ_VERSION_MAJOR) "." \
                                 KOBOFROTZ_TOSTRING(KOBOFROTZ_VERSION_MINOR) "." \
                                 KOBOFROTZ_TOSTRING(KOBOFROTZ_VERSION_PATCH)

// Build number as 4-digit hex string (e.g., "0001")
#define KOBOFROTZ_BUILD_HEX_STRING KOBOFROTZ_TOSTRING(KOBOFROTZ_BUILD_NUMBER)

// Full version with build number (e.g., "V1.0.0-0001")
#define KOBOFROTZ_FULL_VERSION KOBOFROTZ_VERSION_STRING "-" KOBOFROTZ_BUILD_HEX_STRING

// Application name
#define KOBOFROTZ_APP_NAME "KoboFrotz"

// Full application title with version
#define KOBOFROTZ_APP_TITLE KOBOFROTZ_APP_NAME " " KOBOFROTZ_FULL_VERSION

#endif // KOBOFROTZ_VERSION_H
