#!/bin/bash
#
# KoboFrotz Cross-Compilation Build Script
# For Kobo Libra Colour (and other ARM-based Kobo E-Readers)
#

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build-kobo"
OUTPUT_DIR="$SCRIPT_DIR/dist"
LOCAL_TOOLCHAIN_DIR="$SCRIPT_DIR/toolchain"

# Default paths (can be overridden via environment or kobo-build.conf)
if [ -f "$SCRIPT_DIR/kobo-build.conf" ]; then
    source "$SCRIPT_DIR/kobo-build.conf"
fi

# Check for local toolchain first, then fall back to home directory
if [ -d "$LOCAL_TOOLCHAIN_DIR/arm-kobo-linux-gnueabihf" ]; then
    KOBO_TOOLCHAIN="${KOBO_TOOLCHAIN:-$LOCAL_TOOLCHAIN_DIR/arm-kobo-linux-gnueabihf}"
else
    KOBO_TOOLCHAIN="${KOBO_TOOLCHAIN:-$HOME/x-tools/arm-kobo-linux-gnueabihf}"
fi

if [ -d "$LOCAL_TOOLCHAIN_DIR/qt-kobo" ]; then
    QT_KOBO="${QT_KOBO:-$LOCAL_TOOLCHAIN_DIR/qt-kobo}"
else
    QT_KOBO="${QT_KOBO:-$HOME/qt-kobo}"
fi

# Kobo-specific paths (configurable)
KOBO_APP_DIR="${KOBO_APP_DIR:-/mnt/onboard/.adds/kobofrotz}"
KOBO_QT_LIB_DIR="${KOBO_QT_LIB_DIR:-/mnt/onboard/.adds/qt-linux-5.15-kobo/lib}"

# Output colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_toolchain() {
    log_info "Checking toolchain..."
    
    if [ ! -d "$KOBO_TOOLCHAIN" ]; then
        log_error "Kobo toolchain not found: $KOBO_TOOLCHAIN"
        log_info "Please install the toolchain using kobo-qt-setup-scripts:"
        log_info "  git clone https://github.com/Rain92/kobo-qt-setup-scripts.git"
        log_info "  cd kobo-qt-setup-scripts && ./install_toolchain.sh"
        exit 1
    fi

    if [ ! -f "$KOBO_TOOLCHAIN/bin/arm-kobo-linux-gnueabihf-gcc" ]; then
        log_error "Cross-compiler not found in $KOBO_TOOLCHAIN/bin/"
        exit 1
    fi

    log_info "Toolchain found: $KOBO_TOOLCHAIN"
}

check_qt() {
    log_info "Checking Qt for Kobo..."
    
    if [ ! -d "$QT_KOBO" ]; then
        log_error "Qt for Kobo not found: $QT_KOBO"
        log_info "Please build Qt using kobo-qt-setup-scripts:"
        log_info "  ./get_qt.sh && ./build_qt.sh"
        exit 1
    fi

    if [ ! -f "$QT_KOBO/bin/qmake" ]; then
        log_error "qmake not found in $QT_KOBO/bin/"
        exit 1
    fi

    log_info "Qt for Kobo found: $QT_KOBO"
}

setup_environment() {
    log_info "Setting up environment variables..."
    
    export PATH="$KOBO_TOOLCHAIN/bin:$QT_KOBO/bin:$PATH"
    export CROSS_COMPILE=arm-kobo-linux-gnueabihf-
    export SYSROOT="$KOBO_TOOLCHAIN/arm-kobo-linux-gnueabihf/sysroot"
    
    log_info "PATH updated"
    log_info "CROSS_COMPILE=$CROSS_COMPILE"
    log_info "SYSROOT=$SYSROOT"
}

clean_build() {
    log_info "Cleaning build directory..."
    
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
    fi
    
    mkdir -p "$BUILD_DIR"
}

build_kobofrotz() {
    log_info "Starting KoboFrotz build..."
    
    cd "$BUILD_DIR"
    
    log_info "Running qmake..."
    "$QT_KOBO/bin/qmake" "$SCRIPT_DIR/KoboFrotz.pro" \
        CONFIG+=release \
        QMAKE_CXXFLAGS+="-O2" \
        QMAKE_LFLAGS+="-Wl,-rpath,$KOBO_QT_LIB_DIR"
    
    log_info "Compiling..."
    make -j$(nproc)
    
    if [ -f "$BUILD_DIR/KoboFrotz" ]; then
        log_info "Build successful: $BUILD_DIR/KoboFrotz"
    else
        log_error "Build failed - KoboFrotz binary not found"
        exit 1
    fi
}

create_dist() {
    log_info "Creating distribution..."
    
    mkdir -p "$OUTPUT_DIR/kobofrotz"
    mkdir -p "$OUTPUT_DIR/kobofrotz/games"
    mkdir -p "$OUTPUT_DIR/kobofrotz/saves"
    mkdir -p "$OUTPUT_DIR/nm"
    
    # Copy binary
    cp "$BUILD_DIR/KoboFrotz" "$OUTPUT_DIR/kobofrotz/"
    
    # Create startup script (with configurable paths)
    cat > "$OUTPUT_DIR/kobofrotz/run.sh" << EOF
#!/bin/sh
#
# KoboFrotz startup script for Kobo
#

# Configurable paths
KOBOFROTZ_DIR="${KOBO_APP_DIR}"
QT_LIB_DIR="${KOBO_QT_LIB_DIR}"

# Qt environment
export LD_LIBRARY_PATH="\$QT_LIB_DIR:\$LD_LIBRARY_PATH"
export QT_QPA_PLATFORM=kobo

# E Ink display settings for Kobo Libra Colour
export QT_QPA_EVDEV_TOUCHSCREEN_PARAMETERS="rotate=0"
export QT_QPA_GENERIC_PLUGINS="evdevtouch:/dev/input/event1"

# Working directory
cd "\$KOBOFROTZ_DIR"

# Start KoboFrotz
./KoboFrotz "\$@"
EOF
    
    chmod +x "$OUTPUT_DIR/kobofrotz/run.sh"
    
    # NickelMenu configuration
    cat > "$OUTPUT_DIR/nm/kobofrotz" << EOF
menu_item :main :KoboFrotz (Z-Machine) :cmd_spawn :quiet:${KOBO_APP_DIR}/run.sh
  chain_success :nickel_misc :rescan_books_full
EOF
    
    log_info "Distribution created in: $OUTPUT_DIR"
    log_info ""
    log_info "Contents:"
    ls -la "$OUTPUT_DIR/kobofrotz/"
}

print_instructions() {
    log_info ""
    log_info "=========================================="
    log_info "Installation on Kobo:"
    log_info "=========================================="
    log_info ""
    log_info "1. Connect Kobo via USB"
    log_info ""
    log_info "2. Copy files:"
    log_info "   cp -r $OUTPUT_DIR/kobofrotz /media/\$USER/KOBOeReader/.adds/"
    log_info "   cp $OUTPUT_DIR/nm/kobofrotz /media/\$USER/KOBOeReader/.adds/nm/"
    log_info ""
    log_info "3. Ensure Qt libraries are installed"
    log_info "   (use deploy_qt.sh from kobo-qt-setup-scripts)"
    log_info ""
    log_info "4. Safely eject Kobo and reboot"
    log_info ""
    log_info "5. Launch KoboFrotz via NickelMenu"
    log_info ""
}

# Main program
main() {
    log_info "=========================================="
    log_info "KoboFrotz Cross-Compilation Build"
    log_info "=========================================="
    log_info ""
    
    case "${1:-}" in
        --clean)
            clean_build
            log_info "Build directory cleaned"
            exit 0
            ;;
        --help|-h)
            echo "Usage: $0 [--clean|--help]"
            echo ""
            echo "Options:"
            echo "  --clean    Clean the build directory"
            echo "  --help     Show this help"
            echo ""
            echo "Environment variables:"
            echo "  KOBO_TOOLCHAIN  Path to Kobo toolchain (default: ~/x-tools/arm-kobo-linux-gnueabihf)"
            echo "  QT_KOBO         Path to Qt for Kobo (default: ~/qt-kobo)"
            exit 0
            ;;
    esac
    
    check_toolchain
    check_qt
    setup_environment
    clean_build
    build_kobofrotz
    create_dist
    print_instructions
    
    log_info "Build completed!"
}

main "$@"
