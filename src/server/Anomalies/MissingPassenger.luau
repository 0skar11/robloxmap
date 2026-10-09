-- One of the passengers is gone.
return {
	Name = "MissingPassenger",
	Apply = function(ctx)
		ctx:Set(ctx:Pick(ctx.Refs.Passengers), "Parent", nil)
	end,
	Reset = function(ctx)
		ctx:Restore()
	end,
}
