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
	print(string.format("[DragonBall /db] player=%s — 命令:", player.Name))
	print("  /db help")
	print("  /db orbs        — 在 Output 打印所有龙珠世界坐标")
	print("  /db tp <1-7>    — 传送到指定星数龙珠旁")
	print("  /db near        — 传送到离你最近的龙珠")
	print("  /db labels on|off — 龙珠头顶调试标签")
	print("  /db spawn       — 传送到本局救援出生点（与掉落回传同点）")
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
			warn("[DragonBall /db tp] 用法: /db tp <1-7>")
			return
		end
		if DragonBallService.TeleportPlayerNearStar(player, n) then
			print(string.format("[DragonBall /db tp] ok star=%d player=%s", n, player.Name))
		else
			warn(string.format("[DragonBall /db tp] 失败 star=%d（可能已被收集或不在局内）", n))
		end
		return
	end

	if cmd == "near" then
		if DragonBallService.TeleportPlayerNearAnyOrb(player) then
			print("[DragonBall /db near] ok " .. player.Name)
		else
			warn("[DragonBall /db near] 失败（无龙珠或未加载角色）")
		end
		return
	end

	if cmd == "labels" then
		local on = string.lower(args[2] or "") == "on"
		local off = string.lower(args[2] or "") == "off"
		if not on and not off then
			warn("[DragonBall /db labels] 用法: /db labels on|off")
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
			warn("[DragonBall /db spawn] 失败（仅 InMatch 且已开局）")
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
