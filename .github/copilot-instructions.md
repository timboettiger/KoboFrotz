# Copilot Instructions for KoboFrotz

## Project Overview

KoboFrotz is a Z-Machine interpreter for Kobo E-Readers, based on Frotz. It enables playing Interactive Fiction (Text Adventures) on Kobo devices.

## Technology Stack

- **Language**: C++ with Qt 5.15
- **Build System**: qmake (KoboFrotz.pro)
- **Target Platform**: Kobo E-Reader (ARM, Linux)
- **Cross-Compilation**: Docker with rain92/kobo-qt-dev image

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
├── build.sh               # Central build & deploy script
├── increment-build.sh     # Version incrementer
└── BUILD.md               # Detailed build instructions
```

## Build Instructions

### Prerequisites
- Docker installed and running

### Build Command
```bash
./build.sh                              # Build only
./build.sh --deploy /path/to/kobo       # Build and deploy
```

### Output
The build creates `dist/KoboFrotz/` containing:
- ARM binary
- Qt libraries (Core, Gui, Widgets)
- Kobo platform plugin
- Launcher script
- NickelMenu configuration

## Important Files

| File | Description |
|------|-------------|
| `KoboFrotz.pro` | Qt project file with all sources |
| `kobofrotzview.{h,cpp}` | Main widget for game display |
| `kobofrotzwindow.{h,cpp,ui}` | Main window with menus |
| `kobofrotz.h` | Global definitions and configuration |
| `version.h` | Version numbers (auto-incremented) |

## Code Conventions

- Class names: PascalCase (e.g., `KoboFrotzView`)
- File names: lowercase (e.g., `kobofrotzview.cpp`)
- Global variables: `global_` prefix (e.g., `global_kobofrotzwindow`)
- Use Qt signals/slots for UI interaction

## Version System

- Format: V1.0.0-XXXX (major.minor.patch-build)
- Build number: 4-digit hex, auto-incremented by `increment-build.sh`
- Defined in `version.h`

## Debugging

### Desktop Build (for testing)
```bash
# Inside Docker container:
mkdir build && cd build
qmake ../KoboFrotz.pro
make
```

### On Kobo
Check if the app starts via NickelMenu. Touch input issues can often be fixed
by adjusting rotation in `KoboFrotz.sh`.

## Known Limitations

- Sound is not supported (`NO_SOUND` defined)
- Graphics (V6 games) are experimental
- E-Ink optimized: Minimal screen updates
