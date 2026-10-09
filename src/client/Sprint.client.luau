-- Sprinting. PC: hold Shift. Mobile: a button on screen toggles between sprint and walk.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Strings = require(ReplicatedStorage.Shared.Strings)

local player = Players.LocalPlayer

local shiftHeld = false
local toggledOn = false

local function language()
	return if player:GetAttribute("Phase") == "Lobby" then "en" else player:GetAttribute("Language")
end

local function apply()
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = if shiftHeld or toggledOn then Config.SprintSpeed else Config.WalkSpeed
	end
end

UserInputService.InputBegan:Connect(function(input)
	-- Shift can arrive marked as "processed" by Roblox's own controls, so only skip typing.
	if UserInputService:GetFocusedTextBox() then
		return
	end
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		shiftHeld = true
		apply()
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		shiftHeld = false
		apply()
	end
end)
player.CharacterAdded:Connect(function(character)
	character:WaitForChild("Humanoid", 10)
	apply()
end)

-- Mobile button, just above the jump button.
if UserInputService.TouchEnabled then
	local gui = Instance.new("ScreenGui")
	gui.Name = "SprintButton"
	gui.ResetOnSpawn = false

	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(1, 1)
	button.Position = UDim2.new(1, -30, 1, -170)
	button.Size = UDim2.fromOffset(84, 84)
	button.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
	button.BackgroundTransparency = 0.3
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamBold
	button.TextScaled = true
	button.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = button
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0.15, 0)
	padding.PaddingRight = UDim.new(0.15, 0)
	padding.Parent = button

	local function refresh()
		-- The button shows what tapping it will do.
		button.Text = Strings.get(language(), if toggledOn then "Walk" else "Sprint")
		button.BackgroundColor3 = if toggledOn then Color3.fromRGB(200, 150, 20) else Color3.fromRGB(30, 30, 36)
	end

	button.Activated:Connect(function()
		toggledOn = not toggledOn
		refresh()
		apply()
	end)
	player:GetAttributeChangedSignal("Language"):Connect(refresh)
	player:GetAttributeChangedSignal("Phase"):Connect(refresh)
	refresh()
	gui.Parent = player:WaitForChild("PlayerGui")
end
