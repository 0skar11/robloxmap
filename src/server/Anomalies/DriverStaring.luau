-- The driver has turned around in his seat: his head twists all the way back to watch you.
local Stare = require(script.Parent.Parent.Stare)

return {
	Name = "DriverStaring",
	-- Scary: only in the dark half of the game.
	Horror = true,
	Apply = function(ctx)
		-- Much further than a person can turn.
		Stare.track(ctx, { ctx.Refs.Driver }, math.rad(170))
	end,
	Reset = function(ctx)
		ctx:Restore()
	end,
}
