#!/bin/bash
#
# increment-build.sh
# Automatically increments the build number in version.h
#
# Usage: ./increment-build.sh [version.h path]
#

VERSION_FILE="${1:-version.h}"

if [ ! -f "$VERSION_FILE" ]; then
    echo "Error: Version file not found: $VERSION_FILE"
    exit 1
fi

# Extract current build number
CURRENT_BUILD=$(grep -oP '#define KOBOFROTZ_BUILD_NUMBER 0x\K[0-9A-Fa-f]+' "$VERSION_FILE" 2>/dev/null)

# Fallback for macOS (grep -P not available)
if [ -z "$CURRENT_BUILD" ]; then
    CURRENT_BUILD=$(grep '#define KOBOFROTZ_BUILD_NUMBER' "$VERSION_FILE" | sed 's/.*0x\([0-9A-Fa-f]*\).*/\1/')
fi

if [ -z "$CURRENT_BUILD" ]; then
    echo "Error: Could not find KOBOFROTZ_BUILD_NUMBER in $VERSION_FILE"
    exit 1
fi

# Convert hex to decimal, increment, convert back to hex
CURRENT_DEC=$((16#$CURRENT_BUILD))
NEW_DEC=$((CURRENT_DEC + 1))
NEW_BUILD=$(printf "%04X" $NEW_DEC)

# Replace in file (portable for both Linux and macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS requires empty string argument for -i
    sed -i '' "s/#define KOBOFROTZ_BUILD_NUMBER 0x[0-9A-Fa-f]*/#define KOBOFROTZ_BUILD_NUMBER 0x$NEW_BUILD/" "$VERSION_FILE"
else
    # Linux
    sed -i "s/#define KOBOFROTZ_BUILD_NUMBER 0x[0-9A-Fa-f]*/#define KOBOFROTZ_BUILD_NUMBER 0x$NEW_BUILD/" "$VERSION_FILE"
fi

echo "Build number incremented: 0x$CURRENT_BUILD -> 0x$NEW_BUILD"
