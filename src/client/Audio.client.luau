-- Everything the player hears that is not tied to a spot in the world:
--   ambience      a station hum in the bright levels, a horror bed in the dark ones, nothing in
--                 the lobby (crossfaded when the mood changes)
--   one-shots     the train arriving, the doors, the scream of a jumpscare
--   announcement  a chime, then the recorded voice in the group's language if one is set in
--                 Config.Sounds.Announcements (with radio static in the dark half)
-- Sounds that belong to a place (the ringing phone, footsteps) are made by the server there.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)

local player = Players.LocalPlayer
local sounds = Config.Sounds

local FADE = TweenInfo.new(2.5, Enum.EasingStyle.Sine)

local function makeSound(id: string?, volume: number, looped: boolean): Sound?
	if not id then
		return nil
	end
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = volume
	sound.Looped = looped
	sound.Parent = SoundService
	return sound
end

-- ===== Ambience =====

local ambience = {
	Calm = { Sound = makeSound(sounds.StationAmbience, 0, true), Volume = 0.35 },
	Horror = { Sound = makeSound(sounds.HorrorAmbience, 0, true), Volume = 0.3 },
}

local function updateAmbience()
	local inGame = player:GetAttribute("Phase") ~= nil and player:GetAttribute("Phase") ~= "Lobby"
	local mood = player:GetAttribute("Mood")
	for name, track in ambience do
		local sound = track.Sound
		if sound then
			local wanted = if inGame and mood == name then track.Volume else 0
			if wanted > 0 and not sound.IsPlaying then
				sound:Play()
			end
			TweenService:Create(sound, FADE, { Volume = wanted }):Play()
		end
	end
end

player:GetAttributeChangedSignal("Mood"):Connect(updateAmbience)
player:GetAttributeChangedSignal("Phase"):Connect(updateAmbience)
updateAmbience()

-- ===== One-shots =====

local function playOnce(id: string?, volume: number): Sound?
	local sound = makeSound(id, volume, false)
	if not sound then
		return nil
	end
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	sound:Play()
	return sound
end

local ONE_SHOTS = {
	TrainArrive = { Id = sounds.TrainArrive, Volume = 0.6, Seconds = 5 },
	DoorOpen = { Id = sounds.DoorOpen, Volume = 0.5 },
	DoorClose = { Id = sounds.DoorClose, Volume = 0.5 },
}

local function announce(mood: string)
	local chime = playOnce(sounds.AnnouncementChime, 0.5)
	if chime then
		task.wait(1.5)
	end
	local language = player:GetAttribute("Language") or "en"
	local voices = sounds.Announcements[mood] or sounds.Announcements.Calm
	local voice = voices[language]
	if mood == "Horror" then
		local static = playOnce(sounds.Static, 0.25)
		if static then
			task.delay(7, function()
				if static.Parent then
					static:Destroy()
				end
			end)
		end
	end
	playOnce(voice, 0.9)
end

Net.event().OnClientEvent:Connect(function(payload)
	if payload.Kind == "Sound" then
		local shot = ONE_SHOTS[payload.Name]
		if shot then
			local sound = playOnce(shot.Id, shot.Volume)
			-- Long recordings (the train) only play their first few seconds, then fade.
			if sound and shot.Seconds then
				task.delay(shot.Seconds, function()
					if sound.Parent then
						TweenService:Create(sound, TweenInfo.new(1.5), { Volume = 0 }):Play()
						task.delay(1.6, function()
							if sound.Parent then
								sound:Destroy()
							end
						end)
					end
				end)
			end
		end
	elseif payload.Kind == "Announce" then
		task.spawn(announce, payload.Mood)
	elseif payload.Kind == "Jumpscare" then
		playOnce(sounds.Jumpscare, 1)
	end
end)
