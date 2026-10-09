-- Builds the whole station in code: one metro car and one platform, plus the baseline details
-- that anomalies change and the hints that point at the twist.
--
-- Layout (studs, relative to ORIGIN). The platform runs along X, the track is on +Z.
--   Platform floor      X -60..60, Z -10..10, top at Y 1
--   Train car           X -20..20, Z 10..19, doors on the platform side (Z 11)
--   "كمّل" (Continue)    door at the +X end of the platform
--   "ارجع" (Go back)     door at the -X end of the platform

local Workspace = game:GetService("Workspace")

local Mannequin = require(script.Parent.Mannequin)

local MapBuilder = {}

local ORIGIN = CFrame.new(0, 50, 0)

local COLORS = {
	Floor = Color3.fromRGB(150, 146, 138),
	Wall = Color3.fromRGB(221, 214, 196),
	Ceiling = Color3.fromRGB(90, 90, 92),
	Pillar = Color3.fromRGB(196, 186, 160),
	Edge = Color3.fromRGB(245, 197, 24),
	CarBody = Color3.fromRGB(200, 204, 210),
	CarStripe = Color3.fromRGB(245, 197, 24),
	CarSeat = Color3.fromRGB(70, 90, 140),
	Dark = Color3.fromRGB(25, 25, 28),
	Bench = Color3.fromRGB(120, 84, 52),
	Continue = Color3.fromRGB(46, 160, 90),
	Back = Color3.fromRGB(190, 60, 55),
	Light = Color3.fromRGB(255, 241, 214),
}

local ARABIC_MONTHS = {
	"يناير",
	"فبراير",
	"مارس",
	"أبريل",
	"مايو",
	"يونيو",
	"يوليو",
	"أغسطس",
	"سبتمبر",
	"أكتوبر",
	"نوفمبر",
	"ديسمبر",
}

local function at(x: number, y: number, z: number): CFrame
	return ORIGIN * CFrame.new(x, y, z)
end

local function block(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function invisibleWall(parent: Instance, name: string, size: Vector3, cframe: CFrame): Part
	local part = block(parent, name, size, cframe, COLORS.Dark)
	part.Transparency = 1
	part.CastShadow = false
	return part
end

type TextOptions = {
	Background: Color3?,
	TextColor: Color3?,
	Glow: boolean?,
	PixelsPerStud: number?,
}

-- Puts a scaled TextLabel on one face of a part and returns the label.
local function surfaceText(target: BasePart, face: Enum.NormalId, text: string, options: TextOptions?): TextLabel
	local opts: TextOptions = options or {}

	local gui = Instance.new("SurfaceGui")
	gui.Name = "Display"
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = opts.PixelsPerStud or 40
	gui.LightInfluence = if opts.Glow then 0 else 1
	gui.Parent = target

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = opts.Background or Color3.new(1, 1, 1)
	label.BackgroundTransparency = if opts.Background then 0 else 1
	label.BorderSizePixel = 0
	label.TextColor3 = opts.TextColor or Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = text
	label.Parent = gui

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0.06, 0)
	padding.PaddingRight = UDim.new(0.06, 0)
	padding.PaddingTop = UDim.new(0.08, 0)
	padding.PaddingBottom = UDim.new(0.08, 0)
	padding.Parent = label

	return label
end

local function tomorrowText(): string
	local date = os.date("*t", os.time() + 24 * 60 * 60)
	return string.format("%d %s %d", date.day, ARABIC_MONTHS[date.month], date.year)
end

local function clearDefaultPlace()
	-- A fresh "Baseplate" place ships a baseplate and a spawn; players must spawn in the train instead.
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

local function buildShell(map: Folder)
	local shell = Instance.new("Folder")
	shell.Name = "Shell"
	shell.Parent = map

	block(shell, "Platform", Vector3.new(120, 5, 20), at(0, -1.5, 0), COLORS.Floor, Enum.Material.Concrete)
	block(shell, "PlatformEdge", Vector3.new(120, 0.1, 1), at(0, 1.05, 9.5), COLORS.Edge)
	block(shell, "BackWall", Vector3.new(122, 20, 1), at(0, 6, -10.5), COLORS.Wall, Enum.Material.CeramicTiles)
	block(shell, "TunnelWall", Vector3.new(122, 20, 1), at(0, 6, 21.5), COLORS.Dark, Enum.Material.Concrete)
	block(shell, "Ceiling", Vector3.new(122, 1, 33), at(0, 16.5, 5.5), COLORS.Ceiling, Enum.Material.Concrete)
	block(shell, "TrackBed", Vector3.new(120, 1, 11), at(0, -3.5, 15.5), COLORS.Dark, Enum.Material.Slate)
	block(shell, "RailNear", Vector3.new(120, 0.4, 0.4), at(0, -2.8, 13.5), Color3.fromRGB(110, 110, 115), Enum.Material.Metal)
	block(shell, "RailFar", Vector3.new(120, 0.4, 0.4), at(0, -2.8, 17.5), Color3.fromRGB(110, 110, 115), Enum.Material.Metal)

	-- Keep players on the platform and in the car.
	invisibleWall(shell, "EdgeBarrierWest", Vector3.new(40, 15, 0.5), at(-40, 8.5, 10.25))
	invisibleWall(shell, "EdgeBarrierEast", Vector3.new(40, 15, 0.5), at(40, 8.5, 10.25))
end

local function buildExitDoor(map: Folder, kind: "Continue" | "Back")
	local sign = if kind == "Continue" then 1 else -1
	local color = if kind == "Continue" then COLORS.Continue else COLORS.Back
	local face = if kind == "Continue" then Enum.NormalId.Left else Enum.NormalId.Right

	local model = Instance.new("Model")
	model.Name = kind .. "Door"
	model.Parent = map

	block(model, "EndWall", Vector3.new(1, 20, 33), at(sign * 60.5, 6, 5.5), COLORS.Wall, Enum.Material.CeramicTiles)
	local door = block(model, "Door", Vector3.new(0.4, 8, 5), at(sign * 59.8, 5, 0), COLORS.Dark, Enum.Material.Metal)
	block(model, "Frame", Vector3.new(0.3, 9, 6), at(sign * 59.95, 5.5, 0), color)

	local title = if kind == "Continue" then "كمّل" else "ارجع"
	local signPart = block(model, "Sign", Vector3.new(0.4, 2, 8), at(sign * 59.8, 11, 0), color)
	surfaceText(signPart, face, title, { TextColor = Color3.new(1, 1, 1), Glow = true })

	-- Players vote by standing on this zone in front of the door.
	local zone = block(model, "VoteZone", Vector3.new(10, 0.1, 14), at(sign * 53, 1.06, 0), color, Enum.Material.Neon)
	zone.Transparency = 0.7
	zone.CanCollide = false
	zone.CanQuery = false
	zone.CastShadow = false

	return { Model = model, Door = door, Zone = zone }
end

local function buildCar(map: Folder)
	local car = Instance.new("Model")
	car.Name = "TrainCar"
	car.Parent = map

	block(car, "Floor", Vector3.new(40, 4, 9), at(0, -1, 14.5), Color3.fromRGB(80, 80, 85), Enum.Material.DiamondPlate)
	block(car, "Roof", Vector3.new(40, 1, 9), at(0, 10.5, 14.5), COLORS.CarBody, Enum.Material.Metal)
	block(car, "FarWall", Vector3.new(40, 9, 0.5), at(0, 5.5, 18.75), COLORS.CarBody, Enum.Material.Metal)
	block(car, "Window", Vector3.new(36, 2.5, 0.1), at(0, 6.5, 18.45), Color3.fromRGB(10, 12, 16), Enum.Material.Glass)
	block(car, "Stripe", Vector3.new(40, 0.6, 0.1), at(0, 8.4, 18.45), COLORS.CarStripe)
	block(car, "EndWallWest", Vector3.new(0.5, 9, 9), at(-19.75, 5.5, 14.5), COLORS.CarBody, Enum.Material.Metal)
	block(car, "EndWallEast", Vector3.new(0.5, 9, 9), at(19.75, 5.5, 14.5), COLORS.CarBody, Enum.Material.Metal)

	-- Platform side: three wall segments with two door openings (X -12.5..-7.5 and 7.5..12.5).
	block(car, "SideWallWest", Vector3.new(7.5, 9, 0.5), at(-16.25, 5.5, 11.25), COLORS.CarBody, Enum.Material.Metal)
	block(car, "SideWallMiddle", Vector3.new(15, 9, 0.5), at(0, 5.5, 11.25), COLORS.CarBody, Enum.Material.Metal)
	block(car, "SideWallEast", Vector3.new(7.5, 9, 0.5), at(16.25, 5.5, 11.25), COLORS.CarBody, Enum.Material.Metal)

	local doorPanels = {}
	for _, centerX in { -10, 10 } do
		block(car, "DoorHeader", Vector3.new(5, 2, 0.5), at(centerX, 9, 11.25), COLORS.CarBody, Enum.Material.Metal)
		for _, side in { -1, 1 } do
			local closed = at(centerX + side * 1.25, 4.5, 11.75)
			local open = at(centerX + side * 3.6, 4.5, 11.75)
			local panel = block(car, "DoorPanel", Vector3.new(2.5, 7, 0.3), closed, Color3.fromRGB(170, 175, 182), Enum.Material.Metal)
			table.insert(doorPanels, { Part = panel, Closed = closed, Open = open })
		end
	end

	-- Seats along the far wall, poles down the middle, a light strip on the roof.
	for _, centerX in { -10, 10 } do
		block(car, "Seat", Vector3.new(14, 0.6, 1.8), at(centerX, 2.6, 17.6), COLORS.CarSeat, Enum.Material.Fabric)
		block(car, "SeatBack", Vector3.new(14, 2.5, 0.4), at(centerX, 4, 18.3), COLORS.CarSeat, Enum.Material.Fabric)
	end
	for _, x in { -15, 0, 15 } do
		local pole = block(car, "Pole", Vector3.new(9, 0.3, 0.3), at(x, 5.5, 14.5) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(190, 190, 195), Enum.Material.Metal)
		pole.Shape = Enum.PartType.Cylinder
	end
	local strip = block(car, "LightStrip", Vector3.new(36, 0.2, 0.8), at(0, 9.9, 14.5), Color3.fromRGB(240, 245, 255), Enum.Material.Neon)
	local carLight = Instance.new("SurfaceLight")
	carLight.Face = Enum.NormalId.Bottom
	carLight.Range = 12
	carLight.Angle = 120
	carLight.Brightness = 1.2
	carLight.Parent = strip

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "TrainSpawn"
	spawn.Size = Vector3.new(8, 0.1, 2)
	spawn.CFrame = at(0, 1.05, 13.5)
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Transparency = 1
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = car

	local standPoints = {}
	for x = -16, 16, 4 do
		table.insert(standPoints, at(x, 4, 13.5))
	end

	return car, doorPanels, standPoints
end

local function buildStation(map: Folder, refs)
	local station = Instance.new("Folder")
	station.Name = "Station"
	station.Parent = map

	-- Pillars down the middle of the platform.
	refs.Pillars = {}
	for _, x in { -40, -20, 0, 20, 40 } do
		local pillar = block(station, "Pillar", Vector3.new(2, 15, 2), at(x, 8.5, 1), COLORS.Pillar, Enum.Material.Marble)
		pillar:SetAttribute("X", x)
		table.insert(refs.Pillars, pillar)
	end

	-- Ceiling lights.
	refs.Lights = {}
	for x = -50, 50, 20 do
		local fixture = block(station, "Light", Vector3.new(8, 0.2, 1), at(x, 15.9, 0), COLORS.Light, Enum.Material.Neon)
		local light = Instance.new("SurfaceLight")
		light.Face = Enum.NormalId.Bottom
		light.Range = 18
		light.Angle = 120
		light.Color = COLORS.Light
		light.Brightness = 1.4
		light.Parent = fixture
		table.insert(refs.Lights, fixture)
	end

	-- Benches against the back wall, facing the track.
	refs.Benches = {}
	for _, x in { -30, -10, 10, 30 } do
		local bench = Instance.new("Model")
		bench.Name = "Bench"
		local seat = block(bench, "Seat", Vector3.new(6, 0.5, 1.8), at(x, 2.75, -8.3), COLORS.Bench, Enum.Material.WoodPlanks)
		block(bench, "Backrest", Vector3.new(6, 1.8, 0.4), at(x, 4, -9.2), COLORS.Bench, Enum.Material.WoodPlanks)
		block(bench, "LegWest", Vector3.new(0.4, 1.5, 1.4), at(x - 2.6, 1.75, -8.3), COLORS.Dark, Enum.Material.Metal)
		block(bench, "LegEast", Vector3.new(0.4, 1.5, 1.4), at(x + 2.6, 1.75, -8.3), COLORS.Dark, Enum.Material.Metal)
		bench.PrimaryPart = seat
		bench:SetAttribute("Free", x == 10)
		bench.Parent = station
		table.insert(refs.Benches, bench)
	end

	-- Station name and line badge.
	local nameSign = block(station, "StationSign", Vector3.new(16, 3, 0.3), at(0, 11, -9.85), Color3.fromRGB(20, 40, 80))
	refs.StationName = surfaceText(nameSign, Enum.NormalId.Back, "محطة النور", { TextColor = Color3.new(1, 1, 1) })
	local badge = block(station, "LineBadge", Vector3.new(3, 3, 0.3), at(10, 11, -9.85), COLORS.Edge)
	refs.LineBadge = surfaceText(badge, Enum.NormalId.Back, "14", { TextColor = COLORS.Dark })

	-- Digital clock. The game loop ticks it unless its "Frozen" attribute is set.
	refs.Clock = block(station, "Clock", Vector3.new(3.4, 1.4, 0.3), at(-10, 11, -9.85), COLORS.Dark)
	refs.ClockLabel = surfaceText(refs.Clock, Enum.NormalId.Back, "23:57:00", {
		TextColor = Color3.fromRGB(255, 60, 50),
		Glow = true,
	})

	-- Hanging counter sign, readable when stepping out of the car.
	local counter = block(station, "CounterSign", Vector3.new(7, 2.6, 0.3), at(0, 13.5, 7), COLORS.Dark)
	block(station, "CounterHanger", Vector3.new(0.2, 1.7, 0.2), at(0, 15.15, 7), COLORS.Dark, Enum.Material.Metal)
	refs.CounterLabel = surfaceText(counter, Enum.NormalId.Back, "", { TextColor = COLORS.Edge, Glow = true })

	-- Advertisements on the back wall.
	refs.Posters = {}
	local posters = {
		{ X = -40, Text = "مشروب سبيد\nطاقة لآخر الليل", Color = Color3.fromRGB(230, 120, 30) },
		{ X = -20, Text = "شقق النور\nقسّط على 10 سنين", Color = Color3.fromRGB(40, 90, 170) },
		{ X = 20, Text = "تطبيق مشوار\nمشوارك علينا", Color = Color3.fromRGB(40, 140, 90) },
		{ X = 40, Text = "متحف المترو\nافتتاح قريبًا", Color = Color3.fromRGB(110, 60, 150) },
	}
	for _, info in posters do
		local poster = block(station, "Poster", Vector3.new(5, 7, 0.2), at(info.X, 7.5, -9.9), info.Color)
		table.insert(refs.Posters, surfaceText(poster, Enum.NormalId.Back, info.Text, { Background = info.Color }))
	end

	-- Passengers. The game never says who they are.
	refs.Passengers = {
		Mannequin.create("Passenger", "Sit", at(-30, 3, -8.1) * CFrame.Angles(0, math.pi, 0), Color3.fromRGB(40, 55, 90)),
		Mannequin.create("Passenger", "Sit", at(30, 3, -8.1) * CFrame.Angles(0, math.pi, 0), Color3.fromRGB(110, 75, 50)),
		Mannequin.create("Passenger", "Stand", at(-5, 3, -3) * CFrame.Angles(0, math.pi, 0), Color3.fromRGB(95, 95, 100)),
		Mannequin.create("Passenger", "Sit", at(-10, 2.9, 17.4), Color3.fromRGB(120, 40, 45)),
	}
	for _, passenger in refs.Passengers do
		passenger.Parent = station
	end

	-- Hints at the twist. Nobody gets them the first time.
	local newspaper = block(station, "Newspaper", Vector3.new(2, 0.05, 1.4), at(-10.8, 3.03, -8.2), Color3.fromRGB(235, 232, 220))
	refs.NewspaperLabel = surfaceText(newspaper, Enum.NormalId.Top, "جريدة المترو\n" .. tomorrowText(), {
		Background = Color3.fromRGB(235, 232, 220),
		TextColor = COLORS.Dark,
		PixelsPerStud = 80,
	})

	local flowers = Instance.new("Model")
	flowers.Name = "Flowers"
	for i, color in { Color3.fromRGB(200, 30, 40), Color3.fromRGB(245, 245, 240), Color3.fromRGB(200, 30, 40) } do
		local offset = (i - 2) * 0.35
		local base = at(1.8 + offset, 1.1, 2.6) * CFrame.Angles(0, math.rad(20 * (i - 2)), 0)
		block(flowers, "Stem", Vector3.new(0.12, 0.12, 1.6), base, Color3.fromRGB(50, 110, 50))
		local bloom = block(flowers, "Bloom", Vector3.new(0.45, 0.45, 0.45), base * CFrame.new(0, 0.1, -0.85), color)
		bloom.Shape = Enum.PartType.Ball
	end
	flowers.Parent = station

	local phone = block(station, "Phone", Vector3.new(0.7, 0.06, 1.2), at(34, 1.03, 4) * CFrame.Angles(0, math.rad(25), 0), COLORS.Dark)
	refs.PhoneLabel = surfaceText(phone, Enum.NormalId.Top, "12 مكالمة فايتة", {
		Background = Color3.fromRGB(10, 10, 14),
		TextColor = Color3.fromRGB(230, 230, 235),
		Glow = true,
		PixelsPerStud = 90,
	})
	local glow = Instance.new("PointLight")
	glow.Range = 4
	glow.Brightness = 0.6
	glow.Color = Color3.fromRGB(200, 220, 255)
	glow.Parent = phone

	refs.Station = station
end

-- Builds the map into Workspace.EndlessSubway and returns references the game loop and anomalies use.
function MapBuilder.build()
	clearDefaultPlace()

	local existing = Workspace:FindFirstChild("EndlessSubway")
	if existing then
		existing:Destroy()
	end

	local map = Instance.new("Folder")
	map.Name = "EndlessSubway"

	local refs: any = { Map = map, Origin = ORIGIN }

	buildShell(map)
	refs.Doors = {
		Continue = buildExitDoor(map, "Continue"),
		Back = buildExitDoor(map, "Back"),
	}
	refs.Car, refs.DoorPanels, refs.StandPoints = buildCar(map)
	buildStation(map, refs)

	map.Parent = Workspace
	return refs
end

-- Converts map-local coordinates (see the layout at the top) to a world CFrame.
function MapBuilder.at(x: number, y: number, z: number): CFrame
	return at(x, y, z)
end

return MapBuilder
