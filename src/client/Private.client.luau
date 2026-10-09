-- "Moment of doubt": the server picks one player and tells only them that something is wrong.
-- Everything here is made on this player's screen alone, so their friends see a normal station
-- and have to be convinced to GO BACK. It is in place before the screen clears.
--   Figure         a tall black figure with red eyes stands right outside the car doors
--   NameSign       the station sign shows this player's name
--   WallWriting    red writing on the back wall
--   ClockMidnight  the clock is stuck flashing 00:00:00

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Net = require(ReplicatedStorage.Shared.Net)
local Strings = require(ReplicatedStorage.Shared.Strings)

local player = Players.LocalPlayer

local cleanups: { () -> () } = {}

local function clear()
	for i = #cleanups, 1, -1 do
		pcall(cleanups[i])
	end
	table.clear(cleanups)
end

local function localPart(name: string, size: Vector3, cframe: CFrame, color: Color3, neon: boolean?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = if neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CastShadow = false
	part.Parent = Workspace
	table.insert(cleanups, function()
		part:Destroy()
	end)
	return part
end

-- The station's layout origin, from its platform (built at origin * (0, -1.5, 0)).
local function originOf(map: Instance): CFrame?
	local platform = map:FindFirstChild("Platform", true)
	if platform and platform:IsA("BasePart") then
		return platform.CFrame * CFrame.new(0, 1.5, 0)
	end
	return nil
end

local function labelOf(map: Instance, partName: string): TextLabel?
	local part = map:FindFirstChild(partName, true)
	local label = part and part:FindFirstChild("Text", true)
	return if label and label:IsA("TextLabel") then label else nil
end

local EFFECTS = {}

function EFFECTS.Figure(map: Instance)
	local origin = originOf(map)
	if not origin then
		return
	end
	-- Just outside the left car door, facing the car.
	local base = origin * CFrame.new(-10, 1, 7) * CFrame.Angles(0, math.pi, 0)
	local black = Color3.fromRGB(5, 5, 6)
	localPart("Body", Vector3.new(1.6, 6, 0.9), base * CFrame.new(0, 3, 0), black)
	local head = localPart("Head", Vector3.new(1.1, 1.3, 1), base * CFrame.new(0, 6.7, 0), black)
	for _, x in { -0.25, 0.25 } do
		localPart("Eye", Vector3.new(0.16, 0.1, 0.05), head.CFrame * CFrame.new(x, 0.1, -0.53), Color3.fromRGB(255, 20, 20), true)
	end
	for _, x in { -1.05, 1.05 } do
		localPart("Arm", Vector3.new(0.4, 4.6, 0.4), base * CFrame.new(x, 3.6, 0), black)
	end
end

function EFFECTS.NameSign(map: Instance)
	local label = labelOf(map, "StationSign")
	if not label then
		return
	end
	local original = label.Text
	label.Text = player.DisplayName
	table.insert(cleanups, function()
		label.Text = original
	end)
end

function EFFECTS.WallWriting(map: Instance, language: string)
	local origin = originOf(map)
	if not origin then
		return
	end
	local board = localPart("Writing", Vector3.new(14, 5, 0.05), origin * CFrame.new(-26, 7.5, -9.93), Color3.new(0, 0, 0))
	board.Transparency = 1
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.LightInfluence = 0.3
	gui.Parent = board
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.Creepster
	text.TextScaled = true
	text.TextColor3 = Color3.fromRGB(150, 5, 8)
	text.Text = Strings.get(language, "PrivateWall")
	text.Parent = gui
end

function EFFECTS.ClockMidnight(map: Instance)
	local label = labelOf(map, "Clock")
	if not label then
		return
	end
	-- The server keeps writing the time; win every frame until it ends.
	local connection = RunService.RenderStepped:Connect(function()
		label.Text = if os.clock() % 1 < 0.5 then "00:00:00" else ""
	end)
	table.insert(cleanups, function()
		connection:Disconnect()
	end)
end

Net.event().OnClientEvent:Connect(function(payload)
	if payload.Kind == "Private" then
		clear()
		local effect = EFFECTS[payload.Effect]
		if effect and payload.Map then
			effect(payload.Map, payload.Language or "en")
		end
	elseif payload.Kind == "PrivateEnd" then
		clear()
	end
end)

player:GetAttributeChangedSignal("Phase"):Connect(function()
	if player:GetAttribute("Phase") == "Lobby" then
		clear()
	end
end)
