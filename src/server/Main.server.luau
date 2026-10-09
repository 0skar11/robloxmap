-- Endless Subway: builds the station and starts the loop.

local MapBuilder = require(script.Parent.MapBuilder)
local GameLoop = require(script.Parent.GameLoop)

GameLoop.run(MapBuilder.build())
