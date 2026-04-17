--!strict
--[[
	Replace rbxassetid://0 with your uploaded assets when ready.
	Code should read only from this table for Mesh/Sound/Animation IDs.
]]

local AssetRegistry = {
	SFX_WinFanfare = "rbxassetid://0",
	SFX_ShenronRumble = "rbxassetid://0",
	Mesh_DragonBall = "rbxassetid://0", -- optional MeshId on orb Parts
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
