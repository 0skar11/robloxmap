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

-- No time limit: everyone thinks as long as they like, and nothing is ever chosen for them.
-- Set a number of seconds to force a decision after the first vote (ties then go to a coin flip).
Config.VoteTimeoutSeconds = nil :: number?

-- Screen fade and the "riding in the dark" pause between stations.
Config.FadeSeconds = 1
Config.BlackoutSeconds = 2

-- Prints the active anomaly to the server output. Handy while testing, spoils the game otherwise.
Config.Debug = false

-- Testing: the level a new game starts at. Set it to 6 to jump straight into the dark half
-- (checkpoints before it count as reached). Keep it at 1 for the real game.
Config.StartLevel = 1

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

-- NPCs wear their fixed avatars (see Server/NpcOutfits). Set false to use plain block mannequins.
Config.AvatarNpcs = true

-- Movement. PC: hold Shift to sprint. Mobile: a button on screen toggles sprint.
Config.WalkSpeed = 16
Config.SprintSpeed = 26

-- Sounds. Most are public sounds from the Roblox Creator Store; swap any id for your own.
-- The announcement voices are empty until voice recordings are uploaded to Roblox: put each
-- one's "rbxassetid://..." here and it plays after the chime (the text shows on screen anyway).
Config.Sounds = {
	StationAmbience = "rbxassetid://5870205466", -- NYC Subway Station Platform Ambience
	HorrorAmbience = "rbxassetid://1837172508", -- The Fear Within (APM)
	TrainArrive = "rbxassetid://9119665017", -- Subway Train 2 (ProSoundEffects)
	DoorOpen = "rbxassetid://98940676768707", -- Train Door Open Chime
	DoorClose = "rbxassetid://87008566532209", -- Train Door Close Chime
	AnnouncementChime = "rbxassetid://7320266725", -- Announcements On
	Static = "rbxassetid://138347177735590", -- Radio Static Sound
	PhoneRing = "rbxassetid://9117305259", -- Phone Ring Electronic Consumer Phone 1 (ProSoundEffects)
	Jumpscare = "rbxassetid://6150329916", -- Jumpscare Scream
	-- Built into Roblox, no upload needed.
	Footsteps = "rbxasset://sounds/action_footsteps_plastic.mp3",
	Announcements = {
		Calm = { ar = nil :: string?, en = nil :: string? },
		Horror = { ar = nil :: string?, en = nil :: string? },
	},
}

-- Cutscenes made by the animator (see animator/README.md). Leave nil to use the built-in
-- placeholders: eyes opening at the start, and a shake-and-flash crash at level 6.
Config.Cutscenes = {
	-- An R15 animation id: the player waking up in their seat at the start of a game.
	WakeUpAnimation = nil :: string?,
	-- A Roblox Video id: the train crash, shown full screen when the dark half begins.
	CrashVideo = nil :: string?,
	-- How long the game waits on the crash before the station comes back (seconds).
	CrashSeconds = 6,
}

-- Saved progress and the lobby leaderboard (Roblox DataStores). In Studio they need
-- Game Settings > Security > "Enable Studio Access to API Services"; without it the game
-- keeps everything in memory for that test.
Config.DataStoreVersion = "v1"
Config.LeaderboardSize = 10

-- Station lights for the two halves of the game.
Config.Moods = {
	Calm = {
		LightColor = Color3.fromRGB(255, 246, 228),
		LightBrightness = 1.45,
	},
	Horror = {
		LightColor = Color3.fromRGB(255, 205, 160),
		LightBrightness = 0.65,
	},
}

return Config
