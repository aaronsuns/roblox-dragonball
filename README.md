# roblox-dragonball

Dragon Ball–themed MVP: procedural map, seven star-rated Dragon Balls, random puzzles (**times tables as 4-button multiple choice** for touch/tablet / best-of-3 RPS), 1–7 star HUD, and a short Shenron-style win sequence (~10 s).

## Orb textures (Studio note)

Full-orbit art uses attribute `OrbFullImageUri` + client script `OrbFullArtClient.client.lua`. Billboards live under **PlayerGui** with **`Adornee = orb`**. The art is a **camera-facing sprite** (Billboard), not a sphere UV; size uses **BillboardGui.Size scale = studs** ([Size docs](https://create.roblox.com/docs/reference/engine/classes/BillboardGui)). Tune `VisualTheme.OrbFullBillboardDiameterScale`. **`OrbFullBillboardAlwaysOnTop = false`** so orbs hide behind walls (default).

**Important:** `ImageLabel.Image` should use assets uploaded as **Image** (Open Cloud `assetType: "Image"`). **Decal** upload IDs often stay **blank** in GUI `ImageLabel`. See [Textures & Decals](https://create.roblox.com/docs/en-us/parts/textures-decals.md), [ImageLabel](https://create.roblox.com/docs/reference/engine/classes/ImageLabel), and [Open Cloud usage (Decal, Image)](https://create.roblox.com/docs/en-us/cloud/guides/usage-assets.md).

Debug in Studio **client** command bar once: `_G.__DragonBallOrbArtDebug = true` then Play — Output prints each orb billboard URI.

## Roblox Open Cloud (optional, orb uploads)

Secrets live in **macOS Keychain**, not in the repo (same idea as `~/aaron/zsh/modules/secrets.zsh`).

1. `./tools/roblox-store-api-key-keychain.sh` — paste your API key once (or pipe: `pbpaste | ./tools/roblox-store-api-key-keychain.sh --stdin`).
2. `./tools/roblox-store-creator-user-id-keychain.sh` — your numeric Roblox user id (profile URL).
3. New shells: `~/.zsh` already sources `secrets.zsh`, which exports `ROBLOX_API_KEY` and `ROBLOX_CREATOR_USER_ID` when present.
4. From this repo only: `source tools/load_roblox_env_from_keychain.sh` then `python3 tools/upload_orbs_open_cloud.py`.

## Prerequisites

- [Rojo](https://rojo.space/) installed (`rojo --version`)
- Roblox Studio

## Sync into Studio

From the project root:

```bash
rojo serve
```

Install the Rojo plugin in Studio, click **Connect** to `localhost:34872` (use the port Rojo prints), and sync into a new or existing place.

## Local playtesting

- Collect Dragon Balls by standing near them and pressing **E** (keyboard) / **X** (gamepad), or by touching the ball. Interaction uses `ProximityPrompt` so prompts are reliable; tune `OrbProximityDistance` and `OrbInteractDebounceSeconds` in `GameConfig` if needed.
- With `GameConfig.AllowSinglePlayerTest` set to `true`, a **single player** can start a match (handy in Studio).
- For real 2-player matches, set `AllowSinglePlayerTest` to `false` and keep `PlayersRequired = 2`.

### Falls and arena bounds

- **Semi-transparent perimeter walls** reduce walking off the island.
- If you still drop onto the default Baseplate: while horizontally under the arena footprint and below `FallRescueBelowY`, you are **teleported to the rescue spawn** (same offset as `spawnA`). Tune `FallRescueBelowY`, `FallRescueRadiusExtra`, and `PerimeterWallHeight` in [`GameConfig.lua`](src/ReplicatedStorage/Config/GameConfig.lua).

### Quick manual tests (`/db` chat)

**Where results appear:** commands are handled on the **server**. Open **View → Output** in Studio (or your server logs). They do **not** echo into the in-game chat window.

**When it runs:** by default **only in Roblox Studio** (`RunService:IsStudio()`). To allow `/db` on a published place (e.g. private test), set `GameConfig.DebugChatOutsideStudio = true` (not recommended for public games).

**Typing:** you can use **`/db`** or **`/db help`**. Subcommands use a space after `/db`, e.g. `/db tp 3`.

| Command | Effect |
|---------|--------|
| `/db` or `/db help` | List commands (in Output) |
| `/db orbs` | Print each orb’s **star count + world position** |
| `/db tp 3` | Teleport beside the **3-star** ball (use 1–7) |
| `/db near` | Teleport to the **nearest** orb |
| `/db labels on` / `off` | Toggle **star labels** above orbs |
| `/db spawn` | Teleport to **rescue spawn** (same as fall recovery) |
| `/db phase` | Print current phase (Lobby / InMatch, etc.) |

**Text Chat:** `TextChannel.MessageReceived` only runs on the **client**, so the server registers a **`TextChatCommand`** under `TextChatService` with `PrimaryAlias = "/db"` (same pattern as [custom chat commands](https://create.roblox.com/docs/chat/examples/custom-text-chat-commands)). `Player.Chatted` is still connected for **legacy** chat (`ChatVersion.LegacyChatService`). On startup look for `[DragonBall /db] Registered TextChatService TextChatCommand...` in **Output**.

### Self-test on boot

In Studio, Output shows `[DragonBall SelfTest] OK` or a list of failures. Logic lives in [`SelfTest.lua`](src/ReplicatedStorage/Shared/SelfTest.lua).

## Art and visuals (plan)

See **[docs/ART_PLAN.md](docs/ART_PLAN.md)** for a phased pipeline: Dragon Ball look (shine + star decals), Namek-inspired terrain/sky, tools (Blender/Krita), and how to hook into `AssetRegistry` / `MapGenerator` without copyright issues.

**M0 (in repo):** [`VisualTheme.lua`](src/ReplicatedStorage/Config/VisualTheme.lua) + [`LightingTheme.server.lua`](src/ServerScriptService/World/LightingTheme.server.lua) + [`OrbVisuals.lua`](src/ServerScriptService/World/OrbVisuals.lua) — greener lighting/fog, grass tint, orbs glass + sparkles + light + red `★` billboard; optional star **Decals** when `Tex_DragonBall_Stars1–7` in `AssetRegistry` are set.

## Replacing art

Edit [`src/ReplicatedStorage/Config/AssetRegistry.lua`](src/ReplicatedStorage/Config/AssetRegistry.lua): replace `rbxassetid://0` with your uploaded asset IDs; load meshes/sounds from that table in code.

## Layout

| Path | Role |
|------|------|
| `src/ReplicatedStorage/Config/` | `GameConfig`, `AssetRegistry` |
| `src/ReplicatedStorage/Remotes/` | `GameRemotes` (created on server; clients wait) |
| `src/ServerScriptService/Bootstrap.server.lua` | Server entry |
| `src/ServerScriptService/Game/` | State machine, orbs, puzzles, win logic |
| `src/ServerScriptService/World/MapGenerator.lua` | Terrain and props |
| `src/ServerScriptService/World/ArenaSafety.lua` | Perimeter walls + fall rescue |
| `src/ServerScriptService/Dev/DebugChat.server.lua` | Studio chat debug |
| `src/ServerScriptService/Dev/SelfTestRunner.server.lua` | Studio boot self-test |
| `src/ReplicatedStorage/Shared/SelfTest.lua` | Self-test assertions |
| `src/ServerScriptService/Cinematic/` | Win sequence (remotes + placeholder) |
| `src/StarterPlayer/StarterPlayerScripts/ClientMain.client.lua` | HUD, puzzle UI, cinematic bar |
