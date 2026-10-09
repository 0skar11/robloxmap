-- Dark, cold look for the whole server: no sky light, thick dark air, muted colors and a little
-- bloom so the few working lights glow. Lighting.Technology = Future is set in the place file
-- (default.project.json), because scripts cannot change it.

local Lighting = game:GetService("Lighting")

local Graphics = {}

local function effect(className: string, name: string, properties: { [string]: any })
	local existing = Lighting:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
	local instance = Instance.new(className)
	instance.Name = name
	for key, value in properties do
		(instance :: any)[key] = value
	end
	instance.Parent = Lighting
end

function Graphics.apply()
	Lighting.ClockTime = 0
	Lighting.Brightness = 0
	Lighting.Ambient = Color3.fromRGB(14, 14, 18)
	Lighting.OutdoorAmbient = Color3.new(0, 0, 0)
	Lighting.EnvironmentDiffuseScale = 0
	Lighting.EnvironmentSpecularScale = 0.4
	Lighting.GlobalShadows = true
	Lighting.ExposureCompensation = -0.2

	-- Remove the default sky and sun effects a new place ships with.
	for _, child in Lighting:GetChildren() do
		if child:IsA("Sky") or child:IsA("SunRaysEffect") then
			child:Destroy()
		end
	end

	effect("Atmosphere", "SubwayAir", {
		Density = 0.42,
		Offset = 0,
		Color = Color3.fromRGB(20, 20, 24),
		Decay = Color3.fromRGB(10, 10, 12),
		Glare = 0,
		Haze = 2.2,
	})
	effect("ColorCorrectionEffect", "SubwayGrade", {
		Brightness = -0.03,
		Contrast = 0.18,
		Saturation = -0.35,
		TintColor = Color3.fromRGB(225, 232, 240),
	})
	effect("BloomEffect", "SubwayBloom", {
		Intensity = 0.7,
		Size = 30,
		Threshold = 1.4,
	})
end

return Graphics
