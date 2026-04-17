--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetRegistry = require(ReplicatedStorage.Config.AssetRegistry)
local VisualTheme = require(ReplicatedStorage.Config.VisualTheme)

local OrbVisuals = {}

local function rbxId(s: string): string?
	if s == "" or s == "rbxassetid://0" or s == "0" then
		return nil
	end
	return s
end

local function starDecalId(star: number): string?
	if star < 1 or star > 7 then
		return nil
	end
	local pack = AssetRegistry :: { [string]: string }
	local v = pack["Tex_DragonBall_Stars" .. tostring(star)]
	if typeof(v) ~= "string" then
		return nil
	end
	return rbxId(v)
end

function OrbVisuals.apply(orb: BasePart, star: number)
	orb.Material = Enum.Material.Glass
	orb.Color = VisualTheme.OrbBaseColor
	orb.Reflectance = 0.12
	orb.CastShadow = true

	local decalId = starDecalId(star)
	if decalId then
		local d = Instance.new("Decal")
		d.Name = "StarDecal"
		d.Face = Enum.NormalId.Front
		d.Texture = decalId
		d.Color3 = Color3.fromRGB(255, 255, 255)
		d.Transparency = 0.05
		d.Parent = orb
	end

	local att = Instance.new("Attachment")
	att.Name = "OrbVfxAttach"
	att.Parent = orb

	local pe = Instance.new("ParticleEmitter")
	pe.Name = "Sparkle"
	pe.Rate = 2.2
	pe.Lifetime = NumberRange.new(0.35, 0.75)
	pe.Speed = NumberRange.new(0.2, 1.2)
	pe.SpreadAngle = Vector2.new(12, 12)
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.12),
		NumberSequenceKeypoint.new(1, 0.02),
	})
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	pe.LightEmission = 0.85
	pe.Color = ColorSequence.new(VisualTheme.OrbSpecularHint, Color3.fromRGB(255, 220, 140))
	pe.Parent = att

	local pl = Instance.new("PointLight")
	pl.Name = "OrbGlow"
	pl.Range = 14
	pl.Brightness = 0.55
	pl.Color = Color3.fromRGB(255, 190, 120)
	pl.Shadows = false
	pl.Parent = orb

	local bb = Instance.new("BillboardGui")
	bb.Name = "StarCountBillboard"
	bb.AlwaysOnTop = false
	bb.Size = UDim2.new(0, 120, 0, 42)
	bb.StudsOffset = Vector3.new(0, 2.35, 0)
	bb.LightInfluence = 0.2
	bb.Parent = orb

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(200, 35, 35)
	label.TextStrokeTransparency = 0.4
	label.TextStrokeColor3 = Color3.fromRGB(40, 10, 10)
	label.Text = string.rep("★", star)
	label.Parent = bb
end

return OrbVisuals
