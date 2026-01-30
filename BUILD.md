# KoboFrotz Build Guide for Kobo Libra Colour

This guide describes how to cross-compile KoboFrotz for Kobo Libra Colour (Firmware 4.44+) and launch it with NickelMenu.

## Prerequisites

### Hardware
- Kobo Libra Colour (Model N428)
- Firmware Version 4.44 or higher
- NickelMenu installed

### Development Environment
- Docker (recommended - works on Linux, macOS Intel/Apple Silicon, Windows WSL2)
- OR: Linux with native toolchain
- Git

## Quick Start (Docker - Recommended)

The easiest way to build KoboFrotz is using Docker with the pre-built `rain92/kobo-qt-dev` image:

### Interactive Docker Build (Simplest)

```bash
# Clone the repository
git clone https://github.com/timboettiger/KoboFrotz.git
cd KoboFrotz

# Start Docker container (interactive)
docker run --rm -it \
  -v /tmp:/tmp \
  -v "$PWD":/work \
  -w /work \
  rain92/kobo-qt-dev

# Inside the container:
mkdir -p build-kobo
cd build-kobo
/home/user/qt-bin/qt-linux-5.15-kde-kobo/bin/qmake ../KoboFrotz.pro CONFIG+=release
make -j"$(nproc)"

# Exit container (Ctrl+D or 'exit')
# Binary is now at: build-kobo/KoboFrotz
```

### Automated Docker Build

```bash
# Clone the repository
git clone https://github.com/timboettiger/KoboFrotz.git
cd KoboFrotz

# Create Docker helper script
./setup-toolchain.sh --docker

# Build using Docker (increments version automatically)
./build-docker.sh

# Deploy to Kobo
./deploy-kobo.sh /media/$USER/KOBOeReader  # Linux
./deploy-kobo.sh /Volumes/KOBOeReader      # macOS
```

### Native Linux Build (Alternative)

```bash
# Clone the repository
git clone https://github.com/timboettiger/KoboFrotz.git
cd KoboFrotz

# Setup toolchain (downloads ~600MB, builds Qt ~30-60min)
./setup-toolchain.sh

# Build KoboFrotz
./build-kobo.sh

# Deploy to Kobo
./deploy-kobo.sh /media/$USER/KOBOeReader
```

## Detailed Setup Instructions

### 1. Toolchain Installation

#### Automated (Recommended)

The `setup-toolchain.sh` script downloads and installs all required tools into the `toolchain/` directory within the project:

```bash
# Full setup (toolchain + Qt)
./setup-toolchain.sh

# Or step by step:
./setup-toolchain.sh --toolchain-only  # Install ARM toolchain
./setup-toolchain.sh --qt-only         # Build Qt (after toolchain)

# Verify installation
./setup-toolchain.sh --verify
```

#### Manual Installation

```bash
# Clone kobo-qt-setup-scripts
git clone https://github.com/Rain92/kobo-qt-setup-scripts.git
cd kobo-qt-setup-scripts

# Install toolchain
./install_toolchain.sh

# Build Qt for Kobo
./get_qt.sh
./build_qt.sh
```

### 2. Environment Variables

If using manual installation, set these environment variables:

```bash
# Path to toolchain
export KOBO_TOOLCHAIN=~/x-tools/arm-kobo-linux-gnueabihf
export PATH=$KOBO_TOOLCHAIN/bin:$PATH

# Cross-compiler prefix
export CROSS_COMPILE=arm-kobo-linux-gnueabihf-

# Qt for Kobo
export QT_KOBO=~/qt-kobo
export PATH=$QT_KOBO/bin:$PATH
```

Or create a `kobo-build.conf` file (see `kobo-build.conf.example`).

### 3. Compile KoboFrotz

```bash
# Use the build script (recommended)
./build-kobo.sh

# Or manually:
mkdir -p build-kobo
cd build-kobo
$QT_KOBO/bin/qmake ../KoboFrotz.pro
make -j$(nproc)
```

## 4. Deploy to Kobo

### Create Directory Structure on Kobo

```bash
# Connect via USB and mount the Kobo
# Then create the following directories:

/mnt/onboard/.adds/
├── kobofrotz/
│   ├── KoboFrotz              # The compiled application
│   ├── libs/                  # Required Qt libraries
│   │   ├── libQt5Core.so.5
│   │   ├── libQt5Gui.so.5
│   │   ├── libQt5Widgets.so.5
│   │   └── ...
│   ├── plugins/               # Qt plugins
│   │   └── platforms/
│   │       └── libkobo.so
│   ├── games/                 # Z-Machine games (.z3, .z5, .z8, etc.)
│   └── saves/                 # Save files
├── nm/
│   └── config                 # NickelMenu configuration
└── qt-linux-*/                # Qt libraries (from deploy_qt.sh)
```

### Copy Files

```bash
# Use deployment script
./deploy-kobo.sh /media/$USER/KOBOeReader

# Or manually:
cp build-kobo/KoboFrotz /Volumes/KOBOeReader/.adds/kobofrotz/
```

## 5. Configure NickelMenu

### Install NickelMenu (if not already installed)

1. Download NickelMenu from https://pgaskin.net/NickelMenu/
2. Copy the `KoboRoot.tgz` file to the `.kobo` directory on the Kobo
3. Safely eject the Kobo and restart

### Create NickelMenu Entry

Create the file `.adds/nm/config` on the Kobo:

```
menu_item :main :KoboFrotz (Z-Machine) :cmd_spawn :quiet:/mnt/onboard/.adds/kobofrotz/run.sh
  chain_success :nickel_misc :rescan_books_full
```

## 6. Create Startup Script

Create `/mnt/onboard/.adds/kobofrotz/run.sh`:

```bash
#!/bin/sh

# Qt environment
export LD_LIBRARY_PATH=/mnt/onboard/.adds/qt-linux-5.15-kobo/lib:$LD_LIBRARY_PATH
export QT_QPA_PLATFORM=kobo

# E Ink display settings
export QT_QPA_EVDEV_TOUCHSCREEN_PARAMETERS="rotate=0"
export QT_QPA_GENERIC_PLUGINS="evdevtouch:/dev/input/event1"

# Working directory
cd /mnt/onboard/.adds/kobofrotz

# Start application
./KoboFrotz
```

Make the script executable:
```bash
chmod +x /mnt/onboard/.adds/kobofrotz/run.sh
```

## Kobo Libra Colour Specific Notes

### Screen Resolution
- 1264 x 1680 pixels (Portrait)
- 1680 x 1264 pixels (Landscape)
- Color display supports 4096 colors (E Ink Kaleido)

### E Ink Optimizations
- Use high contrast (black/white) for best readability
- Minimize screen updates for longer battery life
- The application already uses `/etc/eink.qss` for E Ink-optimized styles

### Touch Input
The Libra Colour uses a capacitive touchscreen. The qt5-kobo-platform-plugin
supports this automatically.

## Troubleshooting

### Application Won't Start
1. Check if all libraries are present:
   ```bash
   ldd /mnt/onboard/.adds/kobofrotz/KoboFrotz
   ```
2. Make sure run.sh is executable
3. Verify NickelMenu configuration

### Missing Libraries
Use the `deploy_qt.sh` script from kobo-qt-setup-scripts to install
all required libraries.

### Touch Not Working
Adjust `QT_QPA_EVDEV_TOUCHSCREEN_PARAMETERS` in run.sh.
Rotation may be required for Libra Colour.

## Additional Resources

- [kobo-qt-setup-scripts](https://github.com/Rain92/kobo-qt-setup-scripts)
- [qt5-kobo-platform-plugin](https://github.com/Rain92/qt5-kobo-platform-plugin)
- [NickelMenu](https://pgaskin.net/NickelMenu/)
- [kobo-qt-dev-docker](https://github.com/Rain92/kobo-qt-dev-docker)
- [Kobo Firmware Downloads](https://pgaskin.net/KoboStuff/kobofirmware.html)
