-- Endless Subway: sets up the dark look, builds the lobby, and starts matching groups.
-- Each group's station is built when their gate leaves (see SessionManager).

local Graphics = require(script.Parent.Graphics)
local LobbyBuilder = require(script.Parent.LobbyBuilder)
local LobbyManager = require(script.Parent.LobbyManager)
local SessionManager = require(script.Parent.SessionManager)

Graphics.apply()
local lobby = LobbyBuilder.build()
SessionManager.init(lobby)
LobbyManager.start(lobby)
