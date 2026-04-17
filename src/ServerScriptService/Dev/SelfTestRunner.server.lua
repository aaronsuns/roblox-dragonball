--!strict

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if not RunService:IsStudio() then
	return
end

task.defer(function()
	local SelfTest = require(ReplicatedStorage.Shared.SelfTest)
	local errs = SelfTest.run()
	if #errs == 0 then
		print("[DragonBall SelfTest] OK")
	else
		for _, e in errs do
			warn("[DragonBall SelfTest] " .. e)
		end
	end
end)
