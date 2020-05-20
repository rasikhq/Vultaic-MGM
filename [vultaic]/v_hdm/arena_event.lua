local _setElementData = setElementData
local function setElementData(element, index, value, ...)
	return _setElementData(element, index, value, false)
end
local getRealTime = getRealTime
local EVENT = {
	info = "#19846DEVENT :: #FFFFFFLast Survivor event is starting in Deathmatch: Hard!",
	time = nil, --{hour to start in, minutes of the hour under which it can trigger},
	cooldown = nil,
	state = "waiting",
	current_round = 0,
	max_rounds = 15,
	data = {},
	leaderboard = {},
	leaderboard_sorted = {},
	points = {
		[1] = 3,
		[2] = 2,
		[3] = 1,
	}
}
local suffix = {
	[1] = "st",
	[2] = "nd",
	[3] = "rd"
}

addEventHandler("onResourceStart", resourceRoot, function()
	setElementData(arena.element, "disable_shop", false)
	addEventHandler("onArenaMapStarting", arena.element, onArenaMapStart_Event)
end)

local function getEventLeaderboard(range)
	range = range or 3
	EVENT.leaderboard_sorted = {}
	for playerSerial, points in pairs(EVENT.leaderboard) do
		local player = getPlayerFromSerial(playerSerial)
		if isElement(player) and points > 0 then
			tableInsert(EVENT.leaderboard_sorted, {getPlayerName(player), points, player})
		end
	end
	table.sort(EVENT.leaderboard_sorted, function(a, b) return a[2] > b[2] end)
	return EVENT.leaderboard_sorted
end

function onArenaMapStart_Event(mapInfo)
	if not EVENT.time then
		return
	end
	if EVENT.state == "waiting" or EVENT.state == "finished" then
		local currentTime = {getRealTime().hour, getRealTime().minute}
		if currentTime[1] == EVENT.cooldown then
			return
		else
			EVENT.cooldown = nil
		end
		local eventTime = EVENT.time or {currentTime[1], currentTime[2]}
		if currentTime[1] == eventTime[1] and currentTime[2] <= EVENT.time[2] and EVENT.current_round == 0 then
			outputChatBox(EVENT.info, root, 255, 255, 255, true)
			EVENT.state = "starting"
			setElementData(arena.element, "disable_shop", true)
		end
	elseif EVENT.state == "starting" then
		outputArenaMessage("Last Survivor event is now #00FF00live#ffffff!")
		EVENT.state = "running"
		EVENT.current_round = 1
		EVENT.cooldown = EVENT.time[1]
	elseif EVENT.state == "running" then
		EVENT.current_round = EVENT.current_round + 1
		--
		EVENT.data = {}
		local leaderboard = getEventLeaderboard()
		local event_info = ""
		for i = 1, 3 do
			if leaderboard[i] then
				local info = leaderboard[i][1].."#ffffff ["..leaderboard[i][2].."]"
				event_info = event_info == "" and info or event_info..", "..info
			else
				local info = "None [n/a]"
				event_info = event_info == "" and info or event_info..", "..info
			end
		end
		if #leaderboard > 0 then
			outputArenaMessage("Event Leaderboard: "..event_info)
		end
		--
		if EVENT.current_round > EVENT.max_rounds then
			finishEvent((#leaderboard > 0 and leaderboard or nil))
			if #leaderboard > 0 then
				outputArenaMessage("Event Winners: "..event_info)
			else
				outputArenaMessage("Event Winners: None!")
			end
			return true
		end
	end
	--
	if EVENT.state ~= "waiting" and EVENT.state ~= "finished" then
		triggerClientEvent(arena.element, "event:onReceiveSettings", resourceRoot, {
			state = EVENT.state,
			current_round = EVENT.current_round,
			max_rounds = EVENT.max_rounds,
			players = EVENT.leaderboard_sorted
		})
	end
	--
end

function finishEvent(leaderboard)
	EVENT.state = "finished"
	EVENT.current_round = 0
	--
	local rewards = {
		[1] = 25000,
		[2] = 15000,
		[3] = 10000
	}
	if leaderboard then
		for i = 1, 3 do
			local data = leaderboard[i]
			if data and isElement(data[3]) then
				outputChatBox("#19846d[Event] #ffffffFinished #19846d"..i..(suffix[i]).."#ffffff. Reward: #19846d$"..rewards[i], data[3], 255, 255, 255, true)
				exports.v_mysql:givePlayerStats(data[3], "money", rewards[i])
			end
		end
	end
	--
	EVENT.leaderboard = {}
	EVENT.leaderboard_sorted = {}
	--
	triggerClientEvent(arena.element, "event:onReceiveSettings", resourceRoot, false)
	setElementData(arena.element, "disable_shop", false)
end

addEvent("arena:onPlayerFinish")
addEventHandler("arena:onPlayerFinish", resourceRoot, function(player, place)
	iprint(player, place)
	if EVENT.state == "running" then
		local position = place
		local points = EVENT.points[position] or 0
		if EVENT.leaderboard[getPlayerSerial(player)] == nil then
			EVENT.leaderboard[getPlayerSerial(player)] = 0
		end
		EVENT.leaderboard[getPlayerSerial(player)] = EVENT.leaderboard[getPlayerSerial(player)] + points
		outputChatBox("#19846DEVENT :: #FFFFFFFinished at position: #19846D"..position.."#FFFFFF! +"..points, player, 255, 255, 255, true)
		if position <= 3 then
			outputArenaMessage("[Event] "..getPlayerName(player).."#ffffff finished #19846d"..position..(suffix[position]).." this round!")
		end
	end
end)

--

function getPlayerFromSerial ( serial, startAt )
    assert ( type ( serial ) == "string" and #serial == 32, "getPlayerFromSerial - invalid serial" )
	startAt = isElement(startAt) and startAt or arena.element
    for index, player in ipairs ( getElementsByType ( "player", startAt ) ) do
        if ( getPlayerSerial ( player ) == serial ) then
            return player
        end
    end
    return false
end

local COMMAND_PERMISSION = exports.v_admin:getCommandLevels()

addCommandHandler("event", function(player, cmd, ...)
	if getElementParent(player) ~= arena.element then
		return
	end
	local player_level = getElementData(player, "admin_level") or 1
	if player_level < COMMAND_PERMISSION[cmd] then
		outputChatBox("Access denied.", player, 255, 255, 255, true)
		return
	end
	local currentTime = {getRealTime().hour, getRealTime().minute}
	--
	if tonumber(arg[1]) and tonumber(arg[2]) then
		EVENT.time = {tonumber(arg[1]), tonumber(arg[2])}
	elseif tostring(arg[1]) == "off" then
		EVENT.time = nil
		return outputChatBox("#ffffff* Event: #19846dDisabled", player, 255, 255, 255, true)
	else
		EVENT.time = {currentTime[1], 59}
	end
	EVENT.cooldown = nil
	outputChatBox("#ffffff* Event time set to: #19846d"..EVENT.time[1].."#ffffff:#19846d"..EVENT.time[2], player, 255, 255, 255, true)
end)

addCommandHandler("resetevent", function(player, cmd, ...)
	if getElementParent(player) ~= arena.element then
		return
	end
	local player_level = getElementData(player, "admin_level") or 1
	if player_level < COMMAND_PERMISSION[cmd] then
		outputChatBox("Access denied.", player, 255, 255, 255, true)
		return
	end
	if EVENT.state == "starting" or EVENT.state == "running" then
		outputArenaMessage("#ffffff* Event cancelled by admin "..getPlayerName(player))
	end
	finishEvent()
	outputChatBox("* Event reset/cancelled.", player, 255, 255, 255)
end)

addCommandHandler("setround", function(player, cmd, round)
	if getElementParent(player) ~= arena.element then
		return
	end
	local player_level = getElementData(player, "admin_level") or 1
	if player_level < COMMAND_PERMISSION[cmd] then
		outputChatBox("Access denied.", player, 255, 255, 255, true)
		return
	end
	round = tonumber(round)
	if not round then
		return
	end
	if EVENT.state ~= "starting" and EVENT.state ~= "running" then
		return
	end
	EVENT.current_round = math.max(math.min(EVENT.max_rounds-1, round), 1)
	outputChatBox("* Event round set to "..round.." [Updates next map]", player, 255, 255, 255)
end)

addCommandHandler("setmaxrounds", function(player, cmd, round)
	if getElementParent(player) ~= arena.element then
		return
	end
	local player_level = getElementData(player, "admin_level") or 1
	if player_level < COMMAND_PERMISSION[cmd] then
		outputChatBox("Access denied.", player, 255, 255, 255, true)
		return
	end
	round = tonumber(round)
	if not round or round < 10 then
		return
	end
	if EVENT.state ~= "starting" and EVENT.state ~= "running" then
		return
	end
	EVENT.max_rounds = round
	outputChatBox("* Event round set to "..round.." [Updates next map]", player, 255, 255, 255)
end)

addCommandHandler("mapshop", function(player, cmd, round)
	if getElementParent(player) ~= arena.element then
		return
	end
	local player_level = getElementData(player, "admin_level") or 1
	if player_level < COMMAND_PERMISSION[cmd] then
		outputChatBox("Access denied.", player, 255, 255, 255, true)
		return
	end
	local new_state = getElementData(arena.element, "disable_shop") == false
	setElementData(arena.element, "disable_shop", new_state)
	outputArenaMessage("Map shop has been "..(new_state and "#ff0000disabled" or "#00ff00enabled").."#ffffff by admin "..getPlayerName(player))
end)