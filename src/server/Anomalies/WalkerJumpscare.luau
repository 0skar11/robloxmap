-- The man in the middle looks horrifying, and a moment after the doors open he sprints at the
-- nearest player. Reaching you is a jumpscare, not a death. Sprinting (Shift) gets you away.
local Gore = require(script.Parent.Parent.Gore)

return {
	Name = "WalkerJumpscare",
	-- Scary: only in the dark half of the game.
	Horror = true,
	Apply = function(ctx)
		Gore.apply(ctx, ctx.Refs.Walker)
		-- Walker (see Server/Walker) reads this when the doors open.
		ctx:SetAttribute(ctx.Refs.Walker, "Mode", "Chase")
	end,
	Reset = function(ctx)
		ctx:Restore()
	end,
}
