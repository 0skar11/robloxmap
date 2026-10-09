-- The lobby: a bright ticket hall with a row of gates. Groups gather on a gate, and when it leaves
-- they get their own station. The lobby itself is always in English.
--
-- Layout (studs, relative to LOBBY_ORIGIN): floor X -60..60, Z -40..40, gates along Z = -28.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Build = require(script.Parent.Build)
local Npc = require(script.Parent.Npc)
local NpcOutfits = require(script.Parent.NpcOutfits)

local block = Build.block

local LOBBY_ORIGIN = CFrame.new(0, 10, 0)
local GATE_SPACING = 18

local COLORS = {
	Floor = Color3.fromRGB(150, 146, 138),
	Wall = Color3.fromRGB(225, 220, 205),
	Ceiling = Color3.fromRGB(200, 198, 192),
	Frame = Color3.fromRGB(40, 40, 44),
	Yellow = Color3.fromRGB(230, 185, 25),
	Light = Color3.fromRGB(255, 248, 235),
}

local LobbyBuilder = {}

local function at(x: number, y: number, z: number): CFrame
	return LOBBY_ORIGIN * CFrame.new(x, y, z)
end

function LobbyBuilder.clearDefaultPlace()
	-- A fresh "Baseplate" place ships a baseplate and a spawn; players must spawn in the lobby.
	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		baseplate:Destroy()
	end
	for _, descendant in Workspace:GetDescendants() do
		if descendant:IsA("SpawnLocation") then
			descendant.Enabled = false
		end
	end
end

local function buildHall(lobby: Folder)
	block(lobby, "Floor", Vector3.new(120, 2, 80), at(0, -1, 0), COLORS.Floor, Enum.Material.Concrete)
	block(lobby, "Ceiling", Vector3.new(120, 1, 80), at(0, 20.5, 0), COLORS.Ceiling, Enum.Material.Concrete)
	block(lobby, "WallNorth", Vector3.new(122, 22, 1), at(0, 10, -40.5), COLORS.Wall, Enum.Material.CeramicTiles)
	block(lobby, "WallSouth", Vector3.new(122, 22, 1), at(0, 10, 40.5), COLORS.Wall, Enum.Material.CeramicTiles)
	block(lobby, "WallWest", Vector3.new(1, 22, 80), at(-60.5, 10, 0), COLORS.Wall, Enum.Material.CeramicTiles)
	block(lobby, "WallEast", Vector3.new(1, 22, 80), at(60.5, 10, 0), COLORS.Wall, Enum.Material.CeramicTiles)
	block(lobby, "FloorLine", Vector3.new(120, 0.05, 1), at(0, 0.03, -18), COLORS.Yellow)

	for x = -45, 45, 18 do
		for z = -30, 30, 15 do
			Build.ceilingLight(lobby, "Light", Vector3.new(10, 0.2, 1.2), at(x, 19.9, z), COLORS.Light, 1.75, 28)
		end
	end

	local title = block(lobby, "Title", Vector3.new(40, 6, 0.4), at(0, 15, 39.7), COLORS.Frame)
	Build.surfaceText(title, Enum.NormalId.Front, "ENDLESS SUBWAY", { TextColor = COLORS.Yellow, Glow = true })

	local howTo = block(lobby, "HowTo", Vector3.new(30, 7, 0.4), at(0, 6.5, 39.7), COLORS.Frame)
	Build.surfaceText(howTo, Enum.NormalId.Front, table.concat({
		"Stand on a gate with your friends.",
		"The first one in picks the group size (1-10) and the language.",
		"When the gate is full, the train leaves.",
	}, "\n"), { TextColor = Color3.fromRGB(220, 220, 220), Glow = true })

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Size = Vector3.new(12, 0.2, 12)
	spawn.CFrame = at(0, 0.1, 18)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	-- Invisible: nothing on the floor between the player and the gates.
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Parent = lobby
	return spawn
end

local function buildGate(lobby: Folder, index: number, x: number)
	local gate = Instance.new("Model")
	gate.Name = "Gate" .. index
	gate.Parent = lobby

	local zone = block(gate, "Zone", Vector3.new(12, 0.2, 12), at(x, 0.1, -28), Color3.fromRGB(80, 80, 80), Enum.Material.Neon)
	zone.Transparency = 0.55
	zone.CanCollide = false
	zone.CastShadow = false

	block(gate, "PillarWest", Vector3.new(1, 10, 1), at(x - 6.5, 5, -34.5), COLORS.Frame, Enum.Material.Metal)
	block(gate, "PillarEast", Vector3.new(1, 10, 1), at(x + 6.5, 5, -34.5), COLORS.Frame, Enum.Material.Metal)
	block(gate, "Header", Vector3.new(14, 1.5, 1), at(x, 10.5, -34.5), COLORS.Frame, Enum.Material.Metal)
	block(gate, "Tunnel", Vector3.new(12, 10, 0.2), at(x, 5, -39.8), Color3.fromRGB(5, 5, 6))

	local screen = block(gate, "Screen", Vector3.new(12, 4, 0.4), at(x, 13.8, -34.5), Color3.fromRGB(10, 10, 12))
	local label = Build.surfaceText(screen, Enum.NormalId.Back, "", { TextColor = COLORS.Yellow, Glow = true })

	local glow = Instance.new("PointLight")
	glow.Range = 14
	glow.Brightness = 0.8
	glow.Parent = zone

	return { Index = index, Zone = zone, Label = label, Glow = glow }
end

-- The same people as on the train, waiting in the hall: four on seats along the back wall, two
-- near the gates, and the driver by gate 1.
local function buildPeople(lobby: Folder)
	local seatColor = Color3.fromRGB(150, 95, 45)
	local metal = Color3.fromRGB(165, 168, 172)
	for _, x in { -45, -28, 28, 45 } do
		for i = -1, 1 do
			block(lobby, "Seat", Vector3.new(1.8, 0.4, 1.7), at(x + i * 2, 1.8, 37.2), seatColor)
			block(lobby, "SeatBack", Vector3.new(1.8, 1.8, 0.3), at(x + i * 2, 2.95, 38.05), seatColor)
		end
		block(lobby, "SeatFrame", Vector3.new(6.4, 0.3, 0.6), at(x, 1.45, 37.5), metal, Enum.Material.Metal)
		for _, dx in { -3, 3 } do
			block(lobby, "SeatLeg", Vector3.new(0.3, 1.3, 1.2), at(x + dx, 0.65, 37.4), metal, Enum.Material.Metal)
		end
	end

	local outfits = NpcOutfits.Passengers
	local people = {
		-- Seated, facing the gates (-Z).
		Npc.create("Passenger", "Sit", at(-45, 2, 37.1), Color3.fromRGB(40, 55, 90), outfits[1]),
		Npc.create("Passenger", "Sit", at(-28, 2, 37.1), Color3.fromRGB(110, 75, 50), outfits[2]),
		Npc.create("Passenger", "Sit", at(28, 2, 37.1), Color3.fromRGB(60, 60, 60), outfits[3]),
		Npc.create("Passenger", "Sit", at(45, 2, 37.1), Color3.fromRGB(95, 95, 100), outfits[4]),
		-- Standing, looking at the gates.
		Npc.create("Passenger", "Stand", at(-12, 2, -12), Color3.fromRGB(70, 40, 60), outfits[5]),
		Npc.create("Passenger", "Stand", at(16, 2, -14), Color3.fromRGB(120, 40, 45), outfits[6]),
		-- The driver waits by gate 1, facing the hall (+X).
		Npc.create("Driver", "Stand", at(-57, 2, -24) * CFrame.Angles(0, -math.pi / 2, 0), Color3.fromRGB(25, 45, 85), NpcOutfits.Driver),
	}
	for _, person in people do
		person.Parent = lobby
	end
end

-- The fastest-groups board on the east wall. Returns its row labels (filled by Main).
local function buildLeaderboard(lobby: Folder): { TextLabel }
	local board = block(lobby, "Leaderboard", Vector3.new(0.4, 15, 22), at(59.75, 9.5, 0), COLORS.Frame)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Left
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0
	gui.Parent = board

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0.01, 0)
	layout.Parent = gui
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0.04, 0)
	padding.PaddingRight = UDim.new(0.04, 0)
	padding.PaddingTop = UDim.new(0.03, 0)
	padding.Parent = gui

	local function row(order: number, height: number, color: Color3): TextLabel
		local label = Instance.new("TextLabel")
		label.LayoutOrder = order
		label.Size = UDim2.fromScale(1, height)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.TextColor3 = color
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Text = ""
		label.Parent = gui
		return label
	end

	local title = row(0, 0.1, COLORS.Yellow)
	title.Text = "FASTEST GROUPS"
	title.TextXAlignment = Enum.TextXAlignment.Center
	local rows = {}
	for i = 1, Config.LeaderboardSize do
		table.insert(rows, row(i, 0.075, Color3.fromRGB(225, 225, 225)))
	end
	rows[1].Text = "No one has made it out yet..."
	return rows
end

-- Builds the lobby into Workspace.Lobby. Returns the gates and the spawn point.
function LobbyBuilder.build()
	LobbyBuilder.clearDefaultPlace()

	local existing = Workspace:FindFirstChild("Lobby")
	if existing then
		existing:Destroy()
	end

	local lobby = Instance.new("Folder")
	lobby.Name = "Lobby"

	local spawn = buildHall(lobby)
	buildPeople(lobby)
	local leaderboardRows = buildLeaderboard(lobby)
	local gates = {}
	local first = -(Config.LobbyPads - 1) * GATE_SPACING / 2
	for i = 1, Config.LobbyPads do
		table.insert(gates, buildGate(lobby, i, first + (i - 1) * GATE_SPACING))
	end

	lobby.Parent = Workspace
	return {
		Folder = lobby,
		Spawn = spawn,
		SpawnCFrame = spawn.CFrame * CFrame.new(0, 3.5, 0),
		Gates = gates,
		LeaderboardRows = leaderboardRows,
	}
end

return LobbyBuilder
