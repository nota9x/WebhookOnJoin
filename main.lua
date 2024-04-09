local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Constants
local WEBHOOK_URL = "" -- !!!YOUR WEBHOOK URL HERE!!!
local IP_API_URL = "http://ip-api.com/json/"

-- Function to send a webhook message
local function sendWebhookMessage(player, inputType, serverRegion, ping, gameName, gameLink)
	local username = player.Name
	local displayName = player.DisplayName
	local userId = player.UserId

	local embed = {
		title = "New player joined the game",
		description = "A new player has joined " .. gameName .. "!",
		fields = {
			{name = "Name", value = "[" .. displayName .. "](https://www.roblox.com/users/" .. tostring(userId) .. "/profile) (@" .. username .. ")", inline = true},
			{name = "User ID", value = userId, inline = true},
			{name = "Input Device", value = inputType, inline = true},
			{name = "Server Region", value = serverRegion, inline = true},
			{name = "Ping", value = (ping > 0 and string.format("%.5f", ping) or "N/A") .. "ms", inline = true}, -- Format ping to 5 digits or show "N/A" if ping is zero
			{name = "Game Name", value = "[" .. gameName .. "](" .. gameLink .. ")", inline = true}
		}
	}

	local payload = HttpService:JSONEncode({embeds = {embed}})
	local success, errorMessage = pcall(function()
		HttpService:PostAsync(WEBHOOK_URL, payload, Enum.HttpContentType.ApplicationJson, false)
	end)

	if not success then
		warn("Error sending webhook message:", errorMessage)
	end
end

-- Function to determine input type
local function determineInputType()
	if UserInputService:GetLastInputType() == Enum.UserInputType.Touch then
		return "Touchscreen"
	elseif UserInputService.GamepadEnabled then
		return "Gamepad"
	else
		return "Keyboard and Mouse"
	end
end

-- Function to get server region
local function getServerRegion()
	local asyncInfo = HttpService:GetAsync(IP_API_URL)
	local parsedInfo = HttpService:JSONDecode(asyncInfo)
	if parsedInfo and parsedInfo.country then
		return parsedInfo.country
	else
		return "Unknown"
	end
end

-- Function to handle player joining
local function onPlayerJoin(player)
	local inputType = determineInputType()
	local serverRegion = getServerRegion()
	local ping = player:GetNetworkPing() * 2000 -- Convert to milliseconds and account for round trip
	ping = tonumber(string.format("%.5f", ping)) -- Round ping to 5 digits
	local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
	local gameLink = "https://www.roblox.com/games/" .. game.PlaceId
	sendWebhookMessage(player, inputType, serverRegion, ping, gameName, gameLink)
end

-- Bind player joining event
Players.PlayerAdded:Connect(onPlayerJoin)