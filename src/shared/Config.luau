-- Tuning values for Endless Subway. Shared so the HUD can read the same numbers as the server.

local Config = {}

-- Levels. Each level is one stop of the train.
--   Levels 1-5: a normal, bright station with small spot-the-difference changes.
--   Level 5 is a checkpoint: a mistake after it sends the group back to level 6, not level 1.
--   Level 6 on: the lights die, the hints appear, and the strange things start.
Config.TotalLevels = 15
Config.Checkpoints = { 5 }
Config.HorrorStartsAtLevel = 6

-- These levels never have an anomaly, so players can learn what "normal" looks like
-- (once in the bright station, once in the dark one).
Config.AlwaysNormalLevels = { 1, 6 }

-- The GO BACK door only exists from this level on. Level 1 is always safe, so there is
-- nothing to go back from.
Config.BackDoorFromLevel = 2

-- Chance that any other level carries an anomaly.
Config.AnomalyChance = 0.6

-- Bright levels use only the mild anomalies. Set false to make levels 1-5 never change at all.
Config.CalmAnomalies = true

-- Once every player stands at a door and there is a clear majority, this countdown starts.
Config.VoteConfirmSeconds = 3

-- After the first vote, the decision is forced after this many seconds (ties are settled by coin flip).
Config.VoteTimeoutSeconds = 45

-- Screen fade and the "riding in the dark" pause between stations.
Config.FadeSeconds = 1
Config.BlackoutSeconds = 2

-- Prints the active anomaly to the server output. Handy while testing, spoils the game otherwise.
Config.Debug = false

-- Lobby: groups of 1 to 10 players gather on a gate, then go play together.
Config.MinPartySize = 1
Config.MaxPartySize = 10
Config.DefaultPartySize = 4
Config.LobbyPads = 6
Config.LobbyCountdownSeconds = 5

-- In the live game, the lobby and every group's game run in separate servers: a gate teleports
-- its group to a private server of this same place. Roblox Studio cannot teleport, so there
-- everything runs in one server (each group still gets its own station copy).
Config.UseSeparateServers = true

-- How long a game server waits for the whole group to arrive before starting anyway.
Config.GroupArrivalTimeout = 20

-- Each local group's station is built this far from the previous one along X.
Config.StationSpacing = 1000

-- Passengers wear random real Roblox avatars. Set false to use the plain block mannequins.
Config.RandomAvatarNpcs = true

-- Movement. PC: hold Shift to sprint. Mobile: a button on screen toggles sprint.
Config.WalkSpeed = 16
Config.SprintSpeed = 26

-- Station lights for the two halves of the game.
Config.Moods = {
	Calm = {
		LightColor = Color3.fromRGB(255, 246, 228),
		LightBrightness = 1.8,
	},
	Horror = {
		LightColor = Color3.fromRGB(255, 205, 160),
		LightBrightness = 0.8,
	},
}

return Config
