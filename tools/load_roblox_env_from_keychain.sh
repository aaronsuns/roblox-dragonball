#!/usr/bin/env bash
# Source from a shell to export Roblox Open Cloud env vars from macOS Keychain.
# Same pattern as /Users/aaron/aaron/zsh/modules/secrets.zsh
#
#   source tools/load_roblox_env_from_keychain.sh
#   python3 tools/upload_orbs_open_cloud.py
#
# Keychain items (generic password, account = $USER):
#   - ROBLOX_API_KEY          → export ROBLOX_API_KEY
#   - roblox-creator-user-id  → export ROBLOX_CREATOR_USER_ID (digits only)
#
if ! command -v security >/dev/null 2>&1; then
  echo "security(1) not found; nothing loaded." >&2
  return 0 2>/dev/null || exit 0
fi

_rk="$(security find-generic-password -a "$USER" -s "ROBLOX_API_KEY" -w 2>/dev/null || true)"
if [[ -n "$_rk" ]]; then
  export ROBLOX_API_KEY="$_rk"
fi
unset _rk

_ruid="$(security find-generic-password -a "$USER" -s "roblox-creator-user-id" -w 2>/dev/null || true)"
if [[ -n "$_ruid" ]]; then
  export ROBLOX_CREATOR_USER_ID="$_ruid"
fi
unset _ruid
