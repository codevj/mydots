#!/bin/bash

set -e

SCRIPT_DIR="$(dirname "$(realpath "$0")")"

# Colors for output
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

# Check if running as root
check_not_root() {
    if [ "$EUID" -eq 0 ]; then
        log_error "Please do not run this script as root. It will ask for sudo when needed."
        exit 1
    fi
}

# Install logiops from source
install_logiops() {
    log_info "Installing logiops..."

    # Check if already installed
    if command -v logid &> /dev/null; then
        log_warn "logid is already installed. Skipping build."
    else
        # Install dependencies
        log_info "Installing build dependencies..."
        sudo apt update
        sudo apt install -y cmake libevdev-dev libudev-dev libconfig++-dev libglib2.0-dev git build-essential

        # Clone and build
        TEMP_DIR=$(mktemp -d)
        log_info "Cloning logiops to $TEMP_DIR..."
        git clone https://github.com/PixlOne/logiops.git "$TEMP_DIR/logiops"
        cd "$TEMP_DIR/logiops"
        mkdir build && cd build
        cmake ..
        make -j$(nproc)
        sudo make install
        cd "$SCRIPT_DIR"
        rm -rf "$TEMP_DIR"
    fi

    # Copy config
    if [ -f "$SCRIPT_DIR/logid.cfg" ]; then
        log_info "Copying logid.cfg to /etc/..."
        sudo cp "$SCRIPT_DIR/logid.cfg" /etc/logid.cfg
    fi

    # Enable and start service
    log_info "Enabling and starting logid service..."
    sudo systemctl daemon-reload
    sudo systemctl enable logid
    sudo systemctl restart logid

    log_info "logiops installation complete!"
    systemctl status logid --no-pager || true
}

# Install Kando
install_kando() {
    log_info "Installing Kando..."

    # Create Applications directory
    mkdir -p ~/Applications

    # Check if already installed
    if [ -f ~/Applications/Kando.AppImage ]; then
        log_warn "Kando AppImage already exists. Removing old version..."
        rm ~/Applications/Kando.AppImage
    fi

    # Download latest AppImage
    log_info "Downloading Kando AppImage..."
    KANDO_URL=$(curl -s https://api.github.com/repos/kando-menu/kando/releases/latest | grep "browser_download_url.*x86_64.AppImage" | cut -d '"' -f 4)
    
    if [ -z "$KANDO_URL" ]; then
        log_error "Could not find Kando AppImage download URL. Please install manually."
        return 1
    fi

    wget -O ~/Applications/Kando.AppImage "$KANDO_URL"
    chmod +x ~/Applications/Kando.AppImage

    # Create autostart entry
    log_info "Creating autostart entry..."
    mkdir -p ~/.config/autostart
    cat > ~/.config/autostart/kando.desktop << EOF
[Desktop Entry]
Type=Application
Name=Kando
Exec=$HOME/Applications/Kando.AppImage
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Comment=Pie menu launcher
EOF

    # Create desktop entry for app launcher
    mkdir -p ~/.local/share/applications
    cat > ~/.local/share/applications/kando.desktop << EOF
[Desktop Entry]
Type=Application
Name=Kando
Exec=$HOME/Applications/Kando.AppImage
Icon=kando
Hidden=false
NoDisplay=false
Terminal=false
Categories=Utility;
Comment=Pie menu launcher
EOF

    log_info "Kando installation complete!"
    log_info "You can start Kando from your application menu or by running: ~/Applications/Kando.AppImage"
}

# Install Tactile GNOME extension
install_tactile() {
    log_info "Installing Tactile GNOME extension..."

    # Check if GNOME is running
    if ! command -v gnome-shell &> /dev/null; then
        log_error "GNOME Shell not found. Tactile requires GNOME."
        return 1
    fi

    # Try gnome-extensions-cli first
    if command -v gext &> /dev/null; then
        log_info "Using gnome-extensions-cli..."
        gext install tactile@lundal.io
        gext enable tactile@lundal.io
    elif command -v gnome-extensions &> /dev/null; then
        # Manual installation
        log_info "Installing Tactile manually..."
        
        EXTENSION_UUID="tactile@lundal.io"
        EXTENSIONS_DIR="$HOME/.local/share/gnome-shell/extensions"
        
        # Get GNOME Shell version
        GNOME_VERSION=$(gnome-shell --version | grep -oP '\d+' | head -1)
        log_info "Detected GNOME Shell version: $GNOME_VERSION"

        # Download extension from GNOME Extensions website
        TEMP_DIR=$(mktemp -d)
        log_info "Downloading Tactile extension..."
        
        # Get extension info to find download URL
        EXTENSION_INFO=$(curl -s "https://extensions.gnome.org/extension-info/?uuid=${EXTENSION_UUID}&shell_version=${GNOME_VERSION}")
        DOWNLOAD_URL=$(echo "$EXTENSION_INFO" | grep -oP '"download_url"\s*:\s*"\K[^"]+' | head -1)
        
        if [ -z "$DOWNLOAD_URL" ]; then
            log_warn "Could not find compatible version. Trying to install via Extension Manager..."
            if ! command -v gnome-extensions-app &> /dev/null; then
                log_info "Installing Extension Manager..."
                sudo apt install -y gnome-shell-extension-manager
            fi
            log_info "Please open Extension Manager and search for 'Tactile' to install."
            rm -rf "$TEMP_DIR"
            return 0
        fi

        wget -O "$TEMP_DIR/tactile.zip" "https://extensions.gnome.org${DOWNLOAD_URL}"
        
        # Install extension
        mkdir -p "$EXTENSIONS_DIR/$EXTENSION_UUID"
        unzip -o "$TEMP_DIR/tactile.zip" -d "$EXTENSIONS_DIR/$EXTENSION_UUID"
        rm -rf "$TEMP_DIR"
        
        # Enable extension
        gnome-extensions enable "$EXTENSION_UUID" || log_warn "Could not enable extension. You may need to log out and back in."
    else
        log_warn "Neither gext nor gnome-extensions found."
        log_info "Installing Extension Manager..."
        sudo apt install -y gnome-shell-extension-manager
        log_info "Please open Extension Manager and search for 'Tactile' to install."
    fi

    log_info "Tactile installation complete!"
    log_info "You may need to log out and back in for the extension to appear."
}

# Print usage
usage() {
    echo "Usage: $0 [component]"
    echo ""
    echo "Components:"
    echo "  logiops    Install logiops (logid) for Logitech device configuration"
    echo "  kando      Install Kando pie menu launcher"
    echo "  tactile    Install Tactile GNOME window tiling extension"
    echo ""
    echo "If no component is specified, all components will be installed."
}

# Main
main() {
    check_not_root

    if [ $# -eq 0 ]; then
        log_info "Installing all components..."
        install_logiops
        echo ""
        install_kando
        echo ""
        install_tactile
        echo ""
        log_info "All installations complete!"
    else
        case "$1" in
            logiops|logid)
                install_logiops
                ;;
            kando)
                install_kando
                ;;
            tactile)
                install_tactile
                ;;
            -h|--help)
                usage
                ;;
            *)
                log_error "Unknown component: $1"
                usage
                exit 1
                ;;
        esac
    fi
}

main "$@"
