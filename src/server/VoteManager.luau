-- Majority vote by standing in front of a door. Each player votes with their body: whoever is
-- inside a door's zone votes for it, and stepping out takes the vote back.
--
-- The vote locks in when every player is at a door, there is a clear majority, and nobody moves
-- for Config.VoteConfirmSeconds. A tie keeps everyone arguing until the timeout, then a coin flip.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local POLL_SECONDS = 0.2

export type Choice = "Continue" | "Back"
export type Outcome = "Decided" | "Left" | "Wiped"
type Publish = (continueVotes: number, backVotes: number, voters: number, countdown: number, tie: boolean) -> ()

local VoteManager = {}

local function isInside(zone: BasePart, position: Vector3): boolean
	local relative = zone.CFrame:PointToObjectSpace(position)
	local half = zone.Size / 2
	return math.abs(relative.X) <= half.X and math.abs(relative.Z) <= half.Z and relative.Y > -2 and relative.Y < 10
end

-- Only living players vote.
local function count(doors, alive: { Player })
	local continueVotes, backVotes = 0, 0
	for _, player in alive do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			if isInside(doors.Continue.Zone, root.Position) then
				continueVotes += 1
			elseif isInside(doors.Back.Zone, root.Position) then
				backVotes += 1
			end
		end
	end
	return continueVotes, backVotes, #alive
end

-- Yields until the group decides. Returns the choice, whether a coin flip settled a tie, and the
-- outcome: "Decided", "Left" (the whole group left the game) or "Wiped" (everyone is dead).
function VoteManager.collect(
	doors,
	getMembers: () -> { Player },
	getAlive: () -> { Player },
	publish: Publish,
	random: Random
): (Choice?, boolean, Outcome)
	local firstVoteAt: number? = nil
	local leader: Choice? = nil
	local leaderSince = 0

	while true do
		if #getMembers() == 0 then
			return nil, false, "Left"
		end
		local alive = getAlive()
		if #alive == 0 then
			return nil, false, "Wiped"
		end

		local now = os.clock()
		local continueVotes, backVotes, voters = count(doors, alive)
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
				return leader, false, "Decided"
			end
		end

		if firstVoteAt and now - firstVoteAt >= Config.VoteTimeoutSeconds then
			publish(continueVotes, backVotes, voters, -1, false)
			if continueVotes == backVotes then
				return if random:NextNumber() < 0.5 then "Continue" else "Back", true, "Decided"
			end
			return if continueVotes > backVotes then "Continue" else "Back", false, "Decided"
		end

		publish(continueVotes, backVotes, voters, if countdown >= 0 then math.ceil(countdown) else -1, tie)
		task.wait(POLL_SECONDS)
	end
end

return VoteManager
