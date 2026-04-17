--!strict
--[[
	Replace rbxassetid://0 with your uploaded assets when ready.
	Code should read only from this table for Mesh/Sound/Animation IDs.
]]

local AssetRegistry = {
	SFX_WinFanfare = "rbxassetid://0",
	SFX_ShenronRumble = "rbxassetid://0",
	Mesh_DragonBall = "rbxassetid://0", -- optional MeshId on orb Parts
	-- Full orb sprites (one file per star). Priority over Tex_DragonBall_Stars*. When set, OrbVisuals uses BillboardGui + ImageLabel (always visible).
	Tex_DragonBall_OrbFull1 = "rbxassetid://116519344579733",
	Tex_DragonBall_OrbFull2 = "rbxassetid://123616024255985",
	Tex_DragonBall_OrbFull3 = "rbxassetid://112652755016723",
	Tex_DragonBall_OrbFull4 = "rbxassetid://72597119179916",
	Tex_DragonBall_OrbFull5 = "rbxassetid://137251263984784",
	Tex_DragonBall_OrbFull6 = "rbxassetid://100421338508432",
	Tex_DragonBall_OrbFull7 = "rbxassetid://90425669580030",
	-- Optional transparent decals (one per star layout). OrbVisuals applies when non-zero.
	Tex_DragonBall_Stars1 = "rbxassetid://0",
	Tex_DragonBall_Stars2 = "rbxassetid://0",
	Tex_DragonBall_Stars3 = "rbxassetid://0",
	Tex_DragonBall_Stars4 = "rbxassetid://0",
	Tex_DragonBall_Stars5 = "rbxassetid://0",
	Tex_DragonBall_Stars6 = "rbxassetid://0",
	Tex_DragonBall_Stars7 = "rbxassetid://0",
}

return table.freeze(AssetRegistry)
