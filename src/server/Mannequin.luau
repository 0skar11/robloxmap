-- Faceless block passengers built from anchored parts, so the map needs no uploaded assets.
-- The model's pivot is the hip point; it faces the CFrame's LookVector.

local Mannequin = {}

local SKIN = Color3.fromRGB(204, 176, 150)

local function addPart(model: Model, name: string, size: Vector3, offset: CFrame, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = offset
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = model
	return part
end

local function addEyes(head: Part)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Eyes"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 60
	gui.Parent = head

	for _, x in { 0.28, 0.72 } do
		local eye = Instance.new("Frame")
		eye.AnchorPoint = Vector2.new(0.5, 0.5)
		eye.Position = UDim2.fromScale(x, 0.42)
		eye.Size = UDim2.fromScale(0.12, 0.12)
		eye.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
		eye.BorderSizePixel = 0
		eye.Parent = gui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = eye
	end
end

-- pose: "Stand" (pivot 2 studs above the floor) or "Sit" (pivot on the seat surface).
function Mannequin.create(name: string, pose: "Stand" | "Sit", pivot: CFrame, clothes: Color3): Model
	local model = Instance.new("Model")
	model.Name = name

	local pants = clothes:Lerp(Color3.new(0, 0, 0), 0.5)

	local torso = addPart(model, "Torso", Vector3.new(2, 2, 1), CFrame.new(0, 1, 0), clothes)
	local leftArm = addPart(model, "LeftArm", Vector3.new(1, 2, 1), CFrame.new(-1.5, 1, 0), clothes)
	local rightArm = addPart(model, "RightArm", Vector3.new(1, 2, 1), CFrame.new(1.5, 1, 0), clothes)
	local head = addPart(model, "Head", Vector3.new(1.2, 1.2, 1.2), CFrame.new(0, 2.6, 0), SKIN)
	addEyes(head)

	if pose == "Stand" then
		addPart(model, "LeftLeg", Vector3.new(1, 2, 1), CFrame.new(-0.5, -1, 0), pants)
		addPart(model, "RightLeg", Vector3.new(1, 2, 1), CFrame.new(0.5, -1, 0), pants)
	else
		addPart(model, "LeftThigh", Vector3.new(1, 1, 2), CFrame.new(-0.5, 0.5, -0.5), pants)
		addPart(model, "RightThigh", Vector3.new(1, 1, 2), CFrame.new(0.5, 0.5, -0.5), pants)
		addPart(model, "LeftShin", Vector3.new(1, 2.4, 1), CFrame.new(-0.5, -0.7, -1), pants)
		addPart(model, "RightShin", Vector3.new(1, 2.4, 1), CFrame.new(0.5, -0.7, -1), pants)
		torso.CFrame = CFrame.new(0, 2, 0)
		leftArm.CFrame = CFrame.new(-1.5, 2, 0)
		rightArm.CFrame = CFrame.new(1.5, 2, 0)
		head.CFrame = CFrame.new(0, 3.6, 0)
	end

	model.PrimaryPart = torso
	-- Parts were laid out around the origin, so the origin is the hip pivot.
	model.WorldPivot = CFrame.new()
	model:PivotTo(pivot)
	return model
end

return Mannequin
