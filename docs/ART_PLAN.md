# 美工与视觉改进计划（Dragon Ball 风格 / 那美克星方向）

本文档回答：**做什么、按什么顺序做、用什么工具、和代码怎么衔接**。当前工程已有 [`AssetRegistry`](../src/ReplicatedStorage/Config/AssetRegistry.lua) 占位，后续把正式资源 ID 填进去即可由脚本统一替换。

---

## 1. 版权与风格边界（重要）

- **不要直接使用**受版权保护的官方 DBZ 截图、官方模型或商标素材上架公开游戏。
- 做法：**原创或已授权素材** + 「龙珠式」玩法与配色（橙球 + 红星），属于常见奇幻元素；名称与 UI 文案避免直接使用注册商标用语（若上架需进一步咨询法务）。
- 你提供的 PNG 适合作为**美术参考（look dev）**，最终上架应用 **自己重画或委托重画** 的贴图/模型。

---

## 2. 龙珠：闪亮 + 正确星数（对齐参考图）

### 2.1 目标效果

- **材质**：橙→琥珀渐变、玻璃/晶体感、左上**强高光**（Specular/环境反射）、边缘略柔光。
- **星星**：球**内部**红色五角星，1–7 星布局与参考图一致（三角、方阵、六环绕一等）。
- **动画**：缓慢自转 + 轻微上下浮动；**闪光点**（粒子或 Bloom 下高光闪烁）。

### 2.2 在 Roblox 里的实现路径（推荐组合）

| 手段 | 用途 |
|------|------|
| **MeshPart** 或 **球体 + SpecialMesh** | 保持球形；Mesh 可略扁椭增加质感。 |
| **SurfaceAppearance** / **Texture** | 球体表面高光、细微噪点；可配合 `Color` 调橙黄。 |
| **Decal / 多张 Decal**（贴球内侧用透明球壳双层） | 内层贴「星阵」透明 PNG（你可在 PS/Krita 按参考图画 1–7 七张）。 |
| **整球贴图 / 七颗独立 MeshPart**（推荐省事） | 每张图或每个模型已带**固定星数**，游戏里只按 `Star` 换资源 ID，不必再叠 Billboard 字。 |
| **ParticleEmitter**（少量白/金小点） | 「闪闪发亮」 cheap 且性能好。 |
| **PointLight**（弱橙光） | 夜间与阴影下更醒目（注意性能，移动设备少开）。 |

### 2.3 制作流程（建议）

1. 在 **Krita / Photoshop** 按参考图画 **7 张 PNG**（透明底）：仅星阵 + 可选内阴影，分辨率 512 或 1024。
2. 在 **Blender**（可选）做简单球体 UV，烘焙一张「高光mask」或直接用程序材质在 Studio 里调。
3. 导入 Roblox → 得 **TextureId / MeshId**，写入 `AssetRegistry`。
4. 代码侧（下一步可实现）：`DragonBallService` 按 `Star` 属性克隆「外观模板」或换贴图 ID，统一挂粒子和灯光。

### 2.4 与现有代码的衔接

- 在 [`AssetRegistry.lua`](../src/ReplicatedStorage/Config/AssetRegistry.lua) 增加例如：`Tex_DragonBall_Stars1` … `Tex_DragonBall_Stars7`、`FX_OrbSparkle`。
- `OrbVisuals`：无星阵贴图时，用 `BillboardGui` 显示 `★` 行，**`StudsOffset`** 把球心上方抬起（高度见 [`VisualTheme.OrbStarBillboardStudsOffsetY`](../src/ReplicatedStorage/Config/VisualTheme.lua)），读起来清楚、不跟球皮一起「糊在表面」。当 `Tex_DragonBall_StarsN` 为有效 ID 时只加 **`Decal`**、不创建该 Billboard。若走「整球已画好星星」的贴图/模型，可长期不配 Decal，只保留漂浮星标作占位，或后续改为 **换 Mesh / 换整球 Texture**。

---

## 3. 地形：从方块 →「那美克星感」

### 3.1 视觉关键词（Namek-inspired）

- **天空**：偏绿/青绿渐变、柔和云层；用 `Lighting` + `Atmosphere` + `Sky` 对象调（不一定要真实物理天空盒，可用 Roblox 默认 Sky 调颜色）。
- **地面**：**青绿 / 蓝绿**草地，带起伏，少直角；远处略雾。
- **水体**：浅绿松石色水面 + 简单波纹材质。
- **植被**：**圆顶树、球状灌木**（低多边形即可），避免写实树木抢风格。
- **建筑**：圆顶土屋、管道感岩石（仍保持低多边形漫画感，与「漫画风」计划一致）。

### 3.2 技术路线（由易到难）

| 阶段 | 内容 |
|------|------|
| **A. 仅 Studio** | `Terrain` 笔刷雕刻 + 换 `Material`（Grass、Sand、Water）；`Lighting` 调环境色；放几个圆顶 **MeshPart** 树。 |
| **B. 半程序化** | 保留当前 `MapGenerator` 随机逻辑，把 **长方体障碍** 换成从「预制件池」里抽 **树/石/屋** 模型。 |
| **C. 整块地图** | Blender 做一块大地形网格 → 拆成数个大 MeshPart → 碰撞简化用 invisible hitbox。 |

### 3.3 与现有代码的衔接

- `MapGenerator` 里把 `scatterObstacle` 的方块改为 `Insert` **ReplicatedStorage/Assets** 下的预制件（Rojo 映射文件夹）。
- 颜色常量抽到 `GameConfig` 或 `ArtTheme.lua`（那美克星调色板），代码里少写死 RGB。

---

## 4. 其它常见需要美工的地方（清单）

- **UI**：阶段字、谜题面板、胜利/神龙条 → 统一字体与描边（漫画 UI）。
- **ProximityPrompt**：自定义图标或文案样式（可选）。
- **神龙占位**：替换为骨骼模型 + `Animation` + 相机序列（`ShenronCinematicService` 已预留时长）。
- **音效**：收集、谜题对错、雷声（`AssetRegistry` 已有字段可扩展）。

---

## 5. 推荐工具链（你不必全会）

| 环节 | 工具 |
|------|------|
| 2D 贴图 / 星阵 | Krita（免费）、Photoshop |
| 建模 / UV / 导出 | Blender（免费） |
| 导入 Roblox | Studio 上传 → 复制 AssetId |
| 版本管理 | 贴图源文件放仓库外或 `assets-src/`（大文件慎用 Git LFS） |

### 5.1 自动化能做到哪一步？

完全「零点击」不现实（上架、审美、版权总要有人把关），但可以把**重复劳动**压到脚本里：

| 做法 | 能自动化什么 | 典型工具 |
|------|----------------|----------|
| **程序生成 / 占位** | 星阵布局可用代码或矢量脚本生成 **原创** 简单几何星图（再导出 PNG），避免手动画每张；Lighting、粒子、材质参数已在仓库可调。 | Node/Python、SVG→PNG、[`VisualTheme.lua`](../src/ReplicatedStorage/Config/VisualTheme.lua) |
| **3D 批处理** | Blender **无头** `blender -b scene.blend -P export.py` 批量导出 FBX/贴图烘焙。 | Blender CLI + Python API |
| **上传到 Roblox** | 用 **Open Cloud**（或既有流水线）脚本上传 Image/Mesh，拿到 `rbxassetid://…` 写回 `AssetRegistry`（需 Creator 侧 API Key 与权限）。 | [Open Cloud 文档](https://create.roblox.com/docs/cloud) |
| **仓库内衔接** | Cursor **Agent** 按约定批量改 `AssetRegistry`、加 Rojo 映射；可写 **Skill**（例如「上传后把返回 ID 填入某键名」）统一命名规范。 | `.cursor/skills/`、`AssetRegistry.lua` |

**注意**：用第三方 **图像生成 API** 出图仍要你自己确认**授权与是否原创**；Agent 不能替你做法务决策。

### 5.2 尽量自动化的操作步骤（你可照抄执行）

1. **定规格**：统一 **1024×1024** 或 **512 PNG**，透明底；七套资源命名 `stars1`…`stars7`（或七颗完整球 `orb1`…`orb7`）。  
2. **批量出图**：在 [NanoBnana](https://nanobnana.com/en) / ChatGPT / Midjourney 等里用下面 **5.3** 通用模板或 **5.4** 已填好星数的提示词；导出后放进本机 `assets-src/orbs/`（仓库已默认 **gitignore `/assets-src/`**，大图不会误提交）。  
3. **（可选）脚本修图**：ImageMagick 批量 `trim` / `resize`，保证边距一致。  
4. **进 Roblox**：Creator Dashboard 上传 **Decal** 或 **Image**，或走 **Open Cloud** 批量上传 → 复制每个 `rbxassetid`。  
5. **写回仓库**：把 ID 填进 [`AssetRegistry.lua`](../src/ReplicatedStorage/Config/AssetRegistry.lua) 的 `Tex_DragonBall_Stars1`…`7`（或将来扩展 `Mesh_DragonBall_1`…`7` 由代码按星数切换）。  
6. **让 Agent 干活**：把「七行 ID 的表格」贴给 Cursor，说明键名规则，让 Agent 只改 `AssetRegistry`，避免手滑改错 Lua 语法。

### 5.3 图像生成提示词模板（原创奇幻道具，非任何既有作品）

下面每条都强调 **原创、无商标、无角色名**，降低风格撞车与版权风险。生成后你仍要做最终筛选。

**中文版（整颗球 + 固定星数，透明背景）**

> 原创奇幻游戏道具，一颗光滑的橙黄色水晶魔法球，球体半透明带玻璃高光，球**内部**有 **N 颗**平面红色五角星按对称布局排列（N=1 单星居中；2–7 星为清晰可数的独立红星），低多边形卡通渲染，柔和顶光，**纯透明背景**，无文字无 Logo，无角色，4K 细节但导出为游戏贴图用构图居中，单球占画面约 70%。

**English (same intent)**

> Original fantasy game prop: a smooth orange-amber crystal orb, semi-transparent glass with specular highlights, **N** flat red five-pointed stars **inside** the sphere in a clear symmetric layout (N must be exact and readable), stylized low-poly cartoon 3D look, soft top light, **transparent background**, no text, no logos, no characters, centered, orb fills ~70% of frame, suitable as PNG texture for a game.

把提示里的 **N** 换成 1 到 7 各跑一遍；若工具不支持透明底，加一句：「alpha channel / cutout background」或后期抠图。

**只要星阵、不要整球（给 Decal 叠在橙色球上）**

> 透明背景上的 **N** 个红色五角星平面贴纸，对称构图，星与星之间不重叠，无球体无阴影环境，纯 2D 矢量感图标，游戏 UI 用，无文字。

### 5.4 用 NanoBnana 开始做「七颗龙珠」贴图

[NanoBnana](https://nanobnana.com/en) 是文生图站点：打开后选 **正方形比例**（如 1:1、1024 级）便于进 Roblox；若界面有「透明 / PNG / alpha」选项可打开，没有则按 PNG 下载后 **Photopea / remove.bg / macOS 预览抠图** 去底。

**建议你先选一条路：**

| 路线 | 用途 | 存文件名（建议） |
|------|------|------------------|
| **A. 整球** | 一张图里球+星都画好，可当参考或以后做整球 UI | `orb_full_1.png` … `orb_full_7.png` |
| **B. 仅星阵** | 透明底只有红星，叠在工程里橙色球上的 **Decal**（与当前 `Tex_DragonBall_Stars1–7` 最对口） | `stars_only_1.png` … `stars_only_7.png` |

每条提示词在 NanoBnana 里 **各生成 1 次**，不满意就同句微调再抽 2–3 张，选最清晰、星数可数的一张。

---

**路线 A — 整球（7 条，英文，已写死星数；复制即用）**

1. `Original fantasy game prop, one smooth orange-amber crystal sphere, semi-transparent glass, strong specular highlight, exactly **1** flat red five-pointed star visible **inside** the orb at the center, symmetric, low-poly cartoon 3D, soft top light, transparent background, no text, no logos, no characters, orb centered filling ~70% of frame, game texture.`

2. `Original fantasy game prop, one smooth orange-amber crystal sphere, semi-transparent glass, strong specular highlight, exactly **2** flat red five-pointed stars **inside** the orb in a clear symmetric layout, low-poly cartoon 3D, soft top light, transparent background, no text, no logos, no characters, orb centered ~70% frame, game texture.`

3. `Original fantasy game prop, one smooth orange-amber crystal sphere, semi-transparent glass, strong specular highlight, exactly **3** flat red five-pointed stars **inside** the orb in a symmetric triangle layout, low-poly cartoon 3D, soft top light, transparent background, no text, no logos, no characters, orb centered ~70% frame, game texture.`

4. `Original fantasy game prop, one smooth orange-amber crystal sphere, semi-transparent glass, strong specular highlight, exactly **4** flat red five-pointed stars **inside** the orb in a symmetric square or diamond layout, low-poly cartoon 3D, soft top light, transparent background, no text, no logos, no characters, orb centered ~70% frame, game texture.`

5. `Original fantasy game prop, one smooth orange-amber crystal sphere, semi-transparent glass, strong specular highlight, exactly **5** flat red five-pointed stars **inside** the orb in a clear symmetric pattern (e.g. one center + four around), low-poly cartoon 3D, soft top light, transparent background, no text, no logos, no characters, orb centered ~70% frame, game texture.`

6. `Original fantasy game prop, one smooth orange-amber crystal sphere, semi-transparent glass, strong specular highlight, exactly **6** flat red five-pointed stars **inside** the orb in a symmetric ring or hex layout, low-poly cartoon 3D, soft top light, transparent background, no text, no logos, no characters, orb centered ~70% frame, game texture.`

7. `Original fantasy game prop, one smooth orange-amber crystal sphere, semi-transparent glass, strong specular highlight, exactly **7** flat red five-pointed stars **inside** the orb in a clear symmetric layout (one center + six around), low-poly cartoon 3D, soft top light, transparent background, no text, no logos, no characters, orb centered ~70% frame, game texture.`

---

**路线 B — 仅星阵 Decal（7 条）**

1. `Transparent background, exactly **1** red five-pointed star sticker, flat 2D vector icon style, symmetric, no orb, no sphere, no text, no logos, game UI asset, high contrast edges.`

2. `Transparent background, exactly **2** red five-pointed stars, flat 2D vector icon, symmetric spacing, stars do not overlap, no orb, no text, no logos, game UI asset.`

3. `Transparent background, exactly **3** red five-pointed stars in symmetric triangle layout, flat 2D vector, no overlap, no orb, no text, no logos, game UI asset.`

4. `Transparent background, exactly **4** red five-pointed stars in symmetric square layout, flat 2D vector, no overlap, no orb, no text, no logos, game UI asset.`

5. `Transparent background, exactly **5** red five-pointed stars in symmetric pattern, flat 2D vector, no overlap, no orb, no text, no logos, game UI asset.`

6. `Transparent background, exactly **6** red five-pointed stars in symmetric ring layout, flat 2D vector, no overlap, no orb, no text, no logos, game UI asset.`

7. `Transparent background, exactly **7** red five-pointed stars, one center and six around in a ring, flat 2D vector, no overlap, no orb, no text, no logos, game UI asset.`

---

**已有整版七球合图时**：可用仓库脚本 [`tools/split_dragonball_sheet.py`](../tools/split_dragonball_sheet.py)（需本地 `python3 -m venv .venv-art && pip install pillow opencv-python-headless`）按橙色区域自动裁成 `orb_full_1.png`…`7.png` 到 `assets-src/orbs/`；合图布局若与脚本内坐标不一致，需改脚本里的 `layout_map`。裁好后可用 Open Cloud 批量上传并打印 `Tex_DragonBall_OrbFull1–7` 行：[`tools/upload_orbs_open_cloud.py`](../tools/upload_orbs_open_cloud.py) 使用 **`assetType: "Image"`**（`ImageLabel.Image` 用 **Decal** 上传得到的 ID 常会空白；见 [Textures & Decals](https://create.roblox.com/docs/en-us/parts/textures-decals.md)、[ImageLabel](https://create.roblox.com/docs/reference/engine/classes/ImageLabel)、[Usage Assets](https://create.roblox.com/docs/en-us/cloud/guides/usage-assets.md)）。需 `pip install requests` 与钥匙串里的 `ROBLOX_*` 环境变量。

**做完当下一步**

1. 七张 PNG 存好并按上表命名。  
2. Roblox Creator Dashboard 上传为 **Decal**（路线 B 直接对 `Tex_DragonBall_Stars1–7`；路线 A 若只当参考可暂不上传）。  
3. 把七个 `rbxassetid` 填进 [`AssetRegistry.lua`](../src/ReplicatedStorage/Config/AssetRegistry.lua)，或把 ID 列表发给我 / Agent 代填。

---

## 6. 分阶段里程碑（建议执行顺序）

1. **M0（1–2 天）** — **已在仓库实现一版**  
   - `LightingTheme.server.lua`：`Lighting` + `Atmosphere` + `ColorCorrection`（偏绿那美克星感）。  
   - `OrbVisuals`：`ParticleEmitter` 闪光、`PointLight`；`Tex_DragonBall_OrbFull1–7` 有效时写 **`OrbFullImageUri`**、球体 **`Transparency=1`**（贴图 PNG 已画整球，避免与白球「双层」）；客户端 [`OrbFullArtClient.client.lua`](../src/StarterPlayer/StarterPlayerScripts/OrbFullArtClient.client.lua) 在 **PlayerGui** 建 **Billboard 精灵**（永远朝向相机，不是透视错误；要真球面贴图需 `Texture`/MeshPart）。`BillboardGui.Size` 的 **Scale = studs** 对齐直径，系数 [`OrbFullBillboardDiameterScale`](../src/ReplicatedStorage/Config/VisualTheme.lua)。否则 `Glass` 橙球 + 可选 `Tex_DragonBall_Stars*` Decal；再否则 `★` Billboard（`OrbStarBillboardStudsOffsetY`）。  
   - `MapGenerator`：草地颜色读 `VisualTheme` 青绿渐变。可调 [`VisualTheme.lua`](../src/ReplicatedStorage/Config/VisualTheme.lua)。

2. **M1（1 周）**  
   - 7 张星阵 PNG + 球体 Decal/双层壳；`AssetRegistry` 接好（接好后代码侧已自动关闭 Billboard 星标）。  

3. **M2（1–2 周）**  
   - `Terrain` 替换纯方块地板；障碍物换 3–5 种预制件（树、石、屋）。  

4. **M3（按需）**  
   - 神龙模型与镜头；水面与远景雾；移动端 LOD（减面、关部分灯光）。

---

## 7. 你「不知道怎么做」时的最小行动项

1. 在 Studio 里只改 **Lighting + Atmosphere**，截图对比，找到喜欢的「那美克星天色」。  
2. 用 **Krita** 画一颗 **1 星** 透明贴图（按参考图），导入后手动贴到一个球上，确认比例。  
3. 把 **AssetId** 发给自己记在 `AssetRegistry` 表里。  
4. 再复制改 2–7 星布局，七张齐了之后喊程序接到 `SpawnOrbs`。

---

## 8. 程序可配合的后续任务（需要时开 issue / 再迭代）

- `DragonBallVisuals` 模块：按 `star` 应用贴图 / 粒子 / 光。  
- `MapGenerator`：从「预制件表」随机实例化，替代纯色长方体。  
- `Theme.Namek`：天空与雾参数表，便于换「地球篇」主题。

如需，下一步可以从 **M0 纯 Lighting + 龙珠粒子** 开始在仓库里直接改一版占位效果（不涉及版权图，仅参数与粒子）。
