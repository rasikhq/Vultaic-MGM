COMMAND_PERMISSION = {
	-- Level 2 - Moderators
	["a"] = 2,
	["sethp"] = 2,
	["getip"] = 2,
	["getserial"] = 2,
	["gethp"] = 2,
	["akick"] = 2,
	["aslap"] = 2,
	["ablow"] = 2,
	["mute"] = 2,
	["warn"] = 2,
	-- Level 3 - Super Moderators
	["aweather"] = 3,
	["asettime"] = 3,
	["asetgamespeed"] = 3,
	["setteam"] = 3,
	["kick"] = 3,
	["slap"] = 3,
	["ban"] = 3,
	["banip"] = 3,
	["mapres"] = 3,
	["eban"] = 4,
	["pgoto"] = 4,
	-- Level 4 - Developer
	["addtag"] = 5,
	["deltag"] = 5,
}
--
COMMAND_PERMISSION["renametop"] = 3
COMMAND_PERMISSION["deletetop"] = 4
COMMAND_PERMISSION["deletealltops"] = 4
COMMAND_PERMISSION["droptops"] = 5
--
COMMAND_PERMISSION["event"] = 4
COMMAND_PERMISSION["resetevent"] = 4
COMMAND_PERMISSION["setround"] = 4
COMMAND_PERMISSION["setmaxrounds"] = 4
COMMAND_PERMISSION["mapshop"] = 4
-- Tag: mapmanager
COMMAND_PERMISSION["mark"] = 3
COMMAND_PERMISSION["deletemap"] = 3
COMMAND_PERMISSION["setmaptag"] = 3
--
COMMAND_PERMISSION["togvr"] = 3
COMMAND_PERMISSION["redo"] = 3
COMMAND_PERMISSION["random"] = 3
COMMAND_PERMISSION["nextmap"] = 3
--
local CMD = addCommandHandler

local function verify(args, types)
	for i = 1, #args do
		if types[i] == "s" then
			args[i] = tostring(args[i])
		elseif types[i] == "i" then
			args[i] = tonumber(args[i]) or false
		elseif types[i] == "p" then
			args[i] = getPlayer(args[i]) or false
		elseif types[i] == "t" then
			args[i] = getTeam(args[i]) or false
		elseif types[i] == "v" then
		end
	end
	return args
end

CMD("a", function(player, command, ...)
	local player_level = getElementData(player, "admin_level") or 1
	if player_level < COMMAND_PERMISSION[command] then
		outputChatBox("Access denied.", player, 255, 255, 255, true)
		return
	end
	local msg = table.concat(arg, " ")
	local p_name = getPlayerName(player)
	for i = 1, #g_OnlineAdmins do
		local admin = g_OnlineAdmins[i]
		if isElement(admin) then
			outputChatBox("#61FFAB(Staff) #ffffff"..p_name.."#ffffff: "..msg, admin, 255, 255, 255, true)
		else
			table.remove(g_OnlineAdmins, i)
		end
	end
end)

CMD("addtag", function(player, command, plr, tag)
	local player_level = getElementData(player, "admin_level") or 1
	if player_level < COMMAND_PERMISSION[command] then
		outputChatBox("Access denied.", player, 255, 255, 255, true)
		return
	end
	if not plr then
		return vmsg("c_r[ADMIN]c_w: Syntax: /addtag [ID/Player] [Tag]", player) 
	end
	plr = getPlayer(plr)
	if not plr then
		return vmsg("c_r[ADMIN]c_w: Invalid player", player)
	end
	if not tag then
		return vmsg("c_r[ADMIN]c_w: Invalid tag", player)
	end
	tag = string.lower(tostring(tag))
	local add_tag = givePlayerTag(plr, tag)
	if add_tag ~= true then
		return vmsg("c_r[ADMIN]c_w: "..add_tag, player)
	else
		return vmsg("c_r[ADMIN]c_w: "..getPlayerName(plr).."c_w has been given c_g+"..tag.."c_w tag", player)
	end
end)

CMD("deltag", function(player, command, plr, tag)
	local player_level = getElementData(player, "admin_level") or 1
	if player_level < COMMAND_PERMISSION[command] then
		outputChatBox("Access denied.", player, 255, 255, 255, true)
		return
	end
	if not plr then
		return vmsg("c_r[ADMIN]c_w: Syntax: /deltag [ID/Player] [Tag]", player) 
	end
	plr = getPlayer(plr)
	if not plr then
		return vmsg("c_r[ADMIN]c_w: Invalid player", player)
	end
	if not tag then
		return vmsg("c_r[ADMIN]c_w: Invalid tag", player)
	end
	tag = string.lower(tostring(tag))
	local del_tag = removePlayerTag(plr, tag)
	if del_tag ~= true then
		return vmsg("c_r[ADMIN]c_w: "..del_tag, player)
	else
		return vmsg("c_r[ADMIN]c_w: "..getPlayerName(plr).."c_w's c_g+"..tag.."c_w tag has been removed", player)
	end
end)

CMD("mapres", function(player, command, _)
	local player_level = getElementData(player, "admin_level") or 1
	if player_level < COMMAND_PERMISSION[command] then
		return outputChatBox("Access denied.", player, 255, 255, 255, true)
	end
	local arena = getElementParent(player)
	if not arena then
		return
	end
	local resource_name = getElementData(arena, "mapResourceName") or getElementData(player, "training.map")
	if not resource_name then
		outputChatBox("There is no map loaded for you.", player, 255, 255, 255, true)
		return
	end
	outputChatBox(resource_name, player, 255, 255, 255, true)
	triggerClientEvent(player, "admin:setClipboardText", resourceRoot, resource_name)
end)

CMD("setmaptag", function(player, command, action, tag)
	local player_level = getElementData(player, "admin_level") or 1
	if player_level < COMMAND_PERMISSION[command] then
		return outputChatBox("Access denied.", player, 255, 255, 255, true)
	else
		local has_tag = getPlayerTag(player, "mapmanager")
		if player_level > 1 and player_level < 5 and not has_tag then
			return outputChatBox("Access denied.", player, 255, 255, 255, true)
		end
	end
	local arena = getElementParent(player)
	if not arena then
		return
	elseif not action or not tag then
		return vmsg("c_r[ADMIN]c_w: Syntax: /setmaptag [Action: + or -] [Tag]", player) 
	end
	if action ~= "+" and action ~= "-" then
		return vmsg("c_r[ADMIN]c_w: Invalid Action", player) 
	end
	local resource_name = getElementData(arena, "mapResourceName") or getElementData(player, "training.map")
	if not resource_name then
		return vmsg("c_r[ADMIN]c_w: No map is loaded for you", player) 
	end
	local mapResource = getResourceFromName(resource_name)
	if mapResource then
		tag = string.lower(tag)
		local tags = getResourceInfo(mapResource, "tags") or ""
		if tags then
			tags = split(tags, " ")
			--
			if action == "-" then
				local cancel = true
				for i = 1, #tags do
					if tags[i] == tag then
						table.remove(tags, i)
						cancel = false
					end
				end
				if cancel then
					vmsg("c_r[ADMIN]c_w: Map does not have c_r"..action..tag.."c_w tag", player)
				else
					tags = table.concat(tags, " ")
					setResourceInfo(mapResource, "tags", tags)
					vmsg("c_r[ADMIN]c_w: The tag c_r"..action..tag.."c_w has been removed from the map", player)
				end
			elseif action == "+" then
				local cancel = false
				for i = 1, #tags do
					if tags[i] == tag then
						vmsg("c_r[ADMIN]c_w: Map already has the c_g"..action..tag.."c_w tag", player)
						cancel = true
						break
					end
				end
				if cancel then
					return
				else
					table.insert(tags, tag)
					tags = table.concat(tags, " ")
					setResourceInfo(mapResource, "tags", tags)
					vmsg("c_r[ADMIN]c_w: Added ag c_g"..action..tag.."c_w to the map", player)
				end
			end
		end
	end
end)

-- Getters

CMD("getip", function(player, command, plr)
	local player_level = getElementData(player, "admin_level") or 1
	if player_level < COMMAND_PERMISSION[command] then
		outputChatBox("Access denied.", player, 255, 255, 255, true)
		return
	end
	plr = getPlayer(plr)
	if not plr then
		return vmsg("c_r[ADMIN]c_w: Invalid player", player)
	end
	vmsg("c_r[ADMIN]c_w: "..getPlayerName(plr).."c_w's IP: "..getPlayerIP(plr), player)
end)

CMD("getserial", function(player, command, plr)
	local player_level = getElementData(player, "admin_level") or 1
	if player_level < COMMAND_PERMISSION[command] then
		outputChatBox("Access denied.", player, 255, 255, 255, true)
		return
	end
	plr = getPlayer(plr)
	if not plr then
		return vmsg("c_r[ADMIN]c_w: Invalid player", player)
	end
	vmsg("c_r[ADMIN]c_w: "..getPlayerName(plr).."c_w's serial: "..getPlayerSerial(plr), player)
end)

CMD("gethp", function(player, command, plr)
	local player_level = getElementData(player, "admin_level") or 1
	if player_level < COMMAND_PERMISSION[command] then
		outputChatBox("Access denied.", player, 255, 255, 255, true)
		return
	end
	plr = getPlayer(plr)
	if not plr then
		return vmsg("c_r[ADMIN]c_w: Invalid player", player)
	end
	vmsg("c_r[ADMIN]c_w: "..getPlayerName(plr).."c_w's HP: "..getElementHealth(plr), player)
end)

-- Setters

CMD("sethp", function(player, command, plr, hp)
	local player_level = getElementData(player, "admin_level") or 1
	if player_level < COMMAND_PERMISSION[command] then
		outputChatBox("Access denied.", player, 255, 255, 255, true)
		return
	end
	local args = verify({plr, hp}, {"p", "i"})
	local plr, hp = args[1], args[2]
	if not plr then
		return vmsg("c_r[ADMIN]c_w: Invalid player", player)
	end
	if not hp then
		return vmsg("c_r[ADMIN]c_w: Invalid HP", player)
	end
	setElementHealth(plr, hp)
	vmsg("c_r[ADMIN]c_w: "..getPlayerName(plr).."c_w's HP set to "..hp, player)
end)

-- Others

CMD("pgoto", function(player, command, plr)
	local player_level = getElementData(player, "admin_level") or 1
	if player_level < COMMAND_PERMISSION[command] then
		outputChatBox("Access denied.", player, 255, 255, 255, true)
		return
	end
	plr = getPlayer(plr)
	if plr then
		setElementPosition(player, getElementPosition(plr))
	end
end)

CMD("warn", function(player, command, plr, ...)
	local player_level = getElementData(player, "admin_level") or 1
	if player_level < COMMAND_PERMISSION[command] then
		outputChatBox("Access denied.", player, 255, 255, 255, true)
		return
	end
	if not plr then
		return vmsg("c_r[ADMIN]c_w: Syntax: /warn [ID/Player] [Reason]", player) 
	end
	plr = getPlayer(plr)
	if not plr then
		return vmsg("c_r[ADMIN]c_w: Invalid player", player)
	end
	local reason = table.concat(arg, " ")
	if reason == "" then
		return vmsg("c_r[ADMIN]c_w: Specify a reason", player)
	end
	local warn_count = exports.v_mysql:getPlayerStats(plr, "admin_warns") or 0
	warn_count = warn_count + 1
	vmsg("c_r[ADMIN]c_w: "..getPlayerName(player).."c_w warned "..getPlayerName(plr).."c_w! "..("("..reason..")").." ["..warn_count.."/3]")
	exports.v_mysql:setPlayerStats(plr, "admin_warns", (warn_count >= 3 and 0 or warn_count))
	if warn_count >= 3 then
		local plr_serial = getPlayerSerial(plr)
		vmsg("c_r[ADMIN]c_w: Console auto-banned "..getPlayerName(plr).."c_w for exceeding warn-limit! (1 day)")
		addBan(nil, nil, plr_serial, nil, reason.." [Exceeding warn limit]", 86400)
		warn_count = 1
	end
end)

CMD("kick", function(player, command, plr, ...)
	local player_level = getElementData(player, "admin_level") or 1
	if player_level < COMMAND_PERMISSION[command] then
		outputChatBox("Access denied.", player, 255, 255, 255, true)
		return
	end
	plr = getPlayer(plr)
	if not plr then
		return vmsg("c_r[ADMIN]c_w: Invalid player", player)
	end
	local reason = table.concat({...}, " ")
	vmsg("c_r[ADMIN]c_w: "..getPlayerName(player).."c_w kicked "..getPlayerName(plr).."c_w! "..(reason ~= "" and "("..reason..")" or ""))
	kickPlayer(plr, reason)
end)

CMD("slap", function(player, command, plr, hp, ...)
	local player_level = getElementData(player, "admin_level") or 1
	if player_level < COMMAND_PERMISSION[command] then
		outputChatBox("Access denied.", player, 255, 255, 255, true)
		return
	end
	local args = verify({plr, hp}, {"p", "i"})
	local plr, hp = args[1], args[2] or 20
	if not plr then
		return vmsg("c_r[ADMIN]c_w: Invalid player", player)
	end
	local reason = table.concat({...}, " ")
	setElementHealth(plr, getElementHealth(plr)-hp)
	vmsg("c_r[ADMIN]c_w: "..getPlayerName(player).."c_w slapped "..getPlayerName(plr).."c_w! c_r("..hp.." HP) "..(reason ~= "" and "("..reason..")" or ""))
end)

CMD("setteam", function(player, command, plr, ...)
	local player_level = getElementData(player, "admin_level") or 1
	if player_level < COMMAND_PERMISSION[command] then
		outputChatBox("Access denied.", player, 255, 255, 255, true)
		return
	end
	local args = verify({plr, table.concat(arg, " ")}, {"p", "t"})
	local plr, team = args[1], args[2]
	if not plr then
		return vmsg("c_r[ADMIN]c_w: Invalid player", player)
	end
	if not team then
		return vmsg("c_r[ADMIN]c_w: Invalid team", player)
	end
	setPlayerTeam(plr, team)
	vmsg("c_r[ADMIN>]c_w: Moved "..getPlayerName(plr).."c_w to team: "..getTeamName(team), player)
	outputChatBoxEx("* You have been moved to team: "..rgb2hex(getTeamColor(team))..getTeamName(team).."c_w!", plr)
end)

CMD("mute", function(player, command, plr, duration, ...)
	local player_level = getElementData(player, "admin_level") or 1
	if player_level < COMMAND_PERMISSION[command] then
		outputChatBox("Access denied.", player, 255, 255, 255, true)
		return
	end
	if not plr then
		return vmsg("c_r[ADMIN]c_w: Syntax: /mute [ID/Player] [Duration] [Optional: Reason]", player) 
	end
	plr = getPlayer(plr)
	local seconds, action, state = nil, "muted", nil
	if not plr then
		return vmsg("c_r[ADMIN]c_w: Invalid player", player)
	end
	state = not isPlayerMuted(plr)
	if not duration then
		if state then
			return vmsg("c_r[ADMIN]c_w: Invalid duration - 0 for Permanent, 3d = 3 days", player)
		else
			duration = 0
		end
	end
	if tonumber(duration) ~= 0 then
		local n = duration:sub(1, duration:len()-1)
		local f = duration:sub(duration:len())
		seconds = getDuration(n, f)
		if not seconds then
			return vmsg("c_r[ADMIN]c_w: Invalid duration", player)
		end
		duration = "("..secondsToTimeDesc(seconds)..")"
	else
		duration = "(permanent)"
	end
	--
	reason = table.concat(arg, " ")
	reason = reason ~= "" and "("..reason..")" or ""
	--
	if not state then
		action = "un"..action
		duration = ""
		reason = ""
	end
	--
	local plr_serial = getPlayerSerial(plr)
	vmsg("c_r[ADMIN]c_w: "..getPlayerName(player).."c_w "..action.." "..getPlayerName(plr).."c_w! "..duration.." "..reason)
	exports.admin:aSetPlayerMuted(plr, state, seconds or 0)
end)

CMD("ban", function(player, command, plr, duration, ...)
	local player_level = getElementData(player, "admin_level") or 1
	if player_level < COMMAND_PERMISSION[command] then
		outputChatBox("Access denied.", player, 255, 255, 255, true)
		return
	end
	if not plr then
		return vmsg("c_r[ADMIN]c_w: Syntax: /ban [ID/Player] [Duration] [Optional: Reason]", player) 
	end
	plr = getPlayer(plr)
	local seconds
	if not plr then
		return vmsg("c_r[ADMIN]c_w: Invalid player", player)
	end
	if not duration then
		return vmsg("c_r[ADMIN]c_w: Invalid duration - 0 for Permanent, 3d = 3 days", player)
	end
	if tonumber(duration) ~= 0 then
		local n = duration:sub(1, duration:len()-1)
		local f = duration:sub(duration:len())
		seconds = getDuration(n, f)
		if not seconds then
			return vmsg("c_r[ADMIN]c_w: Invalid duration", player)
		end
		duration = "("..secondsToTimeDesc(seconds)..")"
	else
		duration = "(permanent)"
	end
	--
	reason = table.concat(arg, " ")
	reason = reason ~= "" and "("..reason..")" or ""
	--
	local plr_serial = getPlayerSerial(plr)
	vmsg("c_r[ADMIN]c_w: "..getPlayerName(player).."c_w banned "..getPlayerName(plr).."c_w! "..duration.." "..reason)
	vmsg("* Banned Serial: "..plr_serial, player)
	addBan(nil, nil, plr_serial, player, reason, seconds)
end)

CMD("banip", function(player, command, plr, duration, ...)
	local player_level = getElementData(player, "admin_level") or 1
	if player_level < COMMAND_PERMISSION[command] then
		outputChatBox("Access denied.", player, 255, 255, 255, true)
		return
	end
	if not plr then
		return vmsg("c_r[ADMIN]c_w: Syntax: /banip [ID/Player] [Duration] [Optional: Reason]", player) 
	end
	plr = getPlayer(plr)
	local seconds
	if not plr then
		return vmsg("c_r[ADMIN]c_w: Invalid player", player)
	end
	if not duration then
		return vmsg("c_r[ADMIN]c_w: Invalid duration - 0 for Permanent, 3d = 3 days", player)
	end
	if tonumber(duration) ~= 0 then
		local n = duration:sub(1, duration:len()-1)
		local f = duration:sub(duration:len())
		seconds = getDuration(n, f)
		if not seconds then
			return vmsg("c_r[ADMIN]c_w: Invalid duration", player)
		end
		duration = "("..secondsToTimeDesc(seconds)..")"
	else
		duration = "(permanent)"
	end
	--
	reason = table.concat(arg, " ")
	reason = reason ~= "" and "("..reason..")" or ""
	--
	local plr_ip = getPlayerIP(plr)
	vmsg("c_r[ADMIN]c_w: "..getPlayerName(player).."c_w banned "..getPlayerName(plr).."c_w! "..duration.." "..reason)
	vmsg("* Banned IP: "..plr_ip, player)
	addBan(plr_ip, nil, nil, player, reason, seconds)
end)

CMD("eban", function(player, command, plr, duration, ...)
	local player_level = getElementData(player, "admin_level") or 1
	if player_level < COMMAND_PERMISSION[command] then
		outputChatBox("Access denied.", player, 255, 255, 255, true)
		return
	end
	if not plr then
		return vmsg("c_r[ADMIN]c_w: Syntax: /eban [ID/Player] [Duration] [Optional: Reason]", player) 
	end
	plr = getPlayer(plr)
	local seconds
	if not plr then
		return vmsg("c_r[ADMIN]c_w: Invalid player", player)
	end
	if not duration then
		return vmsg("c_r[ADMIN]c_w: Invalid duration - 0 for Permanent, 3d = 3 days", player)
	end
	if tonumber(duration) ~= 0 then
		local n = duration:sub(1, duration:len()-1)
		local f = duration:sub(duration:len())
		seconds = getDuration(n, f)
		if not seconds then
			return vmsg("c_r[ADMIN]c_w: Invalid duration", player)
		end
		duration = "("..secondsToTimeDesc(seconds)..")"
	else
		duration = "(permanent)"
	end
	--
	reason = table.concat(arg, " ")
	reason = reason ~= "" and "("..reason..")" or ""
	--
	local plr_serial = getPlayerSerial(plr)
	local plr_ip = getPlayerIP(plr)
	vmsg("c_r[ADMIN]c_w: "..getPlayerName(player).."c_w banned "..getPlayerName(plr).."c_w! "..duration.." "..reason)
	vmsg("* Banned IP: "..plr_ip.." and Serial: "..plr_serial, player)
	addBan(plr_ip, nil, plr_serial, player, reason, seconds)
end)