-- In one of the dark windows of a closed car, a pale face is pressed against the glass, with
-- two hands beside it. The cars are supposed to be empty.

local function piece(ctx, name: string, size: Vector3, cframe: CFrame, color: Color3, neon: boolean?)
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
	ctx:Add(part)
	return part
end

return {
	Name = "FaceInWindow",
	-- Scary: only in the dark half of the game.
	Horror = true,
	Apply = function(ctx)
		-- Spots just behind the platform-side windows, looking out at the platform (-Z).
		local spot: CFrame = ctx:Pick(ctx.Refs.ClosedCarWindows)
		local pale = Color3.fromRGB(205, 208, 200)
		local face = piece(ctx, "Face", Vector3.new(1.4, 1.6, 0.9), spot, pale)
		piece(ctx, "EyeLeft", Vector3.new(0.3, 0.2, 0.05), spot * CFrame.new(-0.3, 0.2, -0.47), Color3.fromRGB(5, 5, 5))
		piece(ctx, "EyeRight", Vector3.new(0.3, 0.2, 0.05), spot * CFrame.new(0.3, 0.2, -0.47), Color3.fromRGB(5, 5, 5))
		piece(ctx, "Mouth", Vector3.new(0.35, 0.45, 0.05), spot * CFrame.new(0, -0.4, -0.47), Color3.fromRGB(15, 5, 5))
		piece(ctx, "HandLeft", Vector3.new(0.6, 0.9, 0.2), spot * CFrame.new(-1.3, 0.1, -0.35) * CFrame.Angles(0, 0, math.rad(15)), pale)
		piece(ctx, "HandRight", Vector3.new(0.6, 0.9, 0.2), spot * CFrame.new(1.3, -0.1, -0.35) * CFrame.Angles(0, 0, math.rad(-12)), pale)
		local glow = Instance.new("PointLight")
		glow.Color = Color3.fromRGB(180, 200, 220)
		glow.Range = 4
		glow.Brightness = 0.6
		glow.Parent = face
	end,
	Reset = function(ctx)
		ctx:Restore()
	end,
}
