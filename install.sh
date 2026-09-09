#!/usr/bin/env bash
# ==============================================================================
# Tasnet Connect — Universal Linux Installer
#
# Supported distros:
#   - Debian, Ubuntu, Linux Mint, Pop!_OS, Astra Linux, Kali (.deb)
#   - Fedora, RHEL, CentOS, Rocky Linux, AlmaLinux, openSUSE (.rpm)
#   - Arch Linux, Manjaro, Alpine, and others (Portable AppImage)
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/tasnet20/connect-releases/main/install.sh | bash
#   or:
#   curl -fsSL https://github.com/tasnet20/connect-releases/releases/latest/download/install.sh | bash
# ==============================================================================

set -eo pipefail

# ANSI color codes
BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

BANNER="${CYAN}${BOLD}
  _____                      _      _____                            _   
 |_   _|                    | |    / ____|                          | |  
   | | __ _ ___ _ __   ___| |_  | |     ___  _ __  _ __   ___  ___| |_ 
   | |/ _\` / __| '_ \ / _ \ __| | |    / _ \| '_ \| '_ \ / _ \/ __| __|
   | | (_| \__ \ | | |  __/ |_  | |___| (_) | | | | | | |  __/ (__| |_ 
   \_/\__,_|___/_| |_|\___|\__|  \_____\___/|_| |_|_| |_|\___|\___|\__|
${NC}"

echo -e "$BANNER"
echo -e "${BOLD}Tasnet Connect — Universal Linux Installer${NC}\n"

# 1. Check architecture
ARCH="$(uname -m)"
if [ "$ARCH" != "x86_64" ] && [ "$ARCH" != "amd64" ]; then
  echo -e "${YELLOW}[!] Warning: Detected architecture is ${ARCH}.${NC}"
  echo -e "    Tasnet Connect builds are optimized for 64-bit systems (x86_64).\n"
fi

# 2. Determine root / sudo elevation
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  else
    echo -e "${RED}[✗] Error: Superuser privileges (root or sudo) are required for installation.${NC}"
    exit 1
  fi
fi

# 3. Choose download utility (curl or wget)
fetch() {
  local url="$1"
  local dest="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fL --progress-bar -o "$dest" "$url"
  elif command -v wget >/dev/null 2>&1; then
    wget -q --show-progress -O "$dest" "$url"
  else
    echo -e "${RED}[✗] Error: Neither curl nor wget was found. Please install curl or wget.${NC}"
    exit 1
  fi
}

TMP_DIR="$(mktemp -d /tmp/tasnet-installer.XXXXXX)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

RELEASE_BASE="https://github.com/tasnet20/connect-releases/releases/latest/download"

# 4. Detect package manager and install
if command -v apt-get >/dev/null 2>&1; then
  # ---------------- Debian / Ubuntu family ----------------
  echo -e "${CYAN}[i] Detected Debian / Ubuntu based system (apt)${NC}"
  DEB_FILE="$TMP_DIR/Tasnet.Connect.deb"

  echo -e "${GRAY}--> Downloading latest DEB package...${NC}"
  fetch "$RELEASE_BASE/Tasnet.Connect.deb" "$DEB_FILE"

  echo -e "${GRAY}--> Installing tasnet-connect package...${NC}"
  if $SUDO apt-get install -y "$DEB_FILE"; then
    echo -e "${GREEN}[✓] Tasnet Connect successfully installed via apt!${NC}"
  else
    echo -e "${YELLOW}[!] Direct apt installation requested dependency resolution, running dpkg + fix...${NC}"
    $SUDO dpkg -i "$DEB_FILE" || true
    $SUDO apt-get install -f -y
    echo -e "${GREEN}[✓] Tasnet Connect successfully installed!${NC}"
  fi

elif command -v dnf >/dev/null 2>&1; then
  # ---------------- Fedora / RHEL / Alma / Rocky ----------------
  echo -e "${CYAN}[i] Detected Fedora / RHEL based system (dnf)${NC}"
  RPM_FILE="$TMP_DIR/Tasnet.Connect.rpm"

  echo -e "${GRAY}--> Downloading latest RPM package...${NC}"
  fetch "$RELEASE_BASE/Tasnet.Connect.rpm" "$RPM_FILE"

  echo -e "${GRAY}--> Installing tasnet-connect package...${NC}"
  $SUDO dnf install -y "$RPM_FILE"
  echo -e "${GREEN}[✓] Tasnet Connect successfully installed via dnf!${NC}"

elif command -v zypper >/dev/null 2>&1; then
  # ---------------- openSUSE ----------------
  echo -e "${CYAN}[i] Detected openSUSE system (zypper)${NC}"
  RPM_FILE="$TMP_DIR/Tasnet.Connect.rpm"

  echo -e "${GRAY}--> Downloading latest RPM package...${NC}"
  fetch "$RELEASE_BASE/Tasnet.Connect.rpm" "$RPM_FILE"

  echo -e "${GRAY}--> Installing tasnet-connect package...${NC}"
  $SUDO zypper --non-interactive install "$RPM_FILE"
  echo -e "${GREEN}[✓] Tasnet Connect successfully installed via zypper!${NC}"

elif command -v yum >/dev/null 2>&1; then
  # ---------------- Older RHEL / CentOS ----------------
  echo -e "${CYAN}[i] Detected RHEL / CentOS based system (yum)${NC}"
  RPM_FILE="$TMP_DIR/Tasnet.Connect.rpm"

  echo -e "${GRAY}--> Downloading latest RPM package...${NC}"
  fetch "$RELEASE_BASE/Tasnet.Connect.rpm" "$RPM_FILE"

  echo -e "${GRAY}--> Installing tasnet-connect package...${NC}"
  $SUDO yum localinstall -y "$RPM_FILE"
  echo -e "${GREEN}[✓] Tasnet Connect successfully installed via yum!${NC}"

else
  # ---------------- Fallback: Portable AppImage (Arch, Manjaro, Alpine, etc.) ----------------
  echo -e "${CYAN}[i] Standard package manager not detected. Installing portable AppImage...${NC}"
  TARGET_BIN="/usr/local/bin/tasnet-connect"
  DESKTOP_DIR="/usr/share/applications"
  ICON_DIR="/usr/share/icons/hicolor/512x512/apps"

  APPIMAGE_TMP="$TMP_DIR/Tasnet.Connect.AppImage"
  echo -e "${GRAY}--> Downloading universal AppImage...${NC}"
  fetch "$RELEASE_BASE/Tasnet.Connect.AppImage" "$APPIMAGE_TMP"

  echo -e "${GRAY}--> Installing to $TARGET_BIN...${NC}"
  $SUDO cp -f "$APPIMAGE_TMP" "$TARGET_BIN"
  $SUDO chmod +x "$TARGET_BIN"

  # Integration into application menu
  if [ -d "$DESKTOP_DIR" ]; then
    echo -e "${GRAY}--> Creating desktop shortcut and application menu entry...${NC}"
    $SUDO mkdir -p "$ICON_DIR"
    
    $SUDO bash -c "cat > $DESKTOP_DIR/tasnet-connect.desktop" <<'EOF'
[Desktop Entry]
Name=Tasnet Connect
Comment=Automated MikroTik RouterOS HotSpot Configurator
Exec=/usr/local/bin/tasnet-connect %U
Icon=tasnet-connect
Terminal=false
Type=Application
Categories=Network;Utility;Settings;
StartupWMClass=tasnet-connect
EOF
    $SUDO chmod 644 "$DESKTOP_DIR/tasnet-connect.desktop"
    if command -v update-desktop-database >/dev/null 2>&1; then
      $SUDO update-desktop-database "$DESKTOP_DIR" || true
    fi
  fi

  echo -e "${GREEN}[✓] Tasnet Connect successfully installed to $TARGET_BIN!${NC}"
fi

# 5. Finished
echo ""
echo -e "${GREEN}${BOLD}Done! Tasnet Connect has been successfully installed.${NC}"
echo -e "You can launch it:"
echo -e "  1. From your applications menu (Network / Utilities)."
echo -e "  2. Or by running in terminal: ${CYAN}tasnet-connect${NC}\n"
