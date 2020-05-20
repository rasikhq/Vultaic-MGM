-- 'Clan Overview' tab
local settings = {id = 2.1, title = "Clan Overview"}
local content = nil
local items = {
	["custom_header"] = {type = "custom", x = 0, y = 0, width = panel.width, height = panel.height * 0.2},
	["button_goback"] = {type = "button", text = "Return", x = 5, y = 5, width = 100, height = 35},
	["button_acceptinvite"] = {type = "button", text = "Accept", x = panel.width * 0.9 - 5, y = panel.height * 0.2 - 40, width = panel.width * 0.1, height = 35},
	["button_declineinvite"] = {type = "button", text = "Ignore", x = panel.width * 0.8 - 10, y = panel.height * 0.2 - 40, width = panel.width * 0.1, height = 35},
	["gridlist_roster"] = {type = "gridlist", x = 0, y = panel.height * 0.2, width = panel.width, height = panel.height * 0.8, customBlockHeight = panel.fontHeight * 4, columns = 3, font = dxlib.getFont("Roboto-Regular", 11), readOnly = true},
	["button_leave"] = {type = "button", text = "Leave", x = panel.width - 105, y = 5, width = 100, height = 35},
	["rectangle_controls"] = {type = "rectangle", x = panel.width * 0.8, y = panel.height * 0.2, width = panel.width * 0.2, height = panel.height * 0.8, color = tocolor(24, 24, 24, 55)},
	["custom_quickcontrols"] = {type = "custom", x = panel.width * 0.8, y = panel.height * 0.2 + 10, width = panel.width * 0.2, height = 40},
	["button_profile"] = {type = "button", text = "View profile", x = panel.width * 0.8 + 10, y = panel.height * 0.2 + 55, width = panel.width * 0.2 - 20, height = 35},
	["button_promote"] = {type = "button", text = "Promote member", x = panel.width * 0.8 + 10, y = panel.height * 0.2 + 95, width = panel.width * 0.2 - 20, height = 35},
	["button_demote"] = {type = "button", text = "Demote member", x = panel.width * 0.8 + 10, y = panel.height * 0.2 + 135, width = panel.width * 0.2 - 20, height = 35},
	["button_kick"] = {type = "button", text = "Kick member", x = panel.width * 0.8 + 10, y = panel.height * 0.2 + 175, width = panel.width * 0.2 - 20, height = 35},
	["custom_advancedcontrols"] = {type = "custom", x = panel.width * 0.8, y = panel.height * 0.2 + 255, width = panel.width * 0.2, height = 40},
	["button_acp"] = {type = "button", text = "Control panel", x = panel.width * 0.8 + 10, y = panel.height * 0.2 + 300, width = panel.width * 0.2 - 20, height = 35}
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

-- Calculations
local function precacheStuff()
	content.avatarSize = math.floor(items["gridlist_roster"].blockHeight * 0.5)
	content.avatarOffset = (items["gridlist_roster"].blockHeight - content.avatarSize)/2
	content.rankSize = 10
end

local rankTitles = {
	[1] = "Owner",
	[2] = "Leader",
	[3] = "Member"
}

-- Initialization
local function initTab()
	-- Tab registration
	content = panel.initTab(settings.id, settings, items)
	precacheStuff()
	-- Customization
	items["custom_header"].renderingFunction = function(x, y, item)
		if content.clan then
			local r, g, b = unpack(content.clan.colorRGB)
			dxDrawRectangle(x, y, item.width, item.height, tocolor(20, 20, 20, 245))
			dxDrawText(content.name, x, y, item.width, y + item.height * 0.5, tocolor(r, g, b, 255), item.fontScale, dxlib.getFont("RobotoCondensed-Regular", 16), "center", "center", true)
			if content.activeInvitationExist then
				dxDrawText("You have been invited to '"..content.clan.name.."'", x, item.height * 0.4 + 10, item.width, 0, tocolor(255, 255, 255, 255), item.fontScale, item.font, "center", "top", false, false, false, true)
			elseif content.descriptionData then
				local x, y = 0, item.height * 0.4 + 10
				for i, v in pairs(content.descriptionData) do
					dxDrawText(v, x, y, item.width, 0, tocolor(255, 255, 255, 255), item.fontScale, item.font, "center", "top", false, false, false, true)
					y = y + item.fontHeight
				end
			end
		end
	end
	items["gridlist_roster"].customBlockRendering = function(x, y, row, item, i)
		local r, g, b = 255, 255, 255
		if content.clan then
			r, g, b = unpack(content.clan.colorRGB)
		end
		local avatarTexture = content.avatars[i]
		local rank = content.clan.members[i].rank
		if isElement(avatarTexture) then
			dxSetShaderValue(panel.maskShader, "imageTexture", avatarTexture)
		end
		if playerFromID[content.clan.members[i].id] then
			dxDrawText("online", x, y, x + item.blockWidth - 10, y + item.blockHeight - 10, tocolor(255, 255, 255, 155), item.fontScale, item.font, "right", "bottom", false, false, false, true)
		end
		dxDrawImage(x + 10, y + content.avatarOffset, content.avatarSize, content.avatarSize, panel.maskShader, 0, 0, 0, tocolor(255, 255, 255, 255))
		dxDrawText(row.text, x + content.avatarSize + 20, y, x + item.blockWidth, y + item.blockHeight * 0.5, tocolor(r, g, b, 255), item.fontScale, dxlib.getFont("RobotoCondensed-Regular", 14), "left", "bottom", false, false, false, true)
		dxDrawText(rankTitles[rank] or "", x + content.avatarSize + 20, y + item.blockHeight * 0.5, x + item.blockWidth, y + item.blockHeight, tocolor(255, 255, 255, 155), item.fontScale, item.font, "left", "top", false, false, false, true)		
	end
	items["custom_quickcontrols"].renderingFunction = function(x, y, item)
		dxDrawText("Quick Controls", x, y, x + item.width, y + item.height, tocolor(255, 255, 255, 255), item.fontScale, item.font, "center", "center", true)
	end
	items["custom_advancedcontrols"].renderingFunction = function(x, y, item)
		dxDrawText("Advanced", x, y, x + item.width, y + item.height, tocolor(255, 255, 255, 255), item.fontScale, item.font, "center", "center", true)
	end
	-- Functions
	-- 'go back'
	items["button_goback"].onClick = function()
		panel.switch(panel.previousTabID or math.floor(settings.id))
	end
	-- 'select'
	items["gridlist_roster"].onSelect = function(id)
		if not content.adminControlsAllowed then
			local id = tonumber(content.clan.members[id].id)
			local player = id and playerFromID[id]  or nil
			if player then
				if isElement(player) then
					cachePlayerStatistics(player)
					triggerServerEvent("mysql:onRequestPlayerStats", localPlayer, player)
				end
			end
		else
			return true
		end
	end
	-- 'acp button'
	items["button_acp"].onClick = function()
		if content.adminControlsAllowed then
			updateAdministrationCache(content.clan)
			panel.switch(2.3)
		end
	end
	-- 'leave'
	items["button_leave"].onClick = function()
		triggerServerEvent("Clan:onPlayerLeaveClan", localPlayer, content.clan.id)
	end
	-- 'profile'
	items["button_profile"].onClick = function()
		local row, id = dxlib.getGridlistSelectedRow(items["gridlist_roster"])
		if row then
			local member = content.clan.members[tonumber(id)]
			if member and member.online == 1 then
				cachePlayerStatistics(member.player)
				triggerServerEvent("mysql:onRequestPlayerStats", localPlayer, member.player)
			end
		end
	end
	-- 'promote'
	items["button_promote"].onClick = function()
		if content.adminControlsAllowed then
			local user = nil
			local row, id = dxlib.getGridlistSelectedRow(items["gridlist_roster"])
			if row then
				local member = content.clan.members[id]
				if member then
					local rank = member.rank or 3
					if rank == 1 or rank == 2 or (member.player and member.player == localPlayer) then
						return triggerEvent("notification:create", localPlayer, "Clan", "You can't promote this member")
					end
					if member.player then
						triggerServerEvent("Clan:onPlayerUpdateRole", localPlayer, member.player, "leader")
					else
						triggerServerEvent("Clan:onPlayerUpdateRole", localPlayer, {accountID = member.id, username = member.username}, "leader")
					end
				end
			end
		end
	end
	-- 'demote'
	items["button_demote"].onClick = function()
		if content.adminControlsAllowed then
			local user = nil
			local row, id = dxlib.getGridlistSelectedRow(items["gridlist_roster"])
			if row then
				local member = content.clan.members[id]
				if member then
					local rank = member.rank or 3
					if ((rank == 1 or rank == 2) and not content.advancedControlsAllowed) or (member.player and member.player == localPlayer) then
						return triggerEvent("notification:create", localPlayer, "Clan", "You can't demote this member")
					end
					if member.player then
						triggerServerEvent("Clan:onPlayerUpdateRole", localPlayer, member.player, "member")
					else
						triggerServerEvent("Clan:onPlayerUpdateRole", localPlayer, {accountID = member.id, username = member.username}, "member")
					end
				end
			end
		end
	end
	-- 'kick'
	items["button_kick"].onClick = function()
		if content.adminControlsAllowed then
			local user = nil
			local row, id = dxlib.getGridlistSelectedRow(items["gridlist_roster"])
			if row then
				local member = content.clan.members[id]
				if member then
					local rank = member.rank or 3
					if ((rank == 1 or rank == 2) and not content.advancedControlsAllowed) or (member.player and member.player == localPlayer) then
						return triggerEvent("notification:create", localPlayer, "Clan", "You can't kick this member")
					end
					if member.player then
						triggerServerEvent("Clan:onPlayerKick", localPlayer, member.player)
					else
						triggerServerEvent("Clan:onPlayerKick", localPlayer, {accountID = member.id, username = member.username})
					end
				end
			end
		end
	end
	-- 'accept invitation'
	items["button_acceptinvite"].onClick = function()
		if content.activeInvitationExist then
			triggerServerEvent("Clan:onPlayerTakeInvitationAction", localPlayer, content.clan.id, "accept")
		end
	end
	-- 'decline invitation'
	items["button_declineinvite"].onClick = function()
		if content.activeInvitationExist then
			content.activeInvitationExist = nil
			dxlib.setItemVisible(content, items["button_acceptinvite"], content.activeInvitationExist)
			dxlib.setItemVisible(content, items["button_declineinvite"], content.activeInvitationExist)
			triggerServerEvent("Clan:onPlayerTakeInvitationAction", localPlayer, content.clan.id, "decline")
		end
	end
end
addEventHandler("onClientResourceStart", resourceRoot, initTab)

-- Cache clan details
function cacheClanDetails(id)
	local clan = clanFromID[id]
	if type(clan) == "table" then
		content.clan = clan
		getClanDetails()
		updateAdminControls()
	end
end

-- Get clan details
function getClanDetails()
	if not content.clan then
		return
	end
	content.activeInvitationExist = clientInvitedToClan[content.clan.id] ~= nil
	-- Clear previous avatars
	content.avatars = {}
	content.users = {}
	content.usernames = {}
	content.name = string.shrinkToSize(content.clan.name, items["custom_header"].fontScale, items["custom_header"].font, items["custom_header"].width * 0.65)
	for i, member in pairs(content.clan.members) do
		content.avatars[i] = exports.v_avatars:getAvatarTexture(member.player)
		table.insert(content.users, member)
		table.insert(content.usernames, member.nickname and member.nickname or member.username)
	end
	local description = content.clan.data.description or "no description."
	content.descriptionData = getBoundingString(description, items["custom_header"].fontScale, items["custom_header"].font, items["custom_header"].width * 0.6, items["custom_header"].height * 0.6 - 20)
	dxlib.setGridlistContent(items["gridlist_roster"], content.usernames)
	-- Admin controls
	updateAdminControls()
	-- Colorization
	local r, g, b = unpack(content.clan.colorRGB)
	local buttons = {"button_goback", "button_leave", "button_promote", "button_demote", "button_profile", "button_kick", "button_acp", "button_acceptinvite", "button_declineinvite"}
	for i, v in pairs(buttons) do
		items[v].backgroundColor = tocolor(r, g, b, 105)
		items[v].hoverColor = {r, g, b, 255}
	end
end

-- Update admin controls
function updateAdminControls()
	local advancedControlsAllowed = false
	local adminControlsAllowed = false
	local basicControlsAllowed = false
	local id = getElementData(localPlayer, "LoggedIn") and tonumber(getElementData(localPlayer, "account_id")) or nil
	local clan = tonumber(getElementData(localPlayer, "Clan"))
	if id and clan and content.clan.id == clan and content.clan.online[id] then
		basicControlsAllowed = true
		if content.clan.owners[id] then
			advancedControlsAllowed = true
		end
		if advancedControlsAllowed or content.clan.leaders[id] then
			adminControlsAllowed = true
		end
	end
	-- Visibility of buttons
	local _items = {"button_promote", "button_demote", "button_profile", "button_kick", "custom_quickcontrols"}
	for i, v in pairs(_items) do
		dxlib.setItemVisible(content, items[v], adminControlsAllowed)
	end
	dxlib.setItemVisible(content, items["button_acp"], advancedControlsAllowed)
	dxlib.setItemVisible(content, items["custom_advancedcontrols"], advancedControlsAllowed)
	content.advancedControlsAllowed = advancedControlsAllowed
	if adminControlsAllowed then
		dxlib.setItemVisible(content, items["rectangle_controls"], true)
		items["gridlist_roster"].columns = 2
		dxlib.setItemData(items["gridlist_roster"], "width", panel.width * 0.8)
		precacheStuff()
	else
		dxlib.setItemVisible(content, items["rectangle_controls"], false)
		items["gridlist_roster"].columns = 3
		dxlib.setItemData(items["gridlist_roster"], "width", panel.width)
		precacheStuff()
	end
	dxlib.setItemVisible(content, items["button_leave"], basicControlsAllowed)
	content.adminControlsAllowed = adminControlsAllowed
	dxlib.setItemVisible(content, items["button_acceptinvite"], content.activeInvitationExist)
	dxlib.setItemVisible(content, items["button_declineinvite"], content.activeInvitationExist)
end