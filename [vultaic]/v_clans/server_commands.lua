local function cmd(s, f)
	return addCommandHandler(s, f)
end

function list(player, cmd, arg)
	local clans = getClans()
	for ClanID, ClanData in pairs(clans) do
		outputChatBox(ClanID.. ": "..tostring(ClanData))
	end
end
--cmd("clist", list)

function cmd_deleteclan(player, cmd, clanID)
	if not hasObjectPermissionTo(player, "command.stopall" ) then
		return outputChatBox("Access denied", player, 255, 255, 255)
	end
	clanID = tonumber(clanID)
	if type(clanID) == "number" then
		if isClanRegistered(clanID) then
			Clans[clanID]:destroy(player)
			outputChatBox("* Clan destroyed", player, 0, 255, 0)
		else
			outputChatBox("* Clan with the given ID is not registered", player, 255, 0, 0)
		end
	else
		outputChatBox("* Invalid clan ID", player, 255, 0, 0)
	end
end
cmd("deleteclan", cmd_deleteclan)