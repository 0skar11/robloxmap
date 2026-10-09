-- Small helpers for building maps out of plain anchored parts.

local Build = {}

function Build.block(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?): Part
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

function Build.invisibleWall(parent: Instance, name: string, size: Vector3, cframe: CFrame): Part
	local part = Build.block(parent, name, size, cframe, Color3.new(0, 0, 0))
	part.Transparency = 1
	part.CastShadow = false
	return part
end

export type TextOptions = {
	Background: Color3?,
	TextColor: Color3?,
	Glow: boolean?,
	PixelsPerStud: number?,
}

-- Puts a scaled TextLabel on one face of a part and returns the label.
function Build.surfaceText(target: BasePart, face: Enum.NormalId, text: string, options: TextOptions?): TextLabel
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

-- A ceiling fixture: a thin neon strip with a light shining down.
function Build.ceilingLight(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, brightness: number, range: number): Part
	local fixture = Build.block(parent, name, size, cframe, color, Enum.Material.Neon)
	fixture.CastShadow = false
	local light = Instance.new("SurfaceLight")
	light.Face = Enum.NormalId.Bottom
	light.Range = range
	light.Angle = 120
	light.Color = color
	light.Brightness = brightness
	light.Shadows = true
	light.Parent = fixture
	return fixture
end

return Build
