--!strict

local GameConfig = require(game:GetService("ReplicatedStorage").Config.GameConfig)

local STAR_MAX = GameConfig.OrbCount

export type StarSet = { [number]: boolean }

local WinService = {}
local collected: { [number]: StarSet } = {}

function WinService.Reset()
	collected = {}
end

function WinService.HasStar(userId: number, star: number): boolean
	local set = collected[userId]
	if not set then
		return false
	end
	return set[star] == true
end

function WinService.AddStar(userId: number, star: number): boolean
	if star < 1 or star > STAR_MAX then
		return false
	end
	if not collected[userId] then
		collected[userId] = {}
	end
	if collected[userId][star] then
		return false
	end
	collected[userId][star] = true
	for i = 1, STAR_MAX do
		if not collected[userId][i] then
			return false
		end
	end
	return true
end

function WinService.GetStarList(userId: number): { number }
	local set = collected[userId]
	if not set then
		return {}
	end
	local list: { number } = {}
	for i = 1, STAR_MAX do
		if set[i] then
			table.insert(list, i)
		end
	end
	return list
end

function WinService.GetAllCollections(): { [number]: { number } }
	local out: { [number]: { number } } = {}
	for userId, set in collected do
		local list: { number } = {}
		for i = 1, STAR_MAX do
			if set[i] then
				table.insert(list, i)
			end
		end
		out[userId] = list
	end
	return out
end

return WinService
