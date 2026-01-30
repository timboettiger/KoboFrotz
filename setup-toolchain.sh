#!/bin/bash
#
# setup-toolchain.sh
# Downloads and sets up the Kobo cross-compilation toolchain locally
#
# All toolchain components are installed into the 'toolchain/' directory
# within the project folder (not versioned in git)
#
# Supports: Linux (x86_64, ARM), macOS (Intel, Apple Silicon)
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLCHAIN_DIR="$SCRIPT_DIR/toolchain"
KOBO_QT_SCRIPTS_DIR="$TOOLCHAIN_DIR/kobo-qt-setup-scripts"

# Detect OS and architecture
OS_TYPE="$(uname -s)"
ARCH_TYPE="$(uname -m)"

# Output colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_banner() {
    echo ""
    echo "=========================================="
    echo "  KoboFrotz Toolchain Setup"
    echo "=========================================="
    echo ""
    log_info "Detected OS: $OS_TYPE ($ARCH_TYPE)"
    echo ""
}

check_macos_dependencies() {
    log_step "Checking macOS dependencies..."
    
    # Check for Homebrew
    if ! command -v brew &> /dev/null; then
        log_error "Homebrew not found. Please install it first:"
        log_info "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
    log_info "Homebrew found"
    
    # Required packages for cross-compilation on macOS
    local packages=(
        "wget"
        "curl"
        "coreutils"
        "gnu-sed"
        "gnu-tar"
        "make"
        "autoconf"
        "automake"
        "libtool"
        "pkg-config"
    )
    
    local missing_packages=()
    for pkg in "${packages[@]}"; do
        if ! brew list "$pkg" &> /dev/null; then
            missing_packages+=("$pkg")
        fi
    done
    
    if [ ${#missing_packages[@]} -ne 0 ]; then
        log_warn "Missing Homebrew packages: ${missing_packages[*]}"
        log_info "Installing missing packages..."
        brew install "${missing_packages[@]}"
    fi
    
    # Add GNU tools to PATH for this session
    export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
    export PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"
    export PATH="/opt/homebrew/opt/gnu-tar/libexec/gnubin:$PATH"
    export PATH="/opt/homebrew/opt/make/libexec/gnubin:$PATH"
    
    # For Intel Macs
    if [ -d "/usr/local/opt" ]; then
        export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
        export PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
        export PATH="/usr/local/opt/gnu-tar/libexec/gnubin:$PATH"
        export PATH="/usr/local/opt/make/libexec/gnubin:$PATH"
    fi
    
    log_info "All macOS dependencies satisfied"
}

check_linux_dependencies() {
    log_step "Checking Linux dependencies..."
    
    local missing_deps=()
    
    # Check for required tools
    for cmd in git make gcc g++ wget curl tar autoconf automake libtool pkg-config; do
        if ! command -v $cmd &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log_info "Please install them first:"
        log_info "  Ubuntu/Debian: sudo apt install build-essential git wget curl autoconf automake libtool pkg-config"
        log_info "  Fedora: sudo dnf install @development-tools git wget curl autoconf automake libtool pkg-config"
        log_info "  Arch: sudo pacman -S base-devel git wget curl autoconf automake libtool pkg-config"
        exit 1
    fi
    
    log_info "All Linux dependencies found"
}

check_dependencies() {
    case "$OS_TYPE" in
        Darwin)
            check_macos_dependencies
            ;;
        Linux)
            check_linux_dependencies
            ;;
        *)
            log_error "Unsupported operating system: $OS_TYPE"
            exit 1
            ;;
    esac
}

create_directories() {
    log_step "Creating toolchain directory..."
    
    mkdir -p "$TOOLCHAIN_DIR"
    
    log_info "Toolchain directory: $TOOLCHAIN_DIR"
}

clone_setup_scripts() {
    log_step "Cloning kobo-qt-setup-scripts..."
    
    if [ -d "$KOBO_QT_SCRIPTS_DIR" ]; then
        log_info "kobo-qt-setup-scripts already exists, updating..."
        cd "$KOBO_QT_SCRIPTS_DIR"
        git pull || log_warn "Could not update, continuing with existing version"
        git submodule update --init --recursive
    else
        git clone --recursive https://github.com/Rain92/kobo-qt-setup-scripts.git "$KOBO_QT_SCRIPTS_DIR"
    fi
    
    # Ensure submodules are initialized
    cd "$KOBO_QT_SCRIPTS_DIR"
    git submodule update --init --recursive
    
    log_info "Setup scripts ready"
}

install_toolchain() {
    log_step "Installing ARM cross-compilation toolchain..."
    log_info "This may take a while (downloading ~100MB)..."
    
    cd "$KOBO_QT_SCRIPTS_DIR"
    
    # Modify the install script to use our local directory
    export TOOLCHAIN_BASE="$TOOLCHAIN_DIR"
    
    # On macOS, we may need to use a different approach
    if [ "$OS_TYPE" = "Darwin" ]; then
        install_toolchain_macos
    else
        install_toolchain_linux
    fi
    
    log_info "Toolchain installed"
}

install_toolchain_linux() {
    # Run the toolchain installation
    if [ -f "./install_toolchain.sh" ]; then
        ./install_toolchain.sh
        
        # Move toolchain to our directory if it was installed elsewhere
        if [ -d "$HOME/x-tools/arm-kobo-linux-gnueabihf" ] && [ ! -d "$TOOLCHAIN_DIR/arm-kobo-linux-gnueabihf" ]; then
            log_info "Moving toolchain to project directory..."
            mv "$HOME/x-tools/arm-kobo-linux-gnueabihf" "$TOOLCHAIN_DIR/"
            rmdir "$HOME/x-tools" 2>/dev/null || true
        fi
    else
        log_error "install_toolchain.sh not found"
        exit 1
    fi
}

install_toolchain_macos() {
    log_info "Installing toolchain for macOS..."
    
    # Check if we can use the standard script
    if [ -f "./install_toolchain.sh" ]; then
        # Try to run the script - it might work on macOS
        ./install_toolchain.sh || {
            log_warn "Standard toolchain install failed, trying alternative method..."
            install_toolchain_macos_alternative
            return
        }
        
        # Move toolchain to our directory if it was installed elsewhere
        if [ -d "$HOME/x-tools/arm-kobo-linux-gnueabihf" ] && [ ! -d "$TOOLCHAIN_DIR/arm-kobo-linux-gnueabihf" ]; then
            log_info "Moving toolchain to project directory..."
            mv "$HOME/x-tools/arm-kobo-linux-gnueabihf" "$TOOLCHAIN_DIR/"
            rmdir "$HOME/x-tools" 2>/dev/null || true
        fi
    else
        install_toolchain_macos_alternative
    fi
}

install_toolchain_macos_alternative() {
    log_info "Using alternative toolchain installation for macOS..."
    
    # Download pre-built toolchain for macOS if available
    # Otherwise, we'll need to build with crosstool-ng
    
    local TOOLCHAIN_URL=""
    
    if [ "$ARCH_TYPE" = "arm64" ]; then
        # Apple Silicon
        log_info "Detected Apple Silicon Mac"
        # Note: Pre-built toolchains for Apple Silicon may not be available
        # We'll try to use Docker as fallback
        TOOLCHAIN_URL="https://github.com/nickel-dev/kobo-toolchain/releases/download/v1.0/arm-kobo-linux-gnueabihf-darwin-arm64.tar.xz"
    else
        # Intel Mac
        log_info "Detected Intel Mac"
        TOOLCHAIN_URL="https://github.com/nickel-dev/kobo-toolchain/releases/download/v1.0/arm-kobo-linux-gnueabihf-darwin-x86_64.tar.xz"
    fi
    
    # Try to download pre-built toolchain
    local TOOLCHAIN_ARCHIVE="$TOOLCHAIN_DIR/toolchain.tar.xz"
    
    log_info "Attempting to download pre-built toolchain..."
    if curl -fsSL -o "$TOOLCHAIN_ARCHIVE" "$TOOLCHAIN_URL" 2>/dev/null; then
        log_info "Extracting toolchain..."
        cd "$TOOLCHAIN_DIR"
        tar -xf "$TOOLCHAIN_ARCHIVE"
        rm "$TOOLCHAIN_ARCHIVE"
        log_info "Pre-built toolchain installed"
    else
        log_warn "Pre-built toolchain not available for macOS $ARCH_TYPE"
        log_info ""
        log_info "Alternative options for macOS:"
        log_info ""
        log_info "Option 1: Use Docker (Recommended)"
        log_info "  docker pull rain92/kobo-qt-dev"
        log_info "  docker run -it -v \$(pwd):/workspace rain92/kobo-qt-dev"
        log_info "  # Then run ./build-kobo.sh inside the container"
        log_info ""
        log_info "Option 2: Build toolchain with crosstool-ng"
        log_info "  brew install crosstool-ng"
        log_info "  # Follow crosstool-ng documentation to build ARM toolchain"
        log_info ""
        log_info "Option 3: Use a Linux VM"
        log_info "  Use UTM, Parallels, or VMware to run Linux"
        log_info ""
        
        # Create a Docker helper script
        create_docker_helper
        
        log_warn "Toolchain installation incomplete. Please use Docker or another method."
        return 1
    fi
}

create_docker_helper() {
    log_info "Creating Docker helper script..."
    
    cat > "$SCRIPT_DIR/build-docker.sh" << 'EOF'
#!/bin/bash
#
# build-docker.sh
# Build KoboFrotz using Docker (for macOS or systems without native toolchain)
# Builds ARM binary for Kobo E-Readers
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_IMAGE="rain92/kobo-qt-dev"

# Output colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    log_error "Docker not found. Please install Docker first."
    echo "  macOS: brew install --cask docker"
    echo "  Or download from https://www.docker.com/products/docker-desktop"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    log_error "Docker daemon is not running. Please start Docker."
    exit 1
fi

log_info "Pulling Docker image (if needed)..."
docker pull "$DOCKER_IMAGE"

echo ""
log_info "Starting ARM cross-compilation build in Docker container..."
echo ""

# Create output directories
mkdir -p "$SCRIPT_DIR/build-kobo"
mkdir -p "$SCRIPT_DIR/dist"

# Run build inside Docker (override entrypoint!)
docker run --rm \
    --entrypoint /bin/bash \
    -v "$SCRIPT_DIR:/workspace" \
    -w /workspace \
    "$DOCKER_IMAGE" \
    -c '
        set -e
        
        echo "[Docker] Incrementing build number..."
        ./increment-build.sh version.h || echo "Warning: Could not increment build"
        
        echo "[Docker] Cross-compiler: $(which arm-kobo-linux-gnueabihf-gcc)"
        echo "[Docker] qmake: /home/user/qt-bin/qt-linux-5.15-kde-kobo/bin/qmake"
        
        echo "[Docker] Cleaning build directory..."
        rm -rf build-kobo/*
        mkdir -p build-kobo
        cd build-kobo
        
        echo "[Docker] Running qmake..."
        /home/user/qt-bin/qt-linux-5.15-kde-kobo/bin/qmake ../KoboFrotz.pro CONFIG+=release
        
        echo "[Docker] Compiling (this may take a few minutes)..."
        make -j$(nproc)
        
        echo "[Docker] Build result:"
        ls -la KoboFrotz 2>/dev/null || echo "Binary not found!"
        file KoboFrotz 2>/dev/null || true
        
        cd ..
        
        if [ -f build-kobo/KoboFrotz ]; then
            echo "[Docker] Creating distribution..."
            mkdir -p dist/kobofrotz/games dist/kobofrotz/saves dist/nm
            cp build-kobo/KoboFrotz dist/kobofrotz/
            
            # Create run script
            cat > dist/kobofrotz/run.sh << "RUNEOF"
#!/bin/sh
KOBOFROTZ_DIR="/mnt/onboard/.adds/kobofrotz"
QT_LIB_DIR="/mnt/onboard/.adds/qt-linux-5.15-kobo/lib"
export LD_LIBRARY_PATH="$QT_LIB_DIR:$LD_LIBRARY_PATH"
export QT_QPA_PLATFORM=kobo
export QT_QPA_EVDEV_TOUCHSCREEN_PARAMETERS="rotate=0"
export QT_QPA_GENERIC_PLUGINS="evdevtouch:/dev/input/event1"
cd "$KOBOFROTZ_DIR"
exec ./KoboFrotz "$@"
RUNEOF
            chmod +x dist/kobofrotz/run.sh
            
            # Create NickelMenu config
            cat > dist/nm/kobofrotz << "NMEOF"
menu_item :main :KoboFrotz (Z-Machine) :cmd_spawn :quiet:/mnt/onboard/.adds/kobofrotz/run.sh
  chain_success :nickel_misc :rescan_books_full
NMEOF
            
            echo "[Docker] Distribution created successfully!"
            ls -la dist/kobofrotz/
        else
            echo "[Docker] ERROR: Build failed - binary not created"
            exit 1
        fi
    '

echo ""

# Verify build output
if [ -f "$SCRIPT_DIR/dist/kobofrotz/KoboFrotz" ]; then
    ARCH=$(file "$SCRIPT_DIR/dist/kobofrotz/KoboFrotz" | grep -oE "ARM|x86-64|x86_64" || echo "unknown")
    
    log_info "=========================================="
    log_info "Build successful!"
    log_info "=========================================="
    echo ""
    log_info "Binary: $SCRIPT_DIR/dist/kobofrotz/KoboFrotz"
    log_info "Architecture: $ARCH"
    echo ""
    
    if [ "$ARCH" = "ARM" ]; then
        log_info "✓ ARM binary created - ready for Kobo!"
    else
        log_warn "Binary is $ARCH, expected ARM for Kobo"
    fi
    
    echo ""
    log_info "Version:"
    grep "BUILD_NUMBER" "$SCRIPT_DIR/version.h"
    echo ""
    log_info "Contents of dist/kobofrotz/:"
    ls -la "$SCRIPT_DIR/dist/kobofrotz/"
    echo ""
    log_info "To deploy to Kobo:"
    log_info "  ./deploy-kobo.sh /media/\$USER/KOBOeReader"
else
    log_error "Build failed - binary not found in dist/kobofrotz/"
    exit 1
fi
EOF
    
    chmod +x "$SCRIPT_DIR/build-docker.sh"
    log_info "Created build-docker.sh for Docker-based builds"
}

download_qt_sources() {
    log_step "Downloading Qt sources..."
    log_info "This may take a while (downloading ~500MB)..."
    
    cd "$KOBO_QT_SCRIPTS_DIR"
    
    if [ -f "./get_qt.sh" ]; then
        ./get_qt.sh
    else
        log_error "get_qt.sh not found"
        exit 1
    fi
    
    log_info "Qt sources downloaded"
}

build_qt() {
    log_step "Building Qt for Kobo (this will take 30-60 minutes)..."
    
    cd "$KOBO_QT_SCRIPTS_DIR"
    
    # Set up environment for Qt build
    export PATH="$TOOLCHAIN_DIR/arm-kobo-linux-gnueabihf/bin:$PATH"
    
    if [ -f "./build_qt.sh" ]; then
        ./build_qt.sh
        
        # Move Qt to our directory if it was built elsewhere
        if [ -d "$HOME/qt-kobo" ] && [ ! -d "$TOOLCHAIN_DIR/qt-kobo" ]; then
            log_info "Moving Qt to project directory..."
            mv "$HOME/qt-kobo" "$TOOLCHAIN_DIR/"
        fi
    else
        log_error "build_qt.sh not found"
        exit 1
    fi
    
    log_info "Qt built successfully"
}

create_local_config() {
    log_step "Creating local build configuration..."
    
    cat > "$SCRIPT_DIR/kobo-build.conf" << EOF
# KoboFrotz Build Configuration (auto-generated by setup-toolchain.sh)
# This file is not versioned in git

# Path to Kobo Cross-Compilation Toolchain (local)
KOBO_TOOLCHAIN="$TOOLCHAIN_DIR/arm-kobo-linux-gnueabihf"

# Path to Qt for Kobo (local)
QT_KOBO="$TOOLCHAIN_DIR/qt-kobo"

# Installation path on the Kobo for the app
KOBO_APP_DIR=/mnt/onboard/.adds/kobofrotz

# Path to Qt libraries on the Kobo
KOBO_QT_LIB_DIR=/mnt/onboard/.adds/qt-linux-5.15-kobo/lib
EOF
    
    log_info "Configuration saved to kobo-build.conf"
}

verify_installation() {
    log_step "Verifying installation..."
    
    local errors=0
    
    # Check toolchain
    if [ -f "$TOOLCHAIN_DIR/arm-kobo-linux-gnueabihf/bin/arm-kobo-linux-gnueabihf-gcc" ]; then
        log_info "✓ Cross-compiler found"
    else
        log_error "✗ Cross-compiler not found"
        ((errors++))
    fi
    
    # Check Qt
    if [ -f "$TOOLCHAIN_DIR/qt-kobo/bin/qmake" ]; then
        log_info "✓ Qt qmake found"
    else
        log_error "✗ Qt qmake not found"
        ((errors++))
    fi
    
    if [ $errors -eq 0 ]; then
        log_info "Installation verified successfully!"
        return 0
    else
        log_error "Installation has $errors error(s)"
        return 1
    fi
}

print_summary() {
    echo ""
    echo "=========================================="
    echo "  Setup Complete!"
    echo "=========================================="
    echo ""
    log_info "Toolchain installed in: $TOOLCHAIN_DIR"
    echo ""
    log_info "To build KoboFrotz, run:"
    log_info "  ./build-kobo.sh"
    echo ""
    log_info "To deploy to Kobo, run:"
    log_info "  ./deploy-kobo.sh /media/\$USER/KOBOeReader"
    echo ""
    
    if [ "$OS_TYPE" = "Darwin" ]; then
        log_info "macOS Note: If native toolchain doesn't work, use Docker:"
        log_info "  ./build-docker.sh"
        echo ""
    fi
}

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Downloads and sets up the Kobo cross-compilation toolchain locally."
    echo "All components are installed into the 'toolchain/' directory."
    echo ""
    echo "Supported platforms:"
    echo "  - Linux (x86_64, ARM)"
    echo "  - macOS (Intel, Apple Silicon)"
    echo ""
    echo "Options:"
    echo "  --toolchain-only   Only install the ARM toolchain (skip Qt)"
    echo "  --qt-only          Only build Qt (requires toolchain)"
    echo "  --docker           Create Docker helper script only"
    echo "  --verify           Verify existing installation"
    echo "  --clean            Remove toolchain directory"
    echo "  --help, -h         Show this help"
    echo ""
    echo "The full setup will:"
    echo "  1. Clone kobo-qt-setup-scripts"
    echo "  2. Download and install ARM cross-compiler (~100MB)"
    echo "  3. Download Qt sources (~500MB)"
    echo "  4. Build Qt for Kobo (30-60 minutes)"
    echo ""
    echo "macOS users: If native build fails, use Docker:"
    echo "  ./setup-toolchain.sh --docker"
    echo "  ./build-docker.sh"
    echo ""
}

clean_toolchain() {
    log_warn "This will remove the entire toolchain directory!"
    read -p "Are you sure? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$TOOLCHAIN_DIR"
        rm -f "$SCRIPT_DIR/kobo-build.conf"
        log_info "Toolchain directory removed"
    else
        log_info "Cancelled"
    fi
}

# Main program
main() {
    print_banner
    
    case "${1:-}" in
        --help|-h)
            show_help
            exit 0
            ;;
        --clean)
            clean_toolchain
            exit 0
            ;;
        --verify)
            verify_installation
            exit $?
            ;;
        --docker)
            create_docker_helper
            log_info ""
            log_info "To build with Docker, run:"
            log_info "  ./build-docker.sh"
            exit 0
            ;;
        --toolchain-only)
            check_dependencies
            create_directories
            clone_setup_scripts
            install_toolchain
            create_local_config
            verify_installation || true
            ;;
        --qt-only)
            check_dependencies
            if [ ! -d "$TOOLCHAIN_DIR/arm-kobo-linux-gnueabihf" ]; then
                log_error "Toolchain not found. Run setup without --qt-only first."
                exit 1
            fi
            download_qt_sources
            build_qt
            create_local_config
            verify_installation
            ;;
        "")
            check_dependencies
            create_directories
            clone_setup_scripts
            install_toolchain || {
                log_warn "Native toolchain installation failed"
                if [ "$OS_TYPE" = "Darwin" ]; then
                    log_info "On macOS, Docker is recommended. Run:"
                    log_info "  ./build-docker.sh"
                fi
                exit 1
            }
            download_qt_sources
            build_qt
            create_local_config
            verify_installation
            print_summary
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
