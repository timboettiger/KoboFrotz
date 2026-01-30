#!/bin/bash
#
# KoboFrotz Cross-Compilation Build Script
# Für Kobo Libra Colour (und andere ARM-basierte Kobo E-Reader)
#

set -e

# Konfiguration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build-kobo"
OUTPUT_DIR="$SCRIPT_DIR/dist"

# Standard-Pfade (können überschrieben werden)
KOBO_TOOLCHAIN="${KOBO_TOOLCHAIN:-$HOME/x-tools/arm-kobo-linux-gnueabihf}"
QT_KOBO="${QT_KOBO:-$HOME/qt-kobo}"

# Farben für Output
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
    log_info "Prüfe Toolchain..."
    
    if [ ! -d "$KOBO_TOOLCHAIN" ]; then
        log_error "Kobo Toolchain nicht gefunden: $KOBO_TOOLCHAIN"
        log_info "Bitte installiere die Toolchain mit kobo-qt-setup-scripts:"
        log_info "  git clone https://github.com/Rain92/kobo-qt-setup-scripts.git"
        log_info "  cd kobo-qt-setup-scripts && ./install_toolchain.sh"
        exit 1
    fi

    if [ ! -f "$KOBO_TOOLCHAIN/bin/arm-kobo-linux-gnueabihf-gcc" ]; then
        log_error "Cross-Compiler nicht gefunden in $KOBO_TOOLCHAIN/bin/"
        exit 1
    fi

    log_info "Toolchain gefunden: $KOBO_TOOLCHAIN"
}

check_qt() {
    log_info "Prüfe Qt für Kobo..."
    
    if [ ! -d "$QT_KOBO" ]; then
        log_error "Qt für Kobo nicht gefunden: $QT_KOBO"
        log_info "Bitte baue Qt mit kobo-qt-setup-scripts:"
        log_info "  ./get_qt.sh && ./build_qt.sh"
        exit 1
    fi

    if [ ! -f "$QT_KOBO/bin/qmake" ]; then
        log_error "qmake nicht gefunden in $QT_KOBO/bin/"
        exit 1
    fi

    log_info "Qt für Kobo gefunden: $QT_KOBO"
}

setup_environment() {
    log_info "Setze Umgebungsvariablen..."
    
    export PATH="$KOBO_TOOLCHAIN/bin:$QT_KOBO/bin:$PATH"
    export CROSS_COMPILE=arm-kobo-linux-gnueabihf-
    export SYSROOT="$KOBO_TOOLCHAIN/arm-kobo-linux-gnueabihf/sysroot"
    
    log_info "PATH aktualisiert"
    log_info "CROSS_COMPILE=$CROSS_COMPILE"
    log_info "SYSROOT=$SYSROOT"
}

clean_build() {
    log_info "Bereinige Build-Verzeichnis..."
    
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
    fi
    
    mkdir -p "$BUILD_DIR"
}

build_qtfrotz() {
    log_info "Starte Build von QtFrotz..."
    
    cd "$BUILD_DIR"
    
    log_info "Führe qmake aus..."
    "$QT_KOBO/bin/qmake" "$SCRIPT_DIR/QtFrotz.pro" \
        CONFIG+=release \
        QMAKE_CXXFLAGS+="-O2" \
        QMAKE_LFLAGS+="-Wl,-rpath,/mnt/onboard/.adds/qt-linux-5.15-kobo/lib"
    
    log_info "Kompiliere..."
    make -j$(nproc)
    
    if [ -f "$BUILD_DIR/QtFrotz" ]; then
        log_info "Build erfolgreich: $BUILD_DIR/QtFrotz"
    else
        log_error "Build fehlgeschlagen - QtFrotz Binary nicht gefunden"
        exit 1
    fi
}

create_dist() {
    log_info "Erstelle Distribution..."
    
    mkdir -p "$OUTPUT_DIR/qtfrotz"
    mkdir -p "$OUTPUT_DIR/qtfrotz/games"
    mkdir -p "$OUTPUT_DIR/qtfrotz/saves"
    mkdir -p "$OUTPUT_DIR/nm"
    
    # Binary kopieren
    cp "$BUILD_DIR/QtFrotz" "$OUTPUT_DIR/qtfrotz/"
    
    # Start-Skript erstellen
    cat > "$OUTPUT_DIR/qtfrotz/run.sh" << 'EOF'
#!/bin/sh
#
# QtFrotz Start-Skript für Kobo
#

# Qt-Umgebung
export LD_LIBRARY_PATH=/mnt/onboard/.adds/qt-linux-5.15-kobo/lib:$LD_LIBRARY_PATH
export QT_QPA_PLATFORM=kobo

# E Ink Display-Einstellungen für Kobo Libra Colour
export QT_QPA_EVDEV_TOUCHSCREEN_PARAMETERS="rotate=0"
export QT_QPA_GENERIC_PLUGINS="evdevtouch:/dev/input/event1"

# Arbeitsverzeichnis
cd /mnt/onboard/.adds/qtfrotz

# Starte QtFrotz
./QtFrotz "$@"
EOF
    
    chmod +x "$OUTPUT_DIR/qtfrotz/run.sh"
    
    # NickelMenu Konfiguration
    cat > "$OUTPUT_DIR/nm/qtfrotz" << 'EOF'
menu_item :main :QtFrotz (Z-Machine) :cmd_spawn :quiet:/mnt/onboard/.adds/qtfrotz/run.sh
  chain_success :nickel_misc :rescan_books_full
EOF
    
    log_info "Distribution erstellt in: $OUTPUT_DIR"
    log_info ""
    log_info "Inhalt:"
    ls -la "$OUTPUT_DIR/qtfrotz/"
}

print_instructions() {
    log_info ""
    log_info "=========================================="
    log_info "Installation auf dem Kobo:"
    log_info "=========================================="
    log_info ""
    log_info "1. Verbinde den Kobo per USB"
    log_info ""
    log_info "2. Kopiere die Dateien:"
    log_info "   cp -r $OUTPUT_DIR/qtfrotz /media/\$USER/KOBOeReader/.adds/"
    log_info "   cp $OUTPUT_DIR/nm/qtfrotz /media/\$USER/KOBOeReader/.adds/nm/"
    log_info ""
    log_info "3. Stelle sicher, dass Qt-Bibliotheken installiert sind"
    log_info "   (verwende deploy_qt.sh aus kobo-qt-setup-scripts)"
    log_info ""
    log_info "4. Werfe den Kobo sicher aus und starte neu"
    log_info ""
    log_info "5. Starte QtFrotz über das NickelMenu"
    log_info ""
}

# Hauptprogramm
main() {
    log_info "=========================================="
    log_info "KoboFrotz Cross-Compilation Build"
    log_info "=========================================="
    log_info ""
    
    case "${1:-}" in
        --clean)
            clean_build
            log_info "Build-Verzeichnis bereinigt"
            exit 0
            ;;
        --help|-h)
            echo "Verwendung: $0 [--clean|--help]"
            echo ""
            echo "Optionen:"
            echo "  --clean    Bereinigt das Build-Verzeichnis"
            echo "  --help     Zeigt diese Hilfe an"
            echo ""
            echo "Umgebungsvariablen:"
            echo "  KOBO_TOOLCHAIN  Pfad zur Kobo Toolchain (Standard: ~/x-tools/arm-kobo-linux-gnueabihf)"
            echo "  QT_KOBO         Pfad zu Qt für Kobo (Standard: ~/qt-kobo)"
            exit 0
            ;;
    esac
    
    check_toolchain
    check_qt
    setup_environment
    clean_build
    build_qtfrotz
    create_dist
    print_instructions
    
    log_info "Build abgeschlossen!"
}

main "$@"
