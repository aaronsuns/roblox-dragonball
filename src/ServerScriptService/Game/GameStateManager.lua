--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local GameRemotes = require(ReplicatedStorage.Remotes.GameRemotes)

local MapGenerator = require(script.Parent.Parent.World.MapGenerator)
local ArenaSafety = require(script.Parent.Parent.World.ArenaSafety)
local WinService = require(script.Parent.WinService)
local PuzzleService = require(script.Parent.PuzzleService)
local DragonBallService = require(script.Parent.DragonBallService)
local ShenronCinematicService = require(script.Parent.Parent.Cinematic.ShenronCinematicService)

export type Phase = "Lobby" | "InMatch" | "Ended" | "Resetting"

local GameStateManager = {}
local remotes = GameRemotes.Ensure()

local phase: Phase = "Lobby"
local matchSeed = 0
local contestants: { Player } = {}

local function setPhase(nextPhase: Phase, extra: { [string]: any }?)
	phase = nextPhase
	local payload: { [string]: any } = {
		phase = nextPhase,
	}
	if extra then
		for k, v in extra do
			payload[k] = v
		end
	end
	remotes.GameState:FireAllClients(payload)
end

local function getPhase(): string
	return phase
end

local function broadcastCollections()
	local collections = WinService.GetAllCollections()
	local serial: { [string]: { number } } = {}
	for userId, list in collections do
		serial[tostring(userId)] = list
	end
	for _, player in Players:GetPlayers() do
		remotes.CollectionSync:FireClient(player, {
			collections = serial,
		})
	end
end

local function pickContestants(): { Player }
	local list = Players:GetPlayers()
	table.sort(list, function(a, b)
		return a.UserId < b.UserId
	end)
	if GameConfig.AllowSinglePlayerTest and #list == 1 then
		return { list[1] }
	end
	if #list >= GameConfig.PlayersRequired then
		local out: { Player } = {}
		for i = 1, GameConfig.PlayersRequired do
			table.insert(out, list[i])
		end
		return out
	end
	return {}
end

local function teleportContestants(map: any)
	for i, plr in contestants do
		local char = plr.Character or plr.CharacterAdded:Wait()
		local hrp = char:WaitForChild("HumanoidRootPart", 10) :: BasePart?
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hrp and hum then
			hum.AutoRotate = true
			if i == 1 then
				hrp.CFrame = map.spawnA + Vector3.new(0, 3, 0)
			else
				hrp.CFrame = map.spawnB + Vector3.new(0, 3, 0)
			end
		end
	end
end

local function startMatch()
	contestants = pickContestants()
	if #contestants < 1 then
		return
	end
	if not GameConfig.AllowSinglePlayerTest and #contestants < GameConfig.PlayersRequired then
		return
	end

	matchSeed = math.random(1, 1_000_000_000)
	setPhase("InMatch", { seed = matchSeed })
	WinService.Reset()
	broadcastCollections()

	local map = MapGenerator.Generate(matchSeed)
	teleportContestants(map)
	ArenaSafety.beginMatch(map, getPhase)

	local slots = table.clone(map.orbSlots)
	while #slots > GameConfig.OrbCount do
		table.remove(slots, #slots)
	end
	DragonBallService.SpawnOrbs(slots, matchSeed)
end

local tryLobbyStart: (() -> ())? = nil

local function resetRound()
	setPhase("Resetting", {})
	ArenaSafety.endMatch()
	DragonBallService.CancelPuzzlesForEveryone()
	DragonBallService.ClearOrbs()
	MapGenerator.Destroy()
	contestants = {}
	WinService.Reset()
	broadcastCollections()
	task.wait(GameConfig.PostMatchResetSeconds)
	setPhase("Lobby", {})
	if tryLobbyStart then
		task.defer(tryLobbyStart)
	end
end

local function onWinner(player: Player)
	if phase ~= "InMatch" then
		return
	end
	DragonBallService.CancelPuzzlesForEveryone()
	setPhase("Ended", {
		winnerUserId = player.UserId,
		winnerName = player.DisplayName,
	})
	remotes.MatchResult:FireAllClients({
		winnerUserId = player.UserId,
		winnerName = player.DisplayName,
	})
	task.spawn(function()
		ShenronCinematicService.Play(player)
		task.wait(GameConfig.ShenronCinematicSeconds)
		ShenronCinematicService.ReleaseInputLock()
		resetRound()
	end)
end

function GameStateManager.Init()
	PuzzleService.Init(function(player, orbId, star)
		DragonBallService.OnPuzzleSolved(player, orbId, star)
	end, function(player, orbId)
		DragonBallService.OnPuzzleFailed(player, orbId)
	end)

	DragonBallService.Init(PuzzleService, WinService, getPhase, onWinner, broadcastCollections)

	local function tryLobbyStartInner()
		if phase ~= "Lobby" then
			return
		end
		local c = pickContestants()
		local ready = #c >= GameConfig.PlayersRequired
			or (GameConfig.AllowSinglePlayerTest and #c == 1)
		if ready then
			startMatch()
		end
	end
	tryLobbyStart = tryLobbyStartInner

	Players.PlayerAdded:Connect(function()
		task.defer(tryLobbyStartInner)
	end)
	Players.PlayerRemoving:Connect(function()
		if phase == "InMatch" or phase == "Ended" then
			ArenaSafety.endMatch()
			DragonBallService.CancelPuzzlesForEveryone()
			DragonBallService.ClearOrbs()
			MapGenerator.Destroy()
			contestants = {}
			WinService.Reset()
			broadcastCollections()
			setPhase("Lobby", { aborted = true })
		end
	end)

	task.defer(tryLobbyStartInner)
end

function GameStateManager.GetPhase(): Phase
	return phase
end

return GameStateManager
