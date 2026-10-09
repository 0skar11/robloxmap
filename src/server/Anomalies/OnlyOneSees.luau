-- "Moment of doubt": something is wrong, but only one player can see it. The others see a normal
-- station, so that player has to convince them to GO BACK. It shows the moment the screen clears.
-- The effect itself is drawn on that player's screen only (see the Private client script).

local EFFECTS = { "Figure", "NameSign", "WallWriting", "ClockMidnight" }

return {
	Name = "OnlyOneSees",
	Apply = function(ctx)
		if #ctx.Players == 0 then
			return
		end
		-- GameLoop sends this to the chosen player when the screen clears, and ends it after.
		ctx:Set(ctx.Refs, "Private", { Player = ctx:Pick(ctx.Players), Effect = ctx:Pick(EFFECTS) })
	end,
	Reset = function(ctx)
		ctx:Restore()
	end,
}
