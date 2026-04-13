# Linux Setup

This folder contains configuration and installation scripts for Linux desktop tools.

## Tools Overview

| Tool | Description |
|------|-------------|
| **logiops** | Daemon for configuring Logitech mice and keyboards (provides `logid`) |
| **Kando** | Cross-platform pie menu launcher |
| **Tactile** | GNOME extension for window tiling |

---

## Installation

### Quick Install (All Tools)

```bash
./install.sh
```

Or install individual components:

```bash
./install.sh logiops
./install.sh kando
./install.sh tactile
```

---

## Manual Installation

### logiops (logid)

logiops is an unofficial driver for Logitech mice and keyboards.

**Install from source (Ubuntu/Debian):**

```bash
# Install dependencies
sudo apt install cmake libevdev-dev libudev-dev libconfig++-dev libglib2.0-dev

# Clone and build
git clone https://github.com/PixlOne/logiops.git
cd logiops
mkdir build && cd build
cmake ..
make
sudo make install

# Enable and start the service
sudo systemctl enable logid
sudo systemctl start logid
```

**Configuration:**

Copy the config file to `/etc/logid.cfg`:

```bash
sudo cp logid.cfg /etc/logid.cfg
sudo systemctl restart logid
```

Or use the helper script:

```bash
./save-restart.sh
```

---

### Kando

Kando is a pie menu launcher. Download from the [releases page](https://github.com/kando-menu/kando/releases).

**Install via AppImage:**

```bash
# Download latest AppImage
wget -O ~/Applications/Kando.AppImage "https://github.com/kando-menu/kando/releases/latest/download/Kando-x86_64.AppImage"
chmod +x ~/Applications/Kando.AppImage

# Optional: Add to autostart
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/kando.desktop << EOF
[Desktop Entry]
Type=Application
Name=Kando
Exec=$HOME/Applications/Kando.AppImage
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
```

**Install via .deb (Debian/Ubuntu):**

```bash
# Download and install the .deb package
wget -O /tmp/kando.deb "https://github.com/kando-menu/kando/releases/latest/download/Kando_amd64.deb"
sudo apt install /tmp/kando.deb
```

---

### Tactile (GNOME Extension)

Tactile is a GNOME Shell extension for tiling windows.

**Install via Extension Manager (Recommended):**

1. Install Extension Manager:
   ```bash
   sudo apt install gnome-shell-extension-manager
   ```

2. Open Extension Manager and search for "Tactile"

3. Click Install

**Install via extensions.gnome.org:**

1. Visit [Tactile on GNOME Extensions](https://extensions.gnome.org/extension/4548/tactile/)
2. Toggle the switch to install

**Install via command line:**

```bash
# Install gnome-extensions-cli
pipx install gnome-extensions-cli

# Install Tactile
gext install tactile@lundal.io
```

---

## Files

| File | Description |
|------|-------------|
| `logid.cfg` | logiops configuration for Logitech mice |
| `save-restart.sh` | Deploy logid.cfg and restart the service |
| `install.sh` | Install all tools (logiops, Kando, Tactile) |

---

## Troubleshooting

### logid not detecting device

```bash
# Check if the service is running
systemctl status logid

# View logs
journalctl -u logid -f

# List connected devices
sudo logid -v
```

### Kando not responding to hotkey

- Make sure no other application is using the same hotkey
- On Wayland, Kando may need additional permissions

### Tactile not appearing

```bash
# Restart GNOME Shell (X11 only)
# Press Alt+F2, type 'r', press Enter

# Or log out and log back in
```
