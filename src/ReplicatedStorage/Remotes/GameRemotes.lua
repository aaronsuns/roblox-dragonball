--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NAMES = {
	Folder = "DragonBallRemotes",
	GameState = "GameState",
	CollectionSync = "CollectionSync",
	OpenPuzzle = "OpenPuzzle",
	SubmitPuzzle = "SubmitPuzzle",
	PuzzleClosed = "PuzzleClosed",
	MatchResult = "MatchResult",
	Cinematic = "Cinematic",
	InputLock = "InputLock",
}

export type RemotesBundle = {
	GameState: RemoteEvent,
	CollectionSync: RemoteEvent,
	OpenPuzzle: RemoteEvent,
	SubmitPuzzle: RemoteEvent,
	PuzzleClosed: RemoteEvent,
	MatchResult: RemoteEvent,
	Cinematic: RemoteEvent,
	InputLock: RemoteEvent,
}

local serverFolder: Folder? = nil
local cached: RemotesBundle? = nil

local function ensureRemoteEventOnServer(parent: Folder, name: string): RemoteEvent
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	if existing then
		existing:Destroy()
	end
	local ev = Instance.new("RemoteEvent")
	ev.Name = name
	ev.Parent = parent
	return ev
end

local function getOrCreateServerFolder(): Folder
	if serverFolder and serverFolder.Parent then
		return serverFolder
	end
	local f = ReplicatedStorage:FindFirstChild(NAMES.Folder)
	if f and f:IsA("Folder") then
		serverFolder = f
		return f
	end
	local created = Instance.new("Folder")
	created.Name = NAMES.Folder
	created.Parent = ReplicatedStorage
	serverFolder = created
	return created
end

local function ensureServer(): RemotesBundle
	local parent = getOrCreateServerFolder()
	local bundle: RemotesBundle = {
		GameState = ensureRemoteEventOnServer(parent, NAMES.GameState),
		CollectionSync = ensureRemoteEventOnServer(parent, NAMES.CollectionSync),
		OpenPuzzle = ensureRemoteEventOnServer(parent, NAMES.OpenPuzzle),
		SubmitPuzzle = ensureRemoteEventOnServer(parent, NAMES.SubmitPuzzle),
		PuzzleClosed = ensureRemoteEventOnServer(parent, NAMES.PuzzleClosed),
		MatchResult = ensureRemoteEventOnServer(parent, NAMES.MatchResult),
		Cinematic = ensureRemoteEventOnServer(parent, NAMES.Cinematic),
		InputLock = ensureRemoteEventOnServer(parent, NAMES.InputLock),
	}
	cached = bundle
	return bundle
end

local function waitClient(): RemotesBundle
	if cached then
		return cached
	end
	local parent = ReplicatedStorage:WaitForChild(NAMES.Folder, 60) :: Folder
	local function waitEv(name: string): RemoteEvent
		return parent:WaitForChild(name, 60) :: RemoteEvent
	end
	local bundle: RemotesBundle = {
		GameState = waitEv(NAMES.GameState),
		CollectionSync = waitEv(NAMES.CollectionSync),
		OpenPuzzle = waitEv(NAMES.OpenPuzzle),
		SubmitPuzzle = waitEv(NAMES.SubmitPuzzle),
		PuzzleClosed = waitEv(NAMES.PuzzleClosed),
		MatchResult = waitEv(NAMES.MatchResult),
		Cinematic = waitEv(NAMES.Cinematic),
		InputLock = waitEv(NAMES.InputLock),
	}
	cached = bundle
	return bundle
end

local GameRemotes = {
	Names = NAMES,
	GetFolder = function(): Folder
		if RunService:IsServer() then
			return getOrCreateServerFolder()
		end
		return ReplicatedStorage:WaitForChild(NAMES.Folder, 60) :: Folder
	end,
	Ensure = function(): RemotesBundle
		if RunService:IsServer() then
			return ensureServer()
		end
		return waitClient()
	end,
}

return table.freeze(GameRemotes)
