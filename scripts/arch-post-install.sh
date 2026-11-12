#!/usr/bin/env bash
set -euo pipefail

# Arch Linux desktop restoration.
# Run only on the newly installed Arch Linux system.
# Usage: ./scripts/arch-post-install.sh

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ ! -f /etc/arch-release ]]; then
    echo "ERROR: This script is intended for Arch Linux only."
    exit 1
fi

if [[ "$EUID" -eq 0 ]]; then
    echo "ERROR: Run this script as your normal user, not root."
    exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
    echo "ERROR: sudo is required."
    exit 1
fi

echo "=========================================="
echo " ARCH LINUX DESKTOP RESTORATION"
echo "=========================================="
echo "Repository: $REPO_DIR"
echo "User:       $USER"
echo
read -r -p "Continue with package installation and configuration? [y/N] " answer
[[ "$answer" =~ ^[Yy]$ ]] || exit 0

echo
echo "========== ENABLE MULTILIB =========="

sudo sed -i \
    '/^#\[multilib\]$/,/^#Include = \/etc\/pacman.d\/mirrorlist$/ s/^#//' \
    /etc/pacman.conf

if ! grep -q '^\[multilib\]$' /etc/pacman.conf; then
    echo "ERROR: Could not enable the multilib repository."
    exit 1
fi

echo
echo "========== UPDATE ARCH =========="

sudo pacman -Syu --needed

echo
echo "========== INSTALL OFFICIAL PACKAGES =========="

OFFICIAL_PACKAGES=(
    base-devel
    git
    curl
    wget
    unzip
    zip
    jq
    python
    python-pyqt6
    ffmpeg
    xorg-server-xvfb
    linux
    linux-firmware
    amd-ucode
    nvidia-open
    linux-headers
    nvidia-utils
    lib32-nvidia-utils
    mesa
    vulkan-radeon
    hyprland
    xorg-xwayland
    hyprlock
    hyprlauncher
    polkit
    hyprpolkitagent
    waybar
    quickshell
    kitty
    thunar
    dunst
    rofi
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
    wl-clipboard
    grim
    slurp
    qt6-wayland
    brightnessctl
    playerctl
    xdg-user-dirs
    networkmanager
    wpa_supplicant
    bluez
    bluez-utils
    pipewire-audio
    pipewire-alsa
    pipewire-pulse
    wireplumber
    alsa-utils
    pavucontrol
    firefox
    discord
    steam
    vlc
    audacity
    btop
    fastfetch
    mission-center
    gparted
    flatpak
    btrfs-progs
    dosfstools
    efibootmgr
    sbctl
    limine
)

sudo pacman -S --needed "${OFFICIAL_PACKAGES[@]}"

echo
echo "========== INSTALL YAY =========="

if ! command -v yay >/dev/null 2>&1; then
    BUILD_DIR="$(mktemp -d)"
    trap 'rm -rf "$BUILD_DIR"' EXIT
    git clone https://aur.archlinux.org/yay.git "$BUILD_DIR/yay"
    (
        cd "$BUILD_DIR/yay"
        makepkg -si --needed
    )
    rm -rf "$BUILD_DIR"
    trap - EXIT
fi

echo
echo "========== INSTALL AUR APPLICATIONS =========="

AUR_PACKAGES=(
    limine-mkinitcpio-hook
    brave-bin
    proton-ge-custom-bin
    r2modman-bin
    jamesdsp
    waypaper-engine
    linux-wallpaperengine-git
)

yay -S --needed "${AUR_PACKAGES[@]}"

echo
echo "========== RESTORE REPOSITORY CONFIGURATION =========="

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

install -d "$CONFIG_HOME"

restore_config() {
    local source="$1"
    local destination="$2"

    if [[ ! -e "$destination" ]]; then
        install -d "$(dirname "$destination")"
        cp -a "$source" "$destination"
        echo "Restored: $destination"
    else
        echo "Preserved existing: $destination"
    fi
}

restore_config "$REPO_DIR/config/hypr/hyprland.lua" \
    "$CONFIG_HOME/hypr/hyprland.lua"
restore_config "$REPO_DIR/config/hypr/hyprlauncher.conf" \
    "$CONFIG_HOME/hypr/hyprlauncher.conf"
restore_config "$REPO_DIR/config/hypr/hyprlock.conf" \
    "$CONFIG_HOME/hypr/hyprlock.conf"
restore_config "$REPO_DIR/config/hyprland-dock/dock.json" \
    "$CONFIG_HOME/hyprland-dock/dock.json"
restore_config "$REPO_DIR/config/waybar/config.jsonc" \
    "$CONFIG_HOME/waybar/config.jsonc"
restore_config "$REPO_DIR/config/waybar/style.css" \
    "$CONFIG_HOME/waybar/style.css"
restore_config "$REPO_DIR/config/kitty/kitty.conf" \
    "$CONFIG_HOME/kitty/kitty.conf"
restore_config "$REPO_DIR/config/waypaper-engine/config.toml" \
    "$CONFIG_HOME/waypaper-engine/config.toml"
restore_config "$REPO_DIR/config/dunst/dunstrc" \
    "$CONFIG_HOME/dunst/dunstrc"
restore_config "$REPO_DIR/config/jamesdsp" \
    "$CONFIG_HOME/jamesdsp"

echo
echo "========== INSTALL CUSTOM APPLICATIONS =========="

"$REPO_DIR/apps/hyprland-dock/install.sh" --no-autostart

install -d "$HOME/.local/bin" "$HOME/.local/share/launchpad"

# Restore repository-managed executable scripts.
for script in "$REPO_DIR"/scripts/*; do
    [ -f "$script" ] || continue
    [ "$(basename "$script")" = "arch-post-install.sh" ] && continue
    [ -x "$script" ] || continue
    install -m 0755 "$script" "$HOME/.local/bin/$(basename "$script")"
done
install -m 0755 "$REPO_DIR/apps/launchpad/launchpad-toggle" \
    "$HOME/.local/bin/launchpad-toggle"
cp -a "$REPO_DIR/apps/launchpad/shell.qml" \
    "$HOME/.local/share/launchpad/shell.qml"
cp -a "$REPO_DIR/apps/launchpad/launchpad.svg" \
    "$HOME/.local/share/launchpad/launchpad.svg"

install -d "$HOME/.local/share/volume-osd"
cp -a "$REPO_DIR/apps/volume-osd/shell.qml" \
    "$HOME/.local/share/volume-osd/shell.qml"

echo
echo "========== INSTALL SYSTEM CONFIGURATION =========="

sudo install -Dm644 \
    "$REPO_DIR/systemd/alsa-restore.service.d/no-shutdown-overwrite.conf" \
    /etc/systemd/system/alsa-restore.service.d/no-shutdown-overwrite.conf
sudo systemctl daemon-reload

install -Dm644 \
    "$REPO_DIR/systemd/user/restore-mic-gain.service" \
    "$CONFIG_HOME/systemd/user/restore-mic-gain.service"

echo
echo "========== ENABLE SERVICES =========="

sudo systemctl enable NetworkManager.service
sudo systemctl enable bluetooth.service

systemctl --user daemon-reload
systemctl --user enable restore-mic-gain.service

echo
echo "========== CREATE USER DIRECTORIES =========="

xdg-user-dirs-update

echo
echo "=========================================="
echo " BASE RESTORATION COMPLETE"
echo "=========================================="
echo
echo "Still to configure and verify separately:"
echo "  - Limine installation and Secure Boot signing"
echo "  - NVIDIA DRM/KMS and driver verification"
echo "  - Btrfs NVMe storage pool"
echo "  - Flatpak applications"
echo "  - Wallpaper library restoration"
echo "  - Steam and game-library configuration"
echo
echo "Review output above before rebooting."
