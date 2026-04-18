--!strict

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local VisualTheme = require(ReplicatedStorage.Config.VisualTheme)

export type MapResult = {
	folder: Folder,
	orbSlots: { Vector3 },
	spawnA: CFrame,
	spawnB: CFrame,
	baseY: number,
	rimRadius: number,
}

local MapGenerator = {}

local function pickBuildingMaterial(rng: Random): Enum.Material
	local list = VisualTheme.BuildingWallMaterials
	return list[rng:NextInteger(1, #list)]
end

local function pickBuildingColor(rng: Random): Color3
	local palette = VisualTheme.BuildingColorPalette
	local c = palette[rng:NextInteger(1, #palette)]
	local j = rng:NextNumber(-0.05, 0.05)
	return Color3.new(
		math.clamp(c.R + j, 0, 1),
		math.clamp(c.G + j, 0, 1),
		math.clamp(c.B + j, 0, 1)
	)
end

local function clearArena()
	local existing = Workspace:FindFirstChild("DragonBallArena")
	if existing then
		existing:Destroy()
	end
end

local function cellPart(parent: Folder, cx: number, cz: number, size: number, y: number, seed: number): Part
	local p = Instance.new("Part")
	p.Name = string.format("Cell_%d_%d", cx, cz)
	p.Anchored = true
	p.Size = Vector3.new(size, GameConfig.BaseplateThickness, size)
	local nx = cx / 32
	local nz = cz / 32
	local h = math.noise(nx * 1.7, nz * 1.7, seed * 0.001) * GameConfig.TerrainNoiseAmplitude
	p.CFrame = CFrame.new(cx * size, y + h, cz * size)
	p.Material = Enum.Material.Grass
	local t = (h + GameConfig.TerrainNoiseAmplitude) / (2 * GameConfig.TerrainNoiseAmplitude)
	p.Color = VisualTheme.GrassColor:Lerp(VisualTheme.GrassNoiseMix, math.clamp(t, 0, 1))
	p.Parent = parent
	return p
end

local function addPerimeterWalls(folder: Folder, baseY: number, rimRadius: number, wallHeight: number)
	local thickness = 4
	local span = rimRadius * 2 + thickness * 2 + 24
	local y = baseY + wallHeight * 0.5
	local function wall(name: string, cf: CFrame, size: Vector3)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = true
		p.Transparency = 0.92
		p.Material = Enum.Material.SmoothPlastic
		p.Color = Color3.fromRGB(120, 180, 255)
		p.Size = size
		p.CFrame = cf
		p.Parent = folder
	end
	wall(
		"PerimeterNorth",
		CFrame.new(0, y, -(rimRadius + thickness * 0.5)),
		Vector3.new(span, wallHeight, thickness)
	)
	wall(
		"PerimeterSouth",
		CFrame.new(0, y, (rimRadius + thickness * 0.5)),
		Vector3.new(span, wallHeight, thickness)
	)
	wall(
		"PerimeterWest",
		CFrame.new(-(rimRadius + thickness * 0.5), y, 0),
		Vector3.new(thickness, wallHeight, span)
	)
	wall(
		"PerimeterEast",
		CFrame.new((rimRadius + thickness * 0.5), y, 0),
		Vector3.new(thickness, wallHeight, span)
	)
end

local function arenaHorizontalSpan(rimRadius: number): number
	local thickness = 4
	return rimRadius * 2 + thickness * 2 + 24
end

local function addArenaCeiling(folder: Folder, baseY: number, rimRadius: number)
	if not GameConfig.ArenaCeilingEnabled then
		return
	end
	local span = arenaHorizontalSpan(rimRadius)
	local th = GameConfig.ArenaCeilingThicknessStuds
	local undersideY = baseY + GameConfig.ArenaCeilingClearanceAboveBaseY
	local centerY = undersideY + th * 0.5

	local p = Instance.new("Part")
	p.Name = "ArenaCeiling"
	p.Anchored = true
	p.CanCollide = GameConfig.ArenaCeilingCanCollide
	p.Material = Enum.Material.Neon
	p.Color = VisualTheme.ArenaCeilingColor
	p.Transparency = GameConfig.ArenaCeilingTransparency
	p.Size = Vector3.new(span, th, span)
	p.CFrame = CFrame.new(0, centerY, 0)
	p.Parent = folder
end

local function scatterObstacle(
	folder: Folder,
	pos: Vector3,
	w: number,
	h: number,
	d: number,
	color: Color3,
	material: Enum.Material,
	yaw: number
)
	local p = Instance.new("Part")
	p.Name = "Obstacle"
	p.Anchored = true
	p.Size = Vector3.new(w, h, d)
	p.CFrame = CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
	p.Material = material
	p.Color = color
	p.Parent = folder
	return p
end

local function xzNearSpawnClear(x: number, z: number, spawnZ: number, radius: number): boolean
	local dz1 = z - spawnZ
	local dz2 = z + spawnZ
	local d1 = math.sqrt(x * x + dz1 * dz1)
	local d2 = math.sqrt(x * x + dz2 * dz2)
	return d1 < radius or d2 < radius
end

local function scatterFillGridObstacles(
	folder: Folder,
	baseY: number,
	placeExtent: number,
	rng: Random,
	spawnOffsetZ: number
)
	local step = GameConfig.BuildingFillGridStepStuds
	local width = 2 * placeExtent
	local nx = math.max(2, math.floor(width / step))
	local actual = width / nx
	local skipP = GameConfig.BuildingFillCellSkipChance
	local clearR = GameConfig.BuildingSpawnClearRadius

	for ix = 0, nx - 1 do
		for iz = 0, nx - 1 do
			if rng:NextNumber() < skipP then
				continue
			end
			local jx = rng:NextNumber(-actual * 0.38, actual * 0.38)
			local jz = rng:NextNumber(-actual * 0.38, actual * 0.38)
			local cx = -placeExtent + (ix + 0.5) * actual + jx
			local cz = -placeExtent + (iz + 0.5) * actual + jz
			cx = math.clamp(cx, -placeExtent, placeExtent)
			cz = math.clamp(cz, -placeExtent, placeExtent)
			if xzNearSpawnClear(cx, cz, spawnOffsetZ, clearR) then
				continue
			end
			local h = rng:NextInteger(5, 15)
			local w = rng:NextInteger(5, 13)
			local d = rng:NextInteger(5, 13)
			local y = baseY + h * 0.5 + rng:NextNumber(0, GameConfig.TerrainNoiseAmplitude * 0.85)
			scatterObstacle(
				folder,
				Vector3.new(cx, y, cz),
				w,
				h,
				d,
				pickBuildingColor(rng),
				pickBuildingMaterial(rng),
				rng:NextNumber(0, math.pi * 2)
			)
		end
	end
end

function MapGenerator.Generate(seed: number): MapResult
	clearArena()
	local folder = Instance.new("Folder")
	folder.Name = "DragonBallArena"
	folder.Parent = Workspace

	local half = math.floor((GameConfig.MapSize / 20) / 2)
	local cell = 20
	local baseY = GameConfig.ArenaBaseY
	local rimRadius = half * cell + cell * 0.5
	local placeExtent = math.max(8, rimRadius - GameConfig.BuildingPlacementMarginStuds)

	for x = -half, half do
		for z = -half, half do
			cellPart(folder, x, z, cell, baseY, seed)
		end
	end

	local rng = Random.new(seed)
	for _ = 1, GameConfig.ObstacleCount do
		local x = rng:NextNumber(-placeExtent, placeExtent)
		local z = rng:NextNumber(-placeExtent, placeExtent)
		local h = rng:NextInteger(6, 16)
		local w = rng:NextInteger(6, 14)
		local d = rng:NextInteger(6, 14)
		local y = baseY + h * 0.5 + rng:NextNumber(0, GameConfig.TerrainNoiseAmplitude)
		local obsColor = pickBuildingColor(rng)
		local obsMat = pickBuildingMaterial(rng)
		local yaw = rng:NextNumber(0, math.pi * 2)
		scatterObstacle(folder, Vector3.new(x, y, z), w, h, d, obsColor, obsMat, yaw)
	end

	scatterFillGridObstacles(folder, baseY, placeExtent, rng, GameConfig.SpawnOffsetFromCenter)

	for _ = 1, GameConfig.WallCount do
		local angle = rng:NextNumber(0, math.pi * 2)
		local dist = rng:NextNumber(GameConfig.WallMinDistanceFromCenter, placeExtent * 0.98)
		local x = math.cos(angle) * dist
		local z = math.sin(angle) * dist
		local len = rng:NextNumber(24, 60)
		local thick = 3
		local wallH = rng:NextInteger(10, 22)
		local p = Instance.new("Part")
		p.Name = "Wall"
		p.Anchored = true
		p.Size = Vector3.new(len, wallH, thick)
		local look = CFrame.lookAt(Vector3.new(x, baseY + wallH * 0.5, z), Vector3.new(0, baseY + wallH * 0.5, 0))
		p.CFrame = look * CFrame.Angles(0, rng:NextNumber(-0.12, 0.12), rng:NextNumber(-0.04, 0.04))
		p.Material = pickBuildingMaterial(rng)
		p.Color = pickBuildingColor(rng)
		p.Parent = folder
	end

	addPerimeterWalls(folder, baseY, rimRadius, GameConfig.PerimeterWallHeight)
	addArenaCeiling(folder, baseY, rimRadius)

	local orbSlots: { Vector3 } = {}
	for _ = 1, 48 do
		local x = rng:NextNumber(-placeExtent, placeExtent)
		local z = rng:NextNumber(-placeExtent, placeExtent)
		local y = baseY + 4 + rng:NextNumber(0, 8)
		table.insert(orbSlots, Vector3.new(x, y, z))
	end

	local spawnA = CFrame.new(0, baseY + 5, GameConfig.SpawnOffsetFromCenter)
	local spawnB = CFrame.new(0, baseY + 5, -GameConfig.SpawnOffsetFromCenter)

	return {
		folder = folder,
		orbSlots = orbSlots,
		spawnA = spawnA,
		spawnB = spawnB,
		baseY = baseY,
		rimRadius = rimRadius,
	}
end

function MapGenerator.Destroy()
	clearArena()
end

return MapGenerator
