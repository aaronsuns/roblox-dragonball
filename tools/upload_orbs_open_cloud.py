#!/usr/bin/env python3
"""
Upload assets-src/orbs/orb_full_1.png … orb_full_7.png to Roblox via Open Cloud Assets API,
then print AssetRegistry.lua lines you can paste in.

Requires:
  - Creator Dashboard API key with asset:write (+ asset:read for polling)
  - Env ROBLOX_API_KEY
  - Env ROBLOX_CREATOR_USER_ID (your Roblox user id, digits only)

Docs: https://create.roblox.com/docs/en-us/cloud/guides/usage-assets.md

Usage:
  source tools/load_roblox_env_from_keychain.sh   # loads from macOS Keychain (see tools/roblox-store-*.sh)
  python3 tools/upload_orbs_open_cloud.py [optional_dir_default_assets-src_orbs]

Or export ROBLOX_API_KEY / ROBLOX_CREATOR_USER_ID manually.
"""
from __future__ import annotations

import json
import os
import sys
import time
from pathlib import Path

import requests

API = "https://apis.roblox.com/assets/v1"


def poll_operation(session: requests.Session, op_path: str) -> dict:
    # op_path like "operations/abc-123"
    url = f"{API}/{op_path}"
    for _ in range(90):
        r = session.get(url, timeout=120)
        r.raise_for_status()
        data = r.json()
        if data.get("done"):
            if data.get("error"):
                raise RuntimeError(json.dumps(data["error"], indent=2))
            return data.get("response") or {}
        time.sleep(1.0)
    raise TimeoutError("Operation did not finish in time")


def upload_png(session: requests.Session, user_id: str, png: Path, display_name: str) -> str:
    # Use "Image" (not "Decal") so rbxassetid works in ImageLabel.Image / GUI — Decal IDs often stay blank there.
    # See https://create.roblox.com/docs/en-us/parts/textures-decals.md and GUI images:
    # https://create.roblox.com/docs/ui/gui-images
    request_obj = {
        "assetType": "Image",
        "displayName": display_name,
        "description": "Dragon Ball hunt orb art (uploaded by tools/upload_orbs_open_cloud.py)",
        "creationContext": {"creator": {"userId": str(user_id)}},
    }
    with png.open("rb") as f:
        files = {
            "request": (None, json.dumps(request_obj), "application/json"),
            "fileContent": (png.name, f, "image/png"),
        }
        r = session.post(f"{API}/assets", files=files, timeout=300)
    if not r.ok:
        raise RuntimeError(f"POST assets failed {r.status_code}: {r.text[:2000]}")
    body = r.json()
    if body.get("done"):
        resp = body.get("response") or {}
        asset_id = resp.get("assetId") or resp.get("asset_id")
        if asset_id is None:
            raise RuntimeError(f"No assetId in immediate response: {json.dumps(body)[:2000]}")
        return str(asset_id)
    op_path = body.get("path") or body.get("name")
    if not op_path or not isinstance(op_path, str):
        raise RuntimeError(f"Unexpected POST body: {json.dumps(body)[:2000]}")
    resp = poll_operation(session, op_path)
    asset_id = resp.get("assetId") or resp.get("asset_id")
    if asset_id is None:
        raise RuntimeError(f"No assetId in operation response: {json.dumps(resp)[:2000]}")
    return str(asset_id)


def main() -> int:
    key = os.environ.get("ROBLOX_API_KEY", "").strip()
    uid = os.environ.get("ROBLOX_CREATOR_USER_ID", "").strip()
    if not key or not uid:
        print(
            "Set ROBLOX_API_KEY and ROBLOX_CREATOR_USER_ID, then re-run.\n"
            "See https://create.roblox.com/dashboard/credentials",
            file=sys.stderr,
        )
        return 1

    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("assets-src/orbs")
    session = requests.Session()
    session.headers["x-api-key"] = key

    ids: dict[int, str] = {}
    for star in range(1, 8):
        png = root / f"orb_full_{star}.png"
        if not png.is_file():
            print(f"Missing {png}", file=sys.stderr)
            return 2
        print(f"Uploading {png.name} …")
        aid = upload_png(session, uid, png, f"OrbFull_{star}Star")
        ids[star] = aid
        print(f"  -> assetId {aid}")

    print("\n-- Paste into AssetRegistry.lua (replace zeros):")
    for star in range(1, 8):
        print(f'\tTex_DragonBall_OrbFull{star} = "rbxassetid://{ids[star]}",')
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
