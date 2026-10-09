-- One group's game: the train stops, the players look around, they vote on a door, the screen goes
-- dark, and the same station comes back one level further (or not).
--
-- Rule: a normal station means "Continue"; a station with something wrong means "Back".
--   Right call  -> next level.
--   Wrong call  -> back to the level after the last checkpoint (level 1 before any checkpoint).
--   Everyone dead -> everyone respawns at level 1.
-- Levels 1-5 are the bright, calm station; from Config.HorrorStartsAtLevel the lights die and the
-- hints appear.
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
local DEAD_LIGHT = Color3.fromRGB(60, 60, 58)

local GameLoop = {}

local function setDoors(refs, open: boolean)
	for _, panel in refs.DoorPanels do
		TweenService:Create(panel.Part, DOOR_TWEEN, { CFrame = if open then panel.Open else panel.Closed }):Play()
	end
end

local function moodOf(level: number): "Calm" | "Horror"
	return if level >= Config.HorrorStartsAtLevel then "Horror" else "Calm"
end

-- Calm: every light on and no hints. Horror: some lights die and the hints appear.
local function applyMood(refs, mood: "Calm" | "Horror")
	local look = Config.Moods[mood]
	for _, fixture in refs.Lights do
		local on = mood == "Calm" or not fixture:GetAttribute("DiesInHorror")
		fixture.Material = if on then Enum.Material.Neon else Enum.Material.SmoothPlastic
		fixture.Color = if on then look.LightColor else DEAD_LIGHT
		local light = fixture:FindFirstChildOfClass("SurfaceLight")
		if light then
			light.Enabled = on
			light.Color = look.LightColor
			light.Brightness = look.LightBrightness
		end
	end
	for _, hint in refs.Hints do
		hint.Parent = if mood == "Horror" then refs.Station else nil
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
	local checkpoint = 0
	local mood = moodOf(level)
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
		setAll("Mood", mood)
		setAll("Level", level)
		setAll("TotalLevels", Config.TotalLevels)
		setAll("Checkpoint", checkpoint)
		refs.CounterLabel.Text = text("Counter", level, Config.TotalLevels)
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
		for i, player in session.GetAlive() do
			player.Character:PivotTo(refs.StandPoints[(i - 1) % #refs.StandPoints + 1])
		end
	end

	local function pickAnomaly()
		if table.find(Config.AlwaysNormalLevels, level) or #anomalies == 0 then
			return nil
		end
		if mood == "Calm" and not Config.CalmAnomalies then
			return nil
		end
		if random:NextNumber() >= Config.AnomalyChance then
			return nil
		end
		-- Calm levels only use the mild anomalies. Never the same one twice in a row.
		local pool = {}
		for _, anomaly in anomalies do
			if (mood == "Horror" or not anomaly.Horror) and anomaly ~= lastAnomaly then
				table.insert(pool, anomaly)
			end
		end
		if #pool == 0 then
			return nil
		end
		return pool[random:NextInteger(1, #pool)]
	end

	runClock(refs, function()
		return stationStartedAt
	end)
	applyMood(refs, mood)
	publishState("Riding")
	publishVote(0, 0, 0, -1, false)
	-- The lobby fades to black before the group appears in the train.
	fade(true)
	-- Give random-avatar passengers a moment to load in the dark.
	task.wait(Config.BlackoutSeconds)

	while #members() > 0 do
		-- Set up the next station while the screen is dark.
		local newMood = moodOf(level)
		if newMood ~= mood then
			mood = newMood
			applyMood(refs, mood)
		end

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
		if Config.Debug then
			print("[EndlessSubway] session", session.Slot, "level", level, "anomaly:", anomaly and anomaly.Name or "none")
		end

		setDoors(refs, false)
		boardTrain()
		stationStartedAt = os.clock()
		publishState("Riding")
		fade(false)

		-- The train has stopped: doors open and the players decide.
		setDoors(refs, true)
		publishState("Station")
		local choice, byCoinFlip, outcome = VoteManager.collect(refs.Doors, members, session.GetAlive, publishVote, random)

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

		if outcome == "Left" then
			return
		end

		if outcome == "Wiped" then
			-- The whole group died: everyone comes back, from the very beginning.
			level, checkpoint = 1, 0
			message(text("Wiped"), 3)
			session.Revive()
		elseif (choice == "Continue") == (anomaly == nil) then
			if table.find(Config.Checkpoints, level) then
				checkpoint = level
				message(text("CheckpointReached", checkpoint + 1), 4)
			end
			level += 1
			if level > Config.TotalLevels then
				message(text("Ending"), 4)
				task.wait(4)
				return
			end
			if level == Config.HorrorStartsAtLevel then
				task.delay(2, message, text("HorrorBegins"), 3)
			end
		else
			level = checkpoint + 1
			message(text("Wrong", level), 3)
		end

		publishState("Riding")
		task.wait(Config.BlackoutSeconds)
	end
end

return GameLoop
