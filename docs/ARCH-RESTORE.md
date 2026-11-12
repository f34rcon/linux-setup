# Windows 11 + Arch Linux Restoration Guide

This document is the master checklist for rebuilding this PC as a
Windows 11 and Arch Linux dual-boot system.

All important installation and restoration commands must be recorded
here or in scripts in this repository.

## 1. Hardware Inventory

Drive identification must use manufacturer, exact model, capacity,
and interface. Never rely exclusively on device paths such as
/dev/sda or /dev/nvme0n1, or Windows drive letters.

| Drive | Capacity | Interface | Intended use |
|---|---:|---|---|
| Western Digital WDC WDS500G1B0A-00H9H0 | 465.8 GiB | SATA | Windows 11 only |
| Crucial CT1000P3PSSD8 (Crucial P3) | 931.5 GiB | NVMe | 200 GB Arch system; remaining space in Linux pool |
| TEAM TM8FP6001T | 953.9 GiB | NVMe | Linux storage pool |
| Samsung SSD 840 EVO 250GB | 232.9 GiB | SATA | Separate storage; excluded from pool |

### PC platform

Hardware identified on the current CachyOS installation:

| Component | Identified hardware |
|---|---|
| CPU | AMD Ryzen 7 9800X3D (8 cores / 16 threads) |
| Dedicated GPU | NVIDIA GeForce RTX 5080 (GB203) |
| Integrated GPU | AMD Radeon 610M |
| Motherboard | ASUS B650E MAX GAMING WIFI W (Rev 1.xx) |
| Memory | 32 GiB |
| Firmware | American Megatrends, version 3854, dated 2026-04-02 |
| Ethernet | Realtek RTL8125 2.5 GbE |
| Wi-Fi | MediaTek MT7922 (Wi-Fi 6E) |
| Onboard audio | Realtek ALC897 |

Current CachyOS driver observations:

- NVIDIA graphics: `nvidia`
- AMD integrated graphics: `amdgpu`
- Ethernet: `r8125`
- Wi-Fi: `mt7921e`
- Audio controllers: `snd_hda_intel`

These are observations, not a requirement to install identical
driver packages on Arch. Test the standard Arch kernel drivers
first, especially `r8169` for the RTL8125 Ethernet controller.


### Drive identification rules

Before partitioning, formatting, mounting, or changing a drive:

- Confirm its manufacturer and exact model.
- Confirm its capacity and interface.
- Match that information to the current operating system's device path.
- Verify the intended role against this inventory.
- Stop if the identity or intended target is uncertain.

Windows and Linux may assign different device names to the same drive.
The hardware model and capacity are the persistent identifiers.

Linux identification command:

    lsblk -d -o NAME,MODEL,SERIAL,SIZE,TRAN

Windows PowerShell identification commands:

    Get-PhysicalDisk | Select-Object FriendlyName,SerialNumber,BusType,MediaType,Size,HealthStatus

    Get-Disk | Select-Object Number,FriendlyName,SerialNumber,BusType,PartitionStyle,Size,OperationalStatus

    Get-CimInstance Win32_DiskDrive | Select-Object Model,SerialNumber,Size,InterfaceType,DeviceID

Use `Get-PhysicalDisk` and `Get-Disk` to help identify the physical
drives and map them to Windows disk numbers. The `Win32_DiskDrive`
interface type can be generic for some NVMe devices, so do not use
that field alone to distinguish SATA from NVMe.

## 2. Confirmed Storage Decisions

- The WD 500 GB SATA SSD is dedicated to Windows 11.
- The Crucial P3 1 TB NVMe SSD receives a 200 GB Arch system allocation.
- The remaining Crucial P3 capacity joins the Linux storage pool.
- The TEAM 1 TB NVMe SSD joins that same Linux storage pool.
- Only NVMe storage is combined in the Linux pool.
- The Samsung 250 GB SATA SSD remains separate.
- Use separate EFI System Partitions for Windows and Arch Linux.
- Windows EFI resides on the WD SATA SSD; Arch EFI resides on the Crucial P3.
- Use Limine as the Arch bootloader and Windows/Arch boot menu.
- Keep Secure Boot enabled and reuse the existing enrolled keys.
- Preserve the existing encrypted USB Secure Boot key backup.
- Use Btrfs for the unified NVMe storage pool, mounted at /mnt/storage.
- Use the Btrfs single allocation profile without redundancy or RAID0 striping.
- SATA and NVMe drives must never be combined into one pool.

## 3. Rebuild Checklist

### Phase 1 — Preparation

- [ ] Verify backups and recovery information.
- [ ] Identify all four drives by exact model, capacity, and interface.
- [ ] Record their current device paths in the live installation environment.
- [ ] Prepare Windows 11 and Arch Linux installation media.

### Phase 2 — Windows 11

- [ ] Install Windows 11 on the WD 500 GB SATA SSD.
- [ ] Verify Windows boots independently.
- [ ] Complete initial setup and updates.
- [ ] Verify the other drives have not been modified.

### Phase 3 — Arch Linux

- [ ] Install Arch Linux in the 200 GB allocation on the Crucial P3 1 TB NVMe SSD.
- [ ] Install and configure Limine with Secure Boot signing.
- [ ] Verify both operating systems boot.
- [ ] Configure the Btrfs NVMe-only storage pool using the remaining Crucial P3 space and TEAM 1 TB NVMe SSD.
- [ ] Verify the Samsung 250 GB SATA SSD remains separate.

### Initial kernel and hardware package plan

Use the standard Arch `linux` kernel rather than a CachyOS kernel.

Initial hardware packages:

    linux
    linux-firmware
    amd-ucode
    nvidia-open
    nvidia-utils
    lib32-nvidia-utils
    mesa
    vulkan-radeon

Hardware notes:

- The RTX 5080 uses the NVIDIA open kernel module package.
- Keep 32-bit NVIDIA support for Steam and other 32-bit applications.
- Retain AMD integrated graphics support through Mesa and RADV.
- The linux-firmware package supplies firmware for the MediaTek
  Wi-Fi and Realtek network hardware.
- Test the in-kernel r8169 Ethernet driver before considering
  a separate driver package.
- Do not install CachyOS kernels or CachyOS-specific kernel tools.

This is the initial hardware package group. Optional graphics,
compute, and video-acceleration packages will be evaluated separately.

### Initial Hyprland desktop package plan

Use official Arch repository packages wherever possible.

Initial desktop packages:

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

Notes:

- Hyprland is the only desktop environment.
- Use the repository versions of Hyprland components.
- Start the Hyprland Polkit authentication agent with the session.
- Use the existing repository-managed Quickshell dock and Launchpad.
- Use Thunar as the file manager.
- Verify package availability and names against current Arch
  repositories before installation.
- Add application-specific dependencies in their respective sections.

### Networking, Bluetooth, and audio package plan

Initial official Arch repository packages:

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

Hardware and configuration notes:

- Use NetworkManager as the sole network manager.
- Enable NetworkManager.service.
- Use the kernel mt7921e driver for the MediaTek MT7922 Wi-Fi adapter.
- Test the standard r8169 driver for the Realtek RTL8125 Ethernet adapter.
- Use BlueZ for Bluetooth support and enable bluetooth.service.
- Use PipeWire and WirePlumber for audio.
- The Realtek ALC897 uses the standard snd_hda_intel driver.
- Restore the repository-managed microphone gain service and ALSA
  restore configuration after installing the audio stack.
- JamesDSP is a separate AUR application and will be documented
  in the optional/AUR application section.
- Do not install a second network manager or PulseAudio alongside
  the planned PipeWire stack.

### Phase 4 — Desktop and Applications

### Desktop scope

- Hyprland is the only desktop environment.
- Do not install KDE Plasma or a KDE Plasma session.
- Exclude standalone KDE applications and KDE-specific desktop utilities.
- Use Thunar as the file manager.
- Restore the custom Quickshell dock, Launchpad, Waybar, and other
  repository-managed desktop components.


- [ ] Install Hyprland and required desktop components.
- [ ] Restore repository configuration files.
- [ ] Install required packages and dependencies.
- [ ] Restore custom applications and scripts.
- [ ] Configure audio, peripherals, and hardware integrations.

### Applications and gaming software

#### Official Arch repository packages

- firefox
- discord
- steam
- vlc
- audacity
- btop
- fastfetch
- mission-center
- gparted

#### AUR packages

- brave-bin
- proton-ge-custom-bin
- r2modman-bin
- jamesdsp
- waypaper-engine
- linux-wallpaperengine-git

#### Flatpak applications

- net.pcsx2.PCSX2
- org.vinegarhq.Sober

#### Steam and NVIDIA requirements

- Enable the official [multilib] repository in /etc/pacman.conf.
- Refresh package databases and perform a full system upgrade after enabling multilib.
- Install steam and lib32-nvidia-utils for 32-bit game compatibility.
- Use nvidia-open with the standard linux kernel for the RTX 5080 (Blackwell).
- Install nvidia-utils alongside nvidia-open.
- Keep lib32-nvidia-utils aligned with nvidia-utils.
- Retain mesa and vulkan-radeon for AMD integrated graphics.
- Verify NVIDIA DRM/KMS and Hyprland Wayland configuration.
- After reboot, verify the driver with nvidia-smi and check Vulkan device detection.
- Do not use NVIDIA's standalone .run installer.
- Install AUR packages after the base Arch system is working and the AUR helper is configured.
- Install Flatpak applications separately through Flathub.


### Phase 5 — Personal Data and Wallpapers

- [ ] Restore personal files from backups.
- [ ] Restore wallpaper files from Google Drive.
- [ ] Restore the Waypaper Engine gallery and playlist.
- [ ] Verify wallpaper playback and monitor behavior.

### Phase 6 — Final Verification

- [ ] Verify Windows 11 startup.
- [ ] Verify Arch Linux startup.
- [ ] Verify boot selection and recovery options.
- [ ] Verify storage mounts and pool behavior.
- [ ] Verify desktop applications, audio, and peripherals.
- [ ] Review the repository for undocumented setup commands.

## 4. Wallpaper Restoration

The wallpaper backup must retain these directories:

- Anime/
- Generated/
- Downloaded/

After installing Waypaper Engine and its required video backend,
restore the gallery and playlist with:

    python ~/linux-setup/scripts/restore-live-wallpapers.py \
        ~/Downloads/wallpapers

The script checks the six expected files, imports missing gallery
entries, creates or updates the ordered five-minute playlist, and
starts it across connected monitors.

The Waypaper daemon is started by the Hyprland startup helper:
scripts/start-live-wallpapers.

Do not also enable waypaper-daemon.service unless the startup
arrangement is deliberately changed.

## 5. Decisions Still To Be Finalized

- Exact package installation list.
- Final Arch installation and post-install commands.

Record each finalized decision here before carrying out the
corresponding installation step.

## 6. Verified Physical Drive Models

The following exact hardware models were identified using `lsblk`
on the current CachyOS installation.

| Intended use | Manufacturer / exact model | Interface | Reported capacity |
|---|---|---|---:|
| Windows 11 | Western Digital WDC WDS500G1B0A-00H9H0 | SATA | 465.8 GiB |
| Arch system + Linux pool | Crucial CT1000P3PSSD8 (Crucial P3) | NVMe | 931.5 GiB |
| Linux storage pool | TEAM TM8FP6001T | NVMe | 953.9 GiB |
| Separate storage | Samsung SSD 840 EVO 250GB | SATA | 232.9 GiB |

### Current CachyOS device mapping

These device paths describe the current installation only. They
must be re-identified by hardware model during the rebuild.

| Current device path | Hardware model |
|---|---|
| /dev/sda | WDC WDS500G1B0A-00H9H0 |
| /dev/sdb | Samsung SSD 840 EVO 250GB |
| /dev/nvme0n1 | Crucial CT1000P3PSSD8 |
| /dev/nvme1n1 | TEAM TM8FP6001T |

The current 14.6 GB USB device is installation media and is not part
of the internal storage plan. zram0 is virtual compressed memory,
not a physical drive.

### Current Crucial P3 partition observation

The current lsblk output reports these partitions on the Crucial P3:

- 200 MB partition
- 16 MB partition
- 243.3 GiB partition
- 688 GiB partition

This is an observation of the existing installation, not the
approved final partition layout. Inspect filesystem types, labels,
UUIDs, and mount points before deciding what to preserve or replace.


## Final Verified Drive Identifiers

Verified on the existing CachyOS installation on 2026-11-11.
Device paths may change in the Arch installer; identify drives by model and serial.

| Drive | Model | Serial | Capacity | Assignment |
|---|---|---|---:|---|
| WD SATA | WDC WDS500G1B0A-00H9H0 | 171257801660 | 500 GB | Windows 11 only |
| Samsung SATA | Samsung SSD 840 EVO 250GB | S1DBNSBF785486T | 250 GB | Separate; not pooled |
| Crucial NVMe | CT1000P3PSSD8 | 2521506316F1 | 1 TB | Arch system + Btrfs pool |
| TEAM NVMe | TEAM TM8FP6001T | TPBF2207080020200092 | 1 TB | Btrfs pool |

## Verified Installation Media and Secure Boot Backup

- Arch ISO: `archlinux-2026.11.01-x86_64.iso`
- Windows ISO: `Windows11_Client_x64_en-us_26300_9457.iso`
- Both ISO copies on Ventoy match their downloaded originals by SHA-256.
- Secure Boot backup is on the encrypted ASolid USB.
- All backup manifest checksums passed using root permissions.
- PK, KEK, and db private/public key pairs are present.
- Preserve the ASolid USB throughout installation.
