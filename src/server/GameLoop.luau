-- The station loop: the train stops, the players look around, they vote on a door, the screen
-- goes dark, and the same station comes back with the counter moved on (or reset).
--
-- Rule: a normal station means "Continue"; a station with something wrong means "Back".
-- A right call moves the counter up; a wrong one sends everyone to the start of the level.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)
local AnomalyContext = require(script.Parent.AnomalyContext)
local AnomalyRegistry = require(script.Parent.AnomalyRegistry)
local VoteManager = require(script.Parent.VoteManager)

local CLOCK_START_SECONDS = 23 * 3600 + 57 * 60
local DOOR_TWEEN = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

local GameLoop = {}

local function setDoors(refs, open: boolean)
	for _, panel in refs.DoorPanels do
		TweenService:Create(panel.Part, DOOR_TWEEN, { CFrame = if open then panel.Open else panel.Closed }):Play()
	end
end

local function applyLevelMood(refs, level: number)
	local mood = Config.Levels[level]
	Lighting.Ambient = mood.Ambient
	Lighting.OutdoorAmbient = Color3.new(0, 0, 0)
	Lighting.Brightness = 0
	Lighting.ClockTime = 0
	for _, fixture in refs.Lights do
		fixture.Color = mood.LightColor
		local light = fixture:FindFirstChildOfClass("SurfaceLight")
		if light then
			light.Color = mood.LightColor
			light.Brightness = mood.LightBrightness
		end
	end
end

-- Ticks the station clock from 23:57:00 every time the train stops, unless an anomaly froze it.
local function runClock(refs, stationStartedAt: () -> number)
	task.spawn(function()
		while refs.Map.Parent do
			if not refs.Clock:GetAttribute("Frozen") then
				local seconds = CLOCK_START_SECONDS + math.floor(os.clock() - stationStartedAt())
				refs.ClockLabel.Text = string.format("%02d:%02d:%02d", seconds // 3600 % 24, seconds // 60 % 60, seconds % 60)
			end
			task.wait(0.25)
		end
	end)
end

local function boardTrain(refs)
	for i, player in Players:GetPlayers() do
		local character = player.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			character:PivotTo(refs.StandPoints[(i - 1) % #refs.StandPoints + 1])
		end
	end
end

local function waitForPlayers()
	while #Players:GetPlayers() == 0 do
		Players.PlayerAdded:Wait()
	end
	-- Give the first character a moment to spawn into the car.
	task.wait(2)
end

function GameLoop.run(refs)
	local net = Net.folder()
	local event = Net.event()
	local anomalies = AnomalyRegistry.load()
	local random = Random.new()

	local level = 1
	local station = 0
	local enteringLevel = true
	local lastAnomaly = nil
	local stationStartedAt = os.clock()

	net:SetAttribute("StationsPerLevel", Config.StationsPerLevel)
	runClock(refs, function()
		return stationStartedAt
	end)

	local function publishState(phase: string)
		net:SetAttribute("Phase", phase)
		net:SetAttribute("Level", level)
		net:SetAttribute("LevelName", Config.Levels[level].Name)
		net:SetAttribute("Station", station)
		refs.CounterLabel.Text = string.format("Level %d\nالمحطة %d / %d", level, station, Config.StationsPerLevel)
	end

	local function message(text: string, duration: number?)
		event:FireAllClients({ Kind = "Message", Text = text, Duration = duration or 3 })
	end

	local function fade(visible: boolean)
		event:FireAllClients({ Kind = "Fade", Visible = visible, Duration = Config.FadeSeconds })
		task.wait(Config.FadeSeconds)
	end

	local function pickAnomaly()
		if (enteringLevel and Config.FirstStationOfLevelIsNormal) or #anomalies == 0 then
			return nil
		end
		if random:NextNumber() >= Config.AnomalyChance then
			return nil
		end
		-- Never the same anomaly twice in a row.
		local pool = {}
		for _, anomaly in anomalies do
			if anomaly ~= lastAnomaly or #anomalies == 1 then
				table.insert(pool, anomaly)
			end
		end
		return pool[random:NextInteger(1, #pool)]
	end

	publishState("Riding")
	applyLevelMood(refs, level)
	waitForPlayers()

	while true do
		-- Set up the next station while the screen is dark.
		local anomaly = pickAnomaly()
		local ctx = AnomalyContext.new(refs, Players:GetPlayers(), random)
		if anomaly then
			local ok, err = pcall(anomaly.Apply, ctx)
			if not ok then
				warn("[EndlessSubway] anomaly", anomaly.Name, "failed to apply:", err)
				ctx:Restore()
				anomaly = nil
			end
		end
		lastAnomaly = anomaly or lastAnomaly
		enteringLevel = false
		if Config.Debug then
			print("[EndlessSubway] Level", level, "station", station, "anomaly:", anomaly and anomaly.Name or "none")
		end

		setDoors(refs, false)
		boardTrain(refs)
		stationStartedAt = os.clock()
		publishState("Riding")
		fade(false)

		-- The train has stopped: doors open and the players decide.
		setDoors(refs, true)
		publishState("Station")
		local choice, byCoinFlip = VoteManager.collect(refs.Doors, net, random)

		publishState("Riding")
		if byCoinFlip then
			message("تعادل… القرعة اختارت \"" .. (if choice == "Continue" then "كمّل" else "ارجع") .. "\"", 2)
		end
		fade(true)

		if anomaly then
			local ok, err = pcall(anomaly.Reset, ctx)
			if not ok then
				warn("[EndlessSubway] anomaly", anomaly.Name, "failed to reset:", err)
			end
		end
		-- Restore is idempotent, so this also covers anomalies whose Reset forgot to call it.
		ctx:Restore()

		if choice == nil then
			-- Everyone left: start over for the next group.
			level, station, enteringLevel, lastAnomaly = 1, 0, true, nil
			applyLevelMood(refs, level)
			publishState("Riding")
			waitForPlayers()
			continue
		end

		local correct = (choice == "Continue") == (anomaly == nil)
		if correct then
			station += 1
			if station >= Config.StationsPerLevel then
				station = 0
				enteringLevel = true
				if level < #Config.Levels then
					level += 1
					message("Level " .. level .. " — " .. Config.Levels[level].Name, 3)
				else
					level = 1
					message("وصلتوا للنهاية… (المشهد الأخير لسه بيتبني)", 4)
				end
				applyLevelMood(refs, level)
			end
		else
			station = 0
			message("غلط… رجعتوا لأول الـ Level", 3)
		end

		publishState("Riding")
		task.wait(Config.BlackoutSeconds)
	end
end

return GameLoop
