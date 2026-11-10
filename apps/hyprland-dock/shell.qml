import QtQuick
import Quickshell

ShellRoot {
  DockHost {
    configPath: Quickshell.env("HYPRLAND_DOCK_CONFIG")
      || Quickshell.env("HOME") + "/.config/hyprland-dock/dock.json"
  }
}
