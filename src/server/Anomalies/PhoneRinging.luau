-- The phone on the floor is ringing: "Incoming call - Mom", buzzing on the tiles.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

return {
	Name = "PhoneRinging",
	-- Scary, and the phone only exists in the dark half anyway.
	Horror = true,
	Apply = function(ctx)
		local phone: BasePart = ctx.Refs.Phone
		ctx:Set(ctx.Refs.PhoneLabel, "Text", ctx:Text("IncomingCall"))
		ctx:Set(ctx.Refs.PhoneLabel, "BackgroundColor3", Color3.fromRGB(20, 120, 60))
		ctx:Set(phone, "CFrame", phone.CFrame)

		local ring = Instance.new("Sound")
		ring.SoundId = Config.Sounds.PhoneRing
		ring.Looped = true
		ring.Volume = 0.8
		ring.RollOffMaxDistance = 70
		ctx:Add(ring, phone)
		ring:Play()

		-- Buzz on the floor.
		local rest = phone.CFrame
		ctx:Spawn(function()
			while true do
				for _ = 1, 12 do
					phone.CFrame = rest * CFrame.new((math.random() - 0.5) * 0.08, 0, (math.random() - 0.5) * 0.08) * CFrame.Angles(0, math.rad((math.random() - 0.5) * 6), 0)
					task.wait(0.05)
				end
				phone.CFrame = rest
				task.wait(0.8)
			end
		end)
	end,
	Reset = function(ctx)
		ctx:Restore()
	end,
}
