#!/usr/bin/bash
# Refresh snapshot.json to the latest upstream commit of every pinned node.
#
# Spins up a throwaway ComfyUI workspace, restores the current snapshot into
# it, asks ComfyUI-Manager to update every node to its latest commit, then
# saves the resulting state back over snapshot.json.
#
# Requires: comfy-cli (`pip install comfy-cli`).
set -euo pipefail

WORKSPACE="$(mktemp -d -t comfy-snapshot-refresh.XXXXXX)"
trap 'rm -rf "$WORKSPACE"' EXIT

SNAPSHOT="$(cd "$(dirname "$0")" && pwd)/snapshot.json"

comfy --skip-prompt --no-enable-telemetry --workspace="$WORKSPACE/ComfyUI" install \
  --nvidia --skip-torch-or-directml
comfy --skip-prompt --no-enable-telemetry --workspace="$WORKSPACE/ComfyUI" \
  node restore-snapshot "$SNAPSHOT"
comfy --skip-prompt --no-enable-telemetry --workspace="$WORKSPACE/ComfyUI" \
  node update all
comfy --skip-prompt --no-enable-telemetry --workspace="$WORKSPACE/ComfyUI" \
  node save-snapshot --output "$SNAPSHOT"
