#!/usr/bin/env bash
# Store your Roblox numeric UserId for Open Cloud uploads (creationContext.creator.userId).
# Service name: roblox-creator-user-id
#
#   ./tools/roblox-store-creator-user-id-keychain.sh
#
set -euo pipefail
if ! command -v security >/dev/null 2>&1; then
  echo "macOS security(1) not found." >&2
  exit 1
fi

read -rsp "Roblox numeric UserId (from profile URL): " uid
echo "" >&2
if [[ ! "$uid" =~ ^[0-9]+$ ]]; then
  echo "Expected digits only." >&2
  exit 1
fi

security add-generic-password -U -a "$USER" -s "roblox-creator-user-id" -w "$uid"
unset uid
echo "Saved to keychain as service roblox-creator-user-id for account $USER" >&2
