-- Makes people turn their heads to follow the nearest player, through an anomaly context so it
-- all comes undone. Avatars turn their neck joint; block mannequins turn the head part itself.

local RunService = game:GetService("RunService")

local TURN_SPEED = 3

local Stare = {}

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

-- maxTurn: how far (radians) a neck may twist from straight ahead.
function Stare.track(ctx, models: { Model }, maxTurn: number)
	local necks, heads = {}, {}
	for _, model in models do
		local head = model:FindFirstChild("Head", true)
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
				local goal = math.clamp(math.atan2(-relative.X, -relative.Z), -maxTurn, maxTurn)
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
end

return Stare
