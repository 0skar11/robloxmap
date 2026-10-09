-- Runs one game per group, and owns spawning and death.
--
-- Where a group plays:
--   Live game (Config.UseSeparateServers, outside Studio): the lobby server teleports the group to a
--   private server of this same place. That server is the group's own world: it builds one station
--   and runs one game, then sends everyone back to a lobby server.
--   Studio (or teleport failure): the group plays in the lobby server, on its own station copy
--   built far from the lobby.
--
-- Death: players never respawn on their own during a game. A dead player spectates (see the
-- Spectate client script) until the whole group is dead; then the game loop calls Revive and the
-- group starts again from level 1.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)
local Strings = require(ReplicatedStorage.Shared.Strings)
local GameLoop = require(script.Parent.GameLoop)
local MapBuilder = require(script.Parent.MapBuilder)

local LOBBY_RESPAWN_SECONDS = 3

local GAME_ATTRIBUTES = {
	"Level",
	"TotalLevels",
	"Checkpoint",
	"VotesContinue",
	"VotesBack",
	"Voters",
	"VoteCountdown",
	"VoteTie",
	"SessionKey",
}

local SessionManager = {}

local lobby = nil -- lobby refs; nil on a game server
local live = false -- true when groups are teleported to their own servers
local sessionOf: { [Player]: any } = {}
local teleporting: { [Player]: boolean } = {}
local freeSlots: { number } = {}
local nextSlot = 1

local function aliveCharacter(player: Player): Model?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if character and humanoid and humanoid.Health > 0 and character:FindFirstChild("HumanoidRootPart") then
		return character
	end
	return nil
end

local function moveTo(player: Player, cframe: CFrame)
	local character = aliveCharacter(player)
	if character then
		character:PivotTo(cframe)
	end
end

local function sendToLobbyServer(players: { Player })
	local ok, err = pcall(function()
		TeleportService:TeleportAsync(game.PlaceId, players)
	end)
	if not ok then
		warn("[EndlessSubway] teleport to lobby failed:", err)
		for _, player in players do
			player:Kick("Thanks for playing Endless Subway! Rejoin to go back to the lobby.")
		end
	end
end

local function resetToLobby(player: Player)
	for _, name in GAME_ATTRIBUTES do
		player:SetAttribute(name, nil)
	end
	player:SetAttribute("Phase", "Lobby")
	player:SetAttribute("Mood", "Lobby")
	player:SetAttribute("Language", "en")
	player:SetAttribute("Dead", false)
	if not player.Parent then
		return
	end
	Net.event():FireClient(player, { Kind = "Fade", Visible = false, Duration = 0.5 })
	if aliveCharacter(player) then
		moveTo(player, lobby.SpawnCFrame)
	else
		player:LoadCharacter()
	end
end

-- True while a player is in a game, or on their way to one.
function SessionManager.isPlaying(player: Player): boolean
	return sessionOf[player] ~= nil or teleporting[player] == true
end

local function removeMember(player: Player)
	local session = sessionOf[player]
	sessionOf[player] = nil
	local index = session and table.find(session.Members, player)
	if index then
		table.remove(session.Members, index)
	end
	return session
end

-- Takes a player out of their game and back to the lobby.
function SessionManager.leave(player: Player)
	if not removeMember(player) then
		return
	end
	if lobby then
		resetToLobby(player)
	else
		sendToLobbyServer({ player })
	end
end

local function addMember(session, player: Player)
	if not player.Parent or sessionOf[player] then
		return
	end
	sessionOf[player] = session
	table.insert(session.Members, player)
	player:SetAttribute("Language", session.Language)
	player:SetAttribute("SessionKey", session.Key)
	player:SetAttribute("Dead", false)
end

local function newSession(slot: number, language: string, withSpawn: boolean)
	local session = {
		Slot = slot,
		Key = tostring(slot) .. "-" .. tostring(os.clock()),
		Language = Strings.normalize(language),
		Members = {} :: { Player },
		Refs = nil :: any,
	}
	local stationOrigin = CFrame.new(slot * Config.StationSpacing, 50, 0)
	session.Refs = MapBuilder.build(stationOrigin, "Station" .. slot, session.Language, withSpawn)

	-- Players still in the server, in join order.
	function session.GetMembers(): { Player }
		local present = {}
		for _, player in session.Members do
			if player.Parent then
				table.insert(present, player)
			end
		end
		return present
	end

	-- Members whose character is alive.
	function session.GetAlive(): { Player }
		local alive = {}
		for _, player in session.GetMembers() do
			if aliveCharacter(player) then
				table.insert(alive, player)
			end
		end
		return alive
	end

	-- Brings every dead member back (used after the whole group died).
	function session.Revive()
		for _, player in session.GetMembers() do
			player:SetAttribute("Dead", false)
			if not aliveCharacter(player) then
				player:LoadCharacter()
			end
		end
	end

	return session
end

local function runLocal(members: { Player }, language: string)
	local slot = table.remove(freeSlots) or nextSlot
	if slot == nextSlot then
		nextSlot += 1
	end

	local session = newSession(slot, language, false)
	for _, player in members do
		addMember(session, player)
	end

	task.spawn(function()
		local ok, err = pcall(GameLoop.run, session)
		if not ok then
			warn("[EndlessSubway] session", slot, "crashed:", err)
		end
		for _, player in table.clone(session.Members) do
			SessionManager.leave(player)
		end
		session.Refs.Map:Destroy()
		table.insert(freeSlots, slot)
	end)
end

-- Called by the lobby when a gate leaves.
function SessionManager.launch(members: { Player }, language: string)
	if live then
		local options = Instance.new("TeleportOptions")
		options.ShouldReserveServer = true
		options:SetTeleportData({ Language = Strings.normalize(language), Expected = #members })
		for _, player in members do
			teleporting[player] = true
			Net.event():FireClient(player, { Kind = "Fade", Visible = true, Duration = 0.5 })
		end
		local ok, err = pcall(function()
			TeleportService:TeleportAsync(game.PlaceId, members, options)
		end)
		if ok then
			return
		end
		warn("[EndlessSubway] could not teleport the group, playing in this server instead:", err)
	end
	for _, player in members do
		teleporting[player] = nil
	end
	runLocal(members, language)
end

-- canSpawn says whether a player may get a character yet (a game server waits for its station).
local function setUpSpawning(onDied: (Player) -> (), canSpawn: () -> boolean)
	Players.CharacterAutoLoads = false

	local function onPlayer(player: Player)
		player:SetAttribute("Dead", false)
		player.CharacterAdded:Connect(function(character)
			local humanoid = character:WaitForChild("Humanoid", 10)
			if humanoid and humanoid:IsA("Humanoid") then
				humanoid.Died:Connect(function()
					onDied(player)
				end)
			end
			-- Spawning mid-game puts you in your group's train.
			local session = sessionOf[player]
			if session then
				character:WaitForChild("HumanoidRootPart", 5)
				task.wait()
				moveTo(player, session.Refs.StandPoints[1])
			end
		end)
		if canSpawn() then
			player:LoadCharacter()
		end
	end

	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayer, player)
	end
end

-- Lobby server (or Studio).
function SessionManager.init(lobbyRefs, isLive: boolean)
	lobby = lobbyRefs
	live = isLive

	setUpSpawning(function(player)
		if sessionOf[player] then
			player:SetAttribute("Dead", true)
		else
			task.delay(LOBBY_RESPAWN_SECONDS, function()
				if player.Parent and not sessionOf[player] and not aliveCharacter(player) then
					player:LoadCharacter()
				end
			end)
		end
	end, function()
		return true
	end)

	Players.PlayerAdded:Connect(function(player)
		player:SetAttribute("Phase", "Lobby")
		player:SetAttribute("Mood", "Lobby")
		player:SetAttribute("Language", "en")
	end)
	for _, player in Players:GetPlayers() do
		player:SetAttribute("Phase", "Lobby")
		player:SetAttribute("Mood", "Lobby")
		player:SetAttribute("Language", "en")
	end
	Players.PlayerRemoving:Connect(function(player)
		teleporting[player] = nil
		removeMember(player)
	end)

	-- A teleport that fails after it started: put the player back in the lobby.
	TeleportService.TeleportInitFailed:Connect(function(player, _result, errorMessage)
		if teleporting[player] then
			warn("[EndlessSubway] teleport failed for", player.Name, errorMessage)
			teleporting[player] = nil
			resetToLobby(player)
		end
	end)
end

-- A group's own server: wait for the group, play one game, send everyone back to the lobby.
function SessionManager.initGameServer()
	lobby = nil
	live = true

	local session = nil
	local language = "en"
	local expected = 1

	setUpSpawning(function(player)
		player:SetAttribute("Dead", true)
	end, function()
		return session ~= nil
	end)

	local function join(player: Player)
		local data = player:GetJoinData().TeleportData
		if type(data) == "table" and not session then
			language = Strings.normalize(data.Language)
			expected = tonumber(data.Expected) or expected
		end
		player:SetAttribute("Phase", "Riding")
		player:SetAttribute("Mood", "Calm")
		if session then
			-- A late teammate joins the game that is already running.
			addMember(session, player)
		end
	end
	Players.PlayerAdded:Connect(join)
	for _, player in Players:GetPlayers() do
		join(player)
	end
	Players.PlayerRemoving:Connect(removeMember)

	-- Wait for the group to arrive.
	while #Players:GetPlayers() == 0 do
		Players.PlayerAdded:Wait()
	end
	local deadline = os.clock() + Config.GroupArrivalTimeout
	while #Players:GetPlayers() < expected and os.clock() < deadline do
		task.wait(0.5)
	end

	session = newSession(0, language, true)
	for _, player in Players:GetPlayers() do
		addMember(session, player)
		if not player.Character then
			task.spawn(player.LoadCharacter, player)
		end
	end

	local ok, err = pcall(GameLoop.run, session)
	if not ok then
		warn("[EndlessSubway] game crashed:", err)
	end
	sendToLobbyServer(Players:GetPlayers())
end

return SessionManager
