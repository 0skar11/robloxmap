-- A faceless figure steps out at the far end of the platform and slowly walks toward the nearest
-- living player. If it reaches you, you die (and spectate until your group is gone). It is slower
-- than walking, so you can always get away; the safe answer is to GO BACK.
local RunService = game:GetService("RunService")

local Mannequin = require(script.Parent.Parent.Mannequin)

local SPEED = 7
local REACH = 3
local SPOTS = { -88, 88 }

local function nearestRoot(players: { Player }, position: Vector3): BasePart?
	local best, bestDistance = nil, math.huge
	for _, player in players do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
			local distance = (root.Position - position).Magnitude
			if distance < bestDistance then
				best, bestDistance = root, distance
			end
		end
	end
	return best
end

return {
	Name = "TheFollower",
	-- Scary: only in the dark half of the game.
	Horror = true,
	Apply = function(ctx)
		local x = ctx:Pick(SPOTS)
		local start = ctx.Refs.At(x, 3, 0)
		local follower = Mannequin.create("Follower", "Stand", start, Color3.fromRGB(12, 12, 14)) :: Model
		for _, part in follower:GetDescendants() do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
		ctx:Add(follower)

		-- Stays on the platform floor (Y fixed, Z clamped to the platform).
		local floorY = start.Position.Y
		local minZ = ctx.Refs.At(0, 0, -8).Position.Z
		local maxZ = ctx.Refs.At(0, 0, 9).Position.Z

		-- Waits a few seconds before it starts walking, so players can see it first.
		local wakeAt = os.clock() + 4
		ctx:Connect(RunService.Heartbeat, function(dt: number)
			if os.clock() < wakeAt then
				return
			end
			local here = follower:GetPivot().Position
			local target = nearestRoot(ctx.Players, here)
			if not target then
				return
			end

			local flat = Vector3.new(target.Position.X, floorY, target.Position.Z)
			local offset = flat - here
			if offset.Magnitude <= REACH then
				local humanoid = target.Parent and target.Parent:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.Health = 0
				end
				return
			end

			local step = offset.Unit * math.min(offset.Magnitude, SPEED * dt)
			local nextPosition = here + step
			nextPosition = Vector3.new(nextPosition.X, floorY, math.clamp(nextPosition.Z, minZ, maxZ))
			follower:PivotTo(CFrame.lookAt(nextPosition, Vector3.new(flat.X, floorY, flat.Z)))
		end)
	end,
	Reset = function(ctx)
		ctx:Restore()
	end,
}
