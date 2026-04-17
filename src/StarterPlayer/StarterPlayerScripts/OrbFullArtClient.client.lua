--!strict
--[[
	Server sets OrbFullImageUri + OrbId on each Dragon Ball part.
	BillboardGui under PlayerGui, Adornee = orb.

	This is a *sprite* (always faces the camera), not a sphere UV — that is normal, not a "perspective bug".
	For true surface mapping use Texture/MeshPart (heavier).

	Alignment: center on orb, no world lift. BillboardGui.Size Scale = stud size (per Roblox docs).
	Orphan billboards (destroyed adornee) are cleaned periodically.
]]

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local holder = playerGui:FindFirstChild("DragonBallOrbArtBillboards")
if not holder then
	local f = Instance.new("Folder")
	f.Name = "DragonBallOrbArtBillboards"
	f.Parent = playerGui
	holder = f
end
local holderFolder = holder :: Folder

local VisualTheme = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("VisualTheme") :: ModuleScript)

local ATTR = "OrbFullImageUri"
local CLIENT_GUI_PREFIX = "ClientOrbFullBillboard_"

local function clearBillboardsAdorning(orb: BasePart)
	for _, ch in holderFolder:GetChildren() do
		if ch:IsA("BillboardGui") and ch.Adornee == orb then
			ch:Destroy()
		end
	end
end

local function guiNameForOrbId(orbId: string): string
	return CLIENT_GUI_PREFIX .. string.gsub(orbId, "[^%w]", "_")
end

local function sweepOrphanBillboards()
	for _, ch in holderFolder:GetChildren() do
		if ch:IsA("BillboardGui") then
			local ad = ch.Adornee
			if not ad or not ad:IsDescendantOf(Workspace) then
				ch:Destroy()
			end
		end
	end
end

local sweepAcc = 0
RunService.Heartbeat:Connect(function(dt)
	sweepAcc += dt
	if sweepAcc < 2 then
		return
	end
	sweepAcc = 0
	sweepOrphanBillboards()
end)

local function ensureArt(orb: BasePart)
	local uri = orb:GetAttribute(ATTR)
	local orbId = orb:GetAttribute("OrbId")
	if typeof(uri) ~= "string" or uri == "" or uri == "rbxassetid://0" then
		clearBillboardsAdorning(orb)
		return
	end
	if typeof(orbId) ~= "string" or orbId == "" then
		return
	end

	clearBillboardsAdorning(orb)

	local bname = guiNameForOrbId(orbId)
	if holderFolder:FindFirstChild(bname) then
		return
	end

	local diameterStuds = orb.Size.Y * VisualTheme.OrbFullBillboardDiameterScale

	local bb = Instance.new("BillboardGui")
	bb.Name = bname
	bb.Adornee = orb
	bb.AlwaysOnTop = VisualTheme.OrbFullBillboardAlwaysOnTop
	bb.LightInfluence = 0
	bb.MaxDistance = 1_000_000
	-- Scale X/Y = stud size in 3D (Roblox BillboardGui.Size); offset = pixels — use 0 offset.
	bb.Size = UDim2.new(diameterStuds, 0, diameterStuds, 0)
	bb.StudsOffset = Vector3.zero
	bb.StudsOffsetWorldSpace = Vector3.zero
	bb.ResetOnSpawn = false
	bb.Parent = holderFolder

	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.Size = UDim2.fromScale(1, 1)
	img.Image = uri
	img.ScaleType = Enum.ScaleType.Fit
	img.Parent = bb

	pcall(function()
		ContentProvider:PreloadAsync({ img })
	end)

	if _G.__DragonBallOrbArtDebug == true then
		print("[OrbFullArtClient] billboard studs=", diameterStuds, "adornee=", orb:GetFullName())
	end

	orb.Destroying:Once(function()
		clearBillboardsAdorning(orb)
	end)
end

local function isDragonBallPart(inst: Instance): boolean
	return inst:IsA("BasePart") and string.match(inst.Name, "^DragonBall_%d+$") ~= nil
end

local function hookDescendant(desc: Instance)
	if not isDragonBallPart(desc) then
		return
	end
	local orb = desc :: BasePart
	task.defer(function()
		for _ = 1, 48 do
			if not orb.Parent then
				return
			end
			local uri = orb:GetAttribute(ATTR)
			local orbId = orb:GetAttribute("OrbId")
			if
				typeof(uri) == "string"
				and uri ~= ""
				and uri ~= "rbxassetid://0"
				and typeof(orbId) == "string"
				and orbId ~= ""
			then
				ensureArt(orb)
				return
			end
			task.wait()
		end
	end)
end

local function scanArena(folder: Instance)
	for _, d in folder:GetDescendants() do
		hookDescendant(d)
	end
end

local function wireArena(folder: Instance)
	scanArena(folder)
	folder.DescendantAdded:Connect(hookDescendant)
end

local arena = Workspace:FindFirstChild("DragonBallArena")
if arena then
	wireArena(arena)
else
	Workspace.ChildAdded:Connect(function(child)
		if child.Name == "DragonBallArena" then
			wireArena(child)
		end
	end)
end
