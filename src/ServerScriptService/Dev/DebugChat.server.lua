--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
if not RunService:IsStudio() then
	return
end

local DragonBallService = require(ServerScriptService.Game.DragonBallService)
local ArenaSafety = require(ServerScriptService.World.ArenaSafety)
local GameStateManager = require(ServerScriptService.Game.GameStateManager)

local function splitWords(s: string): { string }
	local t: { string } = {}
	for w in string.gmatch(s, "%S+") do
		table.insert(t, w)
	end
	return t
end

local function help(player: Player)
	print(string.format("[DragonBall /db] player=%s — commands:", player.Name))
	print("  /db help")
	print("  /db orbs        — print all orb positions to Output")
	print("  /db tp <1-7>    — teleport next to the N-star ball")
	print("  /db near        — teleport to the nearest orb")
	print("  /db labels on|off — show/hide star labels on orbs")
	print("  /db spawn       — teleport to rescue spawn (same as fall recovery)")
end

local function onChat(player: Player, message: string)
	if string.sub(message, 1, 4) ~= "/db " then
		return
	end
	local rest = string.sub(message, 5)
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

Players.PlayerAdded:Connect(function(player: Player)
	player.Chatted:Connect(function(message: string)
		onChat(player, message)
	end)
end)

for _, p in Players:GetPlayers() do
	p.Chatted:Connect(function(message: string)
		onChat(p, message)
	end)
end
