# Copilot Instructions for KoboFrotz

## Project Overview

KoboFrotz is a Z-Machine interpreter for Kobo E-Readers, based on Frotz. It enables playing Interactive Fiction (Text Adventures) on Kobo devices.

## Technology Stack

- **Language**: C++ with Qt 5.15
- **Build System**: qmake (KoboFrotz.pro)
- **Target Platform**: Kobo E-Reader (ARM, Linux)
- **Cross-Compilation**: koxtoolchain

## Project Structure

```
KoboFrotz/
├── KoboFrotz.pro          # Qt project file
├── main.cpp               # Main entry point
├── kobofrotz*.{h,cpp}     # Main UI components
├── qt*.cpp                # Qt interface implementation
├── frotz/                 # Frotz Z-Machine Engine (C)
├── KoFileDialog/          # Kobo-optimized file dialog
├── KoSettingsDialog/      # Settings dialog
├── QScreenKeyboard/       # On-screen keyboard
├── build-kobo.sh          # Cross-compilation script
├── deploy-kobo.sh         # Deployment script
└── BUILD.md               # Detailed build instructions
```

## Build Instructions

### Prerequisites for Cross-Compilation (Kobo)

1. **Install toolchain**:
   ```bash
   git clone https://github.com/Rain92/kobo-qt-setup-scripts.git
   cd kobo-qt-setup-scripts
   ./install_toolchain.sh
   ./get_qt.sh
   ./build_qt.sh
   ```

2. **Set environment variables**:
   ```bash
   export KOBO_TOOLCHAIN=~/x-tools/arm-kobo-linux-gnueabihf
   export QT_KOBO=~/qt-kobo
   ```

### Cross-Compilation for Kobo

```bash
# Using the build script (recommended)
./build-kobo.sh

# Or manually
mkdir build-kobo && cd build-kobo
$QT_KOBO/bin/qmake ../KoboFrotz.pro CONFIG+=release
make -j$(nproc)
```

### Native Compilation (Desktop, for testing)

```bash
# Prerequisite: Qt 5.15 development packages
# Ubuntu/Debian: apt install qt5-default qtbase5-dev

mkdir build && cd build
qmake ../KoboFrotz.pro
make -j$(nproc)
```

## Deployment to Kobo

```bash
# Connect Kobo via USB
./deploy-kobo.sh /media/$USER/KOBOeReader
```

The app is launched via NickelMenu.

## Configuration

### Build Configuration (kobo-build.conf)

Create `kobo-build.conf` in the project directory:

```bash
# Toolchain paths
KOBO_TOOLCHAIN=/path/to/toolchain
QT_KOBO=/path/to/qt-kobo

# Kobo installation paths
KOBO_APP_DIR=/mnt/onboard/.adds/kobofrotz
KOBO_QT_LIB_DIR=/mnt/onboard/.adds/qt-linux-5.15-kobo/lib
```

## Important Files

| File | Description |
|------|-------------|
| `KoboFrotz.pro` | Qt project file with all sources |
| `kobofrotzview.{h,cpp}` | Main widget for game display |
| `kobofrotzwindow.{h,cpp,ui}` | Main window with menus |
| `kobofrotz.h` | Global definitions and configuration |
| `qtinit.cpp` | Z-Machine initialization |
| `qtinput.cpp` | Input handling |
| `qtscreen.cpp` | Screen output |

## Code Conventions

- Class names: PascalCase (e.g., `KoboFrotzView`)
- File names: lowercase (e.g., `kobofrotzview.cpp`)
- Global variables: `global_` prefix (e.g., `global_kobofrotzwindow`)
- Use Qt signals/slots for UI interaction

## Common Tasks

### Adding a New Setting

1. Edit `KoSettingsDialog/kosettingsdialog.{h,cpp,ui}`
2. Load/save in `kobofrotzview.cpp` via `QSettings`

### Changing Keyboard Layout

1. Edit files in `QScreenKeyboard/layouts/`
2. Layouts are XML files

### Extending Z-Machine Functionality

1. `frotz/` directory contains the engine
2. Implement interface functions in `qt*.cpp`

## Debugging

### On the Kobo

```bash
# Check log file
cat /mnt/onboard/.adds/kobofrotz/kobofrotz.log
```

### Desktop Build

```bash
# Build with debug symbols
qmake ../KoboFrotz.pro CONFIG+=debug
make
gdb ./KoboFrotz
```

## Known Limitations

- Sound is not supported (`NO_SOUND` defined)
- Graphics (V6 games) are experimental
- E Ink optimized: Minimal screen updates

## Additional Resources

- [Z-Machine Standards Document](https://inform-fiction.org/zmachine/standards/)
- [Original Frotz](https://github.com/DavidGriffith/frotz)
- [kobo-qt-setup-scripts](https://github.com/Rain92/kobo-qt-setup-scripts)
- [NickelMenu](https://pgaskin.net/NickelMenu/)
