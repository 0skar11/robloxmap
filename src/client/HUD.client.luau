-- Player HUD.
--   Lobby (always English): a clear screen; on a gate, its status, and for the host: group size
--   1-10, language AR/EN, "Start now".
--   In game (the group's language): level and station counter, the rule, the live door vote,
--   "Back to lobby", the tutorial (level 1, and again when the dark half begins), messages, and
--   the black screen between stations.
-- All state comes from attributes on the local Player (see Shared/Net).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)
local Strings = require(ReplicatedStorage.Shared.Strings)

local player = Players.LocalPlayer
local event = Net.event()
local lobbyAction = Net.lobbyAction()

local YELLOW = Color3.fromRGB(240, 192, 24)
local GREEN = Color3.fromRGB(70, 200, 120)
local RED = Color3.fromRGB(230, 85, 75)
local PANEL = Color3.fromRGB(16, 16, 20)
local BUTTON = Color3.fromRGB(45, 45, 52)

local gui = Instance.new("ScreenGui")
gui.Name = "EndlessSubwayHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local function create(className: string, parent: Instance, props: { [string]: any }): any
	local instance = Instance.new(className)
	for key, value in props do
		(instance :: any)[key] = value
	end
	instance.Parent = parent
	return instance
end

local function rounded(instance: GuiObject, radius: number)
	create("UICorner", instance, { CornerRadius = UDim.new(0, radius) })
end

local function text(parent: Instance, name: string, props: { [string]: any }): TextLabel
	local label = create("TextLabel", parent, {
		Name = name,
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
	})
	for key, value in props do
		(label :: any)[key] = value
	end
	return label
end

local function button(parent: Instance, name: string, props: { [string]: any }): TextButton
	local b = create("TextButton", parent, {
		Name = name,
		BackgroundColor3 = BUTTON,
		AutoButtonColor = true,
		Font = Enum.Font.GothamBold,
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
	})
	for key, value in props do
		(b :: any)[key] = value
	end
	rounded(b, 8)
	create("UIPadding", b, { PaddingTop = UDim.new(0.18, 0), PaddingBottom = UDim.new(0.18, 0) })
	return b
end

-- ===== In-game HUD =====

local gameHud = create("Frame", gui, { Name = "Game", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false })

local levelLabel = text(gameHud, "Level", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -20, 0, 70),
	Size = UDim2.fromOffset(340, 28),
	TextXAlignment = Enum.TextXAlignment.Right,
	TextColor3 = YELLOW,
})
local stationLabel = text(gameHud, "Station", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -20, 0, 100),
	Size = UDim2.fromOffset(340, 40),
	TextXAlignment = Enum.TextXAlignment.Right,
})
local checkpointLabel = text(gameHud, "Checkpoint", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -20, 0, 144),
	Size = UDim2.fromOffset(340, 22),
	TextXAlignment = Enum.TextXAlignment.Right,
	TextColor3 = GREEN,
})
local ruleLabel = text(gameHud, "Rule", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -20, 0, 170),
	Size = UDim2.fromOffset(460, 22),
	TextXAlignment = Enum.TextXAlignment.Right,
	TextColor3 = Color3.fromRGB(190, 190, 195),
})
local leaveButton = button(gameHud, "Leave", {
	Position = UDim2.fromOffset(20, 70),
	Size = UDim2.fromOffset(170, 38),
	BackgroundColor3 = Color3.fromRGB(60, 25, 25),
})

local votePanel = create("Frame", gameHud, {
	Name = "Vote",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -24),
	Size = UDim2.fromOffset(440, 70),
	BackgroundColor3 = PANEL,
	BackgroundTransparency = 0.25,
})
rounded(votePanel, 10)
local continueLabel = text(votePanel, "Continue", { Position = UDim2.fromScale(0.52, 0.1), Size = UDim2.fromScale(0.44, 0.45), TextColor3 = GREEN })
local backLabel = text(votePanel, "Back", { Position = UDim2.fromScale(0.04, 0.1), Size = UDim2.fromScale(0.44, 0.45), TextColor3 = RED })
local voteStatus = text(votePanel, "Status", { Position = UDim2.fromScale(0.04, 0.58), Size = UDim2.fromScale(0.92, 0.34), TextColor3 = Color3.fromRGB(210, 210, 215) })

-- ===== Lobby HUD (English) =====

local lobbyHud = create("Frame", gui, { Name = "Lobby", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })

-- Only shown when you step on a gate that is already full; otherwise the screen stays clear.
local lobbyHint = text(lobbyHud, "Hint", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -30),
	Size = UDim2.fromOffset(560, 30),
	TextColor3 = Color3.fromRGB(220, 220, 220),
	TextStrokeTransparency = 0.5,
	Text = "This gate is full. Try another one.",
	Visible = false,
})

local gatePanel = create("Frame", lobbyHud, {
	Name = "Gate",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -24),
	Size = UDim2.fromOffset(380, 230),
	BackgroundColor3 = PANEL,
	BackgroundTransparency = 0.15,
	Visible = false,
})
rounded(gatePanel, 12)
local gateTitle = text(gatePanel, "Title", { Position = UDim2.new(0, 16, 0, 12), Size = UDim2.new(1, -32, 0, 30), TextColor3 = YELLOW })
local gateStatus = text(gatePanel, "Status", { Position = UDim2.new(0, 16, 0, 46), Size = UDim2.new(1, -32, 0, 22), TextColor3 = Color3.fromRGB(200, 200, 205) })

local hostControls = create("Frame", gatePanel, { Name = "Host", Position = UDim2.new(0, 16, 0, 78), Size = UDim2.new(1, -32, 0, 140), BackgroundTransparency = 1 })
text(hostControls, "SizeLabel", { Size = UDim2.new(0.42, 0, 0, 34), Text = "Group size", TextXAlignment = Enum.TextXAlignment.Left })
local minus = button(hostControls, "Minus", { Position = UDim2.new(0.46, 0, 0, 0), Size = UDim2.new(0.16, 0, 0, 34), Text = "-" })
local sizeValue = text(hostControls, "Size", { Position = UDim2.new(0.64, 0, 0, 0), Size = UDim2.new(0.16, 0, 0, 34), Text = "4" })
local plus = button(hostControls, "Plus", { Position = UDim2.new(0.82, 0, 0, 0), Size = UDim2.new(0.18, 0, 0, 34), Text = "+" })

text(hostControls, "LanguageLabel", { Position = UDim2.new(0, 0, 0, 48), Size = UDim2.new(0.42, 0, 0, 34), Text = "Language", TextXAlignment = Enum.TextXAlignment.Left })
local arabic = button(hostControls, "Arabic", { Position = UDim2.new(0.46, 0, 0, 48), Size = UDim2.new(0.26, 0, 0, 34), Text = "العربية" })
local english = button(hostControls, "English", { Position = UDim2.new(0.74, 0, 0, 48), Size = UDim2.new(0.26, 0, 0, 34), Text = "English" })

local startButton = button(hostControls, "Start", {
	Position = UDim2.new(0, 0, 0, 96),
	Size = UDim2.new(1, 0, 0, 40),
	BackgroundColor3 = Color3.fromRGB(35, 120, 70),
	Text = "Start now",
})

-- ===== Messages and blackout =====

local messageLabel = text(gui, "Message", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.42),
	Size = UDim2.fromScale(0.7, 0.08),
	TextTransparency = 1,
	TextStrokeTransparency = 1,
	ZIndex = 3,
})

-- The station announcement, shown like a PA subtitle while it plays.
local subtitle = text(gui, "Announcement", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -110),
	Size = UDim2.new(0.6, 0, 0, 30),
	BackgroundColor3 = Color3.fromRGB(10, 10, 14),
	BackgroundTransparency = 0.35,
	TextColor3 = Color3.fromRGB(245, 200, 40),
	Visible = false,
	ZIndex = 3,
})

local blackout = create("Frame", gui, {
	Name = "Blackout",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BorderSizePixel = 0,
	BackgroundTransparency = if player:GetAttribute("Phase") == "Riding" then 0 else 1,
	ZIndex = 2,
})

-- ===== Tutorial =====

local tutorial = create("Frame", gui, {
	Name = "Tutorial",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(560, 330),
	BackgroundColor3 = PANEL,
	BackgroundTransparency = 0.08,
	Visible = false,
	ZIndex = 4,
})
rounded(tutorial, 14)
create("UIStroke", tutorial, { Color = YELLOW, Thickness = 2, Transparency = 0.3 })
local tutorialTitle = text(tutorial, "Title", { Position = UDim2.new(0, 24, 0, 18), Size = UDim2.new(1, -48, 0, 36), TextColor3 = YELLOW, ZIndex = 4 })
local tutorialBody = text(tutorial, "Body", {
	Position = UDim2.new(0, 24, 0, 66),
	Size = UDim2.new(1, -48, 0, 190),
	TextScaled = false,
	TextSize = 20,
	TextWrapped = true,
	TextYAlignment = Enum.TextYAlignment.Top,
	LineHeight = 1.15,
	Font = Enum.Font.Gotham,
	ZIndex = 4,
})
local tutorialOk = button(tutorial, "Ok", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -18),
	Size = UDim2.fromOffset(200, 44),
	BackgroundColor3 = Color3.fromRGB(35, 120, 70),
	ZIndex = 4,
	-- In first person the mouse is locked; a visible Modal button frees it so it can be clicked.
	Modal = true,
})

gui.Parent = player:WaitForChild("PlayerGui")

-- ===== Refresh =====

local function attr(name: string, default: any): any
	local value = player:GetAttribute(name)
	if value == nil then
		return default
	end
	return value
end

local tutorialsSeen: { [string]: boolean } = {}

local function closeTutorial()
	tutorial.Visible = false
	player:SetAttribute("UiOpen", false)
end

local function refresh()
	local phase = attr("Phase", "Lobby")
	local inGame = phase ~= "Lobby"
	gameHud.Visible = inGame
	lobbyHud.Visible = not inGame

	if inGame then
		local language = attr("Language", "en")
		local function t(key: string, ...: any): string
			return Strings.get(language, key, ...)
		end

		levelLabel.Text = t(if attr("Mood", "Calm") == "Horror" then "PhaseHorror" else "PhaseCalm")
		stationLabel.Text = t("HudLevel", attr("Level", 1), attr("TotalLevels", Config.TotalLevels))
		local checkpoint = attr("Checkpoint", 0)
		checkpointLabel.Visible = checkpoint > 0
		checkpointLabel.Text = t("HudCheckpoint", checkpoint)
		local backDoor = attr("BackDoor", true)
		ruleLabel.Text = t(if backDoor then "Rule" else "RuleFirst")
		leaveButton.Text = if UserInputService.TouchEnabled then t("LeaveRun") else t("LeaveRun") .. "  [L]"

		-- Dead players spectate instead of voting.
		votePanel.Visible = phase == "Station" and not attr("Dead", false)
		local continueVotes, backVotes = attr("VotesContinue", 0), attr("VotesBack", 0)
		local voters, countdown = attr("Voters", 0), attr("VoteCountdown", -1)
		continueLabel.Text = t("VoteContinue", continueVotes)
		backLabel.Text = t("VoteBack", backVotes)
		backLabel.Visible = backDoor
		continueLabel.Position = if backDoor then UDim2.fromScale(0.52, 0.1) else UDim2.fromScale(0.28, 0.1)
		if attr("VoteTie", false) then
			voteStatus.Text = t("VoteTie")
		elseif countdown >= 0 then
			voteStatus.Text = t("VoteCountdown", countdown)
		elseif continueVotes + backVotes == 0 then
			voteStatus.Text = t("VoteStandAtDoor")
		else
			voteStatus.Text = t("VoteWaiting", continueVotes + backVotes, voters)
		end

		-- Each tutorial shows once per game: on level 1, and when the dark half begins.
		if phase == "Station" and not attr("Dead", false) then
			local level = attr("Level", 1)
			local which = if level == 1 then "Calm" elseif level == Config.HorrorStartsAtLevel then "Horror" else nil
			local key = which and (tostring(attr("SessionKey", "")) .. which)
			if key and not tutorialsSeen[key] then
				tutorialsSeen[key] = true
				tutorialTitle.Text = t(if which == "Calm" then "TutorialTitle" else "TutorialHorrorTitle")
				tutorialBody.Text = t(if which == "Calm" then "TutorialBody" else "TutorialHorrorBody")
				tutorialOk.Text = t("TutorialOk")
				local alignment = if language == "ar" then Enum.TextXAlignment.Right else Enum.TextXAlignment.Left
				tutorialTitle.TextXAlignment = alignment
				tutorialBody.TextXAlignment = alignment
				tutorial.Visible = true
				player:SetAttribute("UiOpen", true)
			end
		elseif phase ~= "Station" and tutorial.Visible then
			closeTutorial()
		end
		return
	end
	if tutorial.Visible then
		closeTutorial()
	end

	local pad = attr("Pad", 0)
	local onGate = pad > 0
	gatePanel.Visible = onGate
	lobbyHint.Visible = attr("PadFull", false) and not onGate
	if not onGate then
		return
	end

	local count, size = attr("PadCount", 0), attr("PadMax", Config.DefaultPartySize)
	local language = attr("PadLanguage", "en")
	local countdown = attr("PadCountdown", -1)
	local isHost = attr("PadHost", false)

	gateTitle.Text = string.format("GATE %d  ·  %d / %d players", pad, count, size)
	if countdown >= 0 then
		gateStatus.Text = string.format("The train leaves in %d...", countdown)
	elseif isHost then
		gateStatus.Text = "You are the host. Pick the size and language."
	else
		gateStatus.Text = string.format("Waiting for the host  ·  %s", if language == "ar" then "Arabic" else "English")
	end

	hostControls.Visible = isHost
	gatePanel.Size = UDim2.fromOffset(380, if isHost then 230 else 84)
	sizeValue.Text = tostring(size)
	arabic.BackgroundColor3 = if language == "ar" then YELLOW else BUTTON
	arabic.TextColor3 = if language == "ar" then Color3.new(0, 0, 0) else Color3.new(1, 1, 1)
	english.BackgroundColor3 = if language == "en" then YELLOW else BUTTON
	english.TextColor3 = if language == "en" then Color3.new(0, 0, 0) else Color3.new(1, 1, 1)
end

player.AttributeChanged:Connect(refresh)
refresh()

minus.Activated:Connect(function()
	lobbyAction:FireServer("SetPartySize", attr("PadMax", Config.DefaultPartySize) - 1)
end)
plus.Activated:Connect(function()
	lobbyAction:FireServer("SetPartySize", attr("PadMax", Config.DefaultPartySize) + 1)
end)
arabic.Activated:Connect(function()
	lobbyAction:FireServer("SetLanguage", "ar")
end)
english.Activated:Connect(function()
	lobbyAction:FireServer("SetLanguage", "en")
end)
startButton.Activated:Connect(function()
	lobbyAction:FireServer("StartNow")
end)
tutorialOk.Activated:Connect(closeTutorial)
leaveButton.Activated:Connect(function()
	lobbyAction:FireServer("LeaveRun")
end)



-- ===== Server moments =====

local messageToken = 0
local function showMessage(body: string, duration: number)
	messageToken += 1
	local token = messageToken
	messageLabel.Text = body
	TweenService:Create(messageLabel, TweenInfo.new(0.3), { TextTransparency = 0, TextStrokeTransparency = 0.5 }):Play()
	task.delay(duration, function()
		if token == messageToken then
			TweenService:Create(messageLabel, TweenInfo.new(0.6), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end

-- Jumpscare: a face fills the screen with a red flash and a shake. Nobody dies from it.
local function jumpscare()
	local scare = create("Frame", gui, {
		Name = "Jumpscare",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(40, 0, 0),
		BorderSizePixel = 0,
		ZIndex = 20,
	})
	local face = create("Frame", scare, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.75, 0.95),
		BackgroundColor3 = Color3.fromRGB(170, 175, 168),
		BorderSizePixel = 0,
		ZIndex = 21,
	})
	create("UICorner", face, { CornerRadius = UDim.new(0.45, 0) })
	for _, x in { 0.3, 0.7 } do
		local eye = create("Frame", face, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(x, 0.38),
			Size = UDim2.fromScale(0.2, 0.16),
			BackgroundColor3 = Color3.fromRGB(10, 0, 0),
			BorderSizePixel = 0,
			ZIndex = 22,
		})
		create("UICorner", eye, { CornerRadius = UDim.new(0.5, 0) })
		local pupil = create("Frame", eye, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.35, 0.45),
			BackgroundColor3 = Color3.fromRGB(255, 30, 20),
			BorderSizePixel = 0,
			ZIndex = 23,
		})
		create("UICorner", pupil, { CornerRadius = UDim.new(0.5, 0) })
		create("Frame", face, {
			Position = UDim2.fromScale(x - 0.02, 0.46),
			Size = UDim2.fromScale(0.04, 0.2),
			BackgroundColor3 = Color3.fromRGB(105, 8, 10),
			BorderSizePixel = 0,
			ZIndex = 22,
		})
	end
	local mouth = create("Frame", face, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.75),
		Size = UDim2.fromScale(0.5, 0.16),
		BackgroundColor3 = Color3.fromRGB(20, 0, 0),
		BorderSizePixel = 0,
		ZIndex = 22,
	})
	create("UICorner", mouth, { CornerRadius = UDim.new(0.3, 0) })
	for i = 0, 6 do
		create("Frame", mouth, {
			Position = UDim2.fromScale(0.04 + i * 0.135, 0),
			Size = UDim2.fromScale(0.07, 0.35),
			BackgroundColor3 = Color3.fromRGB(220, 215, 200),
			BorderSizePixel = 0,
			ZIndex = 23,
		})
	end

	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local started = os.clock()
	while os.clock() - started < 0.9 do
		local strength = 1 - (os.clock() - started) / 0.9
		face.Position = UDim2.new(0.5, math.random(-30, 30) * strength, 0.5, math.random(-30, 30) * strength)
		face.Size = UDim2.fromScale(0.75 + 0.15 * (1 - strength), 0.95 + 0.15 * (1 - strength))
		scare.BackgroundColor3 = if math.random() < 0.5 then Color3.fromRGB(120, 0, 0) else Color3.fromRGB(20, 0, 0)
		if humanoid then
			humanoid.CameraOffset = Vector3.new(math.random(-10, 10) / 20, math.random(-10, 10) / 20, 0) * strength
		end
		task.wait(0.03)
	end
	if humanoid then
		humanoid.CameraOffset = Vector3.zero
	end
	scare:Destroy()
end

event.OnClientEvent:Connect(function(payload)
	if payload.Kind == "Fade" then
		local goal = if payload.Visible then 0 else 1
		TweenService:Create(blackout, TweenInfo.new(payload.Duration or 1), { BackgroundTransparency = goal }):Play()
	elseif payload.Kind == "Message" then
		showMessage(payload.Text, payload.Duration or 3)
	elseif payload.Kind == "Jumpscare" then
		task.spawn(jumpscare)
	elseif payload.Kind == "Announce" then
		subtitle.Text = payload.Text or ""
		subtitle.Visible = true
		local shown = subtitle.Text
		task.delay(7, function()
			if subtitle.Text == shown then
				subtitle.Visible = false
			end
		end)
	end
end)

-- First person locks the mouse on PC, so leaving also works from the keyboard: press L twice.
local leaveArmedUntil = 0
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or input.KeyCode ~= Enum.KeyCode.L or attr("Phase", "Lobby") == "Lobby" then
		return
	end
	if os.clock() < leaveArmedUntil then
		leaveArmedUntil = 0
		lobbyAction:FireServer("LeaveRun")
	else
		leaveArmedUntil = os.clock() + 2
		showMessage(Strings.get(attr("Language", "en"), "LeaveConfirm"), 2)
	end
end)
