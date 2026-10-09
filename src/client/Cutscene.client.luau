-- The two story moments.
--   WakeUp  at the first stop of a game: you wake up in the train. Eyelids open (blinking once)
--           out of a blur, and the animator's wake-up animation plays on your character if
--           Config.Cutscenes.WakeUpAnimation is set.
--   Crash   when the dark half begins: the animator's video if Config.Cutscenes.CrashVideo is
--           set, otherwise a stand-in of flashes, shaking, screeching and the breaking news.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)

local player = Players.LocalPlayer
local cutscenes = Config.Cutscenes

local gui = Instance.new("ScreenGui")
gui.Name = "Cutscene"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
-- Above the HUD and its black screen.
gui.DisplayOrder = 20
gui.Parent = player:WaitForChild("PlayerGui")

local function frame(props: { [string]: any }): Frame
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	f.BackgroundColor3 = Color3.new(0, 0, 0)
	for key, value in props do
		(f :: any)[key] = value
	end
	f.Parent = gui
	return f
end

local function playAnimation(id: string)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = id
	local ok, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if ok and track then
		track.Priority = Enum.AnimationPriority.Action4
		track:Play()
	end
end

local function wakeUp()
	if cutscenes.WakeUpAnimation then
		playAnimation(cutscenes.WakeUpAnimation)
	end

	-- Two eyelids closing the screen from the top and bottom.
	local top = frame({ Size = UDim2.fromScale(1, 0.5), Position = UDim2.fromScale(0, 0) })
	local bottom = frame({ Size = UDim2.fromScale(1, 0.5), Position = UDim2.fromScale(0, 0.5) })
	local blur = Instance.new("BlurEffect")
	blur.Size = 24
	blur.Parent = Lighting

	local function lids(open: number, seconds: number)
		local info = TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		TweenService:Create(top, info, { Position = UDim2.fromScale(0, -0.5 * open) }):Play()
		TweenService:Create(bottom, info, { Position = UDim2.fromScale(0, 0.5 + 0.5 * open) }):Play()
		task.wait(seconds)
	end

	task.wait(1) -- the HUD's black screen is fading out underneath
	lids(0.35, 0.9) -- eyes half open
	lids(0.05, 0.25) -- blink
	lids(1, 1.2) -- awake
	TweenService:Create(blur, TweenInfo.new(1.5), { Size = 0 }):Play()
	task.wait(1.6)
	top:Destroy()
	bottom:Destroy()
	blur:Destroy()
end

local function sound(id: string?, volume: number)
	if not id then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume
	s.Parent = SoundService
	s.Ended:Once(function()
		s:Destroy()
	end)
	s:Play()
	task.delay(cutscenes.CrashSeconds + 1, function()
		if s.Parent then
			s:Destroy()
		end
	end)
end

local function crash(news: string)
	local seconds = cutscenes.CrashSeconds

	if cutscenes.CrashVideo then
		local video = Instance.new("VideoFrame")
		video.Size = UDim2.fromScale(1, 1)
		video.BackgroundColor3 = Color3.new(0, 0, 0)
		video.Video = cutscenes.CrashVideo
		video.Parent = gui
		video:Play()
		local deadline = os.clock() + seconds
		while video.IsPlaying and os.clock() < deadline do
			task.wait(0.1)
		end
		video:Destroy()
		return
	end

	-- Stand-in until the animator's video exists.
	local flash = frame({ Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1 })
	local ticker = Instance.new("TextLabel")
	ticker.AnchorPoint = Vector2.new(0.5, 1)
	ticker.Position = UDim2.new(0.5, 0, 1, -60)
	ticker.Size = UDim2.new(0.9, 0, 0, 44)
	ticker.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
	ticker.BorderSizePixel = 0
	ticker.Font = Enum.Font.GothamBlack
	ticker.TextScaled = true
	ticker.TextColor3 = Color3.new(1, 1, 1)
	ticker.Text = news
	ticker.Visible = false
	ticker.ZIndex = 2
	ticker.Parent = gui

	sound(Config.Sounds.TrainArrive, 1)
	sound(Config.Sounds.Static, 0.5)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local started = os.clock()
	while os.clock() - started < seconds * 0.55 do
		local t = (os.clock() - started) / (seconds * 0.55)
		flash.BackgroundColor3 = if math.random() < 0.5 then Color3.new(1, 1, 1) else Color3.fromRGB(160, 0, 0)
		flash.BackgroundTransparency = if math.random() < 0.35 then 0 else 0.6 + 0.4 * t
		if humanoid then
			humanoid.CameraOffset = Vector3.new(math.random(-10, 10), math.random(-10, 10), 0) / 25 * (1 - t)
		end
		task.wait(0.04)
	end
	if humanoid then
		humanoid.CameraOffset = Vector3.zero
	end
	flash.BackgroundColor3 = Color3.new(0, 0, 0)
	flash.BackgroundTransparency = 0
	ticker.Visible = true
	task.wait(seconds * 0.45)
	flash:Destroy()
	ticker:Destroy()
end

Net.event().OnClientEvent:Connect(function(payload)
	if payload.Kind == "WakeUp" then
		task.spawn(wakeUp)
	elseif payload.Kind == "Crash" then
		task.spawn(crash, payload.News or "")
	end
end)
