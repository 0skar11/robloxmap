-- The station name on the big sign is upside down.
return {
	Name = "UpsideDownSign",
	Apply = function(ctx)
		ctx:Set(ctx.Refs.StationName, "Rotation", 180)
	end,
	Reset = function(ctx)
		ctx:Restore()
	end,
}
