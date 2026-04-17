--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)

local ArenaSafety = {}

local heartbeatConn: RBXScriptConnection? = nil
local getPhase: (() -> string)? = nil
local rescueCFrame: CFrame = CFrame.new(0, 20, 0)
local lastRescueCFrame: CFrame? = nil
local rescueCooldown: { [number]: number } = {}

local function disconnect()
	if heartbeatConn then
		heartbeatConn:Disconnect()
		heartbeatConn = nil
	end
	rescueCooldown = {}
end

function ArenaSafety.endMatch()
	disconnect()
	lastRescueCFrame = nil
end

function ArenaSafety.teleportToRescue(player: Player): boolean
	if not lastRescueCFrame then
		return false
	end
	if getPhase and getPhase() ~= "InMatch" then
		return false
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return false
	end
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.CFrame = lastRescueCFrame :: CFrame
	return true
end

function ArenaSafety.beginMatch(map: { rimRadius: number, spawnA: CFrame, baseY: number }, phaseGetter: () -> string)
	disconnect()
	getPhase = phaseGetter
	rescueCFrame = map.spawnA * CFrame.new(0, 10, 0)
	lastRescueCFrame = rescueCFrame

	local maxR = map.rimRadius + GameConfig.FallRescueRadiusExtra
	local belowY = math.min(GameConfig.FallRescueBelowY, map.baseY - 1)

	heartbeatConn = RunService.Heartbeat:Connect(function()
		if getPhase and getPhase() ~= "InMatch" then
			return
		end
		local now = os.clock()
		for _, plr in Players:GetPlayers() do
			local char = plr.Character
			if char then
				local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hrp and hum and hum.Health > 0 then
					local p = hrp.Position
					local horiz = Vector2.new(p.X, p.Z).Magnitude
					if p.Y < belowY and horiz < maxR then
						local untilOk = rescueCooldown[plr.UserId] or 0
						if now >= untilOk then
							rescueCooldown[plr.UserId] = now + 1.2
							hrp.AssemblyLinearVelocity = Vector3.zero
							hrp.AssemblyAngularVelocity = Vector3.zero
							hrp.CFrame = rescueCFrame
						end
					end
				end
			end
		end
	end)
end

return ArenaSafety
