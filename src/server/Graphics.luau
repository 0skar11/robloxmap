-- Creates the lighting effects every client uses. Each client then tweens Lighting and these
-- effects to its own group's mood (lobby, bright calm levels, dark horror levels); see the Mood
-- client script. Lighting.Technology = Future is set in the place file (default.project.json),
-- because scripts cannot change it.

local Lighting = game:GetService("Lighting")

local Graphics = {}

local function effect(className: string, name: string)
	local existing = Lighting:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
	local instance = Instance.new(className)
	instance.Name = name
	instance.Parent = Lighting
end

function Graphics.apply()
	-- Indoors everywhere: no sky light; rooms are lit by their own lights and the ambient.
	Lighting.ClockTime = 0
	Lighting.Brightness = 0
	Lighting.GlobalShadows = true
	Lighting.EnvironmentDiffuseScale = 0.3
	Lighting.EnvironmentSpecularScale = 0.4
	Lighting.Ambient = Color3.fromRGB(100, 100, 105)
	Lighting.OutdoorAmbient = Color3.fromRGB(70, 70, 75)

	for _, child in Lighting:GetChildren() do
		if child:IsA("Sky") or child:IsA("SunRaysEffect") then
			child:Destroy()
		end
	end

	effect("Atmosphere", "SubwayAir")
	effect("ColorCorrectionEffect", "SubwayGrade")
	effect("BloomEffect", "SubwayBloom")
end

return Graphics
