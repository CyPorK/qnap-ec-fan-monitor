#!/usr/bin/env bash
# Usage: bash docs/record.sh <pve-host>
# Example: bash docs/record.sh <pve-host>

HOST="${1:?Usage: $0 <pve-host>}"
TAPE=$(mktemp /tmp/demo-XXXXXX.tape)
trap 'rm -f "$TAPE"' EXIT

sed "s/<pve-host>/$HOST/" "$(dirname "$0")/demo.tape" > "$TAPE"
vhs -o docs/demo.gif "$TAPE"
