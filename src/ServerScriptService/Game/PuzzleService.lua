--!strict

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local GameRemotes = require(ReplicatedStorage.Remotes.GameRemotes)

export type PuzzleKind = "Multiplication" | "RpsBestOf3"

export type ActiveSession = {
	id: string,
	kind: PuzzleKind,
	userId: number,
	orbId: string,
	star: number,
	-- multiplication
	mulA: number?,
	mulB: number?,
	mulDeadline: number?,
	-- rps
	rpsYour: number,
	rpsOpp: number,
	rpsRound: number,
}

local PuzzleService = {}
local remotes = GameRemotes.Ensure()
local sessions: { [number]: ActiveSession } = {}
local onSolved: ((Player, string, number) -> ())? = nil
local onFailed: ((Player, string) -> ())? = nil

local function closeFor(player: Player, success: boolean)
	local uid = player.UserId
	local session = sessions[uid]
	sessions[uid] = nil
	remotes.PuzzleClosed:FireClient(player, success)
end

local function beats(a: number, b: number): number
	-- 0 rock 1 paper 2 scissors; returns 1 if a wins, -1 if b wins, 0 tie
	if a == b then
		return 0
	end
	if (a == 0 and b == 2) or (a == 1 and b == 0) or (a == 2 and b == 1) then
		return 1
	end
	return -1
end

function PuzzleService.Init(onSolvedCb: (Player, string, number) -> (), onFailedCb: (Player, string) -> ())
	onSolved = onSolvedCb
	onFailed = onFailedCb

	remotes.SubmitPuzzle.OnServerEvent:Connect(function(player: Player, payload: any)
		if typeof(payload) ~= "table" then
			return
		end
		local session = sessions[player.UserId]
		if not session then
			return
		end
		local now = workspace:GetServerTimeNow()

		if session.kind == "Multiplication" then
			local answer = payload.answer
			if typeof(answer) ~= "number" then
				return
			end
			local deadline = session.mulDeadline or 0
			if now > deadline then
				closeFor(player, false)
				if onFailed then
					onFailed(player, session.orbId)
				end
				return
			end
			local a, b = session.mulA or 0, session.mulB or 0
			if math.floor(answer + 0.5) == a * b then
				local orbId, star = session.orbId, session.star
				sessions[player.UserId] = nil
				remotes.PuzzleClosed:FireClient(player, true)
				if onSolved then
					onSolved(player, orbId, star)
				end
			else
				closeFor(player, false)
				if onFailed then
					onFailed(player, session.orbId)
				end
			end
			return
		end

		if session.kind == "RpsBestOf3" then
			local choice = payload.choice
			if typeof(choice) ~= "number" or choice < 0 or choice > 2 then
				return
			end
			local deadline = session.mulDeadline -- reuse field for round deadline
			if deadline and now > deadline then
				closeFor(player, false)
				if onFailed then
					onFailed(player, session.orbId)
				end
				return
			end
			local cpu = math.random(0, 2)
			local outcome = beats(choice, cpu)
			if outcome == 1 then
				session.rpsYour += 1
			elseif outcome == -1 then
				session.rpsOpp += 1
			end
			session.rpsRound += 1

			if session.rpsYour >= 2 then
				local orbId, star = session.orbId, session.star
				sessions[player.UserId] = nil
				remotes.PuzzleClosed:FireClient(player, true)
				if onSolved then
					onSolved(player, orbId, star)
				end
				return
			end
			if session.rpsOpp >= 2 then
				closeFor(player, false)
				if onFailed then
					onFailed(player, session.orbId)
				end
				return
			end
			if session.rpsRound >= 7 then
				closeFor(player, false)
				if onFailed then
					onFailed(player, session.orbId)
				end
				return
			end

			session.mulDeadline = workspace:GetServerTimeNow() + GameConfig.RpsRoundTimeoutSeconds
			remotes.OpenPuzzle:FireClient(player, {
				sessionId = session.id,
				kind = "RpsBestOf3",
				star = session.star,
				yourWins = session.rpsYour,
				oppWins = session.rpsOpp,
				roundIndex = session.rpsRound,
				maxRounds = 5,
				expiresAtUnix = session.mulDeadline,
				lastRound = {
					yours = choice,
					cpu = cpu,
				},
			})
			return
		end
	end)
end

function PuzzleService.CancelForPlayer(player: Player)
	sessions[player.UserId] = nil
	remotes.PuzzleClosed:FireClient(player, false)
end

function PuzzleService.Begin(player: Player, orbId: string, star: number): boolean
	if sessions[player.UserId] then
		return false
	end
	local mul = math.random() < 0.5
	local session: ActiveSession = {
		id = HttpService:GenerateGUID(false),
		kind = mul and "Multiplication" or "RpsBestOf3",
		userId = player.UserId,
		orbId = orbId,
		star = star,
		mulA = nil,
		mulB = nil,
		mulDeadline = nil,
		rpsYour = 0,
		rpsOpp = 0,
		rpsRound = 0,
	}

	if session.kind == "Multiplication" then
		session.mulA = math.random(1, 10)
		session.mulB = math.random(1, 10)
		session.mulDeadline = workspace:GetServerTimeNow() + GameConfig.MultiplicationTimeoutSeconds
		sessions[player.UserId] = session
		remotes.OpenPuzzle:FireClient(player, {
			sessionId = session.id,
			kind = "Multiplication",
			star = star,
			a = session.mulA,
			b = session.mulB,
			expiresAtUnix = session.mulDeadline,
		})
	else
		session.mulDeadline = workspace:GetServerTimeNow() + GameConfig.RpsRoundTimeoutSeconds
		sessions[player.UserId] = session
		remotes.OpenPuzzle:FireClient(player, {
			sessionId = session.id,
			kind = "RpsBestOf3",
			star = star,
			yourWins = 0,
			oppWins = 0,
			roundIndex = 0,
			maxRounds = 5,
			expiresAtUnix = session.mulDeadline,
		})
	end
	return true
end

return PuzzleService
