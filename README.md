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
| `src/ServerScriptService/Cinematic/` | 神龙演出（Remote + 占位） |
| `src/StarterPlayer/StarterPlayerScripts/ClientMain.client.lua` | HUD、谜题 UI、演出条 |
