-- One group's station loop: the train stops, the players look around, they vote on a door, the
-- screen goes dark, and the same station comes back with the counter moved on (or reset).
--
-- Rule: a normal station means "Continue"; a station with something wrong means "Back".
-- A right call moves the counter up; a wrong one sends the group to the start of the level.
--
-- run() returns when the group is gone or has reached the end; SessionManager cleans up.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)
local Strings = require(ReplicatedStorage.Shared.Strings)
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

function GameLoop.run(session)
	local refs = session.Refs
	local language = session.Language
	local event = Net.event()
	local anomalies = AnomalyRegistry.load()
	local random = Random.new()

	local level = 1
	local station = 0
	local enteringLevel = true
	local lastAnomaly = nil
	local stationStartedAt = os.clock()

	local function text(key: string, ...: any): string
		return Strings.get(language, key, ...)
	end

	local function members(): { Player }
		return session.GetMembers()
	end

	local function setAll(name: string, value: any)
		for _, player in members() do
			player:SetAttribute(name, value)
		end
	end

	local function publishState(phase: string)
		setAll("Phase", phase)
		setAll("Level", level)
		setAll("LevelName", Config.Levels[level].Name)
		setAll("Station", station)
		setAll("StationsPerLevel", Config.StationsPerLevel)
		refs.CounterLabel.Text = text("Counter", level, station, Config.StationsPerLevel)
	end

	local function publishVote(continueVotes: number, backVotes: number, voters: number, countdown: number, tie: boolean)
		setAll("VotesContinue", continueVotes)
		setAll("VotesBack", backVotes)
		setAll("Voters", voters)
		setAll("VoteCountdown", countdown)
		setAll("VoteTie", tie)
	end

	local function fire(payload)
		for _, player in members() do
			event:FireClient(player, payload)
		end
	end

	local function message(body: string, duration: number?)
		fire({ Kind = "Message", Text = body, Duration = duration or 3 })
	end

	local function fade(visible: boolean)
		fire({ Kind = "Fade", Visible = visible, Duration = Config.FadeSeconds })
		task.wait(Config.FadeSeconds)
	end

	local function boardTrain()
		for i, player in members() do
			local character = player.Character
			if character and character:FindFirstChild("HumanoidRootPart") then
				character:PivotTo(refs.StandPoints[(i - 1) % #refs.StandPoints + 1])
			end
		end
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

	runClock(refs, function()
		return stationStartedAt
	end)
	applyLevelMood(refs, level)
	publishState("Riding")
	publishVote(0, 0, 0, -1, false)
	-- The lobby fades to black before the group appears in the train.
	fade(true)
	-- Give random-avatar passengers a moment to load in the dark.
	task.wait(Config.BlackoutSeconds)

	while #members() > 0 do
		-- Set up the next station while the screen is dark.
		local anomaly = pickAnomaly()
		local ctx = AnomalyContext.new(refs, members(), random)
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
			print("[EndlessSubway] session", session.Slot, "level", level, "station", station, "anomaly:", anomaly and anomaly.Name or "none")
		end

		setDoors(refs, false)
		boardTrain()
		stationStartedAt = os.clock()
		publishState("Riding")
		fade(false)

		-- The train has stopped: doors open and the players decide.
		setDoors(refs, true)
		publishState("Station")
		local choice, byCoinFlip = VoteManager.collect(refs.Doors, members, publishVote, random)

		publishState("Riding")
		if byCoinFlip then
			message(text("CoinFlip", text(if choice == "Continue" then "DoorContinue" else "DoorBack")), 2)
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
			-- Everyone left.
			return
		end

		local correct = (choice == "Continue") == (anomaly == nil)
		if correct then
			station += 1
			if station >= Config.StationsPerLevel then
				station = 0
				enteringLevel = true
				if level < #Config.Levels then
					level += 1
					message(text("LevelUp", level, Config.Levels[level].Name), 3)
					applyLevelMood(refs, level)
				else
					message(text("Ending"), 4)
					task.wait(4)
					return
				end
			end
		else
			station = 0
			message(text("Wrong"), 3)
		end

		publishState("Riding")
		task.wait(Config.BlackoutSeconds)
	end
end

return GameLoop
