# KoboFrotz Build Guide

Build KoboFrotz for Kobo E-Readers (including Kobo Libra Colour with Firmware 4.44+).

## Prerequisites

- **Docker** (required)
  - macOS: `brew install --cask docker`
  - Linux: `sudo apt install docker.io`
  - Windows: Docker Desktop with WSL2

## Quick Build

```bash
# Clone repository
git clone https://github.com/timboettiger/KoboFrotz.git
cd KoboFrotz

# Build (creates dist/ folder with everything needed)
./build.sh

# Build and deploy directly to connected Kobo
./build.sh --deploy /media/$USER/KOBOeReader   # Linux
./build.sh --deploy /Volumes/KOBOeReader       # macOS
```

## What Gets Built

The `build.sh` script creates a complete distribution package in `dist/`:

```
dist/
├── KoboFrotz/
│   ├── KoboFrotz           # ARM binary
│   ├── KoboFrotz.sh        # Launcher script
│   ├── lib/
│   │   ├── libQt5Core.so.5
│   │   ├── libQt5Gui.so.5
│   │   └── libQt5Widgets.so.5
│   ├── plugins/
│   │   └── platforms/
│   │       ├── libkobo.so      # Kobo E-Ink platform plugin
│   │       └── libqlinuxfb.so  # Fallback framebuffer plugin
│   ├── games/              # Put your .z3/.z5/.z8 files here
│   └── saves/              # Save files will be stored here
└── nm/
    └── kobofrotz           # NickelMenu configuration
```

## Manual Deployment

If you prefer to deploy manually:

1. Connect your Kobo via USB
2. Copy `dist/KoboFrotz/` to `.adds/KoboFrotz/` on the Kobo
3. Copy `dist/nm/kobofrotz` to `.adds/nm/` on the Kobo
4. Safely eject the Kobo and restart it

KoboFrotz will appear in the NickelMenu.

## Interactive Docker Build (Alternative)

For debugging or manual builds:

```bash
# Start interactive Docker session
docker run --rm -it \
  -v "$PWD":/work \
  -w /work \
  rain92/kobo-qt-dev

# Inside container:
mkdir -p build-kobo && cd build-kobo
/home/user/qt-bin/qt-linux-5.15-kde-kobo/bin/qmake ../KoboFrotz.pro CONFIG+=release
make -j$(nproc)

# Exit with Ctrl+D, binary is at build-kobo/KoboFrotz
```

## NickelMenu

KoboFrotz requires [NickelMenu](https://pgaskin.net/NickelMenu/) to launch.

### Install NickelMenu (if not installed)

1. Download from https://pgaskin.net/NickelMenu/
2. Copy `KoboRoot.tgz` to `.kobo/` on your Kobo
3. Safely eject and restart

## Troubleshooting

### App doesn't start
- Ensure NickelMenu is installed
- Check that all files are in `.adds/KoboFrotz/`
- Verify `KoboFrotz.sh` is executable

### Touch not working
- Edit `KoboFrotz.sh` and adjust `QT_QPA_EVDEV_TOUCHSCREEN_PARAMETERS`
- Try different rotation values: `rotate=0`, `rotate=90`, `rotate=180`, `rotate=270`

### Libraries missing
The distribution includes all required Qt libraries. If you still get errors, ensure 
the complete `lib/` folder was copied.

## Version

Current version: V1.0.0 with auto-incrementing build number.
Version is displayed in the window title.
