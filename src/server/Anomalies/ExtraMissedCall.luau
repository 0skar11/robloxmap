-- The phone on the floor now shows 13 missed calls instead of 12.
return {
	Name = "ExtraMissedCall",
	Apply = function(ctx)
		ctx:Set(ctx.Refs.PhoneLabel, "Text", "13 مكالمة فايتة")
	end,
	Reset = function(ctx)
		ctx:Restore()
	end,
}
