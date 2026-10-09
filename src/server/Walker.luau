-- The passenger standing in the middle of the platform. Every station, a moment after the doors
-- open, he walks into the train and sits down: part of what "normal" looks like.
--
-- Anomalies can change him through attributes on his model (see Anomalies/BloodyWalker and
-- Anomalies/WalkerJumpscare):
--   Mode = "Walk"   (default) walk into the car and sit
--   Mode = "Chase"  sprint at the nearest player; on reaching them, a jumpscare (nobody dies)
--
-- Walker.start() runs one station's behavior and returns a stop function that puts him back.

local RunService = game:GetService("RunService")

local WALK_ANIMATION = "rbxassetid://507777826"
local RUN_ANIMATION = "rbxassetid://507767714"
local SIT_ANIMATION = "rbxassetid://2506281703"

local WALK_SPEED = 8
local CHASE_SPEED = 21 -- faster than walking (16), slower than sprinting (26)
local CHASE_SECONDS = 12
local SCARE_DISTANCE = 3.5
local START_DELAY = 2

local Walker = {}

local function bodyOf(model: Model): (BasePart?, Humanoid?)
	local avatar = model:FindFirstChild("Avatar")
	if not avatar then
		return nil, nil
	end
	local root = avatar:FindFirstChild("HumanoidRootPart")
	local humanoid = avatar:FindFirstChildOfClass("Humanoid")
	if root and root:IsA("BasePart") and humanoid then
		return root, humanoid
	end
	return nil, nil
end

local function nearestAlive(players: { Player }, position: Vector3): (Player?, BasePart?)
	local bestPlayer, bestRoot, bestDistance = nil, nil, math.huge
	for _, player in players do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
			local distance = (root.Position - position).Magnitude
			if distance < bestDistance then
				bestPlayer, bestRoot, bestDistance = player, root, distance
			end
		end
	end
	return bestPlayer, bestRoot
end

-- onScare(player) is called when the chase reaches someone.
function Walker.start(refs, getAlive: () -> { Player }, onScare: (Player) -> ()): () -> ()
	local model: Model = refs.Walker
	local mode = model:GetAttribute("Mode") or "Walk"
	local root, humanoid = bodyOf(model)

	-- An avatar moves by its (anchored) root; the block mannequin moves as a whole model.
	local function getCFrame(): CFrame
		return if root then root.CFrame else model:GetPivot()
	end
	local function setCFrame(cframe: CFrame)
		if root then
			root.CFrame = cframe
		else
			model:PivotTo(cframe)
		end
	end

	local home = getCFrame()
	local floorY = home.Position.Y
	local running = true
	local tracks: { AnimationTrack } = {}

	local function load(id: string, priority: Enum.AnimationPriority): AnimationTrack?
		if not humanoid then
			return nil
		end
		local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
		animator.Parent = humanoid
		local animation = Instance.new("Animation")
		animation.AnimationId = id
		local ok, track = pcall(function()
			return animator:LoadAnimation(animation)
		end)
		if not ok or not track then
			return nil
		end
		track.Looped = true
		track.Priority = priority
		return track
	end

	local function play(id: string, speed: number)
		local track = load(id, Enum.AnimationPriority.Movement)
		if track then
			track:Play(0.2)
			track:AdjustSpeed(speed)
			table.insert(tracks, track)
		end
	end

	local function stopTracks(fade: number?)
		for _, track in tracks do
			track:Stop(fade or 0.2)
		end
		table.clear(tracks)
	end

	-- Loaded up front so it is ready the moment he sits, and above every other pose.
	local sitTrack = load(SIT_ANIMATION, Enum.AnimationPriority.Action)

	-- One frame's step toward a point on the floor. Returns the distance left.
	local function stepToward(target: Vector3, speed: number, dt: number): number
		local here = getCFrame().Position
		local offset = Vector3.new(target.X, floorY, target.Z) - here
		local distance = offset.Magnitude
		if distance < 0.05 then
			return 0
		end
		local direction = offset.Unit
		local nextPosition = here + direction * math.min(distance, speed * dt)
		setCFrame(CFrame.lookAt(nextPosition, nextPosition + direction))
		return distance
	end

	local function walkTo(target: Vector3): boolean
		while running do
			local dt = RunService.Heartbeat:Wait()
			if stepToward(target, WALK_SPEED, dt) < 0.3 then
				return true
			end
		end
		return false
	end

	local function sit()
		local seat = refs.WalkerSeat
		if not (root and humanoid and seat) then
			return
		end
		-- Stop walking at once (a fading walk would keep the legs moving), line him up right above
		-- the seat facing the same way, and only then let the seat take him.
		stopTracks(0)
		root.CFrame = seat.CFrame * CFrame.new(0, humanoid.HipHeight + root.Size.Y / 2 + 0.2, 0)
		root.AssemblyLinearVelocity = Vector3.zero
		root.Anchored = false
		seat:Sit(humanoid)
		if sitTrack then
			sitTrack:Play(0)
			table.insert(tracks, sitTrack)
		end
	end

	local thread = task.spawn(function()
		task.wait(START_DELAY)
		if mode == "Chase" then
			task.wait(math.random() * 2)
			play(RUN_ANIMATION, 1.2)
			local deadline = os.clock() + CHASE_SECONDS
			while running and os.clock() < deadline do
				local dt = RunService.Heartbeat:Wait()
				local player, target = nearestAlive(getAlive(), getCFrame().Position)
				if not player or not target then
					break
				end
				if stepToward(target.Position, CHASE_SPEED, dt) <= SCARE_DISTANCE then
					onScare(player)
					break
				end
			end
			-- He is gone after the scare; he'll be back in his spot next station.
			stopTracks()
			setCFrame(home)
			return
		end

		play(WALK_ANIMATION, 0.55)
		for _, point in refs.WalkerPath do
			if not walkTo(point) then
				return
			end
		end
		sit()
	end)

	return function()
		running = false
		if coroutine.status(thread) ~= "dead" then
			task.cancel(thread)
		end
		stopTracks(0)
		-- Get up from the seat and go back to his spot.
		local weld = refs.WalkerSeat and refs.WalkerSeat:FindFirstChild("SeatWeld")
		if weld then
			weld:Destroy()
		end
		if humanoid then
			humanoid.Sit = false
		end
		if root then
			root.Anchored = true
		end
		setCFrame(home)
	end
end

return Walker
