--!strict
--[[
	Replace rbxassetid://0 with your uploaded assets when ready.
	Code should read only from this table for Mesh/Sound/Animation IDs.
]]

local AssetRegistry = {
	SFX_WinFanfare = "rbxassetid://0",
	SFX_ShenronRumble = "rbxassetid://0",
	Mesh_DragonBall = "rbxassetid://0", -- optional MeshId on orb Parts
}

return table.freeze(AssetRegistry)
