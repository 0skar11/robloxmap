-- Lobby gates. Standing on a gate joins its group; stepping off leaves it. The first player on a
-- gate is the host and picks the group size (1-10) and the session language (AR / EN). The group
-- leaves when the gate is full, or when the host presses "Start now".

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)
local SessionManager = require(script.Parent.SessionManager)

local POLL_SECONDS = 0.2

local LANGUAGE_NAMES = { ar = "ARABIC", en = "ENGLISH" }

local LobbyManager = {}

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid or humanoid.Health <= 0 then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function isInside(zone: BasePart, position: Vector3): boolean
	local relative = zone.CFrame:PointToObjectSpace(position)
	local half = zone.Size / 2
	return math.abs(relative.X) <= half.X and math.abs(relative.Z) <= half.Z and relative.Y > -2 and relative.Y < 10
end

local function newPad(gate)
	return {
		Gate = gate,
		Members = {} :: { Player },
		MaxPlayers = Config.DefaultPartySize,
		Language = "en",
		StartRequested = false,
		CountdownEnd = nil :: number?,
	}
end

local function resetPad(pad)
	table.clear(pad.Members)
	pad.MaxPlayers = Config.DefaultPartySize
	pad.Language = "en"
	pad.StartRequested = false
	pad.CountdownEnd = nil
end

local function hostPad(pads, player: Player)
	for _, pad in pads do
		if pad.Members[1] == player then
			return pad
		end
	end
	return nil
end

local function render(pad, now: number)
	local gate = pad.Gate
	local count = #pad.Members
	if count == 0 then
		gate.Label.Text = string.format("GATE %d\nEMPTY", gate.Index)
		gate.Zone.Color = Color3.fromRGB(80, 80, 80)
	elseif pad.CountdownEnd then
		gate.Label.Text = string.format("GATE %d  %d/%d\nLEAVING IN %d", gate.Index, count, pad.MaxPlayers, math.ceil(pad.CountdownEnd - now))
		gate.Zone.Color = Color3.fromRGB(40, 170, 90)
	else
		gate.Label.Text = string.format("GATE %d  %d/%d\n%s", gate.Index, count, pad.MaxPlayers, LANGUAGE_NAMES[pad.Language])
		gate.Zone.Color = Color3.fromRGB(220, 175, 25)
	end
	gate.Glow.Color = gate.Zone.Color
end

function LobbyManager.start(lobby)
	local pads = {}
	for _, gate in lobby.Gates do
		table.insert(pads, newPad(gate))
	end

	Net.lobbyAction().OnServerEvent:Connect(function(player: Player, action: any, value: any)
		if action == "LeaveRun" then
			SessionManager.leave(player)
			return
		end

		local pad = hostPad(pads, player)
		if not pad then
			return
		end
		if action == "SetPartySize" and type(value) == "number" and value == value then
			local size = math.clamp(math.floor(value), Config.MinPartySize, Config.MaxPartySize)
			pad.MaxPlayers = math.max(size, #pad.Members)
		elseif action == "SetLanguage" and (value == "ar" or value == "en") then
			pad.Language = value
		elseif action == "StartNow" then
			pad.StartRequested = true
		end
	end)

	task.spawn(function()
		while true do
			local now = os.clock()
			local claimed: { [Player]: boolean } = {}
			local standingOnFull: { [Player]: boolean } = {}

			for _, pad in pads do
				local zone = pad.Gate.Zone

				-- Keep members who are still standing here, in their original order.
				local kept = {}
				for _, player in pad.Members do
					local root = player.Parent and not SessionManager.isPlaying(player) and rootOf(player)
					if root and isInside(zone, root.Position) then
						table.insert(kept, player)
						claimed[player] = true
					end
				end
				pad.Members = kept

				-- Let newcomers in while there is room.
				for _, player in Players:GetPlayers() do
					if claimed[player] or SessionManager.isPlaying(player) then
						continue
					end
					local root = rootOf(player)
					if root and isInside(zone, root.Position) then
						if #pad.Members < pad.MaxPlayers then
							table.insert(pad.Members, player)
							claimed[player] = true
						else
							standingOnFull[player] = true
						end
					end
				end

				if #pad.Members == 0 then
					resetPad(pad)
				else
					local ready = #pad.Members >= pad.MaxPlayers or pad.StartRequested
					if ready and not pad.CountdownEnd then
						pad.CountdownEnd = now + Config.LobbyCountdownSeconds
					elseif not ready then
						pad.CountdownEnd = nil
					end

					if pad.CountdownEnd and now >= pad.CountdownEnd then
						SessionManager.start(table.clone(pad.Members), pad.Language)
						resetPad(pad)
					end
				end

				render(pad, now)
			end

			-- Tell each lobby player's HUD about their gate.
			for _, player in Players:GetPlayers() do
				if SessionManager.isPlaying(player) then
					continue
				end
				local mine = nil
				for _, pad in pads do
					if table.find(pad.Members, player) then
						mine = pad
						break
					end
				end
				player:SetAttribute("Pad", if mine then mine.Gate.Index else 0)
				player:SetAttribute("PadHost", mine ~= nil and mine.Members[1] == player)
				player:SetAttribute("PadCount", if mine then #mine.Members else 0)
				player:SetAttribute("PadMax", if mine then mine.MaxPlayers else 0)
				player:SetAttribute("PadLanguage", if mine then mine.Language else "en")
				player:SetAttribute("PadCountdown", if mine and mine.CountdownEnd then math.max(0, math.ceil(mine.CountdownEnd - now)) else -1)
				player:SetAttribute("PadFull", standingOnFull[player] == true)
			end

			task.wait(POLL_SECONDS)
		end
	end)
end

return LobbyManager
