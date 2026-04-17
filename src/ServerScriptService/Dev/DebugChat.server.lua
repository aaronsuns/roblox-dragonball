--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TextChatService = game:GetService("TextChatService")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)

local function debugChatEnabled(): boolean
	if RunService:IsStudio() then
		return true
	end
	return GameConfig.DebugChatOutsideStudio == true
end

if not debugChatEnabled() then
	return
end

local DragonBallService = require(ServerScriptService.Game.DragonBallService)
local ArenaSafety = require(ServerScriptService.World.ArenaSafety)
local GameStateManager = require(ServerScriptService.Game.GameStateManager)

-- TextChatCommand + legacy Chatted can both deliver the same line; ignore duplicates briefly.
local lastDbLine: { [number]: { t: number, s: string } } = {}

local function splitWords(s: string): { string }
	local t: { string } = {}
	for w in string.gmatch(s, "%S+") do
		table.insert(t, w)
	end
	return t
end

--[[
	Returns (isDbCommand, restAfterDb) where rest is the substring after "/db" for parsing.
	Accepts "/db", "/db help", "/db  help" (leading/trailing spaces trimmed).
]]
local function parseDbPayload(message: string): (boolean, string)
	local m = string.gsub(message, "^%s+", "")
	m = string.gsub(m, "%s+$", "")
	if m == "/db" then
		return true, ""
	end
	if string.sub(m, 1, 4) == "/db " then
		return true, string.sub(m, 5)
	end
	return false, ""
end

local function help(player: Player)
	print(string.format("[DragonBall /db] player=%s — commands (see Studio Output window):", player.Name))
	print("  /db or /db help")
	print("  /db orbs        — print all orb positions")
	print("  /db tp <1-7>    — teleport next to the N-star ball")
	print("  /db near        — teleport to the nearest orb")
	print("  /db labels on|off — star labels on orbs")
	print("  /db spawn       — teleport to rescue spawn")
	print("  /db phase       — print match phase")
	warn(string.format("[DragonBall /db] %s: replies are printed to the SERVER Output, not in chat.", player.Name))
end

local function onChat(player: Player, message: string)
	local isDb, rest = parseDbPayload(message)
	if not isDb then
		return
	end
	local uid = player.UserId
	local prev = lastDbLine[uid]
	local now = os.clock()
	if prev and prev.s == message and now - prev.t < 0.35 then
		return
	end
	lastDbLine[uid] = { t = now, s = message }

	local args = splitWords(rest)
	local cmd = string.lower(args[1] or "help")

	if cmd == "help" or cmd == "" then
		help(player)
		return
	end

	if cmd == "orbs" then
		local list = DragonBallService.GetOrbDebugList()
		print(string.format("[DragonBall /db orbs] count=%d player=%s", #list, player.Name))
		for _, row in list do
			print(string.format("  star=%d pos=%s id=%s", row.star, tostring(row.position), row.id))
		end
		return
	end

	if cmd == "tp" then
		local n = tonumber(args[2])
		if not n or n < 1 or n > 7 then
			warn("[DragonBall /db tp] usage: /db tp <1-7>")
			return
		end
		if DragonBallService.TeleportPlayerNearStar(player, n) then
			print(string.format("[DragonBall /db tp] ok star=%d player=%s", n, player.Name))
		else
			warn(string.format("[DragonBall /db tp] failed star=%d (collected or not in match)", n))
		end
		return
	end

	if cmd == "near" then
		if DragonBallService.TeleportPlayerNearAnyOrb(player) then
			print("[DragonBall /db near] ok " .. player.Name)
		else
			warn("[DragonBall /db near] failed (no orbs or character not loaded)")
		end
		return
	end

	if cmd == "labels" then
		local on = string.lower(args[2] or "") == "on"
		local off = string.lower(args[2] or "") == "off"
		if not on and not off then
			warn("[DragonBall /db labels] usage: /db labels on|off")
			return
		end
		DragonBallService.SetDebugOrbLabels(on)
		print("[DragonBall /db labels] " .. (on and "on" or "off"))
		return
	end

	if cmd == "spawn" or cmd == "rescue" then
		if ArenaSafety.teleportToRescue(player) then
			print("[DragonBall /db spawn] ok " .. player.Name)
		else
			warn("[DragonBall /db spawn] failed (only while InMatch after start)")
		end
		return
	end

	if cmd == "phase" then
		print("[DragonBall /db phase] " .. GameStateManager.GetPhase())
		return
	end

	help(player)
end

local function hookPlayerChatted(player: Player)
	player.Chatted:Connect(function(message: string)
		onChat(player, message)
	end)
end

Players.PlayerAdded:Connect(hookPlayerChatted)
for _, p in Players:GetPlayers() do
	hookPlayerChatted(p)
end

--[[
	TextChannel.MessageReceived only runs on the CLIENT (Roblox API). For default Text Chat,
	register a TextChatCommand so the SERVER receives Triggered with the full line.
	See: https://create.roblox.com/docs/chat/examples/custom-text-chat-commands
]]
task.defer(function()
	local cv = TextChatService.ChatVersion
	if cv == Enum.ChatVersion.LegacyChatService then
		print("[DragonBall /db] Legacy chat: using Player.Chatted only (TextChatCommand not used).")
		return
	end

	local existing = TextChatService:FindFirstChild("DragonBallDebugCommand")
	if existing then
		existing:Destroy()
	end

	local cmd = Instance.new("TextChatCommand")
	cmd.Name = "DragonBallDebugCommand"
	cmd.PrimaryAlias = "/db"
	cmd.AutocompleteVisible = true
	cmd.Parent = TextChatService

	cmd.Triggered:Connect(function(originTextSource: TextSource, unfilteredText: string)
		local plr = Players:GetPlayerByUserId(originTextSource.UserId)
		if not plr then
			return
		end
		onChat(plr, unfilteredText)
	end)

	print("[DragonBall /db] Registered TextChatService TextChatCommand PrimaryAlias=/db (see Output when you run /db help)")
end)
