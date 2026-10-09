-- Runs one game per group. Each session gets its own station, built in the group's language at
-- its own spot far from the others, and its own game loop. When the loop ends (everyone left, or
-- they reached the end) the station is destroyed and whoever is left goes back to the lobby.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)
local Strings = require(ReplicatedStorage.Shared.Strings)
local GameLoop = require(script.Parent.GameLoop)
local MapBuilder = require(script.Parent.MapBuilder)

local GAME_ATTRIBUTES = {
	"Level",
	"LevelName",
	"Station",
	"StationsPerLevel",
	"VotesContinue",
	"VotesBack",
	"Voters",
	"VoteCountdown",
	"VoteTie",
}

local SessionManager = {}

local lobby = nil
local sessionOf: { [Player]: any } = {}
local freeSlots: { number } = {}
local nextSlot = 1

local function moveTo(player: Player, cframe: CFrame)
	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		character:PivotTo(cframe)
	end
end

local function resetToLobby(player: Player)
	for _, name in GAME_ATTRIBUTES do
		player:SetAttribute(name, nil)
	end
	player:SetAttribute("Phase", "Lobby")
	player:SetAttribute("Language", "en")
	if player.Parent then
		Net.event():FireClient(player, { Kind = "Fade", Visible = false, Duration = 0.5 })
		moveTo(player, lobby.SpawnCFrame)
	end
end

function SessionManager.isPlaying(player: Player): boolean
	return sessionOf[player] ~= nil
end

-- Takes a player out of their session and back to the lobby.
function SessionManager.leave(player: Player)
	local session = sessionOf[player]
	if not session then
		return
	end
	sessionOf[player] = nil
	local index = table.find(session.Members, player)
	if index then
		table.remove(session.Members, index)
	end
	resetToLobby(player)
end

local function finish(session)
	for _, player in table.clone(session.Members) do
		SessionManager.leave(player)
	end
	session.Refs.Map:Destroy()
	table.insert(freeSlots, session.Slot)
end

function SessionManager.start(members: { Player }, language: string)
	local slot = table.remove(freeSlots) or nextSlot
	if slot == nextSlot then
		nextSlot += 1
	end

	local stationOrigin = CFrame.new(slot * Config.StationSpacing, 50, 0)
	local session = {
		Slot = slot,
		Language = Strings.normalize(language),
		Members = {},
		Refs = nil :: any,
	}
	session.Refs = MapBuilder.build(stationOrigin, "Station" .. slot, session.Language)

	-- Players still in the server, in join order.
	function session.GetMembers(): { Player }
		local alive = {}
		for _, player in session.Members do
			if player.Parent then
				table.insert(alive, player)
			end
		end
		return alive
	end

	for _, player in members do
		if player.Parent and not sessionOf[player] then
			sessionOf[player] = session
			table.insert(session.Members, player)
			player:SetAttribute("Language", session.Language)
		end
	end

	task.spawn(function()
		local ok, err = pcall(GameLoop.run, session)
		if not ok then
			warn("[EndlessSubway] session", slot, "crashed:", err)
		end
		finish(session)
	end)
end

function SessionManager.init(lobbyRefs)
	lobby = lobbyRefs

	local function onPlayer(player: Player)
		player:SetAttribute("Phase", "Lobby")
		player:SetAttribute("Language", "en")
		player.CharacterAdded:Connect(function(character)
			-- Respawning mid-game puts you back in your group's train.
			local session = sessionOf[player]
			if session then
				character:WaitForChild("HumanoidRootPart", 5)
				task.wait()
				moveTo(player, session.Refs.StandPoints[1])
			end
		end)
	end

	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		-- Just drop them from their group; there is nobody left to send back to the lobby.
		local session = sessionOf[player]
		sessionOf[player] = nil
		local index = session and table.find(session.Members, player)
		if index then
			table.remove(session.Members, index)
		end
	end)
end

return SessionManager
