-- The train is standing at the platform, but nobody is in the driver's seat.
return {
	Name = "MissingDriver",
	Apply = function(ctx)
		ctx:Hide(ctx.Refs.Driver)
	end,
	Reset = function(ctx)
		ctx:Restore()
	end,
}
