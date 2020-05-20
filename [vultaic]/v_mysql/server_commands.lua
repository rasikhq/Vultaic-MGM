-- Admin command(s)

local function getPlayerFromPartialName(name)
    local name = name and name:gsub("#%x%x%x%x%x%x", ""):lower() or nil
    if name then
        for _, player in ipairs(getElementsByType("player")) do
            local name_ = getPlayerName(player):gsub("#%x%x%x%x%x%x", ""):lower()
            if name_:find(name, 1, true) then
                return player
            end
        end
    end
end

function cmd_set(player, cmd, ...)
	if not hasObjectPermissionTo(player, "command.stopall" ) then
		return
	end
	local args = {...}
	local plr = getPlayerFromPartialName(args[1])
	if not plr then
		return outputChatBox("Invalid player", player)
	end
	local key = args[2]
	local val = args[3]
	if not key or not val then
		return
	end
	val = (type(tonumber(val)) == "number" and tonumber(val) or tostring(val))
	setPlayerStats(plr, key, val)
	outputChatBox("-> Done", player)
end
addCommandHandler("set", cmd_set)

function cmd_set(player, cmd, ...)
	if not hasObjectPermissionTo(player, "command.stopall" ) then
		return
	end
	local args = {...}
	local plr = getPlayerFromPartialName(args[1])
	if not plr then
		return outputChatBox("Invalid player", player)
	end
	local key = args[2]
	local val = args[3]
	if not key or not val then
		return
	end
	val = (type(tonumber(val)) == "number" and tonumber(val) or tostring(val))
	setPlayerTuningStats(plr, key, val)
	outputChatBox("-> Done", player)
end
addCommandHandler("tset", cmd_set)

function cmd_setbool(player, cmd, ...)
	if not hasObjectPermissionTo(player, "command.stopall" ) then
		return
	end
	local args = {...}
	local plr = getPlayerFromPartialName(args[1])
	if not plr then
		return outputChatBox("Invalid player", player)
	end
	local key = args[2]
	local val = args[3]
	if not key or not val then
		return
	end
	val = val == "false" and false or val == "true" and true or val == "nil" and nil or false
	setPlayerStats(player, key, val)
	outputChatBox("-> Done", player)
end
addCommandHandler("setb", cmd_setbool)

function cmd_get(player, cmd, ...)
	if not hasObjectPermissionTo(player, "command.stopall" ) then
		return
	end
	local args = {...}
	local plr = getPlayerFromPartialName(args[1])
	if not plr then
		return outputChatBox("Invalid player", player)
	end
	local key = args[2]
	if not key then
		return
	end
	local val = getPlayerStats(plr, key)
	outputChatBox("-> Done: "..tostring(val).." "..type(val), player)
end
addCommandHandler("get", cmd_get)

function cmd_getelement(player, cmd, ...)
	if not hasObjectPermissionTo(player, "command.stopall" ) then
		return
	end
	local args = {...}
	local plr = getPlayerFromPartialName(args[1])
	if not plr then
		return outputChatBox("Invalid player", player)
	end
	local key = args[2]
	if not key then
		return
	end
	local val = getElementData(plr, key)
	outputChatBox("-> Done: "..tostring(val).." "..type(val), player)
end
addCommandHandler("gete", cmd_getelement)

function cmd_tuning_get(player, cmd, ...)
	local args = {...}
	local key = args[1]
	if not key then
		return
	end
	local val = getPlayerTuningStats(player, key)
	outputChatBox("-> Done: "..tostring(val).." "..type(val), player)
end
addCommandHandler("tget", cmd_tuning_get)

function cmd_vlogin(player, cmd, ...)
	local args = {...}
	local username = args[1]
	local password = args[2]
	if not username or not password then
		return false
	end
	triggerEvent("login:onPlayerRequestLogin", player, username, password)
end
addCommandHandler("vlogin", cmd_vlogin)

function cmd_reloadawards(player, cmd)
	if not hasObjectPermissionTo(player, "command.execute" ) then
		return
	end
	reloadAwards()
end
addCommandHandler("reloadawards", cmd_reloadawards)

function cmd_award(player, cmd, plr, awardName)
	if not hasObjectPermissionTo(player, "command.execute" ) then
		return
	end
	plr = getPlayerFromPartialName(plr) or false
	if not plr or not isElement(plr) then
		return
	end
	givePlayerAward(plr, awardName)
end
addCommandHandler("giveaward", cmd_award)

function cmd_myawards(player, cmd, ...)
	local player_awards = getPlayerStats(player, "awards")
	local award_count = 0
	if type(player_awards) == "table" then
		for awardName, awardInfo in pairs(player_awards) do
			award_count = award_count + 1
			outputChatBox("#19846d"..awardInfo.name.." #ffffff- "..awardInfo.description, player, 255, 255, 255, true)
		end
	end
	outputChatBox("#ffffffTotal awards earned: #19846d"..award_count, player, 255, 255, 255, true)
end
addCommandHandler("myawards", cmd_myawards)