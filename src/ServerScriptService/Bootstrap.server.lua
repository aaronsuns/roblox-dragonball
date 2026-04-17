--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameRemotes = require(ReplicatedStorage.Remotes.GameRemotes)
GameRemotes.Ensure()

local GameStateManager = require(ServerScriptService.Game.GameStateManager)
GameStateManager.Init()
