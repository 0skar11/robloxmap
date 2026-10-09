-- The station clock is stuck on the time the train arrives and never ticks.
return {
	Name = "StoppedClock",
	Apply = function(ctx)
		ctx:SetAttribute(ctx.Refs.Clock, "Frozen", true)
		ctx:Set(ctx.Refs.ClockLabel, "Text", "23:57:00")
	end,
	Reset = function(ctx)
		ctx:Restore()
	end,
}
