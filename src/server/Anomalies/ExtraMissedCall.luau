-- The phone on the floor now shows 13 missed calls instead of 12.
return {
	Name = "ExtraMissedCall",
	-- Scary: only in the dark half of the game.
	Horror = true,
	Apply = function(ctx)
		ctx:Set(ctx.Refs.PhoneLabel, "Text", ctx:Text("MissedCalls", 13))
	end,
	Reset = function(ctx)
		ctx:Restore()
	end,
}
