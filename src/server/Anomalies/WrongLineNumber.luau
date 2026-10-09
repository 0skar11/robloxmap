-- The line badge reads 41 instead of 14.
return {
	Name = "WrongLineNumber",
	Apply = function(ctx)
		ctx:Set(ctx.Refs.LineBadge, "Text", "41")
	end,
	Reset = function(ctx)
		ctx:Restore()
	end,
}
