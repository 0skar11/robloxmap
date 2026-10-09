-- One ceiling light keeps flickering.
return {
	Name = "FlickeringLight",
	-- Scary: only in the dark half of the game.
	Horror = true,
	Apply = function(ctx)
		-- Only a light that is still working can flicker.
		local working = {}
		for _, candidate in ctx.Refs.Lights do
			local surfaceLight = candidate:FindFirstChildOfClass("SurfaceLight")
			if surfaceLight and surfaceLight.Enabled then
				table.insert(working, candidate)
			end
		end
		local fixture = ctx:Pick(working)
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
