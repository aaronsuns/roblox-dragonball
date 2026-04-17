--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetRegistry = require(ReplicatedStorage.Config.AssetRegistry)
local VisualTheme = require(ReplicatedStorage.Config.VisualTheme)

local OrbVisuals = {}

-- Client reads this attribute and parents a BillboardGui (see OrbFullArtClient.client.lua).
local ORB_FULL_IMAGE_ATTR = "OrbFullImageUri"

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

local function fullOrbId(star: number): string?
	if star < 1 or star > 7 then
		return nil
	end
	local pack = AssetRegistry :: { [string]: string }
	local v = pack["Tex_DragonBall_OrbFull" .. tostring(star)]
	if typeof(v) ~= "string" then
		return nil
	end
	return rbxId(v)
end

function OrbVisuals.apply(orb: BasePart, star: number)
	local fullId = fullOrbId(star)
	local decalId = starDecalId(star)

	if fullId then
		-- World BillboardGui + Image created on the server often fails to show textures in play.
		-- Publish the URI as an attribute; StarterPlayerScripts/OrbFullArtClient.client.lua draws it locally.
		orb:SetAttribute(ORB_FULL_IMAGE_ATTR, fullId)
		-- Hide the mesh: the PNG already draws the whole sphere; keeping a white ball looks "double" / wrong depth.
		orb.Material = Enum.Material.SmoothPlastic
		orb.Color = Color3.fromRGB(255, 255, 255)
		orb.Reflectance = 0
		orb.Transparency = 1
		orb.CastShadow = false
	elseif decalId then
		orb:SetAttribute(ORB_FULL_IMAGE_ATTR, nil)
		orb.Material = Enum.Material.Glass
		orb.Color = VisualTheme.OrbBaseColor
		orb.Reflectance = 0.12
		orb.Transparency = 0
		orb.CastShadow = true

		local d = Instance.new("Decal")
		d.Name = "StarDecal"
		d.Face = Enum.NormalId.Front
		d.Texture = decalId
		d.Color3 = Color3.fromRGB(255, 255, 255)
		d.Transparency = 0.05
		d.Parent = orb
	else
		orb:SetAttribute(ORB_FULL_IMAGE_ATTR, nil)
		orb.Material = Enum.Material.Glass
		orb.Color = VisualTheme.OrbBaseColor
		orb.Reflectance = 0.12
		orb.Transparency = 0
		orb.CastShadow = true
	end

	-- Particles at center (inside glow)
	local vfxAttach = Instance.new("Attachment")
	vfxAttach.Name = "OrbVfxAttach"
	vfxAttach.Position = Vector3.zero
	vfxAttach.Parent = orb

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
	pe.Parent = vfxAttach

	local pl = Instance.new("PointLight")
	pl.Name = "OrbGlow"
	pl.Range = 14
	pl.Brightness = 0.55
	pl.Color = Color3.fromRGB(255, 190, 120)
	pl.Shadows = false
	pl.Parent = orb

	-- Floating ★ row when no full art and no star decal
	if not fullId and not decalId then
		local bb = Instance.new("BillboardGui")
		bb.Name = "StarCountBillboard"
		bb.AlwaysOnTop = false
		bb.Size = UDim2.fromOffset(112, 40)
		bb.StudsOffset = Vector3.new(0, VisualTheme.OrbStarBillboardStudsOffsetY, 0)
		bb.LightInfluence = 0.35
		bb.MaxDistance = 80
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
end

return OrbVisuals
