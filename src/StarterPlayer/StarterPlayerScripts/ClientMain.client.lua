--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local GameRemotes = require(ReplicatedStorage.Remotes.GameRemotes)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local remotes = GameRemotes.Ensure()

local savedWalkSpeed: number? = nil
local savedJumpPower: number? = nil

local function getHumanoid(): Humanoid?
	local char = player.Character
	if not char then
		return nil
	end
	return char:FindFirstChildOfClass("Humanoid")
end

local function applyInputLock(locked: boolean)
	local hum = getHumanoid()
	if not hum then
		return
	end
	if locked then
		if savedWalkSpeed == nil then
			savedWalkSpeed = hum.WalkSpeed
			savedJumpPower = hum.JumpPower
		end
		hum.WalkSpeed = 0
		hum.JumpPower = 0
	else
		hum.WalkSpeed = savedWalkSpeed or 16
		hum.JumpPower = savedJumpPower or 50
		savedWalkSpeed = nil
		savedJumpPower = nil
	end
end

player.CharacterAdded:Connect(function()
	task.defer(function()
		applyInputLock(false)
	end)
end)

remotes.InputLock.OnClientEvent:Connect(function(locked: any)
	if typeof(locked) == "boolean" then
		applyInputLock(locked)
	end
end)

-- HUD
local hudGui = Instance.new("ScreenGui")
hudGui.Name = "DragonBallHUD"
hudGui.ResetOnSpawn = false
hudGui.IgnoreGuiInset = true
hudGui.Parent = playerGui

local phaseLabel = Instance.new("TextLabel")
phaseLabel.Size = UDim2.new(0.4, 0, 0, 28)
phaseLabel.Position = UDim2.new(0.02, 0, 0.02, 0)
phaseLabel.BackgroundTransparency = 0.35
phaseLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
phaseLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
phaseLabel.Font = Enum.Font.GothamBold
phaseLabel.TextScaled = true
phaseLabel.Text = "阶段: Lobby"
phaseLabel.Parent = hudGui

local starRow = Instance.new("Frame")
starRow.Name = "StarRow"
starRow.Size = UDim2.new(0.5, 0, 0, 40)
starRow.Position = UDim2.new(0.02, 0, 0.08, 0)
starRow.BackgroundTransparency = 1
starRow.Parent = hudGui

local starTiles: { TextLabel } = {}
for i = 1, 7 do
	local tile = Instance.new("TextLabel")
	tile.Size = UDim2.new(0, 36, 0, 36)
	tile.Position = UDim2.new(0, (i - 1) * 42, 0, 0)
	tile.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
	tile.TextColor3 = Color3.fromRGB(200, 200, 200)
	tile.Text = tostring(i)
	tile.Font = Enum.Font.GothamBold
	tile.TextScaled = true
	tile.Parent = starRow
	table.insert(starTiles, tile)
end

local function updateStarsFromPayload(payload: any)
	if typeof(payload) ~= "table" then
		return
	end
	local collections = payload.collections
	if typeof(collections) ~= "table" then
		return
	end
	local mine = collections[tostring(player.UserId)]
	if typeof(mine) ~= "table" then
		mine = {}
	end
	local have: { [number]: boolean } = {}
	for _, v in mine do
		if typeof(v) == "number" then
			have[v] = true
		end
	end
	for i = 1, 7 do
		local tile = starTiles[i]
		if have[i] then
			tile.BackgroundColor3 = Color3.fromRGB(230, 180, 40)
			tile.TextColor3 = Color3.fromRGB(30, 20, 0)
		else
			tile.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
			tile.TextColor3 = Color3.fromRGB(200, 200, 200)
		end
	end
end

remotes.GameState.OnClientEvent:Connect(function(payload: any)
	if typeof(payload) == "table" and typeof(payload.phase) == "string" then
		phaseLabel.Text = "阶段: " .. payload.phase
	end
end)

remotes.CollectionSync.OnClientEvent:Connect(updateStarsFromPayload)

-- Puzzle overlay
local puzzleGui = Instance.new("ScreenGui")
puzzleGui.Name = "DragonBallPuzzle"
puzzleGui.ResetOnSpawn = false
puzzleGui.Enabled = false
puzzleGui.IgnoreGuiInset = true
puzzleGui.Parent = playerGui

local backdrop = Instance.new("Frame")
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
backdrop.BackgroundTransparency = 0.35
backdrop.Parent = puzzleGui

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 420, 0, 320)
panel.Position = UDim2.new(0.5, -210, 0.5, -160)
panel.BackgroundColor3 = Color3.fromRGB(25, 28, 40)
panel.Parent = puzzleGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 40)
title.Position = UDim2.new(0, 10, 0, 10)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = "谜题"
title.Parent = panel

local body = Instance.new("TextLabel")
body.Size = UDim2.new(1, -20, 0, 60)
body.Position = UDim2.new(0, 10, 0, 55)
body.BackgroundTransparency = 1
body.Font = Enum.Font.Gotham
body.TextWrapped = true
body.TextSize = 20
body.TextColor3 = Color3.fromRGB(230, 230, 230)
body.Text = ""
body.Parent = panel

local inputBox = Instance.new("TextBox")
inputBox.Size = UDim2.new(1, -20, 0, 40)
inputBox.Position = UDim2.new(0, 10, 0, 130)
inputBox.ClearTextOnFocus = false
inputBox.Text = ""
inputBox.PlaceholderText = "输入答案"
inputBox.Visible = false
inputBox.Parent = panel

local submitBtn = Instance.new("TextButton")
submitBtn.Size = UDim2.new(0.45, 0, 0, 40)
submitBtn.Position = UDim2.new(0.05, 0, 0, 200)
submitBtn.Text = "提交"
submitBtn.Font = Enum.Font.GothamBold
submitBtn.TextScaled = true
submitBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
submitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
submitBtn.Parent = panel

local rpsRow = Instance.new("Frame")
rpsRow.Size = UDim2.new(1, -20, 0, 50)
rpsRow.Position = UDim2.new(0, 10, 0, 130)
rpsRow.BackgroundTransparency = 1
rpsRow.Visible = false
rpsRow.Parent = panel

local rpsNames = { "石头", "布", "剪刀" }
local rpsButtons: { TextButton } = {}
for i = 0, 2 do
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, 110, 1, 0)
	b.Position = UDim2.new(0, i * 120, 0, 0)
	b.Text = rpsNames[i + 1]
	b.Font = Enum.Font.GothamBold
	b.TextScaled = true
	b.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Parent = rpsRow
	table.insert(rpsButtons, b)
end

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0.45, 0, 0, 40)
closeBtn.Position = UDim2.new(0.5, 0, 0, 200)
closeBtn.Text = "关闭"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextScaled = true
closeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Parent = panel

local currentKind: string? = nil

local function hidePuzzle()
	puzzleGui.Enabled = false
	currentKind = nil
	inputBox.Visible = false
	rpsRow.Visible = false
	inputBox.Text = ""
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

closeBtn.MouseButton1Click:Connect(function()
	hidePuzzle()
end)

submitBtn.MouseButton1Click:Connect(function()
	if currentKind == "Multiplication" then
		local n = tonumber(inputBox.Text)
		if n then
			remotes.SubmitPuzzle:FireServer({ answer = n })
		end
	end
end)

for idx, b in ipairs(rpsButtons) do
	local choice = idx - 1
	b.MouseButton1Click:Connect(function()
		if currentKind == "RpsBestOf3" then
			remotes.SubmitPuzzle:FireServer({ choice = choice })
		end
	end)
end

remotes.OpenPuzzle.OnClientEvent:Connect(function(payload: any)
	if typeof(payload) ~= "table" then
		return
	end
	puzzleGui.Enabled = true
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	local kind = payload.kind
	currentKind = kind
	title.Text = "获得 " .. tostring(payload.star) .. " 星球"
	if kind == "Multiplication" then
		inputBox.Visible = true
		rpsRow.Visible = false
		body.Text = string.format("计算: %d × %d = ?", payload.a or 0, payload.b or 0)
		inputBox.Text = ""
	elseif kind == "RpsBestOf3" then
		inputBox.Visible = false
		rpsRow.Visible = true
		local yours = payload.lastRound and payload.lastRound.yours
		local cpu = payload.lastRound and payload.lastRound.cpu
		local extra = ""
		if typeof(yours) == "number" and typeof(cpu) == "number" then
			extra = string.format("\n上轮: 你 %s vs CPU %s", rpsNames[yours + 1], rpsNames[cpu + 1])
		end
		body.Text = string.format(
			"三局两胜石头剪刀布\n比分 %d : %d%s",
			payload.yourWins or 0,
			payload.oppWins or 0,
			extra
		)
	end
end)

remotes.PuzzleClosed.OnClientEvent:Connect(function(_success: any)
	hidePuzzle()
end)

-- Cinematic overlay
local cineGui = Instance.new("ScreenGui")
cineGui.Name = "DragonBallCinematic"
cineGui.ResetOnSpawn = false
cineGui.Enabled = false
cineGui.IgnoreGuiInset = true
cineGui.Parent = playerGui

local cineFrame = Instance.new("Frame")
cineFrame.Size = UDim2.new(1, 0, 1, 0)
cineFrame.BackgroundColor3 = Color3.fromRGB(5, 15, 8)
cineFrame.BackgroundTransparency = 0.15
cineFrame.Parent = cineGui

local cineLabel = Instance.new("TextLabel")
cineLabel.Size = UDim2.new(0.8, 0, 0.2, 0)
cineLabel.Position = UDim2.new(0.1, 0, 0.35, 0)
cineLabel.BackgroundTransparency = 1
cineLabel.Font = Enum.Font.GothamBold
cineLabel.TextScaled = true
cineLabel.TextColor3 = Color3.fromRGB(120, 255, 160)
cineLabel.Text = "神龙现身"
cineLabel.Parent = cineGui

local cineSub = Instance.new("TextLabel")
cineSub.Size = UDim2.new(0.8, 0, 0.1, 0)
cineSub.Position = UDim2.new(0.1, 0, 0.56, 0)
cineSub.BackgroundTransparency = 1
cineSub.Font = Enum.Font.Gotham
cineSub.TextScaled = true
cineSub.TextColor3 = Color3.fromRGB(230, 255, 235)
cineSub.Text = ""
cineSub.Parent = cineGui

local bar = Instance.new("Frame")
bar.Size = UDim2.new(0.6, 0, 0, 8)
bar.Position = UDim2.new(0.2, 0, 0.7, 0)
bar.BackgroundColor3 = Color3.fromRGB(40, 60, 50)
bar.Parent = cineGui

local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(90, 255, 140)
barFill.Parent = bar

remotes.Cinematic.OnClientEvent:Connect(function(payload: any)
	if typeof(payload) ~= "table" or payload.kind ~= "ShenronSpawn" then
		return
	end
	cineGui.Enabled = true
	cineSub.Text = "胜者: " .. tostring(payload.winnerName or "")
	local duration = typeof(payload.duration) == "number" and payload.duration or 10
	barFill.Size = UDim2.new(0, 0, 1, 0)
	local tw = TweenService:Create(barFill, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		Size = UDim2.new(1, 0, 1, 0),
	})
	tw:Play()
	task.delay(duration, function()
		cineGui.Enabled = false
	end)
end)

remotes.MatchResult.OnClientEvent:Connect(function(payload: any)
	if typeof(payload) ~= "table" then
		return
	end
	phaseLabel.Text = "胜者: " .. tostring(payload.winnerName or "")
end)
