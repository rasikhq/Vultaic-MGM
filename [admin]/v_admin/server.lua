g_OnlineAdmins = {}

local ADMIN_GROUPS = {
	["manager"] = 5,
	["developer"] = 4,
	["super_moderator"] = 3,
	["moderator"] = 2,
}

local level_to_rank = {
	[1] = "Member",
	[2] = "Moderator",
	[3] = "Super Moderator",
	[4] = "Developer",
	[5] = "Manager"
}

local level_to_acl = {
	[2] = aclGetGroup("Moderator"),
	[3] = aclGetGroup("SuperModerator"),
	[4] = aclGetGroup("SuperModerator"),
	[5] = aclGetGroup("Admin"),
}

function onPlayerLogin(data)
	local group
	--
	if data.moderator then
		group = "moderator"
	end
	if data.super_moderator then
		group = "super_moderator"
	end
	if data.community_manager then
		group = "community_manager"
	end
	if data.developer then
		group = "developer"
	end
	if data.manager then
		group = "manager"
	end
	--
	local level = group and ADMIN_GROUPS[group] or 1
	setElementData(source, "admin_level", level)
	if level > 1 then
		local account = getAccount(data.username, data.password)
		if not account then
			account = getAccount(data.username)
			if account then
				setAccountPassword(account, data.password)
			else
				account = addAccount(data.username, data.password, true)
			end
		end
		if account then
			if level < 4 then
				aclGroupRemoveObject(aclGetGroup("SuperModerator"), "user." .. data.username)
			end
			if level < 2 then
				aclGroupRemoveObject(aclGetGroup("Moderator"), "user." .. data.username)
			end
			--
			if not isObjectInACLGroup("user." .. data.username, level_to_acl[level]) then
				aclGroupAddObject(level_to_acl[level], "user." .. data.username)
			end
			logIn(source, account, data.password)
		end
		table.insert(g_OnlineAdmins, source)
		outputChatBox("* Welcome #19846D"..level_to_rank[level].."#ffffff "..getPlayerName(source), source, 255, 255, 255, true)
	end
end
addEvent("login:onPlayerLogin", true)
addEventHandler("login:onPlayerLogin", root, onPlayerLogin)

addEventHandler("onPlayerLogin", root, function(_, account)
	if((getElementData(source, "admin_level") or 1) < 2) then
		cancelEvent( true )
	end
end)

addEventHandler("onPlayerQuit", root, function(qtype, reason, responsibleElement)
	for i = 1, #g_OnlineAdmins do
		if source == g_OnlineAdmins[i] then
			table.remove(g_OnlineAdmins, i)
		end
	end
end)

addEventHandler("onResourceStart", resourceRoot, function()
	for _, player in ipairs(getElementsByType("player")) do
		if((getElementData(player, "admin_level") or 1) > 1) then
			table.insert(g_OnlineAdmins, player)
		end
	end
end)

function getCommandLevels()
	return COMMAND_PERMISSION
end