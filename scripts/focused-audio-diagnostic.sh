#!/usr/bin/env bash

LOG="$HOME/.local/state/focused-audio-diagnostic.log"
mkdir -p "$(dirname "$LOG")"

{
    echo "========== TIME =========="
    date

    echo
    echo "========== FOCUSED WINDOW =========="
    hyprctl activewindow -j | jq '{class, title, pid}'

    echo
    echo "========== PLAYBACK STREAMS =========="
    pw-dump | jq -r '
      .[]
      | select(.type == "PipeWire:Interface:Node")
      | .info.props as $p
      | select($p["media.class"] == "Stream/Output/Audio")
      | [
          .id,
          ($p["application.name"] // "unknown"),
          ($p["application.process.id"] // "unknown"),
          ($p["node.name"] // "unknown"),
          ($p["media.name"] // "unknown")
        ]
      | @tsv
    ' | column -t -s $'\t'

} > "$LOG" 2>&1
