--!strict
--[[
	Keeps CameraMaxZoomDistance at GameConfig.CameraMaxZoomDistance so players cannot
	zoom far out for a full-arena view (complements the arena ceiling).
	Default PlayerModule may reset zoom after spawn; we re-apply a few times.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)

local player = Players.LocalPlayer
local target = GameConfig.CameraMaxZoomDistance

local function apply()
	-- Cap max zoom-out; do not raise if something else set a lower max.
	if player.CameraMaxZoomDistance > target then
		player.CameraMaxZoomDistance = target
	end
end

apply()
player:GetPropertyChangedSignal("CameraMaxZoomDistance"):Connect(apply)

local function scheduleRetries()
	task.defer(apply)
	task.delay(0.35, apply)
	task.delay(1, apply)
	task.delay(2.5, apply)
end

player.CharacterAdded:Connect(scheduleRetries)
scheduleRetries()
