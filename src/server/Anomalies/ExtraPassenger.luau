-- Someone new is on the platform, standing with their face to the wall.
local Mannequin = require(script.Parent.Parent.Mannequin)
local MapBuilder = require(script.Parent.Parent.MapBuilder)

local SPOTS = {
	{ X = -50, Z = -8.5 },
	{ X = 50, Z = -8.5 },
	{ X = -24, Z = -8.5 },
	{ X = 22, Z = 6 },
}

return {
	Name = "ExtraPassenger",
	Apply = function(ctx)
		local spot = ctx:Pick(SPOTS)
		-- Facing -Z means facing the back wall.
		local pivot = MapBuilder.at(spot.X, 3, spot.Z)
		ctx:Add(Mannequin.create("Stranger", "Stand", pivot, Color3.fromRGB(30, 30, 32)))
	end,
	Reset = function(ctx)
		ctx:Restore()
	end,
}
