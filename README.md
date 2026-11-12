# Windows 11 + Arch Linux Desktop Setup

Personal desktop configuration, custom applications, scripts, and
restoration documentation for this PC.

The current configuration was developed on CachyOS with Hyprland.
The target rebuild is Windows 11 + Arch Linux dual boot.

This repository is a backup and restoration reference, not an
automatic installer.

## Rebuild Documentation

See [docs/ARCH-RESTORE.md](docs/ARCH-RESTORE.md) for the complete
hardware inventory, storage plan, rebuild checklist, and restoration
instructions.

The restoration guide covers both operating systems and records
important installation and configuration commands.

## Repository Structure

- `apps/` — Custom desktop applications and their source files
- `config/` — Desktop and application configuration
- `docs/` — Installation and restoration documentation
- `scripts/` — Custom desktop scripts and utilities
- `systemd/` — System and user service configuration

## Included Components

### Desktop

- Hyprland configuration
- Hyprlock lock screen
- Waybar configuration and styling
- Kitty terminal configuration
- Waypaper Engine configuration

### Custom Applications

- Launchpad — Quickshell-based application launcher
- Hyprland Dock — Quickshell dock and QML components
- Volume OSD — Custom focused-application volume display
- Star Citizen application integration

### Scripts and Utilities

- Background applications menu
- Keyboard shortcuts menu
- Session menu
- App menu toggle
- Rofi click-to-close helper
- Hyprland dock launcher
- Waypaper Engine startup helper
- Wallpaper Engine export utility
- Live wallpaper restoration utility
- Focused-application volume controls
- Focused-audio diagnostic utility

## Restoration Notes

- Configurations should be reviewed before installation on a new system.
- Machine-specific paths and hardware identifiers must be verified.
- Monitor names may differ between installations.
- Quickshell applications require Quickshell.
- Waypaper Engine requires its application dependencies and a compatible
  wallpaper backend.
- Downloaded wallpaper libraries are backed up separately and are not
  stored in this repository.

## Backup Policy

Included:
- Desktop and application configuration files
- Custom application source files
- Custom scripts and utilities
- Restoration documentation
- System and user service configuration

Excluded:
- Historical configuration backups
- Browser caches and temporary files
- Downloaded wallpaper libraries
- Runtime state and databases
- Third-party application binaries
- Private keys, credentials, and tokens

## Onboard Microphone Gain Persistence

Preserves onboard Realtek ALC897 microphone hardware gain across boots
and WirePlumber restarts.

- `systemd/alsa-restore.service.d/no-shutdown-overwrite.conf` saves the
  onboard ALSA card using its stable ID, `Generic_1`.
- `systemd/user/restore-mic-gain.service` reapplies Capture gain 57
  (+25.50 dB) after WirePlumber starts or restarts.
- Rear Mic Boost remains at +20.00 dB.

### Installation

Install the system override:

    sudo install -Dm644 systemd/alsa-restore.service.d/no-shutdown-overwrite.conf /etc/systemd/system/alsa-restore.service.d/no-shutdown-overwrite.conf
    sudo systemctl daemon-reload

Install the user service:

    mkdir -p ~/.config/systemd/user
    install -Dm644 systemd/user/restore-mic-gain.service ~/.config/systemd/user/restore-mic-gain.service
    systemctl --user daemon-reload
    systemctl --user enable restore-mic-gain.service

The local ALSA state file `/var/lib/alsa/asound.state` is intentionally
excluded from Git.

## License

The Hyprland Dock retains its original included license. Other personal
configuration and scripts are provided as-is.
