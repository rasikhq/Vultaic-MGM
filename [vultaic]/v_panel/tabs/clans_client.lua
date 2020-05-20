-- 'Clans' tab
local settings = {id = 2, title = "Clans"}
local content = nil
local items = {
	["input_search"] = {type = "input", placeholder = "Search for a clan...", x = 0, y = 0, width = panel.width,height = panel.fontHeight * 2, maxLength = 20},
	["gridlist_clans"] = {type = "gridlist", x = 0, y = panel.fontHeight * 2, width = panel.width, height = panel.height - panel.fontHeight * 2 - 50, customBlockHeight = panel.fontHeight * 5, columns = (screenWidth > 1000 and 3 or 2)},
	["button_clientclan"] = {type = "button", text = "Create your clan", x = panel.width * 0.375, y = panel.height - 45, width = panel.width * 0.25, height = 35}
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
clanFromID = {}

-- Calculations
local function precacheStuff()
	content.borderHeight = math.floor(items["gridlist_clans"].fontHeight * 1.5)
end

-- Initialization
local function initTab()
	-- Tab registration
	content = panel.initTab(settings.id, settings, items)
	precacheStuff()
	-- Customization
	items["gridlist_clans"].customBlockRendering = function(x, y, row, item, i)
		local clan = content.clans[i]
		local r, g, b = unpack(clan.colorRGB)
		dxDrawText(row.text, x + 10, y, x + item.blockWidth, y + item.blockHeight * 0.5 - 2.5, tocolor(r, g, b, 255), item.fontScale, item.font, "left", "bottom", true, true)
		dxDrawText(clan.data.description or "", x + 10, y + item.blockHeight * 0.5 + 2.5, x + item.blockWidth * 0.95, y + item.blockHeight, tocolor(255, 255, 255, 155), item.fontScale, dxlib.getFont("Roboto-Regular", 11), "left", "top", true, true)
		dxDrawText(clan.membersAmount, x, y, x + item.blockWidth - 10, y + item.blockHeight - 10, tocolor(255, 255, 255, 155), item.fontScale, dxlib.getFont("Roboto-Regular", 11), "right", "bottom", false, false, false, true)
	end
	-- Functions
	-- 'select clan'
	items["gridlist_clans"].onSelect = function(id)
		setSelectedClan(tonumber(content.clans[id].id))
	end
	-- 'client clan'
	items["button_clientclan"].onClick = function()
		if content.clientClan then
			setSelectedClan(tonumber(content.clans[1].id))
		else
			if not getElementData(localPlayer, "LoggedIn") then
				return triggerEvent("notification:create", localPlayer, "Clan", "You have to be logged in to create a clan")
			end
			panel.switch(tonumber(settings.id..".2"))
		end
	end
	updateClans()
	updateInvitations()
end
addEventHandler("onClientResourceStart", resourceRoot, initTab)

function updateClans(clans)
	local clans = type(clans) == "table" and clans or exports.v_clans:getRegisteredClans()
	if type(clans) ~= "table" then
		return
	end
	local clientClan = tonumber(getElementData(localPlayer, "Clan") or 0)
	content.clans = {}
	content.clanNames = {}
	content.clientClan = nil
	clanFromID = {}
	for i, clanData in pairs(clans) do
		local function hexToRGB(hex)
			if hex then
				hex = hex:gsub("#", "")
				return tonumber("0x"..hex:sub(1, 2)), tonumber("0x"..hex:sub(3, 4)), tonumber("0x"..hex:sub(5, 6))
			end
			return 255, 255, 255
		end
		i = tonumber(i)
		local team = getTeamFromName(clanData.ClanName)
		local clan = {}
		if i == clientClan then
			clan.clientClan = 1
			content.clientClan = clan
		else
			clan.clientClan = 0
		end
		clan.id = tonumber(i)
		clan.name = clanData.ClanName
		clan.shrinkedName = string.shrinkToSize(clan.name, items["gridlist_clans"].fontScale, items["gridlist_clans"].font, items["gridlist_clans"].blockWidth * 0.7)
		clan.colorHex = clanData.ClanColor or "#FFFFFF"
		local r, g, b = hexToRGB(clan.colorHex)
		clan.colorRGB = {r, g, b}
		-- Detect online users
		clan.data = {}
		for k, v in pairs(clanData.data) do
			clan.data[k] = v
		end
		clan.online = {}
		-- Detect owners
		clan.owners = {}
		if clanData.data.Founder then
			for i, v in pairs(clanData.data.Founder) do
				clan.owners[tonumber(i)] = v
			end
		end
		-- Detect leaders
		clan.leaders = {}
		for i, v in pairs(clanData.ClanLeaders) do
			clan.leaders[tonumber(i)] = v
		end
		-- Detect members
		clan.members = {}
		clan.membersAmount = 0
		for i, member in pairs(clanData.ClanMembers) do
			i = tonumber(i)
			local owner = clan.owners[i] and true or false
			local leader = clan.leaders[i] and true or false
			local rank = 3
			if owner then
				rank = 1
			elseif leader then
				rank = 2
			end
			local player = playerFromID[i]
			if player then
				clan.online[i] = player
			end
			local nickname = player and getPlayerName(player) or nil
			table.insert(clan.members, {
				id = i,
				rank = rank,
				online = player and 1 or 0,
				player = player,
				username = member,
				nickname = nickname
			})
			clan.membersAmount = clan.membersAmount + 1
		end
		table.sort(clan.members, function(a, b) return (a.rank < b.rank) end)
		clanFromID[i] = clan
		table.insert(content.clans, clan)
	end
	table.sort(content.clans, function(a, b) return (a.clientClan > b.clientClan) end)
	for i, clan in pairs(content.clans) do
		clan.orderID = i
		table.insert(content.clanNames, clan.shrinkedName)
	end
	content.clansCopy, content.clanNamesCopy = table.copy(content.clans, true), table.copy(content.clanNames, true)
	dxlib.setGridlistContent(items["gridlist_clans"], content.clanNames)
	if content.clientClan then
		local r, g, b = unpack(content.clientClan.colorRGB)
		items["button_clientclan"].text = content.clientClan.name
		items["button_clientclan"].backgroundColor = tocolor(r, g, b, 105)
		items["button_clientclan"].hoverColor = {r, g, b, 255}
	else
		items["button_clientclan"].text = "Create your clan"
		items["button_clientclan"].backgroundColor = tocolor(17, 94, 77, 105)
		items["button_clientclan"].hoverColor = {25, 132, 109, 255}
	end
	if content.selectedClanID then
		local clan = clanFromID[content.selectedClanID]
		if clan then
			cacheClanDetails(content.selectedClanID)
		elseif panel.currentTabID == tonumber(settings.id..".1") or panel.currentTabID == tonumber(settings.id..".3") then
			-- If clan doesn't exist anymore, go back to 'Clans' tab
			panel.switch(settings.id)
		end
	end
end
addEvent("Clans:onClandataUpdate", true)
addEventHandler("Clans:onClandataUpdate", root, function(data) updateClans(data) updateInvitations() end)

-- Search filter
function applyClanFilter(filter)
	if not content.clansCopy or #content.clansCopy == 0 then
		return
	end
	if filter == "" then
		content.clans, content.clanNames = table.copy(content.clansCopy), table.copy(content.clanNamesCopy)
		dxlib.setGridlistContent(items["gridlist_clans"], content.clanNamesCopy)
		return
	end
	content.clans, content.clanNames = {}, {}
	local filter = filter:gsub("#%x%x%x%x%x%x", ""):lower()
	for i, clan in pairs(content.clansCopy) do
		if clan.name:gsub("#%x%x%x%x%x%x", ""):lower():find(filter, 1, true) then
			table.insert(content.clans, clan)
			table.insert(content.clanNames, clan.name)
		end
	end
	dxlib.setGridlistContent(items["gridlist_clans"], content.clanNames)
end
items["input_search"].onTextChange = applyClanFilter

-- Catch data updates
addEventHandler("onClientElementDataChange", root,
function(dataName)
	if getElementType(source) == "player" and (dataName == "LoggedIn" or dataName == "Clan") then
		local clan = tonumber(getElementData(source, "Clan"))
		if source == localPlayer then
			updateClans()
			updateInvitations()
			if content.selectedClanID then
				cacheClanDetails(content.selectedClanID)
			end
		elseif clan and content.selectedClanID and content.selectedClanID == clan then
			updateClans()
			updateInvitations()
			cacheClanDetails(content.selectedClanID)
		end
	end
end)

-- Update invitations
function updateInvitations(invitations)
	clientInvitedToClan = {}
	local id = getElementData(localPlayer, "LoggedIn") and tonumber(getElementData(localPlayer, "account_id")) or nil
	local clan = tonumber(getElementData(localPlayer, "Clan") or 0)
	if id and clan == 0 then
		local invitations = type(invitations) == "table" and invitations or getElementData(localPlayer, "ClanInvite")
		if type(invitations) == "table" then
			for i, invite in pairs(invitations) do
				i = tonumber(i)
				local clan = clanFromID[i]
				if clan and not clan.online[id] then
					clientInvitedToClan[i] = true
				end
			end
		end
	end
	if content.selectedClanID then
		cacheClanDetails(content.selectedClanID)
	end
end
addEvent("Clan:onClientInvitationUpdate", true)
addEventHandler("Clan:onClientInvitationUpdate", root, function(data) updateClans() updateInvitations(data) end)

function setSelectedClan(id)
	if id then
		content.selectedClanID = tonumber(id)
		cacheClanDetails(content.selectedClanID)
		panel.switch(tonumber(settings.id..".1"))
	end
end