-- Tuning values for Endless Subway. Shared so the HUD can read the same numbers as the server.

local Config = {}

-- Five correct stations in a row clear a level.
Config.StationsPerLevel = 5

-- Chance that a station (after the first one of a level) carries an anomaly.
Config.AnomalyChance = 0.6

-- The first station of every level is always normal, so players can learn the baseline.
Config.FirstStationOfLevelIsNormal = true

-- Once every player stands at a door and there is a clear majority, this countdown starts.
Config.VoteConfirmSeconds = 3

-- After the first vote, the decision is forced after this many seconds (ties are settled by coin flip).
Config.VoteTimeoutSeconds = 45

-- Screen fade and the "riding in the dark" pause between stations.
Config.FadeSeconds = 1
Config.BlackoutSeconds = 2

-- Prints the active anomaly to the server output. Handy while testing, spoils the game otherwise.
Config.Debug = false

-- Per-level mood. Levels 2 and 3 only change the lighting for now (build step 3 adds their own scenes).
Config.Levels = {
	{
		Name = "The Last Train",
		Ambient = Color3.fromRGB(60, 60, 70),
		LightColor = Color3.fromRGB(255, 241, 214),
		LightBrightness = 1.4,
	},
	{
		Name = "Fractured",
		Ambient = Color3.fromRGB(45, 40, 40),
		LightColor = Color3.fromRGB(255, 205, 170),
		LightBrightness = 0.9,
	},
	{
		Name = "Acceptance",
		Ambient = Color3.fromRGB(30, 34, 45),
		LightColor = Color3.fromRGB(190, 210, 255),
		LightBrightness = 0.6,
	},
}

return Config
