-- One of the passengers is gone.
return {
	Name = "MissingPassenger",
	Apply = function(ctx)
		ctx:Hide(ctx:Pick(ctx.Refs.Passengers))
	end,
	Reset = function(ctx)
		ctx:Restore()
	end,
}
