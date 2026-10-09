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
local SessionManager = require(script.Parent.SessionManager)

local live = Config.UseSeparateServers and not RunService:IsStudio()
local isGameServer = live and game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0

Graphics.apply()
if isGameServer then
	LobbyBuilder.clearDefaultPlace()
	SessionManager.initGameServer()
else
	local lobby = LobbyBuilder.build()
	SessionManager.init(lobby, live)
	LobbyManager.start(lobby)
end
