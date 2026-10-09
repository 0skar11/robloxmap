-- Builds one station in code, styled after real metro stations: a tiled platform with a tactile
-- edge strip, ceiling beams with wide light panels, two-tone pillars, metal seats, and a silver
-- train (an open car you ride in, two closed cars, and the driver's cab at the front).
-- Every group from the lobby gets its own copy, built at its own origin and in its own language.
--
-- Layout (studs, relative to the station origin). The platform runs along X, the track is on +Z.
--   Platform floor      X -100..100, Z -10..10, top at Y 1
--   Train cars          side walls at Z 11 (platform) and Z 24.5 (tunnel), floor top at Y 1
--     Open car          X -20..20, the one the group rides in
--     Closed cars       X -62..-22 and 22..62
--     Driver's cab      X 64..84, the front of the train (it heads toward +X)
--   CONTINUE door       +X end of the platform
--   GO BACK door        -X end of the platform (missing on level 1)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Strings = require(ReplicatedStorage.Shared.Strings)
local Build = require(script.Parent.Build)
local Npc = require(script.Parent.Npc)
local NpcOutfits = require(script.Parent.NpcOutfits)

local block = Build.block
local surfaceText = Build.surfaceText

local HALF_LENGTH = 100

-- Car cross-section (shared by every car).
local CAR = {
	OuterNear = 11, -- platform-side outer face
	OuterFar = 24.5, -- tunnel-side outer face
	Wall = 0.5,
	FloorTop = 1,
	WindowBottom = 5,
	WindowTop = 9,
	DoorTop = 9,
	RoofBottom = 12,
	DoorHalfWidth = 3.5,
}

local COLORS = {
	Floor = Color3.fromRGB(214, 214, 210),
	Wall = Color3.fromRGB(222, 224, 226),
	WallSeam = Color3.fromRGB(170, 174, 180),
	WallStripe = Color3.fromRGB(60, 110, 170),
	Ceiling = Color3.fromRGB(205, 207, 210),
	Beam = Color3.fromRGB(90, 94, 100),
	Pillar = Color3.fromRGB(225, 226, 228),
	PillarBand = Color3.fromRGB(150, 200, 60),
	Edge = Color3.fromRGB(235, 185, 20),
	EdgeBar = Color3.fromRGB(35, 35, 38),
	CarBody = Color3.fromRGB(176, 181, 188),
	CarGroove = Color3.fromRGB(130, 135, 142),
	CarRoof = Color3.fromRGB(205, 208, 212),
	CarInside = Color3.fromRGB(225, 228, 232),
	CarSeat = Color3.fromRGB(95, 175, 190),
	CarFloor = Color3.fromRGB(120, 140, 155),
	Glass = Color3.fromRGB(150, 180, 200),
	Strap = Color3.fromRGB(215, 200, 140),
	Metal = Color3.fromRGB(165, 168, 172),
	CabBlue = Color3.fromRGB(40, 85, 150),
	Dark = Color3.fromRGB(18, 18, 20),
	SeatShell = Color3.fromRGB(150, 95, 45),
	Continue = Color3.fromRGB(40, 140, 80),
	Back = Color3.fromRGB(170, 50, 45),
	Light = Color3.fromRGB(255, 246, 228),
	TunnelLamp = Color3.fromRGB(255, 150, 40),
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

local function noCollide(part: BasePart): BasePart
	part.CanCollide = false
	part.CastShadow = false
	return part
end

-- A dark "window" painted on both faces of a door panel, so the window moves with the panel.
local function doorWindow(panel: BasePart)
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.Parent = panel
		local window = Instance.new("Frame")
		window.AnchorPoint = Vector2.new(0.5, 0)
		window.Position = UDim2.fromScale(0.5, 0.1)
		window.Size = UDim2.fromScale(0.62, 0.36)
		window.BackgroundColor3 = Color3.fromRGB(30, 40, 50)
		window.BorderSizePixel = 0
		window.Parent = gui
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.15, 0)
		corner.Parent = window
	end
end

-- ===== Station shell =====

local function buildShell(map: Folder)
	local shell = Instance.new("Folder")
	shell.Name = "Shell"
	shell.Parent = map

	local length = HALF_LENGTH * 2
	block(shell, "Platform", Vector3.new(length, 5, 20), at(0, -1.5, 0), COLORS.Floor, Enum.Material.CeramicTiles)

	-- Tactile strip along the platform edge: yellow with dark bars.
	block(shell, "EdgeStrip", Vector3.new(length, 0.06, 1.6), at(0, 1.03, 9), COLORS.Edge)
	for x = -HALF_LENGTH + 1, HALF_LENGTH - 1, 2.5 do
		block(shell, "EdgeBar", Vector3.new(0.5, 0.08, 1.6), at(x, 1.04, 9), COLORS.EdgeBar)
	end
	block(shell, "EdgeLip", Vector3.new(length, 0.3, 0.4), at(0, 0.85, 9.8), Color3.fromRGB(240, 240, 238))

	-- Back wall: light panels with seams and a blue stripe.
	block(shell, "BackWall", Vector3.new(length + 2, 20, 1), at(0, 6, -10.5), COLORS.Wall, Enum.Material.SmoothPlastic)
	block(shell, "WallStripe", Vector3.new(length, 1.2, 0.1), at(0, 2.4, -9.95), COLORS.WallStripe)
	block(shell, "WallBase", Vector3.new(length, 1.4, 0.15), at(0, 1.7, -9.9), Color3.fromRGB(70, 75, 82))
	for x = -HALF_LENGTH + 10, HALF_LENGTH - 10, 10 do
		block(shell, "WallSeam", Vector3.new(0.15, 13, 0.08), at(x, 9.5, -9.97), COLORS.WallSeam)
	end

	-- Tunnel side, with small orange lamps.
	block(shell, "TunnelWall", Vector3.new(length + 2, 20, 1), at(0, 6, 27.5), Color3.fromRGB(45, 45, 48), Enum.Material.Concrete)
	for x = -HALF_LENGTH + 12, HALF_LENGTH - 12, 25 do
		noCollide(block(shell, "TunnelLamp", Vector3.new(3, 0.4, 0.2), at(x, 9, 26.9), COLORS.TunnelLamp, Enum.Material.Neon))
	end

	-- Ceiling with cross beams between the light panels.
	block(shell, "Ceiling", Vector3.new(length + 2, 1, 39), at(0, 16.5, 8.5), COLORS.Ceiling, Enum.Material.SmoothPlastic)
	for x = -HALF_LENGTH, HALF_LENGTH, 20 do
		block(shell, "Beam", Vector3.new(1.5, 1.2, 20.5), at(x, 15.4, -0.25), COLORS.Beam, Enum.Material.Metal)
	end

	block(shell, "TrackBed", Vector3.new(length, 1, 17), at(0, -3.5, 18.5), COLORS.Dark, Enum.Material.Slate)
	block(shell, "RailNear", Vector3.new(length, 0.4, 0.4), at(0, -2.8, 15.5), Color3.fromRGB(90, 90, 95), Enum.Material.Metal)
	block(shell, "RailFar", Vector3.new(length, 0.4, 0.4), at(0, -2.8, 20.5), Color3.fromRGB(90, 90, 95), Enum.Material.Metal)

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

	-- The wall belongs to the map; the door model can be removed on its own (see GameLoop).
	block(map, kind .. "EndWall", Vector3.new(1, 20, 39), at(wallX, 6, 8.5), COLORS.Wall)

	local model = Instance.new("Model")
	model.Name = kind .. "Door"
	model.Parent = map

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

-- ===== Train =====

-- One side wall of a car between x0 and x1, at outer face z (near or far side). Door openings are
-- centred on doorXs; windows fill the wall between them. Returns nothing: doors are added by the
-- caller (sliding on the open car, fixed elsewhere).
local function carSide(car: Model, x0: number, x1: number, doorXs: { number }, outerZ: number, inward: number)
	local wallZ = outerZ + inward * CAR.Wall / 2
	local grooveZ = outerZ - inward * 0.03
	local windowY = (CAR.WindowBottom + CAR.WindowTop) / 2
	local windowHeight = CAR.WindowTop - CAR.WindowBottom

	-- Solid sections between the doors.
	local edges = { x0 }
	for _, doorX in doorXs do
		table.insert(edges, doorX - CAR.DoorHalfWidth)
		table.insert(edges, doorX + CAR.DoorHalfWidth)
	end
	table.insert(edges, x1)

	for i = 1, #edges, 2 do
		local a, b = edges[i], edges[i + 1]
		local len = b - a
		local mid = (a + b) / 2
		block(car, "WallLow", Vector3.new(len, CAR.WindowBottom - CAR.FloorTop, CAR.Wall), at(mid, (CAR.FloorTop + CAR.WindowBottom) / 2, wallZ), COLORS.CarBody, Enum.Material.Metal)
		block(car, "WallHigh", Vector3.new(len, CAR.RoofBottom - CAR.WindowTop, CAR.Wall), at(mid, (CAR.WindowTop + CAR.RoofBottom) / 2, wallZ), COLORS.CarBody, Enum.Material.Metal)
		local glass = block(car, "Window", Vector3.new(len, windowHeight, 0.2), at(mid, windowY, wallZ), COLORS.Glass, Enum.Material.Glass)
		glass.Transparency = 0.55
		-- Window posts: at both ends and about every 6.5 studs.
		local posts = math.max(1, math.floor(len / 6.5))
		for p = 0, posts do
			local x = a + 0.3 + (len - 0.6) * p / posts
			block(car, "WindowPost", Vector3.new(0.6, windowHeight, CAR.Wall + 0.1), at(x, windowY, wallZ), COLORS.CarBody, Enum.Material.Metal)
		end
		-- Ribbed lines along the lower body.
		for _, y in { 2.2, 3.4 } do
			noCollide(block(car, "Groove", Vector3.new(len, 0.15, 0.05), at(mid, y, grooveZ), COLORS.CarGroove, Enum.Material.Metal))
		end
	end

	for _, doorX in doorXs do
		block(car, "DoorHeader", Vector3.new(CAR.DoorHalfWidth * 2, CAR.RoofBottom - CAR.DoorTop, CAR.Wall), at(doorX, (CAR.DoorTop + CAR.RoofBottom) / 2, wallZ), COLORS.CarBody, Enum.Material.Metal)
	end
end

-- Floor, curved-looking roof, end walls with end doors, and both side walls. openFront leaves the
-- +X end open (the cab puts its windshield there).
local function carShell(car: Model, x0: number, x1: number, doorXs: { number }, farDoorXs: { number }, openFront: boolean?)
	local mid = (x0 + x1) / 2
	local len = x1 - x0
	local width = CAR.OuterFar - CAR.OuterNear
	local midZ = (CAR.OuterNear + CAR.OuterFar) / 2

	block(car, "Floor", Vector3.new(len, 4, width + 1), at(mid, CAR.FloorTop - 2, midZ - 0.5), COLORS.CarFloor, Enum.Material.SmoothPlastic)
	for _, z in { 15.5, 20 } do
		noCollide(block(car, "FloorLine", Vector3.new(len - 1, 0.03, 0.3), at(mid, CAR.FloorTop + 0.02, z), Color3.fromRGB(235, 230, 200)))
	end

	-- Roof: a slab, a raised middle and sloped edges, so it reads as rounded from the platform.
	block(car, "Roof", Vector3.new(len, 1, width), at(mid, CAR.RoofBottom + 0.5, midZ), COLORS.CarRoof, Enum.Material.Metal)
	block(car, "RoofTop", Vector3.new(len, 0.8, width - 4), at(mid, CAR.RoofBottom + 1.4, midZ), COLORS.CarRoof, Enum.Material.Metal)
	local nearEdge = Instance.new("WedgePart")
	nearEdge.Name = "RoofEdge"
	nearEdge.Size = Vector3.new(len, 0.8, 2)
	nearEdge.CFrame = at(mid, CAR.RoofBottom + 1.4, CAR.OuterNear + 1)
	nearEdge.Color = COLORS.CarRoof
	nearEdge.Material = Enum.Material.Metal
	nearEdge.Anchored = true
	nearEdge.Parent = car
	local farEdge = nearEdge:Clone()
	farEdge.CFrame = at(mid, CAR.RoofBottom + 1.4, CAR.OuterFar - 1) * CFrame.Angles(0, math.pi, 0)
	farEdge.Parent = car

	-- Inside ceiling panel.
	noCollide(block(car, "CeilingPanel", Vector3.new(len - 1, 0.1, width - 1.2), at(mid, CAR.RoofBottom - 0.05, midZ), COLORS.CarInside))

	-- End walls, each with an end door (and its little window) on the inside.
	for _, side in { -1, 1 } do
		if side > 0 and openFront then
			continue
		end
		local x = if side < 0 then x0 + CAR.Wall / 2 else x1 - CAR.Wall / 2
		block(car, "EndWall", Vector3.new(CAR.Wall, CAR.RoofBottom - CAR.FloorTop, width - 1), at(x, (CAR.FloorTop + CAR.RoofBottom) / 2, midZ), COLORS.CarInside)
		-- Turned a quarter so its Front and Back faces (where the window is painted) face along X.
		local endDoor = noCollide(block(car, "EndDoor", Vector3.new(3, 7.5, 0.1), at(x - side * 0.3, CAR.FloorTop + 3.75, midZ) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(150, 170, 190), Enum.Material.Metal))
		doorWindow(endDoor)
	end

	carSide(car, x0, x1, doorXs, CAR.OuterNear, 1)
	carSide(car, x0, x1, farDoorXs, CAR.OuterFar, -1)
end

-- A fixed (closed) door pair in an opening.
local function fixedDoors(car: Model, doorX: number, outerZ: number, inward: number)
	for _, side in { -1, 1 } do
		local panel = block(car, "Door", Vector3.new(CAR.DoorHalfWidth, CAR.DoorTop - CAR.FloorTop, 0.3), at(doorX + side * CAR.DoorHalfWidth / 2, (CAR.FloorTop + CAR.DoorTop) / 2, outerZ + inward * 0.25), COLORS.CarBody, Enum.Material.Metal)
		doorWindow(panel)
	end
end

-- Bench seats along a wall section, between x0 and x1, facing into the car.
local function benches(car: Model, x0: number, x1: number, wallInnerZ: number, facing: number)
	if x1 - x0 < 3 then
		return
	end
	local mid = (x0 + x1) / 2
	local len = x1 - x0
	local seatZ = wallInnerZ + facing * 1.3
	block(car, "BenchSeat", Vector3.new(len, 0.6, 1.8), at(mid, 2.6, seatZ), COLORS.CarSeat)
	block(car, "BenchBack", Vector3.new(len, 2.6, 0.4), at(mid, 4.2, wallInnerZ + facing * 0.2), COLORS.CarSeat)
	block(car, "BenchBase", Vector3.new(len, 1.3, 1.4), at(mid, 1.65, seatZ - facing * 0.1), Color3.fromRGB(70, 80, 90), Enum.Material.Metal)
	for _, x in { x0 + 0.1, x1 - 0.1 } do
		noCollide(block(car, "Armrest", Vector3.new(0.2, 0.2, 1.7), at(x, 3.8, seatZ), COLORS.Metal, Enum.Material.Metal))
		noCollide(block(car, "ArmrestPost", Vector3.new(0.2, 1, 0.2), at(x, 3.2, seatZ + facing * 0.75), COLORS.Metal, Enum.Material.Metal))
	end
end

-- Benches along both walls, in every section that is not a door.
local function carBenches(car: Model, x0: number, x1: number, doorXs: { number })
	local edges = { x0 + CAR.Wall + 0.3 }
	for _, doorX in doorXs do
		table.insert(edges, doorX - CAR.DoorHalfWidth - 0.4)
		table.insert(edges, doorX + CAR.DoorHalfWidth + 0.4)
	end
	table.insert(edges, x1 - CAR.Wall - 0.3)
	for i = 1, #edges, 2 do
		benches(car, edges[i], edges[i + 1], CAR.OuterNear + CAR.Wall, 1)
		benches(car, edges[i], edges[i + 1], CAR.OuterFar - CAR.Wall, -1)
	end
end

local function buildClosedCar(map: Folder, refs, x0: number, x1: number)
	local car = Instance.new("Model")
	car.Name = "ClosedCar"
	car.Parent = map

	local mid = (x0 + x1) / 2
	local doorXs = { mid - 10, mid + 10 }
	carShell(car, x0, x1, doorXs, doorXs)
	for _, doorX in doorXs do
		fixedDoors(car, doorX, CAR.OuterNear, 1)
		fixedDoors(car, doorX, CAR.OuterFar, -1)
	end
	carBenches(car, x0, x1, doorXs)

	-- Its lights are station lights: on in the bright levels, dead in the dark ones.
	local light = Build.ceilingLight(car, "Light", Vector3.new(x1 - x0 - 4, 0.2, 0.8), at(mid, CAR.RoofBottom - 0.15, 17.75), COLORS.Light, 1, 12)
	light:SetAttribute("DiesInHorror", true)
	table.insert(refs.Lights, light)
end

-- The open car: wide doors that slide, benches along both walls, hand straps over the aisle.
local function buildCar(map: Folder, language: string)
	local car = Instance.new("Model")
	car.Name = "TrainCar"
	car.Parent = map

	local x0, x1 = -20, 20
	local doorXs = { -10, 10 }
	carShell(car, x0, x1, doorXs, doorXs)
	for _, doorX in doorXs do
		fixedDoors(car, doorX, CAR.OuterFar, -1)
	end
	carBenches(car, x0, x1, doorXs)

	local doorPanels = {}
	for _, doorX in doorXs do
		for _, side in { -1, 1 } do
			local half = CAR.DoorHalfWidth / 2
			-- Pocket doors: they slide sideways into the wall itself.
			local wallZ = CAR.OuterNear + CAR.Wall / 2
			local closed = at(doorX + side * half, (CAR.FloorTop + CAR.DoorTop) / 2, wallZ)
			local open = at(doorX + side * (CAR.DoorHalfWidth + half + 0.1), (CAR.FloorTop + CAR.DoorTop) / 2, wallZ)
			local panel = block(car, "DoorPanel", Vector3.new(CAR.DoorHalfWidth, CAR.DoorTop - CAR.FloorTop, 0.3), closed, COLORS.CarBody, Enum.Material.Metal)
			doorWindow(panel)
			table.insert(doorPanels, { Part = panel, Closed = closed, Open = open })
		end
	end

	-- Grab bars with hand straps over both sides of the aisle.
	for _, z in { 14.6, 20.9 } do
		local bar = noCollide(block(car, "GrabBar", Vector3.new(38, 0.22, 0.22), at(0, 11.3, z), COLORS.Metal, Enum.Material.Metal))
		bar.Shape = Enum.PartType.Cylinder
		for x = -18, 18, 2 do
			noCollide(block(car, "Strap", Vector3.new(0.08, 1, 0.08), at(x, 10.7, z), Color3.fromRGB(235, 235, 235)))
			noCollide(block(car, "StrapRing", Vector3.new(0.12, 0.55, 0.45), at(x, 10, z), COLORS.Strap))
		end
	end

	-- Ads above the windows inside.
	local texts = Strings.get(language, "Posters")
	for i, x in { -17, -3, 3, 17 } do
		local ad = noCollide(block(car, "Ad", Vector3.new(3.2, 1.4, 0.05), at(x, 10.4, CAR.OuterFar - CAR.Wall - 0.05), POSTER_COLORS[i]))
		surfaceText(ad, Enum.NormalId.Front, texts[i], { Background = POSTER_COLORS[i], PixelsPerStud = 60 })
	end

	for _, z in { 14.6, 20.9 } do
		Build.ceilingLight(car, "LightStrip", Vector3.new(36, 0.15, 0.8), at(0, CAR.RoofBottom - 0.2, z), Color3.fromRGB(240, 245, 255), 1.1, 14)
	end

	-- Where the group stands when the train stops: two rows in the aisle, enough for 10 players.
	local standPoints = {}
	for _, z in { 15.5, 19 } do
		for x = -16, 16, 4 do
			table.insert(standPoints, at(x, 4, z))
		end
	end

	return car, doorPanels, standPoints
end

-- The driver's cab at the front: blue face with a wide windshield and round headlights, a control
-- desk inside, and a driver you can see through the side windows.
local function buildCab(map: Folder, refs)
	local cab = Instance.new("Model")
	cab.Name = "DriverCab"
	cab.Parent = map

	local x0, x1 = 64, 84
	carShell(cab, x0, x1, {}, {}, true)
	local midZ = (CAR.OuterNear + CAR.OuterFar) / 2
	local width = CAR.OuterFar - CAR.OuterNear

	-- Blue front face, over the end wall.
	local faceX = x1 + 0.3
	block(cab, "FaceLow", Vector3.new(0.6, 5, width), at(faceX, 3.5, midZ), COLORS.CabBlue, Enum.Material.SmoothPlastic)
	block(cab, "FaceHigh", Vector3.new(0.6, 2.5, width), at(faceX, 11.25, midZ), COLORS.CabBlue, Enum.Material.SmoothPlastic)
	local windshield = block(cab, "Windshield", Vector3.new(0.2, 4, width - 1), at(faceX, 8, midZ), COLORS.Glass, Enum.Material.Glass)
	windshield.Transparency = 0.45
	for _, z in { midZ - 2.6, midZ + 2.6 } do
		block(cab, "WindshieldPost", Vector3.new(0.7, 4, 0.6), at(faceX, 8, z), COLORS.CabBlue)
	end
	noCollide(block(cab, "FaceStripe", Vector3.new(0.65, 0.4, width), at(faceX, 5.6, midZ), Color3.fromRGB(230, 232, 235)))
	local badge = noCollide(block(cab, "Badge", Vector3.new(0.65, 1.2, 1.6), at(faceX + 0.02, 3.6, midZ), Color3.fromRGB(235, 185, 20)))
	surfaceText(badge, Enum.NormalId.Right, "14", { TextColor = COLORS.Dark, Background = Color3.fromRGB(235, 185, 20) })

	-- Two pairs of round headlights.
	for _, z in { midZ - 5.2, midZ - 3.9, midZ + 3.9, midZ + 5.2 } do
		local lamp = noCollide(block(cab, "Headlight", Vector3.new(0.3, 1, 1), at(faceX + 0.35, 3.4, z), Color3.fromRGB(255, 250, 225), Enum.Material.Neon))
		lamp.Shape = Enum.PartType.Cylinder
	end
	for _, z in { midZ - 4.5, midZ + 4.5 } do
		local beam = Instance.new("SpotLight")
		beam.Face = Enum.NormalId.Right
		beam.Range = 40
		beam.Angle = 50
		beam.Brightness = 2
		beam.Color = Color3.fromRGB(255, 248, 225)
		local holder = noCollide(block(cab, "HeadlightBeam", Vector3.new(0.2, 0.2, 0.2), at(faceX + 0.5, 3.4, z), COLORS.CabBlue))
		holder.Transparency = 1
		beam.Parent = holder
	end

	-- Control desk and the driver's seat.
	local desk = block(cab, "ControlDesk", Vector3.new(2.5, 3.5, 9), at(x1 - 1.9, 2.75, midZ) * CFrame.Angles(0, 0, math.rad(-12)), Color3.fromRGB(35, 38, 42), Enum.Material.Metal)
	desk.Name = "ControlDesk"
	for i, color in { Color3.fromRGB(60, 220, 90), Color3.fromRGB(240, 70, 60), Color3.fromRGB(250, 200, 40), Color3.fromRGB(70, 160, 255) } do
		noCollide(block(cab, "Button", Vector3.new(0.3, 0.3, 0.6), at(x1 - 2.9, 4.65, midZ - 3 + i * 1.2), color, Enum.Material.Neon))
	end
	noCollide(block(cab, "Throttle", Vector3.new(0.25, 1.4, 0.25), at(x1 - 3.1, 5.1, midZ + 2.8) * CFrame.Angles(0, 0, math.rad(20)), Color3.fromRGB(20, 20, 22), Enum.Material.Metal))
	block(cab, "DriverSeat", Vector3.new(2, 2, 2), at(x1 - 6, 2, midZ), Color3.fromRGB(60, 70, 90), Enum.Material.Fabric)
	block(cab, "DriverSeatBack", Vector3.new(0.4, 3, 2), at(x1 - 7.2, 4.5, midZ), Color3.fromRGB(60, 70, 90), Enum.Material.Fabric)
	Build.ceilingLight(cab, "CabLight", Vector3.new(4, 0.15, 2), at(x1 - 8, CAR.RoofBottom - 0.2, midZ), Color3.fromRGB(235, 240, 255), 0.9, 12)

	-- The driver faces the way the train goes (+X).
	refs.Driver = Npc.create("Driver", "Sit", at(x1 - 6, 3, midZ) * CFrame.Angles(0, -math.pi / 2, 0), Color3.fromRGB(25, 45, 85), NpcOutfits.Driver)
	refs.Driver.Parent = cab
	refs.Cab = cab
end

-- Rubber gangways between cars.
local function gangways(map: Folder)
	for _, x in { -21, 21, 63 } do
		block(map, "Gangway", Vector3.new(2, 9, 5), at(x, 6, 17.75), Color3.fromRGB(30, 30, 32), Enum.Material.Rubber)
	end
end

-- ===== Platform furniture =====

-- A row of three metal seats. The middle seat is the PrimaryPart (anomalies turn the bench around
-- it, and seated passengers sit on it).
local function seatRow(station: Folder, x: number): Model
	local bench = Instance.new("Model")
	bench.Name = "Bench"
	local middle = nil
	for i = -1, 1 do
		local seat = block(bench, "Seat", Vector3.new(1.8, 0.4, 1.7), at(x + i * 2, 2.8, -8.2), COLORS.SeatShell)
		block(bench, "SeatBack", Vector3.new(1.8, 1.8, 0.3), at(x + i * 2, 3.95, -9.05), COLORS.SeatShell)
		if i == 0 then
			middle = seat
		end
	end
	block(bench, "Frame", Vector3.new(6.4, 0.3, 0.6), at(x, 2.45, -8.5), COLORS.Metal, Enum.Material.Metal)
	for _, dx in { -3, 3 } do
		block(bench, "Leg", Vector3.new(0.3, 1.3, 1.2), at(x + dx, 1.65, -8.4), COLORS.Metal, Enum.Material.Metal)
	end
	bench.PrimaryPart = middle
	bench.Parent = station
	return bench
end

local function buildStation(map: Folder, refs, language: string)
	local station = Instance.new("Folder")
	station.Name = "Station"
	station.Parent = map

	-- Two-tone pillars down the middle of the platform, spaced out to keep it open.
	refs.Pillars = {}
	for x = -80, 80, 40 do
		local pillar = Instance.new("Model")
		pillar.Name = "Pillar"
		block(pillar, "Core", Vector3.new(2, 15, 2), at(x, 8.5, 1), COLORS.Pillar, Enum.Material.SmoothPlastic)
		block(pillar, "Band", Vector3.new(2.3, 8, 2.3), at(x, 9, 1), COLORS.PillarBand, Enum.Material.SmoothPlastic)
		block(pillar, "Base", Vector3.new(2.6, 0.6, 2.6), at(x, 1.3, 1), Color3.fromRGB(150, 152, 156), Enum.Material.Metal)
		pillar:SetAttribute("X", x)
		pillar.Parent = station
		table.insert(refs.Pillars, pillar)
	end

	-- Wide ceiling light panels between the beams, plus a second row over the platform edge. In the
	-- dark half of the game some of them die ("DiesInHorror"), which leaves pools of darkness.
	local diesInHorror = { [-70] = true, [-30] = true, [50] = true, [90] = true }
	for x = -90, 90, 20 do
		local fixture = Build.ceilingLight(station, "Light", Vector3.new(8, 0.2, 2.5), at(x, 15.9, 0), COLORS.Light, 1.8, 20)
		fixture:SetAttribute("DiesInHorror", diesInHorror[x] == true)
		table.insert(refs.Lights, fixture)
	end
	for _, x in { -70, -30, 10, 50 } do
		local fixture = Build.ceilingLight(station, "Light", Vector3.new(8, 0.2, 1.5), at(x, 15.9, 7), COLORS.Light, 1.8, 20)
		fixture:SetAttribute("DiesInHorror", true)
		table.insert(refs.Lights, fixture)
	end

	-- Seat rows against the back wall, facing the track.
	local busyBenches = { [-70] = true, [-30] = true, [-10] = true, [30] = true }
	refs.Benches = {}
	for x = -70, 70, 20 do
		local bench = seatRow(station, x)
		bench:SetAttribute("Free", not busyBenches[x])
		table.insert(refs.Benches, bench)
	end

	-- Station name and line badge.
	local nameSign = block(station, "StationSign", Vector3.new(16, 3, 0.3), at(0, 11, -9.85), Color3.fromRGB(20, 45, 95))
	refs.StationName = surfaceText(nameSign, Enum.NormalId.Back, Strings.get(language, "StationName"), { TextColor = Color3.fromRGB(240, 240, 240) })
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
		block(station, "PosterFrame", Vector3.new(5.6, 7.6, 0.15), at(x, 7.5, -9.95), COLORS.Metal, Enum.Material.Metal)
		local poster = block(station, "Poster", Vector3.new(5, 7, 0.2), at(x, 7.5, -9.9), color)
		table.insert(refs.Posters, surfaceText(poster, Enum.NormalId.Back, texts[i], { Background = color }))
	end

	-- A vending machine.
	local vending = block(station, "VendingMachine", Vector3.new(4, 7, 2.5), at(-60, 4.5, -8.6), Color3.fromRGB(180, 30, 35), Enum.Material.Metal)
	local panel = block(station, "VendingPanel", Vector3.new(3, 4, 0.1), at(-60, 5.2, -7.3), Color3.fromRGB(200, 220, 255), Enum.Material.Neon)
	surfaceText(panel, Enum.NormalId.Back, Strings.get(language, "Vending"), {
		Background = Color3.fromRGB(190, 210, 245),
		TextColor = Color3.fromRGB(150, 25, 30),
		Glow = true,
	})
	local vendingLight = Instance.new("PointLight")
	vendingLight.Color = Color3.fromRGB(190, 210, 255)
	vendingLight.Range = 10
	vendingLight.Brightness = 0.7
	vendingLight.Parent = vending

	-- Trash bins: upright cylinders (a cylinder's axis is its X, so turn it to stand up).
	for _, x in { -44, 44 } do
		local bin = block(station, "TrashBin", Vector3.new(2.4, 1.6, 1.6), at(x, 2.2, -9) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(40, 70, 130), Enum.Material.Metal)
		bin.Shape = Enum.PartType.Cylinder
	end

	-- Passengers. The game never says who they are.
	-- Always the same six people, each in the same spot.
	local flip = CFrame.Angles(0, math.pi, 0)
	local outfits = NpcOutfits.Passengers
	refs.Passengers = {
		Npc.create("Passenger", "Sit", at(-30, 3, -8.1) * flip, Color3.fromRGB(40, 55, 90), outfits[1]),
		Npc.create("Passenger", "Sit", at(30, 3, -8.1) * flip, Color3.fromRGB(110, 75, 50), outfits[2]),
		Npc.create("Passenger", "Sit", at(-70, 3, -8.1) * flip, Color3.fromRGB(60, 60, 60), outfits[3]),
		Npc.create("Passenger", "Stand", at(-5, 3, -3) * flip, Color3.fromRGB(95, 95, 100), outfits[4]),
		Npc.create("Passenger", "Stand", at(62, 3, 6) * flip, Color3.fromRGB(70, 40, 60), outfits[5]),
		Npc.create("Passenger", "Sit", at(-2, 2.9, 22.4), Color3.fromRGB(120, 40, 45), outfits[6]),
	}
	for _, passenger in refs.Passengers do
		passenger.Parent = station
	end

	-- Hints at the twist. They only show up once the dark half begins (see GameLoop), and nobody
	-- gets them the first time.
	local newspaper = block(station, "Newspaper", Vector3.new(1.6, 0.05, 1.3), at(-12, 3.03, -8.2), Color3.fromRGB(225, 222, 210))
	refs.NewspaperLabel = surfaceText(newspaper, Enum.NormalId.Top, Strings.get(language, "Newspaper", Strings.tomorrow(language)), {
		Background = Color3.fromRGB(225, 222, 210),
		TextColor = COLORS.Dark,
		PixelsPerStud = 80,
	})

	local flowers = Instance.new("Model")
	flowers.Name = "Flowers"
	for i, color in { Color3.fromRGB(180, 25, 35), Color3.fromRGB(235, 235, 230), Color3.fromRGB(180, 25, 35) } do
		local offset = (i - 2) * 0.35
		local base = at(2 + offset, 1.1, 2.8) * CFrame.Angles(0, math.rad(20 * (i - 2)), 0)
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
		Lights = {},
		At = function(x: number, y: number, z: number): CFrame
			return stationOrigin * CFrame.new(x, y, z)
		end,
	}

	buildShell(map)
	refs.Doors = {
		Continue = buildExitDoor(map, "Continue", language),
		Back = buildExitDoor(map, "Back", language),
	}
	buildClosedCar(map, refs, -62, -22)
	buildClosedCar(map, refs, 22, 62)
	buildCab(map, refs)
	gangways(map)
	refs.Car, refs.DoorPanels, refs.StandPoints = buildCar(map, language)
	buildStation(map, refs, language)

	if withSpawn then
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "TrainSpawn"
		spawn.Size = Vector3.new(16, 0.1, 3)
		spawn.CFrame = at(0, 1.05, 17.25)
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
