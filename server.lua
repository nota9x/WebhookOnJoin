--[[
#################################################################################
#                              a9x Development                                  #
#                                                                               #
# This script is developed by a9x Development and is licensed under the GPL-3.0 #
# (GNU General Public License v3.0).                                            #
#                                                                               #
# This script is provided "as is", without warranty of any kind, express or     #
# implied, including but not limited to the warranties of merchantability,      #
# fitness for a particular purpose and noninfringement. In no event shall the   #
# authors or copyright holders be liable for any claim, damages or other        #
# liability, whether in an action of contract, tort or otherwise, arising from, #
# out of or in connection with the script or the use or other dealings in the   #
# script.                                                                       #
#                                                                               #
# You should have received a copy of the GNU General Public License along with  #
# this script. If not, see https://www.gnu.org/licenses/.                       #
#################################################################################
]]

-- ServerScript (placed in ServerScriptService)
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create the RemoteEvent if it doesn't exist
local inputTypeEvent = ReplicatedStorage:FindFirstChild("InputTypeEvent") or Instance.new("RemoteEvent", ReplicatedStorage)
inputTypeEvent.Name = "InputTypeEvent"

-- Constants
local WEBHOOK_URL = "WEBHOOK_URL_HERE"
local IP_API_URL = "https://api.ipgeolocation.io/ipgeo?apiKey=API_KEY_HERE"

-- Potential error messages
local ERROR_FETCHING_REGION = "[getServerRegion] Error fetching server region: "
local ERROR_CONVERTING_FLAG = "[convertFlagToEmoji] Error: "
local ERROR_MISSING_DATA = "[getServerRegion] Missing data in API response"
local ERROR_SENDING_WEBHOOK = "[sendWebhookMessage] Error: "
local ERROR_WEBHOOK_URL_MISSING = "[sendWebhookMessage] Webhook URL is not set."
local ERROR_API_KEY_MISSING = "[getServerRegion] API key is missing or API URL is blank."

-- Abbreviation mappings
local stateAbbreviations = {
    -- US States
    ["Alabama"] = "AL", ["Alaska"] = "AK", ["Arizona"] = "AZ", ["Arkansas"] = "AR", ["California"] = "CA",
    ["Colorado"] = "CO", ["Connecticut"] = "CT", ["Delaware"] = "DE", ["Florida"] = "FL", ["Georgia"] = "GA",
    ["Hawaii"] = "HI", ["Idaho"] = "ID", ["Illinois"] = "IL", ["Indiana"] = "IN", ["Iowa"] = "IA",
    ["Kansas"] = "KS", ["Kentucky"] = "KY", ["Louisiana"] = "LA", ["Maine"] = "ME", ["Maryland"] = "MD",
    ["Massachusetts"] = "MA", ["Michigan"] = "MI", ["Minnesota"] = "MN", ["Mississippi"] = "MS", ["Missouri"] = "MO",
    ["Montana"] = "MT", ["Nebraska"] = "NE", ["Nevada"] = "NV", ["New Hampshire"] = "NH", ["New Jersey"] = "NJ",
    ["New Mexico"] = "NM", ["New York"] = "NY", ["North Carolina"] = "NC", ["North Dakota"] = "ND", ["Ohio"] = "OH",
    ["Oklahoma"] = "OK", ["Oregon"] = "OR", ["Pennsylvania"] = "PA", ["Rhode Island"] = "RI", ["South Carolina"] = "SC",
    ["South Dakota"] = "SD", ["Tennessee"] = "TN", ["Texas"] = "TX", ["Utah"] = "UT", ["Vermont"] = "VT",
    ["Virginia"] = "VA", ["Washington"] = "WA", ["West Virginia"] = "WV", ["Wisconsin"] = "WI", ["Wyoming"] = "WY",
    -- Major Canadian Provinces
    ["Ontario"] = "ON", ["Quebec"] = "QC", ["British Columbia"] = "BC", ["Alberta"] = "AB",
    -- Major European Regions
    ["Hamburg"] = "HH", ["Berlin"] = "BE", ["Bavaria"] = "BY", ["Saxony"] = "SN"
    -- Add additional abbreviations if necessary
}

-- Fire webhook message
local function sendWebhookMessage(player, inputType, serverRegion, ping, gameName, gameLink)
    if WEBHOOK_URL == "" or WEBHOOK_URL == "WEBHOOK_URL_HERE" then
        warn(ERROR_WEBHOOK_URL_MISSING)
        return
    end

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
            {name = "Ping", value = (ping > 0 and string.format("%.2f", ping) or "N/A") .. "ms", inline = true},
            {name = "Game Name", value = "[" .. gameName .. "](" .. gameLink .. ")", inline = true}
        }
    }

    local payload = HttpService:JSONEncode({embeds = {embed}})
    local success, errorMessage = pcall(function()
        HttpService:PostAsync(WEBHOOK_URL, payload, Enum.HttpContentType.ApplicationJson, false)
    end)

    if not success then
        warn(ERROR_SENDING_WEBHOOK .. errorMessage)
    end
end

-- Get server region
local function getServerRegion()
    -- Convert flag image URL to Discord emoji
    local function convertFlagToEmoji(flagUrl)
        local success, result = pcall(function()
            local countryCode = string.match(flagUrl, "flags/(%a+)_64.png")
            if not countryCode then
                error("Failed to extract country code from flag URL")
            end
            return ":flag_" .. countryCode:lower() .. ":"
        end)

        if not success then
            warn(ERROR_CONVERTING_FLAG .. result)
            return ":question:" -- Default emoji for errors
        end

        return result
    end
   
    if IP_API_URL == "" or string.find(IP_API_URL, "API_KEY_HERE") then
        warn(ERROR_API_KEY_MISSING)
        return "Unknown"
    end

    local success, asyncInfo = pcall(function()
        return HttpService:GetAsync(IP_API_URL)
    end)

    if not success then
        warn(ERROR_FETCHING_REGION .. asyncInfo)
        return "Unknown"
    end

    local parsedInfo = HttpService:JSONDecode(asyncInfo)
    if parsedInfo and parsedInfo.city and parsedInfo.state_prov and parsedInfo.country_flag then
        local state = parsedInfo.state_prov
        local abbreviation = stateAbbreviations[state] or state
        local flagEmoji = convertFlagToEmoji(parsedInfo.country_flag)
        return parsedInfo.city .. ", " .. abbreviation .. " " .. flagEmoji
    else
        warn(ERROR_MISSING_DATA)
        return "Unknown"
    end
end

-- Function to handle player joining
local function onPlayerJoin(player)
    local function onInputTypeReceived(player, inputType)
        local serverRegion = getServerRegion()
        local ping = player:GetNetworkPing() * 2000 -- Convert to milliseconds and account for round trip
        local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
        local gameLink = "https://www.roblox.com/games/" .. game.PlaceId
        sendWebhookMessage(player, inputType, serverRegion, ping, gameName, gameLink)
    end

    inputTypeEvent.OnServerEvent:Connect(onInputTypeReceived)
end

-- Bind player joining event
Players.PlayerAdded:Connect(onPlayerJoin)