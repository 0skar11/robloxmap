-- Endless Subway. This one place plays two roles:
--   Lobby server: builds the lobby and sends groups off from its gates.
--   Game server: a private server a gate teleported its group to; it runs only their game.
-- Roblox Studio cannot teleport, so there it is always a lobby server that also hosts the games.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Graphics = require(script.Parent.Graphics)
local LobbyBuilder = require(script.Parent.LobbyBuilder)
local LobbyManager = require(script.Parent.LobbyManager)
local Records = require(script.Parent.Records)
local SessionManager = require(script.Parent.SessionManager)

local live = Config.UseSeparateServers and not RunService:IsStudio()
local isGameServer = live and game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0

-- The fastest-groups board: "1. 4:12  -  OSKAR, Ali (2)".
local function showLeaderboard(rows: { TextLabel })
	local runs = Records.refreshTop()
	for i, label in rows do
		local run = runs[i]
		if run then
			label.Text = string.format("%d.  %d:%02d   %s (%d)", i, run.Seconds // 60, run.Seconds % 60, run.Names, run.Size)
		else
			label.Text = if i == 1 then "No one has made it out yet..." else ""
		end
	end
end

Graphics.apply()
Records.init()
if isGameServer then
	LobbyBuilder.clearDefaultPlace()
	SessionManager.initGameServer()
else
	local lobby = LobbyBuilder.build()
	SessionManager.init(lobby, live)
	LobbyManager.start(lobby)
	task.spawn(function()
		while true do
			showLeaderboard(lobby.LeaderboardRows)
			task.wait(60)
		end
	end)
	SessionManager.onRunFinished = function()
		task.defer(showLeaderboard, lobby.LeaderboardRows)
	end
end
