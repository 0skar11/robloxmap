-- Turns a person into something horrifying, through an anomaly context so it all comes undone:
-- corpse-pale skin, clothes soaked dark red, blood on the face and chest, and glowing red eyes.

local Gore = {}

local PALE = Color3.fromRGB(170, 175, 168)
local BLOOD = Color3.fromRGB(105, 8, 10)
local SOAKED = Color3.fromRGB(120, 35, 35)

local function stain(ctx, anchor: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3, neon: boolean?)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = anchor.CFrame * offset
	part.Color = color
	part.Material = if neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
	part.Anchored = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.CastShadow = false
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = anchor
	weld.Part1 = part
	weld.Parent = part
	ctx:Add(part, anchor)
	if neon then
		local glow = Instance.new("PointLight")
		glow.Color = color
		glow.Range = 4
		glow.Brightness = 1.5
		glow.Parent = part
	end
end

function Gore.apply(ctx, model: Model)
	local head, chest = nil, nil
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart" and not descendant:FindFirstAncestorOfClass("Accessory") then
			ctx:Set(descendant, "Color", PALE)
			if descendant.Name == "Head" then
				head = descendant
			elseif descendant.Name == "UpperTorso" or descendant.Name == "Torso" then
				chest = descendant
			end
		elseif descendant:IsA("Shirt") or descendant:IsA("Pants") then
			ctx:Set(descendant, "Color3", SOAKED)
		elseif descendant:IsA("ShirtGraphic") then
			ctx:Set(descendant, "Color3", SOAKED)
		end
	end

	if head then
		local front = -head.Size.Z / 2 - 0.03
		-- Glowing eyes, and blood running down from them and the mouth.
		for _, x in { -0.22, 0.22 } do
			stain(ctx, head, "Eye", Vector3.new(0.16, 0.12, 0.05), CFrame.new(x * head.Size.X, 0.1 * head.Size.Y, front), Color3.fromRGB(255, 30, 20), true)
			stain(ctx, head, "Tear", Vector3.new(0.08, 0.35, 0.04), CFrame.new(x * head.Size.X, -0.12 * head.Size.Y, front), BLOOD)
		end
		stain(ctx, head, "Mouth", Vector3.new(0.4, 0.1, 0.04), CFrame.new(0, -0.25 * head.Size.Y, front), BLOOD)
		stain(ctx, head, "Drip", Vector3.new(0.1, 0.3, 0.04), CFrame.new(0.1, -0.38 * head.Size.Y, front), BLOOD)
	end
	if chest then
		local front = -chest.Size.Z / 2 - 0.03
		stain(ctx, chest, "Splatter", Vector3.new(0.8, 0.6, 0.05), CFrame.new(-0.2, 0.2, front) * CFrame.Angles(0, 0, math.rad(25)), BLOOD)
		stain(ctx, chest, "Splatter", Vector3.new(0.4, 0.9, 0.05), CFrame.new(0.35, -0.1, front) * CFrame.Angles(0, 0, math.rad(-10)), BLOOD)
	end
end

return Gore
