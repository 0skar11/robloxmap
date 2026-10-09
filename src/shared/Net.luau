-- Shared networking folder. The server owns it; game state lives in its attributes and one-off
-- moments (fades, messages) go through the GameEvent RemoteEvent.
--
-- Attributes on the folder:
--   Phase            "Riding" (screen dark, between stations) | "Station" (doors open, voting)
--   Level, LevelName, Station, StationsPerLevel
--   VotesContinue, VotesBack, Voters
--   VoteCountdown    seconds left before the vote locks in, -1 when no countdown is running
--   VoteTie          true when everyone voted and the doors are tied

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "EndlessSubwayNet"

local Net = {}

function Net.folder(): Folder
	if RunService:IsServer() then
		local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
		if existing then
			return existing :: Folder
		end

		local folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME

		local event = Instance.new("RemoteEvent")
		event.Name = "GameEvent"
		event.Parent = folder

		folder.Parent = ReplicatedStorage
		return folder
	end

	return ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
end

function Net.event(): RemoteEvent
	return Net.folder():WaitForChild("GameEvent") :: RemoteEvent
end

return Net
