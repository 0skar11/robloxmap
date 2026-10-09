-- Someone new is on the platform: a faceless figure standing with their face to the wall.
local Mannequin = require(script.Parent.Parent.Mannequin)

local SPOTS = {
	{ X = -85, Z = -8.5 },
	{ X = 85, Z = -8.5 },
	{ X = -24, Z = -8.5 },
	{ X = 22, Z = 6 },
	{ X = -56, Z = 6 },
}

return {
	Name = "ExtraPassenger",
	Apply = function(ctx)
		local spot = ctx:Pick(SPOTS)
		-- Facing -Z means facing the back wall.
		local pivot = ctx.Refs.At(spot.X, 3, spot.Z)
		ctx:Add(Mannequin.create("Stranger", "Stand", pivot, Color3.fromRGB(20, 20, 22)))
	end,
	Reset = function(ctx)
		ctx:Restore()
	end,
}
