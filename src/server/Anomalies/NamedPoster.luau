-- An advertisement now carries one of the players' names.
return {
	Name = "NamedPoster",
	-- Scary: only in the dark half of the game.
	Horror = true,
	Apply = function(ctx)
		local name = if #ctx.Players > 0 then ctx:Pick(ctx.Players).DisplayName else "???"
		ctx:Set(ctx:Pick(ctx.Refs.Posters), "Text", ctx:Text("NamedPoster", name))
	end,
	Reset = function(ctx)
		ctx:Restore()
	end,
}
