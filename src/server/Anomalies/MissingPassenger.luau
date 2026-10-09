-- One of the passengers is gone. They are made invisible rather than removed, so a seated
-- avatar keeps its pose when it comes back.
return {
	Name = "MissingPassenger",
	Apply = function(ctx)
		local passenger = ctx:Pick(ctx.Refs.Passengers)
		for _, descendant in passenger:GetDescendants() do
			if descendant:IsA("BasePart") then
				ctx:Set(descendant, "Transparency", 1)
				ctx:Set(descendant, "CanCollide", false)
				ctx:Set(descendant, "CastShadow", false)
			elseif descendant:IsA("Decal") then
				ctx:Set(descendant, "Transparency", 1)
			elseif descendant:IsA("SurfaceGui") then
				ctx:Set(descendant, "Enabled", false)
			end
		end
	end,
	Reset = function(ctx)
		ctx:Restore()
	end,
}
