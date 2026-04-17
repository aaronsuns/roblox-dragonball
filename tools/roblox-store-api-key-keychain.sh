#!/usr/bin/env bash
# Store Roblox Open Cloud API key in macOS Keychain (generic password).
# Service name: ROBLOX_API_KEY (matches secrets.zsh + load_roblox_env_from_keychain.sh)
#
# Usage (recommended — key never appears on command line):
#   ./tools/roblox-store-api-key-keychain.sh
#
# Or from stdin (still avoid shell history with the secret):
#   ./tools/roblox-store-api-key-keychain.sh --stdin < /path/to/keyfile
#   pbpaste | ./tools/roblox-store-api-key-keychain.sh --stdin
#
set -euo pipefail
if ! command -v security >/dev/null 2>&1; then
  echo "macOS security(1) not found." >&2
  exit 1
fi

if [[ "${1:-}" == "--stdin" ]]; then
  key="$(cat)"
else
  read -rsp "Roblox Open Cloud API key: " key
  echo "" >&2
fi

if [[ -z "${key// }" ]]; then
  echo "Empty key, aborting." >&2
  exit 1
fi

# -U: update if entry already exists
security add-generic-password -U -a "$USER" -s "ROBLOX_API_KEY" -w "$key"
unset key
echo "Saved to keychain as service ROBLOX_API_KEY for account $USER" >&2
