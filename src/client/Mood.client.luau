-- Local look of the world, from the player's "Mood" attribute:
--   Lobby   bright, warm hall
--   Calm    levels 1-5: a normal, bright, slightly cheerful station
--   Horror  level 6 on: dark, foggy and gloomy (colors drained to grey-green), with a dim
--           personal light so you can still see
-- Lighting changes made here only affect this player, so groups never fight over the look.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local TWEEN = TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local LOOKS = {
	Lobby = {
		Lighting = { Ambient = Color3.fromRGB(88, 86, 83), OutdoorAmbient = Color3.fromRGB(64, 64, 64), ExposureCompensation = 0.1 },
		SubwayAir = { Density = 0.08, Haze = 0, Color = Color3.fromRGB(200, 195, 185), Decay = Color3.fromRGB(150, 145, 135) },
		SubwayGrade = { Brightness = 0.02, Contrast = 0.05, Saturation = 0.1, TintColor = Color3.fromRGB(255, 250, 242) },
		SubwayBloom = { Intensity = 0.4, Size = 24, Threshold = 1.6 },
		PersonalLight = false,
	},
	Calm = {
		Lighting = { Ambient = Color3.fromRGB(95, 93, 88), OutdoorAmbient = Color3.fromRGB(64, 64, 64), ExposureCompensation = 0.15 },
		SubwayAir = { Density = 0.1, Haze = 0, Color = Color3.fromRGB(205, 200, 190), Decay = Color3.fromRGB(160, 155, 145) },
		SubwayGrade = { Brightness = 0.03, Contrast = 0.06, Saturation = 0.2, TintColor = Color3.fromRGB(255, 248, 236) },
		SubwayBloom = { Intensity = 0.5, Size = 24, Threshold = 1.5 },
		PersonalLight = false,
	},
	Horror = {
		Lighting = { Ambient = Color3.fromRGB(34, 34, 41), OutdoorAmbient = Color3.fromRGB(8, 8, 10), ExposureCompensation = -0.05 },
		SubwayAir = { Density = 0.32, Haze = 1.6, Color = Color3.fromRGB(22, 22, 28), Decay = Color3.fromRGB(12, 12, 15) },
		-- Gloomy: colors drained almost to grey, with a cold, sickly green-grey cast.
		SubwayGrade = { Brightness = -0.04, Contrast = 0.22, Saturation = -0.7, TintColor = Color3.fromRGB(205, 215, 205) },
		SubwayBloom = { Intensity = 0.8, Size = 30, Threshold = 1.3 },
		PersonalLight = true,
	},
}

local personalLight: PointLight? = nil

local function updatePersonalLight(enabled: boolean)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local light = personalLight
	if not light or light.Parent ~= root then
		light = Instance.new("PointLight")
		light.Name = "PersonalLight"
		light.Color = Color3.fromRGB(200, 210, 230)
		light.Range = 14
		light.Brightness = 0.7
		light.Shadows = false
		light.Parent = root
		personalLight = light
	end
	light.Enabled = enabled
end

local function apply()
	local look = LOOKS[player:GetAttribute("Mood") or "Lobby"] or LOOKS.Lobby
	TweenService:Create(Lighting, TWEEN, look.Lighting):Play()
	for name, goal in look do
		local instance = Lighting:FindFirstChild(name)
		if instance and type(goal) == "table" then
			TweenService:Create(instance, TWEEN, goal):Play()
		end
	end
	updatePersonalLight(look.PersonalLight)
end

player:GetAttributeChangedSignal("Mood"):Connect(apply)
player.CharacterAdded:Connect(function(character)
	character:WaitForChild("HumanoidRootPart", 10)
	apply()
end)
-- The effects are created by the server; wait for them before the first look.
Lighting:WaitForChild("SubwayAir", 10)
Lighting:WaitForChild("SubwayGrade", 10)
Lighting:WaitForChild("SubwayBloom", 10)
apply()
