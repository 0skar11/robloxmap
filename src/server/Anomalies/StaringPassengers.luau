-- Every passenger slowly turns their head to follow the nearest player.
local RunService = game:GetService("RunService")

local TURN_SPEED = 3
local MAX_TURN = math.rad(75)

local function nearestHead(players: { Player }, position: Vector3): Vector3?
	local best, bestDistance = nil, math.huge
	for _, player in players do
		local head = player.Character and player.Character:FindFirstChild("Head")
		if head and head:IsA("BasePart") then
			local distance = (head.Position - position).Magnitude
			if distance < bestDistance then
				best, bestDistance = head.Position, distance
			end
		end
	end
	return best
end

return {
	Name = "StaringPassengers",
	Apply = function(ctx)
		-- Avatars turn their neck joint; block mannequins turn the head part itself.
		local necks, heads = {}, {}
		for _, passenger in ctx.Refs.Passengers do
			local head = passenger:FindFirstChild("Head", true)
			local neck = head and head:FindFirstChild("Neck")
			if neck and neck:IsA("Motor6D") and neck.Part0 then
				ctx:Set(neck, "C0", neck.C0)
				table.insert(necks, { Joint = neck, Rest = neck.C0, Yaw = 0 })
			elseif head and head:IsA("BasePart") then
				ctx:Set(head, "CFrame", head.CFrame)
				table.insert(heads, head)
			end
		end

		ctx:Connect(RunService.Heartbeat, function(dt: number)
			local blend = math.min(1, dt * TURN_SPEED)
			for _, neck in necks do
				local target = nearestHead(ctx.Players, neck.Joint.Part1.Position)
				if target then
					local relative = neck.Joint.Part0.CFrame:PointToObjectSpace(target)
					local goal = math.clamp(math.atan2(-relative.X, -relative.Z), -MAX_TURN, MAX_TURN)
					neck.Yaw += (goal - neck.Yaw) * blend
					neck.Joint.C0 = neck.Rest * CFrame.Angles(0, neck.Yaw, 0)
				end
			end
			for _, head in heads do
				local target = nearestHead(ctx.Players, head.Position)
				if target then
					head.CFrame = head.CFrame:Lerp(CFrame.lookAt(head.Position, target), blend)
				end
			end
		end)
	end,
	Reset = function(ctx)
		ctx:Restore()
	end,
}
