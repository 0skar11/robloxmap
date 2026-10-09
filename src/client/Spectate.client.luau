-- When you die mid-game you stay dead and watch your living teammates, in third person, until
-- the whole group is dead (then everyone respawns at level 1). Tap the arrows or press Q / E to
-- switch who you watch.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Strings = require(ReplicatedStorage.Shared.Strings)

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "Spectate"
gui.ResetOnSpawn = false
gui.Enabled = false

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.new(0.5, 0, 0, 70)
panel.Size = UDim2.fromOffset(460, 76)
panel.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
panel.BackgroundTransparency = 0.2
panel.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = panel

local function label(position: UDim2, size: UDim2, color: Color3): TextLabel
	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.Position = position
	text.Size = size
	text.Font = Enum.Font.GothamBold
	text.TextScaled = true
	text.TextColor3 = color
	text.Parent = panel
	return text
end
local watching = label(UDim2.fromScale(0.14, 0.08), UDim2.fromScale(0.72, 0.5), Color3.fromRGB(230, 85, 75))
local hint = label(UDim2.fromScale(0.14, 0.6), UDim2.fromScale(0.72, 0.32), Color3.fromRGB(200, 200, 205))

local function arrow(text: string, x: number): TextButton
	local button = Instance.new("TextButton")
	button.Text = text
	button.Position = UDim2.fromScale(x, 0.15)
	button.Size = UDim2.fromScale(0.1, 0.7)
	button.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamBold
	button.TextScaled = true
	button.Parent = panel
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, 8)
	round.Parent = button
	return button
end
local previous = arrow("<", 0.02)
local nextButton = arrow(">", 0.88)

gui.Parent = player:WaitForChild("PlayerGui")

local index = 1

local function teammates(): { Player }
	local key = player:GetAttribute("SessionKey")
	local list = {}
	for _, other in Players:GetPlayers() do
		local humanoid = other.Character and other.Character:FindFirstChildOfClass("Humanoid")
		if other ~= player and other:GetAttribute("SessionKey") == key and humanoid and humanoid.Health > 0 then
			table.insert(list, other)
		end
	end
	return list
end

local function refresh()
	local camera = Workspace.CurrentCamera
	local dead = player:GetAttribute("Dead") == true and player:GetAttribute("Phase") ~= "Lobby"
	gui.Enabled = dead

	if not dead then
		-- Back to normal first person on your own character.
		player.CameraMode = Enum.CameraMode.LockFirstPerson
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
		end
		return
	end

	player.CameraMode = Enum.CameraMode.Classic
	player.CameraMaxZoomDistance = 20
	local language = player:GetAttribute("Language")
	hint.Text = Strings.get(language, "SpectateHint")

	local list = teammates()
	if #list == 0 then
		watching.Text = Strings.get(language, "Spectating", "...")
		return
	end
	index = (index - 1) % #list + 1
	local target = list[index]
	watching.Text = Strings.get(language, "Spectating", target.DisplayName)
	local humanoid = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		camera.CameraSubject = humanoid
	end
end

previous.Activated:Connect(function()
	index -= 1
	refresh()
end)
nextButton.Activated:Connect(function()
	index += 1
	refresh()
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not gui.Enabled then
		return
	end
	if input.KeyCode == Enum.KeyCode.Q then
		index -= 1
		refresh()
	elseif input.KeyCode == Enum.KeyCode.E then
		index += 1
		refresh()
	end
end)

player:GetAttributeChangedSignal("Dead"):Connect(refresh)
player:GetAttributeChangedSignal("Phase"):Connect(refresh)
player.CharacterAdded:Connect(function()
	task.wait()
	refresh()
end)

-- Re-check now and then: the teammate you watch may die too, or the stations may change.
while true do
	task.wait(1)
	if gui.Enabled then
		refresh()
	end
end
