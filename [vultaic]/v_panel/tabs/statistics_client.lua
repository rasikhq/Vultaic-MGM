-- 'Statistics' tab
local settings = {id = 1, title = "Statistics"}
local content = nil
local items = {
	["input_search"] = {type = "input", placeholder = "Search for a player...", x = 0, y = 0, width = panel.width, height = panel.fontHeight * 2, maxLength = 20},
	["gridlist_players"] = {type = "gridlist", x = 0, y = panel.fontHeight * 2, width = panel.width, height = panel.height - panel.fontHeight * 2, customBlockHeight = panel.fontHeight * 4, columns = (screenWidth < 1000 and 2 or 3), readOnly = true}
}
playerFromID = {}
-- Optimization
local dxCreateRenderTarget = dxCreateRenderTarget
local dxSetRenderTarget = dxSetRenderTarget
local dxSetBlendMode = dxSetBlendMode
local dxDrawRectangle = dxDrawRectangle
local dxDrawText = dxDrawText
local dxDrawImage = dxDrawImage
local dxDrawImageSection = dxDrawImageSection
local unpack = unpack
local tocolor = tocolor
local math_min = math.min
local math_max = math.max
local math_floor = math.floor
local tableInsert = table.insert
local tableRemove = table.remove
local pairs = pairs
local interpolateBetween = interpolateBetween

-- Calculations
local function precacheStuff()
	content.avatarSize = math.floor(items["gridlist_players"].blockHeight * 0.5)
	content.avatarOffset = (items["gridlist_players"].blockHeight - content.avatarSize)/2
	content.rankSize = 10
end

-- Initialization
local function initTab()
	-- Tab registration
	content = panel.initTab(settings.id, settings, items)
	precacheStuff()
	-- Customization
	items["gridlist_players"].customBlockRendering = function(x, y, row, item, i, hover)
		local player = content.players[i]
		if not player then
			return
		end
		local logged = getElementData(player, "LoggedIn")
		if getElementData(player, "donator") then
			dxDrawImage(x + 1, y + content.avatarOffset - 9, content.avatarSize + 18, content.avatarSize + 18, "img/highlight.png", 0, 0, 0, tocolor(55, 255, 55, 255))
		end
		dxDrawPlayerAvatar(player, x + 10, y + content.avatarOffset, content.avatarSize, 255)
		dxDrawText(row.text, x + content.avatarSize + 20, y, x + item.blockWidth, y + item.blockHeight, tocolor(255, 255, 255, 255), item.fontScale, item.font, "left", "center", false, false, false, true)
		dxDrawText("playing at "..content.userdata[player].arena, x + content.avatarSize + 20, y, x + item.blockWidth - 10, y + item.blockHeight - 10, tocolor(255, 255, 255, 155), item.fontScale, dxlib.getFont("Roboto-Regular", 11), "right", "bottom", true)	
		if not logged and hover > 0 then
			dxDrawRectangle(x, y, item.blockWidth, item.blockHeight, tocolor(25, 25, 25, 225 * hover))
			dxDrawText("User is not logged in", x, y, x + item.blockWidth, y + item.blockHeight - 10 * (1 - hover), tocolor(255, 255, 255, 255 * hover), item.fontScale, dxlib.getFont("Roboto-Regular", 11), "center", "center", false, false, false, true)
		end
	end
	-- Functions
	-- 'Select player'
	items["gridlist_players"].onSelect = function(id)
		local player = content.players[id]
		if isElement(player) then
			cachePlayerStatistics(player)
			triggerServerEvent("mysql:onRequestPlayerStats", localPlayer, player)
		end
	end
	updatePlayers()
end
addEventHandler("onClientResourceStart", resourceRoot, initTab)

-- Update player list
function updatePlayers(exceptionPlayer)
	content.players = {}
	content.playerNames = {}
	content.userdata = {}
	playerFromID = {}
	local players = getElementsByType("player")
	for i, player in pairs(players) do
		if player == localPlayer then
			table.remove(players, i)
			table.insert(players, 1, localPlayer)
			break
		end
	end
	for i, player in pairs(getElementsByType("player")) do
		if not exceptionPlayer or player ~= exceptionPlayer then
			table.insert(content.players, player)
			table.insert(content.playerNames, getPlayerName(player))
			content.userdata[player] = {}
			content.userdata[player].arena = (getElementData(player, "arena") or "n/a"):upper()
			local id = tonumber(getElementData(player, "account_id"))
			if id then
				playerFromID[id] = player
			end
		end
	end
	dxlib.setGridlistContent(items["gridlist_players"], content.playerNames)
end
addEventHandler("onClientPlayerJoin", root, updatePlayers)
addEventHandler("onClientPlayerQuit", root, function() updatePlayers(source) end)

addEventHandler("onClientPlayerChangeNick", root,
function()
	content.refreshReqired = true
end)

addEvent("panel:onVisibilityChanged", true)
addEventHandler("panel:onVisibilityChanged", localPlayer,
function(state)
	if state and content.refreshReqired then
		updatePlayers()
		content.refreshReqired = nil
	end
end)

-- Search filter
function applyPlayerFilter(filter)
	local filter = filter and filter or (items["input_search"].text or "")
	if filter == "" then
		updatePlayers()
		return
	end
	content.players = {}
	content.playerNames = {}
	local filter = filter:gsub("#%x%x%x%x%x%x", ""):lower()
	for i, player in pairs(getElementsByType("player")) do
		local playerName = getPlayerName(player)
		if playerName:gsub("#%x%x%x%x%x%x", ""):lower():find(filter, 1, true) then
			table.insert(content.players, player)
			table.insert(content.playerNames, playerName)
		end
	end
	dxlib.setGridlistContent(items["gridlist_players"], content.playerNames)
end
items["input_search"].onTextChange = applyPlayerFilter

-- Catching data updates
local dataToCatch = {username = true, arena = true, Clan = true}
addEventHandler("onClientElementDataChange", root,
function(dataName)
	local text = items["input_search"].text or ""
	if getElementType(source) == "player" and dataToCatch[dataName] and text == "" then
		updatePlayers()
		applyPlayerFilter()
	end
end)