-- One ceiling light keeps flickering.
return {
	Name = "FlickeringLight",
	Apply = function(ctx)
		local fixture = ctx:Pick(ctx.Refs.Lights)
		local light = fixture:FindFirstChildOfClass("SurfaceLight")

		-- Record the originals first so Restore turns the light back on.
		ctx:Set(fixture, "Material", fixture.Material)
		ctx:Set(light, "Enabled", true)

		ctx:Spawn(function()
			while true do
				local on = ctx.Random:NextNumber() > 0.35
				light.Enabled = on
				fixture.Material = if on then Enum.Material.Neon else Enum.Material.SmoothPlastic
				task.wait(ctx.Random:NextNumber(0.05, 0.4))
			end
		end)
	end,
	Reset = function(ctx)
		ctx:Restore()
	end,
}
