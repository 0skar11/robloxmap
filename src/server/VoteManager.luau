-- Majority vote by standing in front of a door. Each player votes with their body: whoever is
-- inside a door's zone votes for it, and stepping out takes the vote back.
--
-- The vote locks in when every player is at a door, there is a clear majority, and nobody moves
-- for Config.VoteConfirmSeconds. A tie keeps everyone arguing until the timeout, then a coin flip.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local POLL_SECONDS = 0.2

export type Choice = "Continue" | "Back"
type Publish = (continueVotes: number, backVotes: number, voters: number, countdown: number, tie: boolean) -> ()

local VoteManager = {}

local function isInside(zone: BasePart, position: Vector3): boolean
	local relative = zone.CFrame:PointToObjectSpace(position)
	local half = zone.Size / 2
	return math.abs(relative.X) <= half.X and math.abs(relative.Z) <= half.Z and relative.Y > -2 and relative.Y < 10
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid or humanoid.Health <= 0 then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function count(doors, members: { Player })
	local continueVotes, backVotes, voters = 0, 0, 0
	for _, player in members do
		local root = rootOf(player)
		if root then
			voters += 1
			if isInside(doors.Continue.Zone, root.Position) then
				continueVotes += 1
			elseif isInside(doors.Back.Zone, root.Position) then
				backVotes += 1
			end
		end
	end
	return continueVotes, backVotes, voters
end

-- Yields until the group decides. Returns nil if the whole group left. The second value is true
-- when a tie was settled by coin flip.
function VoteManager.collect(doors, getMembers: () -> { Player }, publish: Publish, random: Random): (Choice?, boolean)
	local firstVoteAt: number? = nil
	local leader: Choice? = nil
	local leaderSince = 0

	while true do
		local members = getMembers()
		if #members == 0 then
			return nil, false
		end

		local now = os.clock()
		local continueVotes, backVotes, voters = count(doors, members)
		local voted = continueVotes + backVotes
		local everyone = voters > 0 and voted == voters
		local tie = everyone and continueVotes == backVotes

		if voted > 0 then
			firstVoteAt = firstVoteAt or now
		else
			firstVoteAt = nil
		end

		local current: Choice? = nil
		if everyone and not tie then
			current = if continueVotes > backVotes then "Continue" else "Back"
		end
		if current ~= leader then
			leader = current
			leaderSince = now
		end

		local countdown = -1
		if leader then
			countdown = Config.VoteConfirmSeconds - (now - leaderSince)
			if countdown <= 0 then
				publish(continueVotes, backVotes, voters, -1, false)
				return leader, false
			end
		end

		if firstVoteAt and now - firstVoteAt >= Config.VoteTimeoutSeconds then
			publish(continueVotes, backVotes, voters, -1, false)
			if continueVotes == backVotes then
				return if random:NextNumber() < 0.5 then "Continue" else "Back", true
			end
			return if continueVotes > backVotes then "Continue" else "Back", false
		end

		publish(continueVotes, backVotes, voters, if countdown >= 0 then math.ceil(countdown) else -1, tie)
		task.wait(POLL_SECONDS)
	end
end

return VoteManager
