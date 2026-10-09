-- The lobby: a bright ticket hall with a row of gates. Groups gather on a gate, and when it leaves
-- they get their own station. The lobby itself is always in English.
--
-- Layout (studs, relative to LOBBY_ORIGIN): floor X -60..60, Z -40..40, gates along Z = -28.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Build = require(script.Parent.Build)

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
			Build.ceilingLight(lobby, "Light", Vector3.new(10, 0.2, 1.2), at(x, 19.9, z), COLORS.Light, 2.2, 28)
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
	spawn.Color = COLORS.Yellow
	spawn.Material = Enum.Material.Neon
	spawn.Transparency = 0.6
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
	}
end

return LobbyBuilder
