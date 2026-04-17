--!strict

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VisualTheme = require(ReplicatedStorage.Config.VisualTheme)

if not VisualTheme.UseNamekLighting then
	return
end

local L = VisualTheme.Lighting
Lighting.ClockTime = L.ClockTime
Lighting.GeographicLatitude = L.GeographicLatitude
Lighting.Brightness = L.Brightness
Lighting.OutdoorAmbient = L.OutdoorAmbient
Lighting.Ambient = L.Ambient
Lighting.ColorShift_Top = L.ColorShift_Top
Lighting.ColorShift_Bottom = L.ColorShift_Bottom
Lighting.EnvironmentDiffuseScale = L.EnvironmentDiffuseScale
Lighting.EnvironmentSpecularScale = L.EnvironmentSpecularScale

local atm = Lighting:FindFirstChildOfClass("Atmosphere")
if not atm then
	atm = Instance.new("Atmosphere")
	atm.Parent = Lighting
end
local A = VisualTheme.Atmosphere
atm.Density = A.Density
atm.Offset = A.Offset
atm.Color = A.Color
atm.Decay = A.Decay
atm.Glare = A.Glare
atm.Haze = A.Haze

local cc = Lighting:FindFirstChild("DragonBallColorCorrection")
if not cc or not cc:IsA("ColorCorrectionEffect") then
	if cc then
		cc:Destroy()
	end
	cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "DragonBallColorCorrection"
	cc.Parent = Lighting
end
local C = VisualTheme.ColorCorrection
cc.Brightness = C.Brightness
cc.Contrast = C.Contrast
cc.Saturation = C.Saturation
cc.TintColor = C.TintColor

print("[DragonBall] Applied VisualTheme lighting (Namek-inspired M0)")
