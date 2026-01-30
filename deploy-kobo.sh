#!/bin/bash
#
# KoboFrotz Deployment Script
# Copies KoboFrotz and all required files to the Kobo
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="$SCRIPT_DIR/dist"
BUILD_DIR="$SCRIPT_DIR/build-kobo"

# Load configuration if available
if [ -f "$SCRIPT_DIR/kobo-build.conf" ]; then
    source "$SCRIPT_DIR/kobo-build.conf"
fi

# Kobo-specific paths (configurable)
KOBO_APP_DIR="${KOBO_APP_DIR:-/mnt/onboard/.adds/kobofrotz}"
KOBO_QT_LIB_DIR="${KOBO_QT_LIB_DIR:-/mnt/onboard/.adds/qt-linux-5.15-kobo/lib}"

# Output colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

usage() {
    echo "Usage: $0 <kobo-mount-point>"
    echo ""
    echo "Examples:"
    echo "  $0 /media/\$USER/KOBOeReader"
    echo "  $0 /Volumes/KOBOeReader"
    echo ""
    echo "Optionally set QT_DEPLOY_DIR to install Qt libraries:"
    echo "  QT_DEPLOY_DIR=~/qt-kobo-deploy $0 /media/\$USER/KOBOeReader"
    exit 1
}

check_kobo_mount() {
    if [ ! -d "$KOBO_MOUNT" ]; then
        log_error "Kobo mount point not found: $KOBO_MOUNT"
        exit 1
    fi

    # Check if this is actually a Kobo
    if [ ! -d "$KOBO_MOUNT/.kobo" ]; then
        log_warn "No .kobo directory found - is this really a Kobo?"
        read -p "Continue? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    log_info "Kobo found: $KOBO_MOUNT"
}

check_build() {
    if [ ! -f "$DIST_DIR/kobofrotz/KoboFrotz" ] && [ ! -f "$BUILD_DIR/KoboFrotz" ]; then
        log_error "KoboFrotz binary not found."
        log_info "Please build first with: ./build-kobo.sh"
        exit 1
    fi
    
    if [ -f "$DIST_DIR/kobofrotz/KoboFrotz" ]; then
        BINARY_SOURCE="$DIST_DIR/kobofrotz/KoboFrotz"
    else
        BINARY_SOURCE="$BUILD_DIR/KoboFrotz"
    fi
    
    log_info "Binary found: $BINARY_SOURCE"
}

create_directories() {
    log_info "Creating directories..."
    
    mkdir -p "$KOBO_MOUNT/.adds/kobofrotz"
    mkdir -p "$KOBO_MOUNT/.adds/kobofrotz/games"
    mkdir -p "$KOBO_MOUNT/.adds/kobofrotz/saves"
    mkdir -p "$KOBO_MOUNT/.adds/nm"
    
    log_info "Directories created"
}

deploy_binary() {
    log_info "Copying KoboFrotz binary..."
    
    cp "$BINARY_SOURCE" "$KOBO_MOUNT/.adds/kobofrotz/"
    chmod +x "$KOBO_MOUNT/.adds/kobofrotz/KoboFrotz"
    
    log_info "Binary copied"
}

deploy_run_script() {
    log_info "Creating startup script..."
    
    # Extract paths for Kobo filesystem
    local APP_PATH="${KOBO_APP_DIR}"
    local QT_LIB_PATH="${KOBO_QT_LIB_DIR}"
    
    cat > "$KOBO_MOUNT/.adds/kobofrotz/run.sh" << EOF
#!/bin/sh
#
# KoboFrotz startup script for Kobo Libra Colour
#

# Configurable paths
KOBOFROTZ_DIR="${APP_PATH}"
QT_LIB_DIR="${QT_LIB_PATH}"

# Enable logging (optional)
exec > "\$KOBOFROTZ_DIR/kobofrotz.log" 2>&1
echo "=== KoboFrotz Start: \$(date) ==="

# Qt environment
export LD_LIBRARY_PATH="\$QT_LIB_DIR:\$LD_LIBRARY_PATH"
export QT_QPA_PLATFORM=kobo

# E Ink display settings for Kobo Libra Colour (N428)
# Screen resolution: 1264 x 1680 (Portrait)
export QT_QPA_EVDEV_TOUCHSCREEN_PARAMETERS="rotate=0"
export QT_QPA_GENERIC_PLUGINS="evdevtouch:/dev/input/event1"

# Disable frontlight (optional, saves power)
# export KOBO_FRONTLIGHT=0

# Working directory
cd "\$KOBOFROTZ_DIR"

echo "LD_LIBRARY_PATH=\$LD_LIBRARY_PATH"
echo "Starting KoboFrotz..."

# Start KoboFrotz
./KoboFrotz "\$@"

EXIT_CODE=\$?
echo "=== KoboFrotz End: \$(date), Exit Code: \$EXIT_CODE ==="
exit \$EXIT_CODE
EOF
    
    chmod +x "$KOBO_MOUNT/.adds/kobofrotz/run.sh"
    
    log_info "Startup script created"
}

deploy_nickelmenu_config() {
    log_info "Creating NickelMenu configuration..."
    
    # Check if NickelMenu is installed
    if [ ! -d "$KOBO_MOUNT/.adds/nm" ]; then
        log_warn "NickelMenu does not appear to be installed."
        log_info "Please install NickelMenu from https://pgaskin.net/NickelMenu/"
    fi
    
    cat > "$KOBO_MOUNT/.adds/nm/kobofrotz" << EOF
# KoboFrotz - Z-Machine Interpreter
# Main menu entry

menu_item :main :KoboFrotz (Z-Machine) :cmd_spawn :quiet:${KOBO_APP_DIR}/run.sh
  chain_success :nickel_misc :rescan_books_full

# Optional: Custom submenu for different games
# menu_item :main :Interactive Fiction :nickel_open :library

EOF
    
    log_info "NickelMenu configuration created"
}

deploy_qt_libs() {
    if [ -n "${QT_DEPLOY_DIR:-}" ] && [ -d "$QT_DEPLOY_DIR" ]; then
        log_info "Copying Qt libraries..."
        
        # Target directory
        QT_TARGET="$KOBO_MOUNT/.adds/qt-linux-5.15-kobo"
        
        mkdir -p "$QT_TARGET"
        cp -r "$QT_DEPLOY_DIR"/* "$QT_TARGET/"
        
        log_info "Qt libraries copied to $QT_TARGET"
    else
        log_warn "QT_DEPLOY_DIR not set or not found."
        log_info "Qt libraries must be installed separately."
        log_info "Use deploy_qt.sh from kobo-qt-setup-scripts"
    fi
}

create_readme() {
    log_info "Creating README..."
    
    cat > "$KOBO_MOUNT/.adds/kobofrotz/README.txt" << 'EOF'
KoboFrotz - Z-Machine Interpreter for Kobo
==========================================

KoboFrotz enables playing Interactive Fiction (Text Adventures)
on your Kobo E-Reader.

Supported formats:
- Z-Machine games (.z3, .z5, .z8, .zblorb, .zlb)
- Infocom games
- Inform games

Directories:
- games/  - Place your Z-Machine games here
- saves/  - Game saves are stored here

Controls:
- Start via NickelMenu -> KoboFrotz
- On-screen keyboard for input
- Menu for Save/Restore

Where to get games?
- IFDB: https://ifdb.org
- IF Archive: https://www.ifarchive.org

Note:
For best readability on E Ink displays, high contrast
(black on white) is recommended.
EOF
    
    log_info "README created"
}

print_summary() {
    log_info ""
    log_info "=========================================="
    log_info "Deployment complete!"
    log_info "=========================================="
    log_info ""
    log_info "Installed files:"
    ls -la "$KOBO_MOUNT/.adds/kobofrotz/"
    log_info ""
    log_info "NickelMenu configuration:"
    cat "$KOBO_MOUNT/.adds/nm/kobofrotz"
    log_info ""
    log_info "Next steps:"
    log_info "1. Copy Z-Machine games to .adds/kobofrotz/games/"
    log_info "2. Safely eject the Kobo"
    log_info "3. The Kobo will automatically reboot"
    log_info "4. Launch KoboFrotz via NickelMenu"
    log_info ""
}

# Main program
main() {
    if [ $# -lt 1 ]; then
        usage
    fi
    
    KOBO_MOUNT="$1"
    
    log_info "=========================================="
    log_info "KoboFrotz Deployment"
    log_info "=========================================="
    log_info ""
    
    check_kobo_mount
    check_build
    create_directories
    deploy_binary
    deploy_run_script
    deploy_nickelmenu_config
    deploy_qt_libs
    create_readme
    print_summary
}

main "$@"
