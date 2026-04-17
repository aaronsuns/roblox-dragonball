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

local function scatterObstacle(folder: Folder, pos: Vector3, w: number, h: number, d: number, color: Color3)
	local p = Instance.new("Part")
	p.Name = "Obstacle"
	p.Anchored = true
	p.Size = Vector3.new(w, h, d)
	p.CFrame = CFrame.new(pos)
	p.Material = Enum.Material.SmoothPlastic
	p.Color = color
	p.Parent = folder
	return p
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

	for x = -half, half do
		for z = -half, half do
			cellPart(folder, x, z, cell, baseY, seed)
		end
	end

	local rng = Random.new(seed)
	for _ = 1, GameConfig.ObstacleCount do
		local x = rng:NextNumber(-GameConfig.MapSize * 0.4, GameConfig.MapSize * 0.4)
		local z = rng:NextNumber(-GameConfig.MapSize * 0.4, GameConfig.MapSize * 0.4)
		local h = rng:NextInteger(6, 16)
		local w = rng:NextInteger(6, 14)
		local d = rng:NextInteger(6, 14)
		local y = baseY + h * 0.5 + rng:NextNumber(0, GameConfig.TerrainNoiseAmplitude)
		scatterObstacle(
			folder,
			Vector3.new(x, y, z),
			w,
			h,
			d,
			Color3.fromRGB(160 + rng:NextInteger(0, 40), 120 + rng:NextInteger(0, 30), 90)
		)
	end

	for _ = 1, GameConfig.WallCount do
		local angle = rng:NextNumber(0, math.pi * 2)
		local dist = rng:NextNumber(40, GameConfig.MapSize * 0.45)
		local x = math.cos(angle) * dist
		local z = math.sin(angle) * dist
		local len = rng:NextNumber(24, 60)
		local thick = 3
		local wallH = rng:NextInteger(10, 22)
		local p = Instance.new("Part")
		p.Name = "Wall"
		p.Anchored = true
		p.Size = Vector3.new(len, wallH, thick)
		p.CFrame = CFrame.lookAt(Vector3.new(x, baseY + wallH * 0.5, z), Vector3.new(0, baseY + wallH * 0.5, 0))
		p.Material = Enum.Material.Concrete
		p.Color = Color3.fromRGB(130, 130, 135)
		p.Parent = folder
	end

	addPerimeterWalls(folder, baseY, rimRadius, GameConfig.PerimeterWallHeight)

	local orbSlots: { Vector3 } = {}
	for _ = 1, 48 do
		local x = rng:NextNumber(-GameConfig.MapSize * 0.42, GameConfig.MapSize * 0.42)
		local z = rng:NextNumber(-GameConfig.MapSize * 0.42, GameConfig.MapSize * 0.42)
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
