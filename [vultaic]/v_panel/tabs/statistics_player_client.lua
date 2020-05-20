-- 'Player Statistics' tab
local settings = {id = 1.1, title = "Player Statistics"}
local content = nil
local items = {
	["custom_header"] = {type = "custom", x = 0, y = 0, width = panel.width, height = panel.height * 0.2, font = dxlib.getFont("RobotoCondensed-Regular", 16)},
	["button_return"] = {type = "button", text = "Return", x = 5, y = 5, width = 100, height = 35},
	["button_invite"] = {type = "button", text = "Invite to clan", x = panel.width - 155, y = 5, width = 150, height = 35},
	["gridlist_badges"] = {type = "gridlist", x = 0, y = panel.height * 0.2, width = panel.width * 0.3, height = panel.height * 0.8, customBlockHeight = panel.height * 0.8 * 0.3, readOnly = true},	
	["gridlist_statistics"] = {type = "gridlist", x = panel.width * 0.3, y = panel.height * 0.2, width = panel.width * 0.7, height = panel.height * 0.8, customBlockHeight = panel.fontHeight * 4, columns = (screenWidth > 1000 and 3 or 2), readOnly = true}
}
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
-- Table of statistics to show
local dataToShow = {
	{"country", "countryName", "mars"},
	{"language", "language", "not specified"},
	{"money", "money", 0},
	{"clan", "Clan", "none"},
	{"deathmatch points", "dm_points", 0},
	{"derby points", "dd_points", 0},
	{"old school points", "os_points", 0},
	{"race points", "race_points", 0},
	{"shooter points", "shooter_points", 0},
	{"hunter points", "hunter_points", 0},
	{"hunters", "hunters", 0},
	{"toptimes", "toptimes", 0},
	{"achievements", "achievements", "n/a"},
	{"playtime", "playtime", "0 days 0 hours 0 minutes 0 seconds"},
}

-- Calculations
local function precacheStuff()
	content.avatarSize = math_floor(items["custom_header"].height * 0.4)
	content.avatarOffset = (items["custom_header"].width - content.avatarSize)/2
	content.badgeSize = math_floor(items["gridlist_badges"].blockHeight * 0.5)
	content.badgeOffset = (items["gridlist_badges"].blockWidth - content.badgeSize)/2
end

-- Local functions
local function formatMilliseconds(milliseconds)
    local totalseconds = math_floor(milliseconds/1000) 
    local minutes = math_floor(totalseconds/60)
    local hours = math_floor(minutes/60)
    local days = math_floor(hours/24)
    minutes = minutes%60
    hours = hours%24
    return string.format("%01d %s %01d %s %01d %s",
		days, (days ~= 1 and "days" or "day"),
		hours, (hours ~= 1 and "hours" or "hour"),
		minutes, (minutes ~= 1 and "minutes" or "minute")
	)
end 

-- Initialization
local function initTab()
	-- Tab registration
	content = panel.initTab(settings.id, settings, items)
	precacheStuff()
	local data = {}
	for i, v in pairs(dataToShow) do
		table.insert(data, v[1])
	end
	dxlib.setGridlistContent(items["gridlist_statistics"], data)
	-- Customization
	items["custom_header"].renderingFunction = function(x, y, item)
		dxDrawRectangle(x, y, item.width, item.height, tocolor(20, 20, 20, 245))
		if content.player then
			local offsetX, offsetY = x + content.avatarOffset, y + 20
			if getElementData(content.player, "donator") then
				dxDrawImage(offsetX - 9, offsetY - 9, content.avatarSize + 18, content.avatarSize + 18, "img/highlight.png", 0, 0, 0, tocolor(55, 255, 55, 255))
			end
			dxDrawPlayerAvatar(content.player, offsetX, offsetY, content.avatarSize, 255)
			dxDrawText(content.playerName, x, y + item.height * 0.5, x + item.width, y + item.height, tocolor(255, 255, 255, 255), item.fontScale, item.font, "center", "center", false, false, false, true)
		end
	end
	items["gridlist_badges"].customBlockRendering = function(x, y, row, item, i)
		local award = content.awards[i]
		if award then
			local badge = "img/badges/"..award.id..".png"
			if fileExists(badge) then
				dxDrawImage(x + content.badgeOffset, y + 10, content.badgeSize, content.badgeSize, badge, 0, 0, 0, tocolor(255, 255, 255, 255))
			end
			dxDrawText(row.text, x, y + content.badgeSize + 20, x + item.blockWidth, y + item.blockHeight, tocolor(255, 255, 255, 255), item.fontScale, item.font, "center", "top", true)
			dxDrawText(award.description or "", x, y, x + item.blockWidth, y + item.blockHeight - 10, tocolor(255, 255, 255, 155), item.fontScale, dxlib.getFont("Roboto-Regular", 11), "center", "bottom", true)

		end
	end
	items["gridlist_statistics"].customBlockRendering = function(x, y, row, item, i)
		local value = content.statistics[i] and content.statistics[i].value  or "-"
		dxDrawText(row.text, x, y + item.blockHeight * 0.6, x + item.blockWidth, y + item.blockHeight, tocolor(255, 255, 255, 155), item.fontScale, dxlib.getFont("Roboto-Regular", 11), "center", "top", true)
		if value then
			dxDrawText(value, x, y, x + item.blockWidth, y + item.blockHeight * 0.6, tocolor(255, 255, 255, 255), item.fontScale, dxlib.getFont("RobotoCondensed-Regular", 14), "center", "bottom", false, false, false, true)
		end
	end
	-- Functions
	-- 'return'
	items["button_return"].onClick = function()
		panel.switch(panel.previousTabID and panel.previousTabID or 1)
	end
	-- 'invite'
	items["button_invite"].onClick = function()
		triggerServerEvent("Clan:onPlayerInvite", localPlayer, content.player)
	end
	items["gridlist_statistics"].onSelect = function(i)
		if i == 4 and content.clanID then
			setSelectedClan(content.clanID)
		end
	end
end
addEventHandler("onClientResourceStart", resourceRoot, initTab)

-- Cache a player's statistics
function cachePlayerStatistics(player)
	if isElement(player) then
		content.player = player
	end
end

addEvent("mysql:onReceivePlayerStats", true)
addEventHandler("mysql:onReceivePlayerStats", root,
function(player, userdata)
	if player == content.player then
		if type(userdata) == "table" then
			getPlayerStatistics(userdata)
			panel.switch(settings.id)
		else
			triggerEvent("notification:create", localPlayer, "Statistics", getPlayerName(player).." #FFFFFFis a guest")
		end
	end
end)

-- Update statistics
function getPlayerStatistics(userdata)
	content.statistics = {}
	if isElement(content.player) and type(userdata) == "table" then
		content.playerName = string.shrinkToSize(getPlayerName(content.player), items["custom_header"].fontScale, items["custom_header"].font, items["custom_header"].width)
		content.nameWidth = dxGetTextWidth(content.playerName:gsub("#%x%x%x%x%x%x", ""), items["custom_header"].fontScale, items["custom_header"].font)
		local clan = tonumber(getElementData(content.player, "Clan"))
		clan = clan and clanFromID[clan] or nil
		if clan then
			content.clanID = clan.id
		else
			content.clanID = nil
		end
		for i = 1, #dataToShow do
			local dataName = dataToShow[i] and dataToShow[i][2] or nil
			local value = nil
			if dataName then
				if dataName == "countryName" then
					value = getElementData(content.player, "countryName")
				else
					value = getElementData(content.player, dataName) or userdata[dataName] or userdata.data[dataName] or userdata.temporary[dataName] or nil
				end
				if value then
					if dataName == "money" then
						value = "$"..value
					elseif dataName == "Clan" then
						value = clanFromID[value] and clanFromID[value].name or "-"
					elseif dataName == "playtime" then
						value = formatMilliseconds(value)
					end
				else
					value = dataToShow[i][3] and dataToShow[i][3] or "-"
				end
			end
			content.statistics[i] = {}
			content.statistics[i].value = value
			content.member = getElementData(content.player, "clanmember")
			content.donator = getElementData(content.player, "donator")
		end
		content.awards = {}
		local awardNames = {}
		if userdata.data.awards then
			for i, award in pairs(userdata.data.awards) do
				award.id = i
				table.insert(content.awards, award)
				table.insert(awardNames, award.name)
			end
		end
		dxlib.setGridlistContent(items["gridlist_badges"], awardNames)
		if #content.awards > 0 then
			dxlib.setItemVisible(content, items["gridlist_badges"], true)
			dxlib.setItemData(items["gridlist_statistics"], "x", items["gridlist_badges"].width)
			dxlib.setItemData(items["gridlist_statistics"], "width", panel.width - items["gridlist_badges"].width)
		else
			dxlib.setItemVisible(content, items["gridlist_badges"], false)
			dxlib.setItemData(items["gridlist_statistics"], "x", 0)
			dxlib.setItemData(items["gridlist_statistics"], "width", panel.width)
		end
		updateInviteButtonVisibility()
	end
end

-- Update 'Invite' button
function updateInviteButtonVisibility()
	local invitationAllowed = false
	local id = getElementData(localPlayer, "LoggedIn") and tonumber(getElementData(localPlayer, "account_id")) or nil
	local clan = getElementData(localPlayer, "LoggedIn") and getElementData(localPlayer, "Clan")
	clan = clan and clanFromID[tonumber(clan)] or nil
	if id and clan and (clan.owners[id] or clan.leaders[id]) then
		local playerClan = getElementData(content.player, "Clan")
		if content.player ~= localPlayer and getElementData(content.player, "LoggedIn") and (not playerClan or not clanFromID[playerClan]) then
			invitationAllowed = true
		end
	end
	dxlib.setItemVisible(content, items["button_invite"], invitationAllowed)
end

addEventHandler("onClientElementDataChange", root,
function(dataName)
	if content and content.player and source == content.player and dataName == "Clan" then
		cachePlayerStatistics(source)
	end
end)

-- Switch to 'Statistics' tab when selected player leaves
addEventHandler("onClientPlayerQuit", root,
function(dataName)
	if content.player and source == content.player and panel.currentTabID == settings.id then
		panel.switch(panel.previousTabID or 1)
	end
end)