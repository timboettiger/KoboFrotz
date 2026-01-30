#!/bin/bash
#
# build.sh - Central build and deploy script for KoboFrotz
# Creates a complete distribution package with all dependencies for Kobo E-Readers
#
# Usage:
#   ./build.sh              # Build only
#   ./build.sh --deploy /path/to/kobo   # Build and deploy to Kobo
#
# Requires: Docker
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_IMAGE="rain92/kobo-qt-dev"
QMAKE_PATH="/home/user/qt-bin/qt-linux-5.15-kde-kobo/bin/qmake"
QT_LIB_PATH="/home/user/qt-bin/qt-linux-5.15-kde-kobo/lib"
QT_PLUGIN_PATH="/home/user/qt-bin/qt-linux-5.15-kde-kobo/plugins"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step()  { echo -e "${BLUE}[STEP]${NC} $1"; }

# Parse arguments
DEPLOY_PATH=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --deploy)
            DEPLOY_PATH="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--deploy /path/to/kobo]"
            echo ""
            echo "Options:"
            echo "  --deploy PATH   Deploy to Kobo mounted at PATH"
            echo "  -h, --help      Show this help"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check Docker
if ! command -v docker &> /dev/null; then
    log_error "Docker not found. Please install Docker first."
    echo "  macOS: brew install --cask docker"
    echo "  Linux: sudo apt install docker.io"
    exit 1
fi

if ! docker info &> /dev/null; then
    log_error "Docker daemon is not running. Please start Docker."
    exit 1
fi

echo ""
echo "=========================================="
echo "  KoboFrotz Build Script"
echo "=========================================="
echo ""

# Pull Docker image
log_step "Pulling Docker image..."
docker pull "$DOCKER_IMAGE" 2>/dev/null || true

# Clean previous build
log_step "Cleaning previous build..."
sudo rm -rf "$SCRIPT_DIR/build-kobo" "$SCRIPT_DIR/dist" 2>/dev/null || true
mkdir -p "$SCRIPT_DIR/build-kobo"
mkdir -p "$SCRIPT_DIR/dist"

# Build inside Docker
log_step "Building KoboFrotz (ARM cross-compilation)..."

docker run --rm \
    --entrypoint /bin/bash \
    -v "$SCRIPT_DIR:/work" \
    -w /work \
    "$DOCKER_IMAGE" \
    -c '
set -e

echo "[Docker] Incrementing build number..."
if [ -f increment-build.sh ]; then
    chmod +x increment-build.sh
    ./increment-build.sh version.h 2>/dev/null || echo "Could not increment build number"
fi

echo "[Docker] Running qmake..."
cd build-kobo
'"$QMAKE_PATH"' ../KoboFrotz.pro CONFIG+=release

echo "[Docker] Compiling..."
make -j$(nproc)

echo "[Docker] Checking binary..."
file KoboFrotz
ls -la KoboFrotz

echo ""
echo "[Docker] Creating distribution package..."

# Create directory structure
mkdir -p /work/dist/KoboFrotz/lib
mkdir -p /work/dist/KoboFrotz/plugins/platforms
mkdir -p /work/dist/KoboFrotz/games
mkdir -p /work/dist/KoboFrotz/saves

# Copy binary
cp KoboFrotz /work/dist/KoboFrotz/

# Copy required Qt libraries (only the ones we need)
echo "[Docker] Copying Qt libraries..."
cp '"$QT_LIB_PATH"'/libQt5Core.so.5 /work/dist/KoboFrotz/lib/
cp '"$QT_LIB_PATH"'/libQt5Gui.so.5 /work/dist/KoboFrotz/lib/
cp '"$QT_LIB_PATH"'/libQt5Widgets.so.5 /work/dist/KoboFrotz/lib/

# Copy platform plugin (use linuxfb as fallback, kobo plugin needs to be built separately)
echo "[Docker] Copying platform plugins..."
cp '"$QT_PLUGIN_PATH"'/platforms/libqlinuxfb.so /work/dist/KoboFrotz/plugins/platforms/

# Check if kobo platform plugin exists (may need to be pre-built)
if [ -f /home/user/qt5-kobo-platform-plugin/build/libkobo.so ]; then
    cp /home/user/qt5-kobo-platform-plugin/build/libkobo.so /work/dist/KoboFrotz/plugins/platforms/
    echo "[Docker] Kobo platform plugin found and copied"
else
    echo "[Docker] Building kobo platform plugin..."
    cd /home/user/qt5-kobo-platform-plugin
    mkdir -p build && cd build
    '"$QMAKE_PATH"' ../koboplatformplugin.pro CONFIG+=release 2>/dev/null || true
    make -j$(nproc) 2>/dev/null || true
    if [ -f libkobo.so ]; then
        cp libkobo.so /work/dist/KoboFrotz/plugins/platforms/
        echo "[Docker] Kobo platform plugin built and copied"
    else
        echo "[Docker] Warning: Could not build kobo platform plugin, using linuxfb"
    fi
fi

# Create run script
echo "[Docker] Creating run script..."
cat > /work/dist/KoboFrotz/KoboFrotz.sh << "RUNSCRIPT"
#!/bin/sh
#
# KoboFrotz launcher script for Kobo E-Readers
#

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOGFILE="$SCRIPT_DIR/kobofrotz.log"

# Set up library paths
export LD_LIBRARY_PATH="$SCRIPT_DIR/lib:$LD_LIBRARY_PATH"
export QT_PLUGIN_PATH="$SCRIPT_DIR/plugins"

# E-Ink display optimizations
export QT_QPA_EVDEV_TOUCHSCREEN_PARAMETERS="rotate=0"
export QT_QPA_GENERIC_PLUGINS="evdevtouch:/dev/input/event1"

# Disable GPU (not available on Kobo)
export QT_QPA_NO_HWSURFACE=1

# Working directory
cd "$SCRIPT_DIR"

# Decide platform once (no reload)
if [ -f "$SCRIPT_DIR/plugins/platforms/libkobo.so" ]; then
    export QT_QPA_PLATFORM=kobo
    PLATFORM_MSG="Using kobo platform plugin"
else
    export QT_QPA_PLATFORM=linuxfb:fb=/dev/fb0
    PLATFORM_MSG="Using linuxfb platform (kobo plugin not found)"
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - Launching KoboFrotz... ${PLATFORM_MSG}" > "$LOGFILE"

# Start KoboFrotz (single attempt). Capture exit for NickelMenu chain.
"$SCRIPT_DIR/KoboFrotz" "$@" >> "$LOGFILE" 2>&1
STATUS=$?
echo "$(date '+%Y-%m-%d %H:%M:%S') - KoboFrotz exited with status $STATUS" >> "$LOGFILE"
exit $STATUS
RUNSCRIPT
chmod +x /work/dist/KoboFrotz/KoboFrotz.sh

# Create NickelMenu config
echo "[Docker] Creating NickelMenu configuration..."
mkdir -p /work/dist/nm
cat > /work/dist/nm/kobofrotz << "NMCONFIG"
menu_item :main :KoboFrotz :cmd_spawn :quiet:/mnt/onboard/.adds/KoboFrotz/KoboFrotz.sh
  chain_success :dbg_msg :KoboFrotz exited OK (see log)
  chain_failure :dbg_msg :KoboFrotz failed (see log)
  chain_always  :nickel_misc :rescan_books_full
NMCONFIG

echo ""
echo "[Docker] Distribution package created!"
'

# Check build result
if [ ! -f "$SCRIPT_DIR/dist/KoboFrotz/KoboFrotz" ]; then
    log_error "Build failed - binary not found"
    exit 1
fi

# Show result
echo ""
log_info "=========================================="
log_info "Build successful!"
log_info "=========================================="
echo ""

BINARY_INFO=$(file "$SCRIPT_DIR/dist/KoboFrotz/KoboFrotz")
if echo "$BINARY_INFO" | grep -q "ARM"; then
    log_info "✓ ARM binary created - ready for Kobo!"
else
    log_warn "Binary architecture: $BINARY_INFO"
fi

echo ""
log_info "Version:"
grep "BUILD_NUMBER\|VERSION" "$SCRIPT_DIR/version.h" 2>/dev/null || echo "  (version.h not found)"

echo ""
log_info "Distribution contents:"
ls -la "$SCRIPT_DIR/dist/KoboFrotz/"
echo ""
ls -la "$SCRIPT_DIR/dist/KoboFrotz/lib/"
echo ""
ls -la "$SCRIPT_DIR/dist/KoboFrotz/plugins/platforms/"

# Calculate total size
TOTAL_SIZE=$(du -sh "$SCRIPT_DIR/dist/KoboFrotz" | cut -f1)
log_info "Total package size: $TOTAL_SIZE"

# Deploy if requested
if [ -n "$DEPLOY_PATH" ]; then
    echo ""
    log_step "Deploying to $DEPLOY_PATH..."
    
    if [ ! -d "$DEPLOY_PATH" ]; then
        log_error "Deploy path does not exist: $DEPLOY_PATH"
        exit 1
    fi
    
    # Create .adds directory if needed
    ADDS_DIR="$DEPLOY_PATH/.adds"
    mkdir -p "$ADDS_DIR"
    
    # Copy KoboFrotz
    log_info "Copying KoboFrotz..."
    cp -r "$SCRIPT_DIR/dist/KoboFrotz" "$ADDS_DIR/"
    
    # Copy NickelMenu config
    if [ -d "$ADDS_DIR/nm" ]; then
        log_info "Adding NickelMenu entry..."
        cp "$SCRIPT_DIR/dist/nm/kobofrotz" "$ADDS_DIR/nm/"
    else
        log_warn "NickelMenu not found at $ADDS_DIR/nm"
        log_info "Creating nm directory..."
        mkdir -p "$ADDS_DIR/nm"
        cp "$SCRIPT_DIR/dist/nm/kobofrotz" "$ADDS_DIR/nm/"
    fi
    
    echo ""
    log_info "=========================================="
    log_info "Deployment complete!"
    log_info "=========================================="
    log_info "Safely eject your Kobo and restart it."
    log_info "KoboFrotz will appear in NickelMenu."
fi

echo ""
log_info "To deploy manually:"
log_info "  1. Connect Kobo via USB"
log_info "  2. Copy dist/KoboFrotz/ to .adds/KoboFrotz/"
log_info "  3. Copy dist/nm/kobofrotz to .adds/nm/"
log_info "  4. Safely eject and restart Kobo"
echo ""
