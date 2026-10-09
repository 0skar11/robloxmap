-- The man in the middle of the platform looks horrifying: pale, soaked in blood, red eyes.
-- He still walks into the train and sits down, as if nothing were wrong.
local Gore = require(script.Parent.Parent.Gore)

return {
	Name = "BloodyWalker",
	-- Scary: only in the dark half of the game.
	Horror = true,
	Apply = function(ctx)
		Gore.apply(ctx, ctx.Refs.Walker)
	end,
	Reset = function(ctx)
		ctx:Restore()
	end,
}
