--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local GameRemotes = require(ReplicatedStorage.Remotes.GameRemotes)

local ShenronCinematicService = {}
local remotes = GameRemotes.Ensure()

function ShenronCinematicService.Play(winner: Player)
	local duration = GameConfig.ShenronCinematicSeconds
	remotes.InputLock:FireAllClients(true)
	remotes.Cinematic:FireAllClients({
		kind = "ShenronSpawn",
		winnerUserId = winner.UserId,
		winnerName = winner.DisplayName,
		duration = duration,
	})
end

function ShenronCinematicService.ReleaseInputLock()
	remotes.InputLock:FireAllClients(false)
end

return ShenronCinematicService
