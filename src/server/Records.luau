-- Saved progress and the fastest-groups leaderboard.
--
--   Best level  each player's highest level reached (TotalLevels + 1 means they finished). Shown
--               above their head in the lobby only, and published as the "BestLevel" attribute.
--   Fastest     the quickest groups to finish the game, shown on the board in the lobby.
--
-- Uses DataStores. If they are not available (Studio without API access, or an outage) the same
-- data lives in memory for that server, so nothing breaks.

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local VERSION = Config.DataStoreVersion

local Records = {}

local progressStore, fastestStore, runStore = nil, nil, nil
local storesOk = pcall(function()
	progressStore = DataStoreService:GetDataStore("EndlessSubway_Progress_" .. VERSION)
	fastestStore = DataStoreService:GetOrderedDataStore("EndlessSubway_Fastest_" .. VERSION)
	runStore = DataStoreService:GetDataStore("EndlessSubway_Runs_" .. VERSION)
end)

local bestCache: { [number]: number } = {}
local memoryRuns: { { Seconds: number, Names: string, Size: number } } = {}
local topCache: { { Seconds: number, Names: string, Size: number } } = {}

local function warnOnce(err)
	if storesOk then
		warn("[EndlessSubway] DataStore unavailable, keeping records in memory:", err)
		storesOk = false
	end
end

-- ===== Best level =====

local function updateTag(player: Player)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head then
		return
	end
	local tag = head:FindFirstChild("BestTag")
	if not tag then
		tag = Instance.new("BillboardGui")
		tag.Name = "BestTag"
		tag.Size = UDim2.fromOffset(200, 26)
		tag.StudsOffset = Vector3.new(0, 2.6, 0)
		tag.AlwaysOnTop = false
		tag.MaxDistance = 60
		local label = Instance.new("TextLabel")
		label.Name = "Text"
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.TextColor3 = Color3.fromRGB(245, 200, 40)
		label.TextStrokeTransparency = 0.4
		label.Parent = tag
		tag.Parent = head
	end
	local best = bestCache[player.UserId] or 0
	local label = tag:FindFirstChild("Text") :: TextLabel
	if best > Config.TotalLevels then
		label.Text = "Best: FINISHED"
	elseif best > 0 then
		label.Text = string.format("Best: Level %d", best)
	else
		label.Text = "Best: -"
	end
	-- Only in the lobby.
	tag.Enabled = player:GetAttribute("Phase") == "Lobby"
end

local function loadBest(player: Player)
	local best = 0
	if storesOk then
		local ok, value = pcall(function()
			return progressStore:GetAsync("u_" .. player.UserId)
		end)
		if ok then
			best = tonumber(value) or 0
		else
			warnOnce(value)
		end
	end
	bestCache[player.UserId] = math.max(bestCache[player.UserId] or 0, best)
	player:SetAttribute("BestLevel", bestCache[player.UserId])
	updateTag(player)
end

-- Called whenever a player reaches a level (TotalLevels + 1 when they finish).
function Records.reportLevel(player: Player, level: number)
	local previous = bestCache[player.UserId] or 0
	if level <= previous then
		return
	end
	bestCache[player.UserId] = level
	player:SetAttribute("BestLevel", level)
	if storesOk then
		task.spawn(function()
			local ok, err = pcall(function()
				progressStore:UpdateAsync("u_" .. player.UserId, function(old)
					return math.max(tonumber(old) or 0, level)
				end)
			end)
			if not ok then
				warnOnce(err)
			end
		end)
	end
end

-- ===== Fastest groups =====

-- Called when a group finishes the game.
function Records.submitRun(players: { Player }, seconds: number)
	local names = {}
	for _, player in players do
		table.insert(names, player.DisplayName)
	end
	local run = { Seconds = math.floor(seconds + 0.5), Names = table.concat(names, ", "), Size = #players }
	table.insert(memoryRuns, run)
	if not storesOk then
		return
	end
	task.spawn(function()
		local id = HttpService:GenerateGUID(false)
		local ok, err = pcall(function()
			runStore:SetAsync(id, run)
			fastestStore:SetAsync(id, run.Seconds)
		end)
		if not ok then
			warnOnce(err)
		end
	end)
end

-- The fastest runs, quickest first (cached; refreshed by refreshTop).
function Records.top(): { { Seconds: number, Names: string, Size: number } }
	return topCache
end

function Records.refreshTop()
	local runs = {}
	if storesOk then
		local ok, err = pcall(function()
			local page = fastestStore:GetSortedAsync(true, Config.LeaderboardSize):GetCurrentPage()
			for _, entry in page do
				local run = runStore:GetAsync(entry.key)
				if type(run) == "table" then
					table.insert(runs, { Seconds = entry.value, Names = tostring(run.Names), Size = tonumber(run.Size) or 0 })
				end
			end
		end)
		if not ok then
			warnOnce(err)
		end
	end
	if not storesOk then
		runs = table.clone(memoryRuns)
		table.sort(runs, function(a, b)
			return a.Seconds < b.Seconds
		end)
	end
	while #runs > Config.LeaderboardSize do
		table.remove(runs)
	end
	topCache = runs
	return runs
end

function Records.init()
	local function onPlayer(player: Player)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("Head", 10)
			updateTag(player)
		end)
		player:GetAttributeChangedSignal("Phase"):Connect(function()
			updateTag(player)
		end)
		player:GetAttributeChangedSignal("BestLevel"):Connect(function()
			updateTag(player)
		end)
		task.spawn(loadBest, player)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		bestCache[player.UserId] = nil
	end)
end

return Records
