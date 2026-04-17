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
	-- Chance each orb puzzle is multiplication (arithmetic) vs RPS; 0–1.
	PuzzleMultiplicationChance = 0.82,

	ShenronCinematicSeconds = 10,
	PostMatchResetSeconds = 3,

	MapSize = 180,
	BaseplateThickness = 2,
	TerrainNoiseAmplitude = 6,
	ObstacleCount = 40,
	WallCount = 22,
	-- Radial walls spawn between this distance and MapSize*0.45 (lower = denser center).
	WallMinDistanceFromCenter = 8,

	-- Must match MapGenerator floor reference height.
	ArenaBaseY = 10,
	-- If player is below this Y and under the arena footprint, teleport to rescue.
	FallRescueBelowY = 7,
	-- Horizontal margin beyond cell rim for “under arena” rescue column.
	FallRescueRadiusExtra = 22,
	-- Invisible perimeter wall height above deck.
	PerimeterWallHeight = 52,

	-- Roof slab over the island (same span as perimeter) so high camera / flying cannot trivially scout orbs.
	ArenaCeilingEnabled = true,
	ArenaCeilingThicknessStuds = 6,
	-- Underside of ceiling sits this many studs above ArenaBaseY (keep > PerimeterWallHeight).
	ArenaCeilingClearanceAboveBaseY = 54,
	ArenaCeilingTransparency = 0.14,
	ArenaCeilingCanCollide = true,

	SpawnOffsetFromCenter = 55,

	-- When true, `/db` debug chat works in published games (any player). Keep false for public releases.
	DebugChatOutsideStudio = false,
}

return table.freeze(GameConfig)
