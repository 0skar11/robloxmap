-- Every passenger's head slowly follows the nearest player.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local TURN_SPEED = 3

local function nearestHead(position: Vector3): Vector3?
	local best, bestDistance = nil, math.huge
	for _, player in Players:GetPlayers() do
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
		local heads = {}
		for _, passenger in ctx.Refs.Passengers do
			local head = passenger:FindFirstChild("Head")
			-- Record the resting pose; the loop below moves the head directly.
			ctx:Set(head, "CFrame", head.CFrame)
			table.insert(heads, head)
		end

		ctx:Connect(RunService.Heartbeat, function(dt)
			for _, head in heads do
				local target = nearestHead(head.Position)
				if target then
					local goal = CFrame.lookAt(head.Position, target)
					head.CFrame = head.CFrame:Lerp(goal, math.min(1, dt * TURN_SPEED))
				end
			end
		end)
	end,
	Reset = function(ctx)
		ctx:Restore()
	end,
}
