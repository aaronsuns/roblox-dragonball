--!strict
--[[
	Central look for M0 "Namek-inspired" pass + Dragon Ball materials.
	Tweak RGB values here; LightingTheme.server.lua reads this module.
]]

local VisualTheme = {
	UseNamekLighting = true,

	-- Ground tiles (grass)
	GrassColor = Color3.fromRGB(86, 148, 118),
	GrassNoiseMix = Color3.fromRGB(62, 120, 98),

	-- Dragon Ball base tint (amber crystal)
	OrbBaseColor = Color3.fromRGB(255, 168, 58),
	OrbSpecularHint = Color3.fromRGB(255, 245, 210),

	-- Lighting snapshot (applied on server boot)
	Lighting = {
		ClockTime = 16.5,
		GeographicLatitude = 10,
		Brightness = 2.1,
		OutdoorAmbient = Color3.fromRGB(110, 165, 145),
		Ambient = Color3.fromRGB(70, 110, 95),
		ColorShift_Top = Color3.fromRGB(140, 210, 175),
		ColorShift_Bottom = Color3.fromRGB(60, 95, 85),
		EnvironmentDiffuseScale = 0.35,
		EnvironmentSpecularScale = 0.45,
	},

	Atmosphere = {
		Density = 0.35,
		Offset = 0.15,
		Color = Color3.fromRGB(120, 185, 165),
		Decay = Color3.fromRGB(80, 130, 115),
		Glare = 0.2,
		Haze = 1.8,
	},

	ColorCorrection = {
		Brightness = 0.03,
		Contrast = 0.08,
		Saturation = 0.12,
		TintColor = Color3.fromRGB(235, 255, 248),
	},
}

return table.freeze(VisualTheme)
