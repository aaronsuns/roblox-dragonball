# roblox-dragonball

双人夺珠 MVP：程序化地图、七颗不同星数龙珠、随机谜题（10 以内乘法 / 三局两胜猜拳）、HUD 1–7 星状态、神龙占位演出（约 10 秒）。

## 前置

- [Rojo](https://rojo.space/) 已安装（`rojo --version`）
- Roblox Studio

## 同步到 Studio

在项目根目录执行：

```bash
rojo serve
```

在 Studio 中安装 Rojo 插件，点击 **Connect** 连接到 `localhost:34872`（端口以 Rojo 输出为准），将工程同步到新的或已有的 Place。

## 本地测试

- `GameConfig.AllowSinglePlayerTest` 为 `true` 时，**单人**进入即可开局（方便 Studio 调试）。
- 正式双人对战将 `AllowSinglePlayerTest` 设为 `false`，并保证 `PlayersRequired = 2`。

### 掉落与地图边界

- 竞技场四周有**半透明碰撞墙**，减少走出边缘跌落。
- 若仍掉到默认 Baseplate：在竞技场水平范围下、高度低于 `FallRescueBelowY` 时，会**自动传送回本局出生救援点**（与 `spawnA` 偏移一致）。可在 [`GameConfig.lua`](src/ReplicatedStorage/Config/GameConfig.lua) 调整 `FallRescueBelowY`、`FallRescueRadiusExtra`、`PerimeterWallHeight`。

### Studio 快速手动测试（聊天命令）

仅在 **Roblox Studio 运行（非发布 Live）** 时生效，打开 **Output** 查看打印。

进入对局（`InMatch`）后，在聊天栏输入（注意开头 `/db ` 有空格）：

| 命令 | 作用 |
|------|------|
| `/db help` | 列出命令 |
| `/db orbs` | 在 Output 打印每颗龙珠的 **星数 + 世界坐标** |
| `/db tp 3` | 传送到 **3 星**龙珠旁边（可换 1–7） |
| `/db near` | 传送到**离你最近**的龙珠 |
| `/db labels on` / `off` | 龙珠头顶显示/关闭 **星数标签**（便于肉眼找） |
| `/db spawn` | 传送到本局**救援出生点**（与自动回传同位置） |
| `/db phase` | 打印当前阶段（Lobby / InMatch 等） |

若使用新版 **TextChat** 且 `Chatted` 无反应，可暂时在 Studio 里关闭 TextChatService 测试，或后续再加 TextChatCommand 适配。

### 自动自检

Studio 启动时会在 Output 打印 `[DragonBall SelfTest] OK` 或列出失败项；逻辑见 [`SelfTest.lua`](src/ReplicatedStorage/Shared/SelfTest.lua)。

## 替换正式美术

编辑 [`src/ReplicatedStorage/Config/AssetRegistry.lua`](src/ReplicatedStorage/Config/AssetRegistry.lua)，把 `rbxassetid://0` 换成你上传后的资源 ID；在代码中通过该表加载音效/网格等。

## 目录说明

| 路径 | 作用 |
|------|------|
| `src/ReplicatedStorage/Config/` | `GameConfig`、`AssetRegistry` |
| `src/ReplicatedStorage/Remotes/` | `GameRemotes`（仅服务器创建，客户端等待） |
| `src/ServerScriptService/Bootstrap.server.lua` | 服务器入口 |
| `src/ServerScriptService/Game/` | 状态机、龙珠、谜题、胜负 |
| `src/ServerScriptService/World/MapGenerator.lua` | 地形与障碍 |
| `src/ServerScriptService/World/ArenaSafety.lua` | 周边挡墙 + 掉落回传 |
| `src/ServerScriptService/Dev/DebugChat.server.lua` | Studio 聊天调试（仅 Studio） |
| `src/ServerScriptService/Dev/SelfTestRunner.server.lua` | Studio 启动自检 |
| `src/ReplicatedStorage/Shared/SelfTest.lua` | 自检断言集合 |
| `src/ServerScriptService/Cinematic/` | 神龙演出（Remote + 占位） |
| `src/StarterPlayer/StarterPlayerScripts/ClientMain.client.lua` | HUD、谜题 UI、演出条 |
