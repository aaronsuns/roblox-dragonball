--!strict
--[[
	Global tunables for Dragon Ball hunt MVP.
]]

local GameConfig = {
	PlayersRequired = 2,
	-- When true, a single player in Studio can start a match (easier local test).
	AllowSinglePlayerTest = true,

	OrbCount = 7,
	OrbCooldownSeconds = 4,
	MultiplicationTimeoutSeconds = 20,
	RpsRoundTimeoutSeconds = 12,

	ShenronCinematicSeconds = 10,
	PostMatchResetSeconds = 3,

	MapSize = 180,
	BaseplateThickness = 2,
	TerrainNoiseAmplitude = 6,
	ObstacleCount = 28,
	WallCount = 12,

	SpawnOffsetFromCenter = 55,
}

return table.freeze(GameConfig)
