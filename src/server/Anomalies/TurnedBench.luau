-- The empty bench has been turned to face the wall.
return {
	Name = "TurnedBench",
	Apply = function(ctx)
		local candidates = {}
		for _, bench in ctx.Refs.Benches do
			if bench:GetAttribute("Free") then
				table.insert(candidates, bench)
			end
		end
		local bench = ctx:Pick(candidates)
		ctx:Pivot(bench, bench:GetPivot() * CFrame.Angles(0, math.pi, 0))
	end,
	Reset = function(ctx)
		ctx:Restore()
	end,
}
