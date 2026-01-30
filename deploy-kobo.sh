#!/bin/bash
#
# KoboFrotz Deployment Script
# Kopiert QtFrotz und alle benötigten Dateien auf den Kobo
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="$SCRIPT_DIR/dist"
BUILD_DIR="$SCRIPT_DIR/build-kobo"

# Farben für Output
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
    echo "Verwendung: $0 <kobo-mount-point>"
    echo ""
    echo "Beispiele:"
    echo "  $0 /media/\$USER/KOBOeReader"
    echo "  $0 /Volumes/KOBOeReader"
    echo ""
    echo "Optional kann QT_DEPLOY_DIR gesetzt werden, um Qt-Bibliotheken zu installieren:"
    echo "  QT_DEPLOY_DIR=~/qt-kobo-deploy $0 /media/\$USER/KOBOeReader"
    exit 1
}

check_kobo_mount() {
    if [ ! -d "$KOBO_MOUNT" ]; then
        log_error "Kobo Mount-Point nicht gefunden: $KOBO_MOUNT"
        exit 1
    fi

    # Prüfe ob es wirklich ein Kobo ist
    if [ ! -d "$KOBO_MOUNT/.kobo" ]; then
        log_warn "Kein .kobo Verzeichnis gefunden - ist das wirklich ein Kobo?"
        read -p "Fortfahren? (j/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Jj]$ ]]; then
            exit 1
        fi
    fi

    log_info "Kobo gefunden: $KOBO_MOUNT"
}

check_build() {
    if [ ! -f "$DIST_DIR/qtfrotz/QtFrotz" ] && [ ! -f "$BUILD_DIR/QtFrotz" ]; then
        log_error "QtFrotz Binary nicht gefunden."
        log_info "Bitte erst bauen mit: ./build-kobo.sh"
        exit 1
    fi
    
    if [ -f "$DIST_DIR/qtfrotz/QtFrotz" ]; then
        BINARY_SOURCE="$DIST_DIR/qtfrotz/QtFrotz"
    else
        BINARY_SOURCE="$BUILD_DIR/QtFrotz"
    fi
    
    log_info "Binary gefunden: $BINARY_SOURCE"
}

create_directories() {
    log_info "Erstelle Verzeichnisse..."
    
    mkdir -p "$KOBO_MOUNT/.adds/qtfrotz"
    mkdir -p "$KOBO_MOUNT/.adds/qtfrotz/games"
    mkdir -p "$KOBO_MOUNT/.adds/qtfrotz/saves"
    mkdir -p "$KOBO_MOUNT/.adds/nm"
    
    log_info "Verzeichnisse erstellt"
}

deploy_binary() {
    log_info "Kopiere QtFrotz Binary..."
    
    cp "$BINARY_SOURCE" "$KOBO_MOUNT/.adds/qtfrotz/"
    chmod +x "$KOBO_MOUNT/.adds/qtfrotz/QtFrotz"
    
    log_info "Binary kopiert"
}

deploy_run_script() {
    log_info "Erstelle Start-Skript..."
    
    cat > "$KOBO_MOUNT/.adds/qtfrotz/run.sh" << 'EOF'
#!/bin/sh
#
# QtFrotz Start-Skript für Kobo Libra Colour
#

# Logging aktivieren (optional)
exec > /mnt/onboard/.adds/qtfrotz/qtfrotz.log 2>&1
echo "=== QtFrotz Start: $(date) ==="

# Qt-Umgebung
export LD_LIBRARY_PATH=/mnt/onboard/.adds/qt-linux-5.15-kobo/lib:$LD_LIBRARY_PATH
export QT_QPA_PLATFORM=kobo

# E-Ink Display-Einstellungen für Kobo Libra Colour (N428)
# Bildschirmauflösung: 1264 x 1680 (Portrait)
export QT_QPA_EVDEV_TOUCHSCREEN_PARAMETERS="rotate=0"
export QT_QPA_GENERIC_PLUGINS="evdevtouch:/dev/input/event1"

# Frontlight deaktivieren (optional, spart Strom)
# export KOBO_FRONTLIGHT=0

# Arbeitsverzeichnis
cd /mnt/onboard/.adds/qtfrotz

echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
echo "Starting QtFrotz..."

# Starte QtFrotz
./QtFrotz "$@"

EXIT_CODE=$?
echo "=== QtFrotz Ende: $(date), Exit Code: $EXIT_CODE ==="
exit $EXIT_CODE
EOF
    
    chmod +x "$KOBO_MOUNT/.adds/qtfrotz/run.sh"
    
    log_info "Start-Skript erstellt"
}

deploy_nickelmenu_config() {
    log_info "Erstelle NickelMenu-Konfiguration..."
    
    # Prüfe ob NickelMenu installiert ist
    if [ ! -d "$KOBO_MOUNT/.adds/nm" ]; then
        log_warn "NickelMenu scheint nicht installiert zu sein."
        log_info "Bitte installiere NickelMenu von https://pgaskin.net/NickelMenu/"
    fi
    
    cat > "$KOBO_MOUNT/.adds/nm/qtfrotz" << 'EOF'
# QtFrotz - Z-Machine Interpreter
# Menüeintrag im Hauptmenü

menu_item :main :QtFrotz (Z-Machine) :cmd_spawn :quiet:/mnt/onboard/.adds/qtfrotz/run.sh
  chain_success :nickel_misc :rescan_books_full

# Optional: Eigenes Untermenü für verschiedene Spiele
# menu_item :main :Interactive Fiction :nickel_open :library

EOF
    
    log_info "NickelMenu-Konfiguration erstellt"
}

deploy_qt_libs() {
    if [ -n "${QT_DEPLOY_DIR:-}" ] && [ -d "$QT_DEPLOY_DIR" ]; then
        log_info "Kopiere Qt-Bibliotheken..."
        
        # Zielverzeichnis
        QT_TARGET="$KOBO_MOUNT/.adds/qt-linux-5.15-kobo"
        
        mkdir -p "$QT_TARGET"
        cp -r "$QT_DEPLOY_DIR"/* "$QT_TARGET/"
        
        log_info "Qt-Bibliotheken kopiert nach $QT_TARGET"
    else
        log_warn "QT_DEPLOY_DIR nicht gesetzt oder nicht gefunden."
        log_info "Qt-Bibliotheken müssen separat installiert werden."
        log_info "Verwende deploy_qt.sh aus kobo-qt-setup-scripts"
    fi
}

create_readme() {
    log_info "Erstelle README..."
    
    cat > "$KOBO_MOUNT/.adds/qtfrotz/README.txt" << 'EOF'
QtFrotz - Z-Machine Interpreter für Kobo
========================================

QtFrotz ermöglicht das Spielen von Interactive Fiction (Text Adventures)
auf deinem Kobo E-Reader.

Unterstützte Formate:
- Z-Machine Spiele (.z3, .z5, .z8, .zblorb, .zlb)
- Infocom-Spiele
- Inform-Spiele

Verzeichnisse:
- games/  - Lege hier deine Z-Machine Spiele ab
- saves/  - Spielstände werden hier gespeichert

Bedienung:
- Start über NickelMenu -> QtFrotz
- Touchscreen-Tastatur für Eingaben
- Menü für Speichern/Laden

Wo bekomme ich Spiele?
- IFDB: https://ifdb.org
- IF Archive: https://www.ifarchive.org

Hinweis:
Für beste Lesbarkeit auf dem E-Ink Display wird hoher Kontrast
(Schwarz auf Weiß) empfohlen.
EOF
    
    log_info "README erstellt"
}

print_summary() {
    log_info ""
    log_info "=========================================="
    log_info "Deployment abgeschlossen!"
    log_info "=========================================="
    log_info ""
    log_info "Installierte Dateien:"
    ls -la "$KOBO_MOUNT/.adds/qtfrotz/"
    log_info ""
    log_info "NickelMenu Konfiguration:"
    cat "$KOBO_MOUNT/.adds/nm/qtfrotz"
    log_info ""
    log_info "Nächste Schritte:"
    log_info "1. Kopiere Z-Machine Spiele nach .adds/qtfrotz/games/"
    log_info "2. Werfe den Kobo sicher aus"
    log_info "3. Der Kobo startet automatisch neu"
    log_info "4. Starte QtFrotz über das NickelMenu"
    log_info ""
}

# Hauptprogramm
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
