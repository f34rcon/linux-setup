#!/usr/bin/env bash

# Install this wrapper beside the original Star Citizen sc-launch.sh.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

export DISABLE_LSFGVK=1
export NVPRESENT_ENABLE_SMOOTH_MOTION=1

exec bash "$SCRIPT_DIR/sc-launch.sh" "$@"
