-- Every passenger slowly turns their head to follow the nearest player.
local Stare = require(script.Parent.Parent.Stare)

return {
	Name = "StaringPassengers",
	-- Scary: only in the dark half of the game.
	Horror = true,
	Apply = function(ctx)
		Stare.track(ctx, ctx.Refs.Passengers, math.rad(75))
	end,
	Reset = function(ctx)
		ctx:Restore()
	end,
}
