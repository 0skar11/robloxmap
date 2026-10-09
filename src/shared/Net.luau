-- Shared networking. The server owns the remotes; game state is published as attributes on each
-- Player, so every player's HUD only shows their own group.
--
-- Player attributes:
--   Phase            "Lobby" | "Riding" (screen dark, between stations) | "Station" (doors open)
--   Mood             "Lobby" | "Calm" (levels 1-5, bright) | "Horror" (dark) - drives the local look
--   Language         "ar" | "en" for the player's session ("en" in the lobby)
--   Level, TotalLevels, Checkpoint (0 = none yet)
--   BackDoor         false while the GO BACK door does not exist yet (level 1)
--   Dead             true while spectating after dying mid-game
--   SessionKey       same value for everyone in one group (spectators find teammates by it)
--   VotesContinue, VotesBack, Voters
--   VoteCountdown    seconds before the vote locks in, -1 when no countdown is running
--   VoteTie          true when everyone voted and the doors are tied
--   Pad              lobby gate the player stands on and belongs to (0 = none)
--   PadHost          true for the player who picks the group size and language
--   PadCount, PadMax, PadLanguage   members on the gate, chosen group size and language
--   PadCountdown     seconds before the group leaves, -1 when not counting down
--   PadFull          standing on a gate that is already full
--
-- Remotes:
--   GameEvent    server -> client  { Kind = "Fade", Visible, Duration } | { Kind = "Message", Text, Duration }
--   LobbyAction  client -> server  ("SetPartySize", n) | ("SetLanguage", "ar" | "en") | ("StartNow") | ("LeaveRun")

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
		for _, name in { "GameEvent", "LobbyAction" } do
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
		folder.Parent = ReplicatedStorage
		return folder
	end

	return ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
end

function Net.event(): RemoteEvent
	return Net.folder():WaitForChild("GameEvent") :: RemoteEvent
end

function Net.lobbyAction(): RemoteEvent
	return Net.folder():WaitForChild("LobbyAction") :: RemoteEvent
end

return Net
