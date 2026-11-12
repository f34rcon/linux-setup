#!/usr/bin/env bash

set -u

ACTION="${1:-}"

case "$ACTION" in
    up|down|mute) ;;
    *)
        echo "Usage: focused-app-volume.sh {up|down|mute}"
        exit 2
        ;;
esac

ROOT_PID=$(hyprctl activewindow -j | jq -r '.pid // empty')

if [[ ! "$ROOT_PID" =~ ^[0-9]+$ ]]; then
    exit 0
fi

# Build the exact focused-process descendant tree.
PID_JSON=$(
    ps -eo pid=,ppid= |
    python3 -c '
import sys, json

root = int(sys.argv[1])
children = {}

for line in sys.stdin:
    parts = line.split()
    if len(parts) != 2:
        continue
    pid, ppid = map(int, parts)
    children.setdefault(ppid, []).append(pid)

found = {root}
stack = [root]

while stack:
    parent = stack.pop()
    for child in children.get(parent, []):
        if child not in found:
            found.add(child)
            stack.append(child)

print(json.dumps(sorted(found)))
' "$ROOT_PID"
)

mapfile -t STREAMS < <(
    pw-dump | jq -r --argjson pids "$PID_JSON" '
        .[]
        | select(.type == "PipeWire:Interface:Node")
        | .info.props as $p
        | select($p["media.class"] == "Stream/Output/Audio")
        | select(
            ($p["application.process.id"] // -1 | tonumber) as $pid
            | ($pids | index($pid)) != null
          )
        | select(
            (($p["application.name"] // "") + " " +
             ($p["node.name"] // "")) | test("jamesdsp"; "i") | not
          )
        | .id
    '
)

LOG="$HOME/.local/state/focused-app-volume.log"
mkdir -p "$(dirname "$LOG")"

{
    echo "========== $(date) =========="
    echo "Action: $ACTION"
    echo "Focused PID: $ROOT_PID"
    echo "Descendant PIDs: $PID_JSON"
    echo "Matched streams: ${STREAMS[*]:-none}"
} >> "$LOG"

if [[ ${#STREAMS[@]} -eq 0 ]]; then
    exit 0
fi

case "$ACTION" in
    up)
        for id in "${STREAMS[@]}"; do
            wpctl set-volume "$id" -l 1.0 5%+
        done
        ;;
    down)
        for id in "${STREAMS[@]}"; do
            wpctl set-volume "$id" 5%-
        done
        ;;
    mute)
        SET_MUTED=1
        for id in "${STREAMS[@]}"; do
            if wpctl get-volume "$id" | grep -q '\[MUTED\]'; then
                SET_MUTED=0
                break
            fi
        done

        for id in "${STREAMS[@]}"; do
            wpctl set-mute "$id" "$SET_MUTED"
        done
        ;;
esac

for id in "${STREAMS[@]}"; do
    echo "Stream $id: $(wpctl get-volume "$id")" >> "$LOG"
done
