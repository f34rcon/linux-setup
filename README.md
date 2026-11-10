# CachyOS Hyprland Desktop Setup

My personal CachyOS + Hyprland desktop configuration and custom applications.

This repository preserves the configuration, scripts, and source files used by my desktop. It is intended as a backup and restoration reference, not an automatic installer.

## Repository Structure

- `apps/hyprland-dock/` — Quickshell dock source
- `apps/launchpad/` — Claude-created Launchpad application
- `config/hypr/` — Hyprland, Hyprlock, and Hyprpaper
- `config/hyprland-dock/` — Dock settings
- `config/kitty/` — Kitty terminal configuration
- `config/waybar/` — Waybar configuration and styling
- `config/waypaper-engine/` — Wallpaper Engine settings
- `scripts/` — Custom desktop scripts

## Included Components

### Desktop
- Hyprland configuration
- Hyprlock lock screen
- Hyprpaper configuration
- Waybar configuration and CSS
- Kitty terminal configuration

### Custom Applications
- Launchpad — Quickshell-based application launcher
- Hyprland Dock — Quickshell dock, including QML components, installer, and uninstaller

### Scripts
- Background applications menu
- Keyboard shortcuts menu
- Session menu
- App menu toggle
- Rofi click-to-close helper
- Hyprland dock launcher
- Waypaper Engine startup helper
- Wallpaper Engine export utility

## Restoration Notes

These files reflect the original machine and may need adjustments before use elsewhere.

- Some configurations reference `/home/pilot` directly.
- Hyprpaper references `/home/pilot/Pictures/Screenshot_20261108_212013.png`, which is not included.
- Waypaper Engine uses machine-specific database, image, log, thumbnail, and socket paths.
- Wallpaper startup references monitors `DP-2` and `DP-3`; monitor names may differ on another system.
- The desktop uses Hyprland, Quickshell, Waybar, Kitty, Rofi, Hyprlock, Hyprpaper, and Waypaper Engine.
- Launchpad and the dock require Quickshell.
- Xodus Nexus itself is not included; its installed application must be restored separately.

## Backup Policy

Included:
- Active configuration files
- Custom application source files
- Custom scripts
- Dock and Launchpad assets

Excluded:
- Historical configuration backups
- Browser caches and temporary files
- Downloaded wallpaper libraries
- Runtime state and databases
- Third-party application binaries
- Private keys, credentials, and tokens

## License

The Hyprland Dock retains its original included license. Other personal configuration and scripts are provided as-is.

### Onboard Microphone Gain Persistence

Preserves onboard Realtek ALC897 microphone hardware gain across boots and WirePlumber restarts.

- `systemd/alsa-restore.service.d/no-shutdown-overwrite.conf` saves the onboard ALSA card using its stable ID, `Generic_1`.
- `systemd/user/restore-mic-gain.service` reapplies Capture gain 57 (+25.50 dB) after WirePlumber starts or restarts.
- Rear Mic Boost remains at +20.00 dB.

#### Installation

Install the system override:
`sudo install -Dm644 systemd/alsa-restore.service.d/no-shutdown-overwrite.conf /etc/systemd/system/alsa-restore.service.d/no-shutdown-overwrite.conf`
`sudo systemctl daemon-reload`

Install the user service:
`mkdir -p ~/.config/systemd/user`
`install -Dm644 systemd/user/restore-mic-gain.service ~/.config/systemd/user/restore-mic-gain.service`
`systemctl --user daemon-reload`
`systemctl --user enable restore-mic-gain.service`

The local ALSA state file `/var/lib/alsa/asound.state` is intentionally excluded from Git.
