-- An advertisement now carries one of the players' names.
return {
	Name = "NamedPoster",
	Apply = function(ctx)
		local name = if #ctx.Players > 0 then ctx:Pick(ctx.Players).DisplayName else "محمد"
		ctx:Set(ctx:Pick(ctx.Refs.Posters), "Text", name .. "\nمتنساش تنزل هنا")
	end,
	Reset = function(ctx)
		ctx:Restore()
	end,
}
