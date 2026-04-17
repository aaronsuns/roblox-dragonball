--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local GameRemotes = require(ReplicatedStorage.Remotes.GameRemotes)

local SelfTest = {}

function SelfTest.run(): { string }
	local errors: { string } = {}

	if GameConfig.OrbCount ~= 7 then
		table.insert(errors, "GameConfig.OrbCount should be 7 for current MVP rules")
	end
	if GameConfig.ArenaBaseY < 0 then
		table.insert(errors, "GameConfig.ArenaBaseY should be non-negative")
	end

	local ok, rem = pcall(function()
		return GameRemotes.Ensure()
	end)
	if not ok then
		table.insert(errors, "GameRemotes.Ensure threw: " .. tostring(rem))
	else
		if rem.GameState.Name ~= "GameState" then
			table.insert(errors, "GameState remote missing or misnamed")
		end
	end

	return errors
end

return SelfTest
