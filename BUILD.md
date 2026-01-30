# KoboFrotz Build-Anleitung für Kobo Libra Colour

Diese Anleitung beschreibt, wie KoboFrotz für den Kobo Libra Colour (Firmware 4.44+) cross-kompiliert und mit NickelMenu gestartet werden kann.

## Voraussetzungen

### Hardware
- Kobo Libra Colour (Modell N428)
- Firmware Version 4.44 oder höher
- NickelMenu installiert

### Entwicklungsumgebung
- Linux-basiertes Betriebssystem (Ubuntu 20.04+ empfohlen)
- Git
- Grundlegende Build-Tools (build-essential, autoconf, automake, libtool)

## 1. Toolchain Installation

### Option A: kobo-qt-setup-scripts (Empfohlen)

```bash
# Repository klonen
git clone https://github.com/Rain92/kobo-qt-setup-scripts.git
cd kobo-qt-setup-scripts

# Toolchain installieren
./install_toolchain.sh

# Qt für Kobo bauen
./get_qt.sh
./build_qt.sh
```

### Option B: Docker-basierte Entwicklung

```bash
# Docker-Image verwenden
docker pull rain92/kobo-qt-dev
docker run -it -v $(pwd):/workspace rain92/kobo-qt-dev
```

## 2. Umgebungsvariablen setzen

```bash
# Pfad zur Toolchain
export KOBO_TOOLCHAIN=~/x-tools/arm-kobo-linux-gnueabihf
export PATH=$KOBO_TOOLCHAIN/bin:$PATH

# Cross-Compiler Präfix
export CROSS_COMPILE=arm-kobo-linux-gnueabihf-

# Qt für Kobo
export QT_KOBO=~/qt-kobo
export PATH=$QT_KOBO/bin:$PATH

# Sysroot
export SYSROOT=$KOBO_TOOLCHAIN/arm-kobo-linux-gnueabihf/sysroot
```

## 3. KoboFrotz kompilieren

```bash
# In das KoboFrotz-Verzeichnis wechseln
cd KoboFrotz

# Build-Skript verwenden (empfohlen)
./build-kobo.sh

# Oder manuell:
mkdir -p build-kobo
cd build-kobo
$QT_KOBO/bin/qmake ../QtFrotz.pro
make -j$(nproc)
```

## 4. Deployment auf den Kobo

### Verzeichnisstruktur auf dem Kobo erstellen

```bash
# USB-Verbindung herstellen und Kobo mounten
# Dann folgende Verzeichnisse erstellen:

/mnt/onboard/.adds/
├── qtfrotz/
│   ├── QtFrotz              # Die kompilierte Anwendung
│   ├── libs/                # Benötigte Qt-Bibliotheken
│   │   ├── libQt5Core.so.5
│   │   ├── libQt5Gui.so.5
│   │   ├── libQt5Widgets.so.5
│   │   └── ...
│   ├── plugins/             # Qt-Plugins
│   │   └── platforms/
│   │       └── libkobo.so
│   ├── games/               # Z-Machine Spiele (.z3, .z5, .z8, etc.)
│   └── saves/               # Spielstände
├── nm/
│   └── config               # NickelMenu Konfiguration
└── qt-linux-*/              # Qt-Bibliotheken (von deploy_qt.sh)
```

### Dateien kopieren

```bash
# Deployment-Skript verwenden
./deploy-kobo.sh /media/$USER/KOBOeReader

# Oder manuell kopieren:
cp build-kobo/QtFrotz /Volumes/KOBOeReader/.adds/qtfrotz/
```

## 5. NickelMenu konfigurieren

### NickelMenu installieren (falls noch nicht vorhanden)

1. NickelMenu von https://pgaskin.net/NickelMenu/ herunterladen
2. Die `KoboRoot.tgz` Datei in das `.kobo` Verzeichnis auf dem Kobo kopieren
3. Kobo sicher auswerfen und neu starten

### NickelMenu-Eintrag erstellen

Erstelle die Datei `.adds/nm/config` auf dem Kobo:

```
menu_item :main :QtFrotz (Z-Machine) :cmd_spawn :quiet:/mnt/onboard/.adds/qtfrotz/run.sh
  chain_success :nickel_misc :rescan_books_full
```

## 6. Start-Skript erstellen

Erstelle `/mnt/onboard/.adds/qtfrotz/run.sh`:

```bash
#!/bin/sh

# Qt-Umgebung setzen
export LD_LIBRARY_PATH=/mnt/onboard/.adds/qt-linux-5.15-kobo/lib:$LD_LIBRARY_PATH
export QT_QPA_PLATFORM=kobo

# E-Ink Display-Einstellungen
export QT_QPA_EVDEV_TOUCHSCREEN_PARAMETERS="rotate=0"
export QT_QPA_GENERIC_PLUGINS="evdevtouch:/dev/input/event1"

# Arbeitsverzeichnis setzen
cd /mnt/onboard/.adds/qtfrotz

# Anwendung starten
./QtFrotz
```

Mache das Skript ausführbar:
```bash
chmod +x /mnt/onboard/.adds/qtfrotz/run.sh
```

## Kobo Libra Colour spezifische Hinweise

### Bildschirmauflösung
- 1264 x 1680 Pixel (Portrait)
- 1680 x 1264 Pixel (Landscape)
- Das Farbdisplay unterstützt 4096 Farben (E-Ink Kaleido)

### E-Ink Optimierungen
- Verwende hohen Kontrast (Schwarz/Weiß) für beste Lesbarkeit
- Minimiere Bildschirmaktualisierungen für längere Akkulaufzeit
- Die Anwendung nutzt bereits `/etc/eink.qss` für E-Ink-optimierte Styles

### Touch-Input
Der Libra Colour verwendet einen kapazitiven Touchscreen. Das qt5-kobo-platform-plugin 
unterstützt diesen automatisch.

## Fehlerbehebung

### Anwendung startet nicht
1. Prüfe, ob alle Bibliotheken vorhanden sind:
   ```bash
   ldd /mnt/onboard/.adds/qtfrotz/QtFrotz
   ```
2. Stelle sicher, dass das run.sh Skript ausführbar ist
3. Überprüfe die NickelMenu-Konfiguration

### Bibliotheken fehlen
Verwende das `deploy_qt.sh` Skript aus kobo-qt-setup-scripts, um alle
benötigten Bibliotheken zu installieren.

### Touch funktioniert nicht
Passe die `QT_QPA_EVDEV_TOUCHSCREEN_PARAMETERS` im run.sh an.
Für den Libra Colour könnte eine Rotation erforderlich sein.

## Weiterführende Links

- [kobo-qt-setup-scripts](https://github.com/Rain92/kobo-qt-setup-scripts)
- [qt5-kobo-platform-plugin](https://github.com/Rain92/qt5-kobo-platform-plugin)
- [NickelMenu](https://pgaskin.net/NickelMenu/)
- [kobo-qt-dev-docker](https://github.com/Rain92/kobo-qt-dev-docker)
- [Kobo Firmware Downloads](https://pgaskin.net/KoboStuff/kobofirmware.html)
