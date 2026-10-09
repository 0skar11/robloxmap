-- Player HUD: level and station counter, the rule, the live door vote, messages, and the
-- black screen between stations. All game state comes from attributes on the Net folder.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Net = require(ReplicatedStorage.Shared.Net)

local player = Players.LocalPlayer
local net = Net.folder()
local event = Net.event()

local YELLOW = Color3.fromRGB(245, 197, 24)
local GREEN = Color3.fromRGB(70, 200, 120)
local RED = Color3.fromRGB(230, 85, 75)

local gui = Instance.new("ScreenGui")
gui.Name = "EndlessSubwayHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local function label(name: string, props: { [string]: any }): TextLabel
	local text = Instance.new("TextLabel")
	text.Name = name
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBold
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextScaled = true
	for key, value in props do
		(text :: any)[key] = value
	end
	text.Parent = gui
	return text
end

-- Top-right: level and counter (Arabic reads from the right).
local levelLabel = label("Level", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -20, 0, 50),
	Size = UDim2.fromOffset(320, 28),
	TextXAlignment = Enum.TextXAlignment.Right,
	TextColor3 = YELLOW,
})
local stationLabel = label("Station", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -20, 0, 80),
	Size = UDim2.fromOffset(320, 40),
	TextXAlignment = Enum.TextXAlignment.Right,
})
label("Rule", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -20, 0, 124),
	Size = UDim2.fromOffset(420, 22),
	TextXAlignment = Enum.TextXAlignment.Right,
	TextColor3 = Color3.fromRGB(200, 200, 205),
	Text = "المحطة طبيعية ← كمّل.  فيها حاجة غلط ← ارجع.",
})

-- Bottom: the live vote.
local votePanel = Instance.new("Frame")
votePanel.Name = "Vote"
votePanel.AnchorPoint = Vector2.new(0.5, 1)
votePanel.Position = UDim2.new(0.5, 0, 1, -24)
votePanel.Size = UDim2.fromOffset(420, 70)
votePanel.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
votePanel.BackgroundTransparency = 0.25
votePanel.Visible = false
votePanel.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = votePanel

local function panelLabel(name: string, position: UDim2, size: UDim2, color: Color3): TextLabel
	local text = label(name, { Position = position, Size = size, TextColor3 = color })
	text.Parent = votePanel
	return text
end

local continueLabel = panelLabel("Continue", UDim2.fromScale(0.52, 0.1), UDim2.fromScale(0.44, 0.45), GREEN)
local backLabel = panelLabel("Back", UDim2.fromScale(0.04, 0.1), UDim2.fromScale(0.44, 0.45), RED)
local statusLabel = panelLabel("Status", UDim2.fromScale(0.04, 0.58), UDim2.fromScale(0.92, 0.34), Color3.fromRGB(210, 210, 215))

-- Center: messages.
local messageLabel = label("Message", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.42),
	Size = UDim2.fromScale(0.7, 0.08),
	TextTransparency = 1,
	TextStrokeTransparency = 1,
	ZIndex = 3,
})

-- Full-screen black for the ride between stations. Starts dark unless we joined mid-station.
local blackout = Instance.new("Frame")
blackout.Name = "Blackout"
blackout.Size = UDim2.fromScale(1, 1)
blackout.BackgroundColor3 = Color3.new(0, 0, 0)
blackout.BorderSizePixel = 0
blackout.BackgroundTransparency = if net:GetAttribute("Phase") == "Station" then 1 else 0
blackout.ZIndex = 2
blackout.Parent = gui

gui.Parent = player:WaitForChild("PlayerGui")

local function refreshState()
	local level = net:GetAttribute("Level") or 1
	local levelName = net:GetAttribute("LevelName") or ""
	local station = net:GetAttribute("Station") or 0
	local total = net:GetAttribute("StationsPerLevel") or 5
	levelLabel.Text = string.format("Level %d · %s", level, levelName)
	stationLabel.Text = string.format("المحطة %d / %d", station, total)
end

local function refreshVote()
	votePanel.Visible = net:GetAttribute("Phase") == "Station"

	local continueVotes = net:GetAttribute("VotesContinue") or 0
	local backVotes = net:GetAttribute("VotesBack") or 0
	local voters = net:GetAttribute("Voters") or 0
	local countdown = net:GetAttribute("VoteCountdown") or -1

	continueLabel.Text = "كمّل: " .. continueVotes
	backLabel.Text = "ارجع: " .. backVotes

	if net:GetAttribute("VoteTie") then
		statusLabel.Text = "تعادل! لازم أغلبية"
	elseif countdown >= 0 then
		statusLabel.Text = "القرار خلال " .. countdown .. "…"
	elseif continueVotes + backVotes == 0 then
		statusLabel.Text = "اقف قدام الباب اللي تختاره"
	else
		statusLabel.Text = string.format("مستنيين الباقيين (%d / %d)", continueVotes + backVotes, voters)
	end
end

for _, name in { "Level", "LevelName", "Station", "StationsPerLevel" } do
	net:GetAttributeChangedSignal(name):Connect(refreshState)
end
for _, name in { "Phase", "VotesContinue", "VotesBack", "Voters", "VoteCountdown", "VoteTie" } do
	net:GetAttributeChangedSignal(name):Connect(refreshVote)
end
refreshState()
refreshVote()

local messageToken = 0
local function showMessage(text: string, duration: number)
	messageToken += 1
	local token = messageToken
	messageLabel.Text = text
	TweenService:Create(messageLabel, TweenInfo.new(0.3), { TextTransparency = 0, TextStrokeTransparency = 0.5 }):Play()
	task.delay(duration, function()
		if token == messageToken then
			TweenService:Create(messageLabel, TweenInfo.new(0.6), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end

event.OnClientEvent:Connect(function(payload)
	if payload.Kind == "Fade" then
		local goal = if payload.Visible then 0 else 1
		TweenService:Create(blackout, TweenInfo.new(payload.Duration or 1), { BackgroundTransparency = goal }):Play()
	elseif payload.Kind == "Message" then
		showMessage(payload.Text, payload.Duration or 3)
	end
end)
