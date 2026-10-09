-- One of the pillars is missing. The middle one stays: the flowers lean on it.
return {
	Name = "MissingPillar",
	Apply = function(ctx)
		local candidates = {}
		for _, pillar in ctx.Refs.Pillars do
			if pillar:GetAttribute("X") ~= 0 then
				table.insert(candidates, pillar)
			end
		end
		ctx:Set(ctx:Pick(candidates), "Parent", nil)
	end,
	Reset = function(ctx)
		ctx:Restore()
	end,
}
