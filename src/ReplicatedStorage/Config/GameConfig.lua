--!strict
--[[
	Global tunables for Dragon Ball hunt MVP.
]]

local GameConfig = {
	PlayersRequired = 2,
	-- When true, a single player in Studio can start a match (easier local test).
	AllowSinglePlayerTest = true,

	OrbCount = 7,
	-- ProximityPrompt distance (studs); more reliable than physics Touched alone.
	OrbProximityDistance = 12,
	-- Min seconds between interact attempts per player per orb (stops spam / double fires).
	OrbInteractDebounceSeconds = 0.45,
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

	-- Must match MapGenerator floor reference height.
	ArenaBaseY = 10,
	-- If player is below this Y and under the arena footprint, teleport to rescue.
	FallRescueBelowY = 7,
	-- Horizontal margin beyond cell rim for “under arena” rescue column.
	FallRescueRadiusExtra = 22,
	-- Invisible perimeter wall height above deck.
	PerimeterWallHeight = 55,

	SpawnOffsetFromCenter = 55,
}

return table.freeze(GameConfig)
