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
| **ParticleEmitter**（少量白/金小点） | 「闪闪发亮」 cheap 且性能好。 |
| **PointLight**（弱橙光） | 夜间与阴影下更醒目（注意性能，移动设备少开）。 |

### 2.3 制作流程（建议）

1. 在 **Krita / Photoshop** 按参考图画 **7 张 PNG**（透明底）：仅星阵 + 可选内阴影，分辨率 512 或 1024。
2. 在 **Blender**（可选）做简单球体 UV，烘焙一张「高光mask」或直接用程序材质在 Studio 里调。
3. 导入 Roblox → 得 **TextureId / MeshId**，写入 `AssetRegistry`。
4. 代码侧（下一步可实现）：`DragonBallService` 按 `Star` 属性克隆「外观模板」或换贴图 ID，统一挂粒子和灯光。

### 2.4 与现有代码的衔接

- 在 [`AssetRegistry.lua`](../src/ReplicatedStorage/Config/AssetRegistry.lua) 增加例如：`Tex_DragonBall_Stars1` … `Tex_DragonBall_Stars7`、`FX_OrbSparkle`。
- 在 `DragonBallService.SpawnOrbs` 里：创建外观子 `BillboardGui` **仅作调试**；正式版用 **Decal + 粒子**，避免星星永远朝向相机失真（若要做「刻在球里」的感觉，优先 **双层球壳 + 内层贴花**）。

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

---

## 6. 分阶段里程碑（建议执行顺序）

1. **M0（1–2 天）** — **已在仓库实现一版**  
   - `LightingTheme.server.lua`：`Lighting` + `Atmosphere` + `ColorCorrection`（偏绿那美克星感）。  
   - `OrbVisuals`：`Glass` 材质、琥珀色、`ParticleEmitter` 闪光、`PointLight`、头顶 `★` 星数（贴图 `Tex_DragonBall_Stars1–7` 非 0 时再加 `Decal`）。  
   - `MapGenerator`：草地颜色读 `VisualTheme` 青绿渐变。可调 [`VisualTheme.lua`](../src/ReplicatedStorage/Config/VisualTheme.lua)。

2. **M1（1 周）**  
   - 7 张星阵 PNG + 球体 Decal/双层壳；`AssetRegistry` 接好；关闭调试用 Billboard 星标。  

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
