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

-- Lobby: groups of 1 to 10 players gather on a pad, then get their own copy of the station.
Config.MinPartySize = 1
Config.MaxPartySize = 10
Config.DefaultPartySize = 4
Config.LobbyPads = 6
Config.LobbyCountdownSeconds = 5

-- Each group's station is built this far from the previous one along X.
Config.StationSpacing = 1000

-- Passengers wear random real Roblox avatars. Set false to use the plain block mannequins.
Config.RandomAvatarNpcs = true

-- Per-level mood of the station lights. Levels 2 and 3 only change the lights for now
-- (build step 3 adds their own scenes).
Config.Levels = {
	{
		Name = "The Last Train",
		LightColor = Color3.fromRGB(255, 226, 180),
		LightBrightness = 0.9,
	},
	{
		Name = "Fractured",
		LightColor = Color3.fromRGB(255, 180, 140),
		LightBrightness = 0.6,
	},
	{
		Name = "Acceptance",
		LightColor = Color3.fromRGB(170, 195, 255),
		LightBrightness = 0.4,
	},
}

return Config
