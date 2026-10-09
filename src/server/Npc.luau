-- Passengers. Each one appears straight away as a block mannequin, then (if
-- Config.RandomAvatarNpcs is on) swaps to the avatar of a random real Roblox user once it loads.
-- If no avatar loads, the mannequin stays.
--
-- The returned Model is the passenger for good: anomalies can hide it or look inside it for
-- "Head", whichever body it ends up with.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Mannequin = require(script.Parent.Mannequin)

-- Roblox's default R15 sit animation.
local SIT_ANIMATION = "rbxassetid://2506281703"
local MAX_USER_ID = 3_000_000_000
local ATTEMPTS = 8

local random = Random.new()

local Npc = {}

local function randomDescription(): HumanoidDescription?
	for _ = 1, ATTEMPTS do
		local ok, description = pcall(function()
			return Players:GetHumanoidDescriptionFromUserId(random:NextInteger(1, MAX_USER_ID))
		end)
		if ok and description then
			return description
		end
	end
	return nil
end

local function waitUntilInWorld(model: Model): boolean
	local deadline = os.clock() + 30
	while not model:IsDescendantOf(Workspace) do
		if os.clock() > deadline then
			return false
		end
		task.wait(0.5)
	end
	return true
end

local function loadAvatar(container: Model, pose: "Stand" | "Sit", pivot: CFrame)
	local description = randomDescription()
	if not description then
		return
	end

	local ok, avatar = pcall(function()
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
	if not ok or not avatar or not waitUntilInWorld(container) then
		return
	end

	local humanoid = avatar:FindFirstChildOfClass("Humanoid")
	local root = avatar:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or not root:IsA("BasePart") then
		avatar:Destroy()
		return
	end

	avatar.Name = "Avatar"
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.BreakJointsOnDeath = false
	for _, descendant in avatar:GetDescendants() do
		if descendant:IsA("BaseScript") then
			descendant:Destroy()
		end
	end

	container:ClearAllChildren()

	if pose == "Stand" then
		-- The mannequin pivot sits 2 studs above the floor.
		local floor = pivot * CFrame.new(0, -2, 0)
		root.Anchored = true
		avatar:PivotTo(floor * CFrame.new(0, humanoid.HipHeight + root.Size.Y / 2, 0))
		avatar.Parent = container
		return
	end

	-- Sitting: let a hidden Seat place the body, then play the sit pose.
	local seat = Instance.new("Seat")
	seat.Name = "NpcSeat"
	seat.Size = Vector3.new(2, 0.2, 2)
	seat.CFrame = pivot * CFrame.new(0, -0.1, 0)
	seat.Anchored = true
	seat.CanCollide = false
	seat.Transparency = 1
	seat.Parent = container

	avatar:PivotTo(pivot * CFrame.new(0, 3, 0))
	avatar.Parent = container
	seat:Sit(humanoid)

	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
	animator.Parent = humanoid
	local animation = Instance.new("Animation")
	animation.AnimationId = SIT_ANIMATION
	local played = pcall(function()
		local track = animator:LoadAnimation(animation)
		track.Looped = true
		track:Play(0)
	end)
	if not played then
		warn("[EndlessSubway] could not play the sit animation for a passenger")
	end
end

-- pose: "Stand" (pivot 2 studs above the floor) or "Sit" (pivot on the seat surface),
-- facing the pivot's LookVector.
function Npc.create(name: string, pose: "Stand" | "Sit", pivot: CFrame, clothes: Color3): Model
	local container = Mannequin.create(name, pose, pivot, clothes)
	if Config.RandomAvatarNpcs then
		task.spawn(loadAvatar, container, pose, pivot)
	end
	return container
end

return Npc
