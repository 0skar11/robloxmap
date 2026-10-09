-- Builds one station in code: an enterable metro car between two closed ones, a long dark
-- platform, the baseline details that anomalies change, and the hints that point at the twist.
-- Every group from the lobby gets its own copy, built at its own origin and in its own language.
--
-- Layout (studs, relative to the station origin). The platform runs along X, the track is on +Z.
--   Platform floor      X -100..100, Z -10..10, top at Y 1
--   Train car (open)    X -20..20,   Z 10..24 (wide), doors on the platform side (Z 11)
--   Closed cars         X -62..-22 and 22..62
--   Driver's cab       X 64..84, the front of the train (it heads toward +X)
--   CONTINUE door       +X end of the platform
--   GO BACK door        -X end of the platform (missing on level 1)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Strings = require(ReplicatedStorage.Shared.Strings)
local Build = require(script.Parent.Build)
local Npc = require(script.Parent.Npc)

local block = Build.block
local surfaceText = Build.surfaceText

local HALF_LENGTH = 100

local COLORS = {
	Floor = Color3.fromRGB(92, 90, 86),
	Wall = Color3.fromRGB(150, 146, 132),
	WallGrime = Color3.fromRGB(70, 68, 62),
	WallStripe = Color3.fromRGB(30, 70, 55),
	Ceiling = Color3.fromRGB(40, 40, 42),
	Pillar = Color3.fromRGB(140, 132, 112),
	Edge = Color3.fromRGB(220, 175, 20),
	CarBody = Color3.fromRGB(150, 155, 162),
	CarStripe = Color3.fromRGB(220, 175, 20),
	CarSeat = Color3.fromRGB(55, 70, 110),
	Dark = Color3.fromRGB(18, 18, 20),
	Bench = Color3.fromRGB(90, 62, 40),
	Continue = Color3.fromRGB(40, 140, 80),
	Back = Color3.fromRGB(170, 50, 45),
	Light = Color3.fromRGB(255, 226, 180),
	Pipe = Color3.fromRGB(60, 62, 60),
}

local POSTER_COLORS = {
	Color3.fromRGB(170, 85, 25),
	Color3.fromRGB(30, 65, 125),
	Color3.fromRGB(30, 105, 65),
	Color3.fromRGB(85, 45, 115),
	Color3.fromRGB(150, 120, 20),
	Color3.fromRGB(25, 100, 110),
	Color3.fromRGB(120, 30, 30),
}

local MapBuilder = {}

-- Origin of the station being built. build() runs without yielding, so one shared value is safe.
local origin = CFrame.new()

local function at(x: number, y: number, z: number): CFrame
	return origin * CFrame.new(x, y, z)
end

local function buildShell(map: Folder)
	local shell = Instance.new("Folder")
	shell.Name = "Shell"
	shell.Parent = map

	local length = HALF_LENGTH * 2
	block(shell, "Platform", Vector3.new(length, 5, 20), at(0, -1.5, 0), COLORS.Floor, Enum.Material.Concrete)
	block(shell, "PlatformEdge", Vector3.new(length, 0.1, 1), at(0, 1.05, 9.5), COLORS.Edge)
	block(shell, "BackWall", Vector3.new(length + 2, 20, 1), at(0, 6, -10.5), COLORS.Wall, Enum.Material.CeramicTiles)
	block(shell, "WallStripe", Vector3.new(length, 1.2, 0.1), at(0, 2.6, -9.95), COLORS.WallStripe, Enum.Material.CeramicTiles)
	block(shell, "WallGrime", Vector3.new(length, 3, 0.1), at(0, 14.5, -9.95), COLORS.WallGrime, Enum.Material.Concrete)
	block(shell, "TunnelWall", Vector3.new(length + 2, 20, 1), at(0, 6, 27.5), COLORS.Dark, Enum.Material.Concrete)
	block(shell, "Ceiling", Vector3.new(length + 2, 1, 39), at(0, 16.5, 8.5), COLORS.Ceiling, Enum.Material.Concrete)
	block(shell, "TrackBed", Vector3.new(length, 1, 17), at(0, -3.5, 18.5), COLORS.Dark, Enum.Material.Slate)
	block(shell, "RailNear", Vector3.new(length, 0.4, 0.4), at(0, -2.8, 15.5), Color3.fromRGB(90, 90, 95), Enum.Material.Metal)
	block(shell, "RailFar", Vector3.new(length, 0.4, 0.4), at(0, -2.8, 20.5), Color3.fromRGB(90, 90, 95), Enum.Material.Metal)

	-- Pipes along the ceiling.
	for _, z in { -8.2, -7.2 } do
		local pipe = block(shell, "Pipe", Vector3.new(length, 0.6, 0.6), at(0, 15.3, z), COLORS.Pipe, Enum.Material.Metal)
		pipe.Shape = Enum.PartType.Cylinder
	end

	-- Keep players on the platform and in the open car.
	local barrierLength = HALF_LENGTH - 20
	local barrierCenter = 20 + barrierLength / 2
	Build.invisibleWall(shell, "EdgeBarrierWest", Vector3.new(barrierLength, 15, 0.5), at(-barrierCenter, 8.5, 10.25))
	Build.invisibleWall(shell, "EdgeBarrierEast", Vector3.new(barrierLength, 15, 0.5), at(barrierCenter, 8.5, 10.25))
end

local function buildExitDoor(map: Folder, kind: "Continue" | "Back", language: string)
	local sign = if kind == "Continue" then 1 else -1
	local color = if kind == "Continue" then COLORS.Continue else COLORS.Back
	local face = if kind == "Continue" then Enum.NormalId.Left else Enum.NormalId.Right
	local wallX = sign * (HALF_LENGTH + 0.5)
	local doorX = sign * (HALF_LENGTH - 0.2)

	local model = Instance.new("Model")
	model.Name = kind .. "Door"
	model.Parent = map

	-- The wall belongs to the map; the door model can be removed on its own (see GameLoop).
	block(map, kind .. "EndWall", Vector3.new(1, 20, 39), at(wallX, 6, 8.5), COLORS.Wall, Enum.Material.CeramicTiles)
	local door = block(model, "Door", Vector3.new(0.4, 8, 5), at(doorX, 5, 0), COLORS.Dark, Enum.Material.Metal)
	block(model, "Frame", Vector3.new(0.3, 9, 6), at(sign * (HALF_LENGTH - 0.05), 5.5, 0), color)

	local title = Strings.get(language, if kind == "Continue" then "DoorContinue" else "DoorBack")
	local signPart = block(model, "Sign", Vector3.new(0.4, 2, 8), at(doorX, 11, 0), color, Enum.Material.Neon)
	surfaceText(signPart, face, title, { TextColor = Color3.new(1, 1, 1), Glow = true })
	local glow = Instance.new("PointLight")
	glow.Color = color
	glow.Range = 14
	glow.Brightness = 0.8
	glow.Parent = signPart

	-- Players vote by standing on this zone in front of the door.
	local zone = block(model, "VoteZone", Vector3.new(10, 0.1, 14), at(sign * (HALF_LENGTH - 7), 1.06, 0), color, Enum.Material.Neon)
	zone.Transparency = 0.8
	zone.CanCollide = false
	zone.CanQuery = false
	zone.CastShadow = false

	return { Model = model, Door = door, Zone = zone }
end

local function buildClosedCar(map: Folder, centerX: number)
	local car = Instance.new("Model")
	car.Name = "ClosedCar"
	car.Parent = map

	block(car, "Body", Vector3.new(40, 11, 14), at(centerX, 6.5, 18), COLORS.CarBody, Enum.Material.Metal)
	block(car, "Underbody", Vector3.new(40, 4, 13), at(centerX, -1.5, 18), COLORS.Dark, Enum.Material.Metal)
	block(car, "Stripe", Vector3.new(40, 0.6, 0.1), at(centerX, 3.2, 10.95), COLORS.CarStripe)
	-- Dark windows: nobody seems to be inside. Mostly.
	for offset = -15, 15, 10 do
		block(car, "Window", Vector3.new(6, 3, 0.1), at(centerX + offset, 7, 10.95), Color3.fromRGB(8, 10, 14), Enum.Material.Glass)
	end
	for _, offset in { -10, 10 } do
		block(car, "DoorOutline", Vector3.new(7, 8, 0.1), at(centerX + offset, 5, 10.94), Color3.fromRGB(110, 115, 122), Enum.Material.Metal)
	end
end

-- The driver's cab at the front of the train: hollow, with a windshield, headlights, a control
-- desk and a driver you can see through the side window.
local function buildCab(map: Folder, refs)
	local cab = Instance.new("Model")
	cab.Name = "DriverCab"
	cab.Parent = map

	local x0, x1 = 64, 84
	local centerX = (x0 + x1) / 2
	local length = x1 - x0
	local glass = Color3.fromRGB(120, 150, 170)

	block(cab, "Floor", Vector3.new(length, 4, 14), at(centerX, -1, 18), Color3.fromRGB(60, 60, 64), Enum.Material.DiamondPlate)
	block(cab, "Roof", Vector3.new(length, 1, 14), at(centerX, 12.5, 18), COLORS.CarBody, Enum.Material.Metal)
	block(cab, "BackWall", Vector3.new(0.5, 11, 14), at(x0 + 0.25, 6.5, 18), COLORS.CarBody, Enum.Material.Metal)
	block(cab, "FarWall", Vector3.new(length, 11, 0.5), at(centerX, 6.5, 24.75), COLORS.CarBody, Enum.Material.Metal)

	-- Platform side: solid wall with a big window near the front.
	block(cab, "SideWallBack", Vector3.new(11, 11, 0.5), at(x0 + 5.5, 6.5, 11.25), COLORS.CarBody, Enum.Material.Metal)
	block(cab, "SideWallLow", Vector3.new(9, 4, 0.5), at(x1 - 4.5, 3, 11.25), COLORS.CarBody, Enum.Material.Metal)
	block(cab, "SideWallHigh", Vector3.new(9, 3, 0.5), at(x1 - 4.5, 10.5, 11.25), COLORS.CarBody, Enum.Material.Metal)
	local sideWindow = block(cab, "SideWindow", Vector3.new(9, 4, 0.2), at(x1 - 4.5, 7, 11.25), glass, Enum.Material.Glass)
	sideWindow.Transparency = 0.6
	block(cab, "Stripe", Vector3.new(length, 0.6, 0.1), at(centerX, 3.2, 10.95), COLORS.CarStripe)

	-- Front: windshield above a painted nose, headlights below.
	block(cab, "Nose", Vector3.new(0.6, 5, 14), at(x1 + 0.3, 3.5, 18), COLORS.CarStripe, Enum.Material.Metal)
	block(cab, "FrontTop", Vector3.new(0.6, 2, 14), at(x1 + 0.3, 11, 18), COLORS.CarBody, Enum.Material.Metal)
	local windshield = block(cab, "Windshield", Vector3.new(0.2, 4, 14), at(x1 + 0.3, 8, 18), glass, Enum.Material.Glass)
	windshield.Transparency = 0.5
	for _, z in { 13.5, 22.5 } do
		local lamp = block(cab, "Headlight", Vector3.new(0.3, 1, 1.6), at(x1 + 0.7, 3, z), Color3.fromRGB(255, 250, 225), Enum.Material.Neon)
		local beam = Instance.new("SpotLight")
		beam.Face = Enum.NormalId.Right
		beam.Range = 40
		beam.Angle = 50
		beam.Brightness = 2
		beam.Color = Color3.fromRGB(255, 248, 225)
		beam.Parent = lamp
	end

	-- Control desk and the driver's seat.
	local desk = block(cab, "ControlDesk", Vector3.new(2.5, 3.5, 9), at(x1 - 1.6, 2.75, 18), Color3.fromRGB(35, 38, 42), Enum.Material.Metal)
	desk.CFrame = at(x1 - 1.6, 2.75, 18) * CFrame.Angles(0, 0, math.rad(-12))
	for i, color in { Color3.fromRGB(60, 220, 90), Color3.fromRGB(240, 70, 60), Color3.fromRGB(250, 200, 40), Color3.fromRGB(70, 160, 255) } do
		block(cab, "Button", Vector3.new(0.3, 0.3, 0.6), at(x1 - 2.6, 4.65, 15 + i * 1.2), color, Enum.Material.Neon)
	end
	local throttle = block(cab, "Throttle", Vector3.new(0.25, 1.4, 0.25), at(x1 - 2.8, 5.1, 20.5), Color3.fromRGB(20, 20, 22), Enum.Material.Metal)
	throttle.CFrame = throttle.CFrame * CFrame.Angles(0, 0, math.rad(20))
	block(cab, "DriverSeat", Vector3.new(2, 2, 2), at(x1 - 6, 2, 18), COLORS.CarSeat, Enum.Material.Fabric)
	block(cab, "DriverSeatBack", Vector3.new(0.4, 3, 2), at(x1 - 7.2, 4.5, 18), COLORS.CarSeat, Enum.Material.Fabric)
	Build.ceilingLight(cab, "CabLight", Vector3.new(4, 0.2, 2), at(centerX + 3, 11.9, 18), Color3.fromRGB(235, 240, 255), 0.9, 12)

	-- The driver faces the way the train goes (+X).
	refs.Driver = Npc.create("Driver", "Sit", at(x1 - 6, 3, 18) * CFrame.Angles(0, -math.pi / 2, 0), Color3.fromRGB(25, 45, 85))
	refs.Driver.Parent = cab
	refs.Cab = cab
end

-- The open car is wide and clear: wide doors, seats only along the far wall, and grab bars up at
-- the roof instead of poles in the way.
local function buildCar(map: Folder)
	local car = Instance.new("Model")
	car.Name = "TrainCar"
	car.Parent = map

	block(car, "Floor", Vector3.new(40, 4, 14), at(0, -1, 17), Color3.fromRGB(70, 70, 76), Enum.Material.DiamondPlate)
	block(car, "Roof", Vector3.new(40, 1, 14), at(0, 12.5, 17), COLORS.CarBody, Enum.Material.Metal)
	block(car, "FarWall", Vector3.new(40, 11, 0.5), at(0, 6.5, 24.25), COLORS.CarBody, Enum.Material.Metal)
	block(car, "Window", Vector3.new(36, 3, 0.1), at(0, 7.5, 23.95), Color3.fromRGB(6, 8, 12), Enum.Material.Glass)
	block(car, "Stripe", Vector3.new(40, 0.6, 0.1), at(0, 10, 23.95), COLORS.CarStripe)
	block(car, "EndWallWest", Vector3.new(0.5, 11, 14), at(-19.75, 6.5, 17), COLORS.CarBody, Enum.Material.Metal)
	block(car, "EndWallEast", Vector3.new(0.5, 11, 14), at(19.75, 6.5, 17), COLORS.CarBody, Enum.Material.Metal)

	-- Platform side: three wall segments with two wide door openings (X -13.5..-6.5 and 6.5..13.5).
	block(car, "SideWallWest", Vector3.new(6.5, 11, 0.5), at(-16.75, 6.5, 11.25), COLORS.CarBody, Enum.Material.Metal)
	block(car, "SideWallMiddle", Vector3.new(13, 11, 0.5), at(0, 6.5, 11.25), COLORS.CarBody, Enum.Material.Metal)
	block(car, "SideWallEast", Vector3.new(6.5, 11, 0.5), at(16.75, 6.5, 11.25), COLORS.CarBody, Enum.Material.Metal)

	local doorPanels = {}
	for _, centerX in { -10, 10 } do
		block(car, "DoorHeader", Vector3.new(7, 3, 0.5), at(centerX, 10.5, 11.25), COLORS.CarBody, Enum.Material.Metal)
		for _, side in { -1, 1 } do
			local closed = at(centerX + side * 1.75, 5, 11.75)
			local open = at(centerX + side * 5.3, 5, 11.75)
			local panel = block(car, "DoorPanel", Vector3.new(3.5, 8, 0.3), closed, Color3.fromRGB(130, 135, 142), Enum.Material.Metal)
			table.insert(doorPanels, { Part = panel, Closed = closed, Open = open })
		end
	end

	for _, centerX in { -10, 10 } do
		block(car, "Seat", Vector3.new(14, 0.6, 1.8), at(centerX, 2.6, 22.9), COLORS.CarSeat, Enum.Material.Fabric)
		block(car, "SeatBack", Vector3.new(14, 2.5, 0.4), at(centerX, 4, 23.8), COLORS.CarSeat, Enum.Material.Fabric)
	end
	for _, z in { 14.5, 19.5 } do
		local bar = block(car, "GrabBar", Vector3.new(36, 0.25, 0.25), at(0, 11.4, z), Color3.fromRGB(170, 170, 175), Enum.Material.Metal)
		bar.Shape = Enum.PartType.Cylinder
		bar.CanCollide = false
	end
	for _, z in { 14.5, 19.5 } do
		Build.ceilingLight(car, "LightStrip", Vector3.new(36, 0.2, 0.8), at(0, 11.9, z), Color3.fromRGB(235, 240, 255), 1.4, 14)
	end

	-- Where the group stands when the train stops: two rows, enough for 10 players.
	local standPoints = {}
	for _, z in { 15, 18.5 } do
		for x = -16, 16, 4 do
			table.insert(standPoints, at(x, 4, z))
		end
	end

	return car, doorPanels, standPoints
end

local function buildStation(map: Folder, refs, language: string)
	local station = Instance.new("Folder")
	station.Name = "Station"
	station.Parent = map

	-- Pillars down the middle of the platform.
	refs.Pillars = {}
	for x = -80, 80, 20 do
		local pillar = block(station, "Pillar", Vector3.new(2, 15, 2), at(x, 8.5, 1), COLORS.Pillar, Enum.Material.Marble)
		pillar:SetAttribute("X", x)
		table.insert(refs.Pillars, pillar)
	end

	-- Ceiling lights, plus a second row over the platform edge. In the dark half of the game some of
	-- them die ("DiesInHorror"), which leaves pools of darkness along the platform.
	local diesInHorror = { [-70] = true, [-30] = true, [50] = true, [90] = true }
	refs.Lights = {}
	for x = -90, 90, 20 do
		local fixture = Build.ceilingLight(station, "Light", Vector3.new(8, 0.2, 1), at(x, 15.9, 0), COLORS.Light, 1.8, 20)
		fixture:SetAttribute("DiesInHorror", diesInHorror[x] == true)
		table.insert(refs.Lights, fixture)
	end
	for x = -80, 80, 40 do
		local fixture = Build.ceilingLight(station, "Light", Vector3.new(8, 0.2, 1), at(x, 15.9, 7), COLORS.Light, 1.8, 20)
		fixture:SetAttribute("DiesInHorror", true)
		table.insert(refs.Lights, fixture)
	end

	-- Benches against the back wall, facing the track.
	local busyBenches = { [-70] = true, [-30] = true, [-10] = true, [30] = true }
	refs.Benches = {}
	for x = -70, 70, 20 do
		local bench = Instance.new("Model")
		bench.Name = "Bench"
		local seat = block(bench, "Seat", Vector3.new(6, 0.5, 1.8), at(x, 2.75, -8.3), COLORS.Bench, Enum.Material.WoodPlanks)
		block(bench, "Backrest", Vector3.new(6, 1.8, 0.4), at(x, 4, -9.2), COLORS.Bench, Enum.Material.WoodPlanks)
		block(bench, "LegWest", Vector3.new(0.4, 1.5, 1.4), at(x - 2.6, 1.75, -8.3), COLORS.Dark, Enum.Material.Metal)
		block(bench, "LegEast", Vector3.new(0.4, 1.5, 1.4), at(x + 2.6, 1.75, -8.3), COLORS.Dark, Enum.Material.Metal)
		bench.PrimaryPart = seat
		bench:SetAttribute("Free", not busyBenches[x])
		bench.Parent = station
		table.insert(refs.Benches, bench)
	end

	-- Station name and line badge.
	local nameSign = block(station, "StationSign", Vector3.new(16, 3, 0.3), at(0, 11, -9.85), Color3.fromRGB(16, 30, 60))
	refs.StationName = surfaceText(nameSign, Enum.NormalId.Back, Strings.get(language, "StationName"), { TextColor = Color3.fromRGB(230, 230, 230) })
	local badge = block(station, "LineBadge", Vector3.new(3, 3, 0.3), at(10, 11, -9.85), COLORS.Edge)
	refs.LineBadge = surfaceText(badge, Enum.NormalId.Back, "14", { TextColor = COLORS.Dark })

	-- Digital clock. The game loop ticks it unless its "Frozen" attribute is set.
	refs.Clock = block(station, "Clock", Vector3.new(3.4, 1.4, 0.3), at(-10, 11, -9.85), COLORS.Dark)
	refs.ClockLabel = surfaceText(refs.Clock, Enum.NormalId.Back, "23:57:00", {
		TextColor = Color3.fromRGB(255, 50, 40),
		Glow = true,
	})

	-- Hanging counter sign, readable when stepping out of the car.
	local counter = block(station, "CounterSign", Vector3.new(7, 2.6, 0.3), at(0, 13.5, 7), COLORS.Dark)
	block(station, "CounterHanger", Vector3.new(0.2, 1.7, 0.2), at(0, 15.15, 7), COLORS.Dark, Enum.Material.Metal)
	refs.CounterLabel = surfaceText(counter, Enum.NormalId.Back, "", { TextColor = COLORS.Edge, Glow = true })

	-- Advertisements on the back wall.
	refs.Posters = {}
	local texts = Strings.get(language, "Posters")
	for i, x in { -80, -40, -20, 20, 40, 60, 80 } do
		local color = POSTER_COLORS[i]
		local poster = block(station, "Poster", Vector3.new(5, 7, 0.2), at(x, 7.5, -9.9), color)
		table.insert(refs.Posters, surfaceText(poster, Enum.NormalId.Back, texts[i], { Background = color }))
	end

	-- A vending machine humming in the dark.
	local vending = block(station, "VendingMachine", Vector3.new(4, 7, 2.5), at(-60, 4.5, -8.6), Color3.fromRGB(110, 20, 25), Enum.Material.Metal)
	local panel = block(station, "VendingPanel", Vector3.new(3, 4, 0.1), at(-60, 5.2, -7.3), Color3.fromRGB(200, 220, 255), Enum.Material.Neon)
	surfaceText(panel, Enum.NormalId.Back, Strings.get(language, "Vending"), {
		Background = Color3.fromRGB(190, 210, 245),
		TextColor = Color3.fromRGB(110, 20, 25),
		Glow = true,
	})
	local vendingLight = Instance.new("PointLight")
	vendingLight.Color = Color3.fromRGB(190, 210, 255)
	vendingLight.Range = 10
	vendingLight.Brightness = 0.7
	vendingLight.Parent = vending

	-- Trash bins: upright cylinders (a cylinder's axis is its X, so turn it to stand up).
	for _, x in { -44, 44 } do
		local bin = block(station, "TrashBin", Vector3.new(2.4, 1.6, 1.6), at(x, 2.2, -9) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(45, 55, 45), Enum.Material.Metal)
		bin.Shape = Enum.PartType.Cylinder
	end

	-- Passengers. The game never says who they are.
	local flip = CFrame.Angles(0, math.pi, 0)
	refs.Passengers = {
		Npc.create("Passenger", "Sit", at(-30, 3, -8.1) * flip, Color3.fromRGB(40, 55, 90)),
		Npc.create("Passenger", "Sit", at(30, 3, -8.1) * flip, Color3.fromRGB(110, 75, 50)),
		Npc.create("Passenger", "Sit", at(-70, 3, -8.1) * flip, Color3.fromRGB(60, 60, 60)),
		Npc.create("Passenger", "Stand", at(-5, 3, -3) * flip, Color3.fromRGB(95, 95, 100)),
		Npc.create("Passenger", "Stand", at(62, 3, 6) * flip, Color3.fromRGB(70, 40, 60)),
		Npc.create("Passenger", "Sit", at(-10, 2.9, 22.7), Color3.fromRGB(120, 40, 45)),
	}
	for _, passenger in refs.Passengers do
		passenger.Parent = station
	end

	-- Hints at the twist. They only show up once the dark half begins (see GameLoop), and nobody
	-- gets them the first time.
	local newspaper = block(station, "Newspaper", Vector3.new(2, 0.05, 1.4), at(-10.8, 3.03, -8.2), Color3.fromRGB(225, 222, 210))
	refs.NewspaperLabel = surfaceText(newspaper, Enum.NormalId.Top, Strings.get(language, "Newspaper", Strings.tomorrow(language)), {
		Background = Color3.fromRGB(225, 222, 210),
		TextColor = COLORS.Dark,
		PixelsPerStud = 80,
	})

	local flowers = Instance.new("Model")
	flowers.Name = "Flowers"
	for i, color in { Color3.fromRGB(180, 25, 35), Color3.fromRGB(235, 235, 230), Color3.fromRGB(180, 25, 35) } do
		local offset = (i - 2) * 0.35
		local base = at(1.8 + offset, 1.1, 2.6) * CFrame.Angles(0, math.rad(20 * (i - 2)), 0)
		block(flowers, "Stem", Vector3.new(0.12, 0.12, 1.6), base, Color3.fromRGB(45, 95, 45))
		local bloom = block(flowers, "Bloom", Vector3.new(0.45, 0.45, 0.45), base * CFrame.new(0, 0.1, -0.85), color)
		bloom.Shape = Enum.PartType.Ball
	end
	flowers.Parent = station

	local phone = block(station, "Phone", Vector3.new(0.7, 0.06, 1.2), at(34, 1.03, 4) * CFrame.Angles(0, math.rad(25), 0), COLORS.Dark)
	refs.PhoneLabel = surfaceText(phone, Enum.NormalId.Top, Strings.get(language, "MissedCalls", 12), {
		Background = Color3.fromRGB(10, 10, 14),
		TextColor = Color3.fromRGB(230, 230, 235),
		Glow = true,
		PixelsPerStud = 90,
	})
	local glow = Instance.new("PointLight")
	glow.Range = 5
	glow.Brightness = 0.8
	glow.Color = Color3.fromRGB(200, 220, 255)
	glow.Parent = phone

	refs.Hints = { newspaper, flowers, phone }
	refs.Station = station
end

-- Builds one station at stationOrigin into Workspace and returns the references the game loop and
-- anomalies use. refs.At(x, y, z) converts layout coordinates of this station to world space.
-- withSpawn adds a spawn point in the train, for game servers that have no lobby.
function MapBuilder.build(stationOrigin: CFrame, name: string, language: string, withSpawn: boolean?)
	origin = stationOrigin

	local existing = Workspace:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end

	local map = Instance.new("Folder")
	map.Name = name

	local refs: any = {
		Map = map,
		Origin = stationOrigin,
		Language = language,
		At = function(x: number, y: number, z: number): CFrame
			return stationOrigin * CFrame.new(x, y, z)
		end,
	}

	buildShell(map)
	refs.Doors = {
		Continue = buildExitDoor(map, "Continue", language),
		Back = buildExitDoor(map, "Back", language),
	}
	buildClosedCar(map, -42)
	buildClosedCar(map, 42)
	buildCab(map, refs)
	refs.Car, refs.DoorPanels, refs.StandPoints = buildCar(map)
	buildStation(map, refs, language)

	if withSpawn then
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "TrainSpawn"
		spawn.Size = Vector3.new(16, 0.1, 6)
		spawn.CFrame = at(0, 1.05, 17)
		spawn.Anchored = true
		spawn.CanCollide = false
		spawn.Transparency = 1
		spawn.Neutral = true
		spawn.Duration = 0
		spawn.Parent = refs.Car
	end

	map.Parent = Workspace
	return refs
end

return MapBuilder
