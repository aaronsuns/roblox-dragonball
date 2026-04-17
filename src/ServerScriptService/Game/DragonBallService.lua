--!strict

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local GameRemotes = require(ReplicatedStorage.Remotes.GameRemotes)
local OrbVisuals = require(script.Parent.Parent.World.OrbVisuals)

export type OrbInfo = {
	part: BasePart,
	id: string,
	star: number,
	touchConn: RBXScriptConnection?,
}

local DragonBallService = {}
local remotes = GameRemotes.Ensure()

local orbs: { OrbInfo } = {}
local knownOrbIds: { [string]: boolean } = {}
local cooldownUntil: { [string]: number } = {}
local lockedOrb: { [string]: boolean } = {}
local lastInteractAt: { [string]: number } = {}

local puzzleService: any = nil
local winService: any = nil
local getPhase: (() -> string)? = nil
local onFullWin: ((Player) -> ())? = nil
local broadcastCollections: (() -> ())? = nil

local promptHooked = false

local function shuffle<T>(arr: { T }, rng: Random)
	for i = #arr, 2, -1 do
		local j = rng:NextInteger(1, i)
		arr[i], arr[j] = arr[j], arr[i]
	end
end

function DragonBallService._broadcastCollections()
	if broadcastCollections then
		broadcastCollections()
	end
end

local function debounceOk(player: Player, orbId: string): boolean
	local key = tostring(player.UserId) .. "_" .. orbId
	local now = os.clock()
	local last = lastInteractAt[key] or 0
	if now - last < GameConfig.OrbInteractDebounceSeconds then
		return false
	end
	lastInteractAt[key] = now
	return true
end

--[[
	Starts puzzle if allowed. Returns true if Begin() was invoked successfully.
]]
local function requestOrbPuzzle(player: Player, orbId: string, star: number): boolean
	local phase = if getPhase then getPhase() else "Lobby"
	if phase ~= "InMatch" then
		return false
	end
	if not knownOrbIds[orbId] then
		return false
	end
	if winService and winService.HasStar(player.UserId, star) then
		return false
	end
	if lockedOrb[orbId] then
		return false
	end
	local now = workspace:GetServerTimeNow()
	if cooldownUntil[orbId] and now < cooldownUntil[orbId] then
		return false
	end
	if not debounceOk(player, orbId) then
		return false
	end

	lockedOrb[orbId] = true
	if puzzleService then
		local ok = puzzleService.Begin(player, orbId, star)
		if not ok then
			lockedOrb[orbId] = false
		end
		return ok
	end
	lockedOrb[orbId] = false
	return false
end

local function onProximityPromptTriggered(prompt: ProximityPrompt, player: Player)
	local parent = prompt.Parent
	if not parent or not parent:IsA("BasePart") then
		return
	end
	local orbId = parent:GetAttribute("OrbId")
	local star = parent:GetAttribute("Star")
	if typeof(orbId) ~= "string" or typeof(star) ~= "number" then
		return
	end
	requestOrbPuzzle(player, orbId, star)
end

local function hookProximityPromptService()
	if promptHooked then
		return
	end
	promptHooked = true
	ProximityPromptService.PromptTriggered:Connect(onProximityPromptTriggered)
end

local function destroyOrb(orbId: string)
	knownOrbIds[orbId] = nil
	local idx: number? = nil
	for i, info in orbs do
		if info.id == orbId then
			idx = i
			break
		end
	end
	if not idx then
		return
	end
	local info = orbs[idx :: number]
	if info.touchConn then
		info.touchConn:Disconnect()
	end
	if info.part.Parent then
		info.part:Destroy()
	end
	table.remove(orbs, idx :: number)
end

function DragonBallService.SpawnOrbs(orbPositions: { Vector3 }, seed: number)
	DragonBallService.ClearOrbs()
	hookProximityPromptService()

	local rng = Random.new(seed + 911)
	local positions = table.clone(orbPositions)
	shuffle(positions, rng)
	local stars = { 1, 2, 3, 4, 5, 6, 7 }
	shuffle(stars, rng)

	for i = 1, math.min(GameConfig.OrbCount, #positions) do
		local star = stars[i]
		local pos = positions[i]
		local orb = Instance.new("Part")
		orb.Name = "DragonBall_" .. tostring(star)
		orb.Shape = Enum.PartType.Ball
		orb.Size = Vector3.new(4, 4, 4)
		orb.Material = Enum.Material.SmoothPlastic
		orb.Color = Color3.fromRGB(255, 210, 60) -- OrbVisuals overwrites material/color for M0 look
		local id = HttpService:GenerateGUID(false)
		orb:SetAttribute("OrbId", id)
		orb:SetAttribute("Star", star)
		orb.CFrame = CFrame.new(pos)
		orb.Anchored = false
		orb.CanCollide = true
		orb.CustomPhysicalProperties = PhysicalProperties.new(0.4, 0.2, 0.6, 1, 1)
		local folder = workspace:FindFirstChild("DragonBallArena")
		if folder and folder:IsA("Folder") then
			orb.Parent = folder
		else
			orb.Parent = workspace
		end

		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "CollectPrompt"
		prompt.ActionText = "Solve"
		prompt.ObjectText = string.format("%d-star Dragon Ball", star)
		prompt.MaxActivationDistance = GameConfig.OrbProximityDistance
		prompt.HoldDuration = 0
		prompt.RequiresLineOfSight = false
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
		prompt.Style = Enum.ProximityPromptStyle.Default
		prompt.Parent = orb

		OrbVisuals.apply(orb, star)

		local info: OrbInfo = {
			part = orb,
			id = id,
			star = star,
			touchConn = nil,
		}

		knownOrbIds[id] = true

		-- Touched is unreliable on rolling balls; kept as a secondary path with shared debounce.
		info.touchConn = orb.Touched:Connect(function(hit: BasePart)
			local model = hit:FindFirstAncestorOfClass("Model")
			if not model then
				return
			end
			local player = Players:GetPlayerFromCharacter(model)
			if not player then
				return
			end
			requestOrbPuzzle(player, id, star)
		end)

		table.insert(orbs, info)
	end
end

function DragonBallService.ClearOrbs()
	for _, info in orbs do
		if info.touchConn then
			info.touchConn:Disconnect()
		end
		if info.part.Parent then
			info.part:Destroy()
		end
	end
	orbs = {}
	knownOrbIds = {}
	cooldownUntil = {}
	lockedOrb = {}
	lastInteractAt = {}
end

function DragonBallService.Init(
	puzzle: any,
	win: any,
	phaseGetter: () -> string,
	onWinAll: (Player) -> (),
	broadcastCols: () -> ()
)
	puzzleService = puzzle
	winService = win
	getPhase = phaseGetter
	onFullWin = onWinAll
	broadcastCollections = broadcastCols
	hookProximityPromptService()
end

function DragonBallService.OnPuzzleSolved(player: Player, orbId: string, star: number)
	lockedOrb[orbId] = false
	destroyOrb(orbId)
	if winService then
		local wonMatch = winService.AddStar(player.UserId, star)
		DragonBallService._broadcastCollections()
		if wonMatch and onFullWin then
			onFullWin(player)
		end
	end
end

function DragonBallService.OnPuzzleFailed(player: Player, orbId: string)
	lockedOrb[orbId] = false
	cooldownUntil[orbId] = workspace:GetServerTimeNow() + GameConfig.OrbCooldownSeconds
end

function DragonBallService.CancelPuzzlesForEveryone()
	for _, p in Players:GetPlayers() do
		if puzzleService then
			puzzleService.CancelForPlayer(p)
		end
	end
end

export type OrbDebugInfo = {
	star: number,
	position: Vector3,
	id: string,
}

function DragonBallService.GetOrbDebugList(): { OrbDebugInfo }
	local out: { OrbDebugInfo } = {}
	for _, info in orbs do
		table.insert(out, {
			star = info.star,
			position = info.part.Position,
			id = info.id,
		})
	end
	table.sort(out, function(a, b)
		return a.star < b.star
	end)
	return out
end

function DragonBallService.TeleportPlayerNearStar(player: Player, star: number): boolean
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return false
	end
	local target: BasePart? = nil
	for _, info in orbs do
		if info.star == star then
			target = info.part
			break
		end
	end
	if not target then
		return false
	end
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.CFrame = target.CFrame * CFrame.new(4, 2, 0)
	return true
end

function DragonBallService.TeleportPlayerNearAnyOrb(player: Player): boolean
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp or #orbs == 0 then
		return false
	end
	local best = orbs[1].part
	local bestDist = (best.Position - hrp.Position).Magnitude
	for i = 2, #orbs do
		local d = (orbs[i].part.Position - hrp.Position).Magnitude
		if d < bestDist then
			bestDist = d
			best = orbs[i].part
		end
	end
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.CFrame = best.CFrame * CFrame.new(4, 2, 0)
	return true
end

function DragonBallService.SetDebugOrbLabels(enabled: boolean)
	for _, info in orbs do
		local existing = info.part:FindFirstChild("DebugOrbLabel")
		if existing then
			existing:Destroy()
		end
		if enabled then
			local gui = Instance.new("BillboardGui")
			gui.Name = "DebugOrbLabel"
			gui.Size = UDim2.new(0, 120, 0, 36)
			gui.AlwaysOnTop = true
			gui.StudsOffset = Vector3.new(0, 4, 0)
			local t = Instance.new("TextLabel")
			t.Size = UDim2.new(1, 0, 1, 0)
			t.BackgroundTransparency = 0.3
			t.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
			t.TextColor3 = Color3.fromRGB(255, 230, 120)
			t.Font = Enum.Font.GothamBold
			t.TextScaled = true
			t.Text = tostring(info.star) .. "-star"
			t.Parent = gui
			gui.Parent = info.part
		end
	end
end

return DragonBallService
