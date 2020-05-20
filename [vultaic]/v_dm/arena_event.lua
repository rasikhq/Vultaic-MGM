local _setElementData = setElementData
local function setElementData(element, index, value, ...)
	return _setElementData(element, index, value, false)
end
local getRealTime = getRealTime
local EVENT = {
	info = "#19846DEVENT :: #FFFFFF[WFF] Who Finishes First event is starting in Deathmatch: Regular!",
	time = nil, --{hour to start in, minutes of the hour under which it can trigger}
	state = "waiting",
	current_round = 0,
	max_rounds = 20,
	data = {},
	leaderboard = {},
	leaderboard_sorted = {},
	points = {
		[1] = 3,
		[2] = 2,
		[3] = 1,
		[4] = 1
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
	for player, points in pairs(EVENT.leaderboard) do
		if isElement(player) and points > 0 then
			tableInsert(EVENT.leaderboard_sorted, {player, points})
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
		local eventTime = EVENT.time or {currentTime[1], currentTime[2]}
		if currentTime[1] == eventTime[1] and currentTime[2] <= EVENT.time[2] and EVENT.current_round == 0 then
			outputChatBox(EVENT.info, root, 255, 255, 255, true)
			EVENT.state = "starting"
			setElementData(arena.element, "disable_shop", true)
		end
	elseif EVENT.state == "starting" then
		outputArenaMessage("[WFF] Who Finishes First event is now #00FF00live#ffffff!")
		EVENT.state = "running"
		EVENT.current_round = 1
	elseif EVENT.state == "running" then
		EVENT.current_round = EVENT.current_round + 1
		--
		EVENT.data = {}
		local leaderboard = getEventLeaderboard()
		local event_info = ""
		for i = 1, 3 do
			if leaderboard[i] then
				local info = getPlayerName(leaderboard[i][1]).."#ffffff ["..leaderboard[i][2].."]"
				event_info = event_info == "" and info or event_info..", "..info
			else
				local info = "None [n/a]"
				event_info = event_info == "" and info or event_info..", "..info
			end
		end
		--[[if #leaderboard > 0 then
			outputArenaMessage("[WFF] Leaderboard: "..event_info)
		end]]
		--
		if EVENT.current_round > EVENT.max_rounds then
			finishEvent((#leaderboard > 0 and leaderboard or nil))
			if #leaderboard > 0 then
				outputArenaMessage("[WFF] Winners: "..event_info)
			else
				outputArenaMessage("[WFF] Winners: None!")
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
			if data and isElement(data[1]) then
				outputChatBox("#19846d[Event] #ffffff[WFF] Finished #19846d"..i..(suffix[i]).."#ffffff. Reward: #19846d$"..rewards[i], data[1], 255, 255, 255, true)
				exports.v_mysql:givePlayerStats(data[1], "money", rewards[i])
			end
		end
	end
	triggerClientEvent(arena.element, "event:onReceiveSettings", resourceRoot, false)
	setElementData(arena.element, "disable_shop", false)
end

addEventHandler("arena:onPlayerHunter", resourceRoot, function(pickupType, pickupVehicle)
	if EVENT.state == "running" and not tableFind(EVENT.data, client) and getElementData(client, "state") == "alive" then
		tableInsert(EVENT.data, client)
		local position = #EVENT.data
		local points = EVENT.points[position] or 0
		if EVENT.leaderboard[client] == nil then
			EVENT.leaderboard[client] = 0
		end
		EVENT.leaderboard[client] = EVENT.leaderboard[client] + points
		killPed(client)
		outputChatBox("#19846DEVENT :: #FFFFFFFinished at position: #19846D"..position.."#FFFFFF! +"..points, client, 255, 255, 255, true)
		if position <= 3 then
			outputArenaMessage("[WFF] "..getPlayerName(client).."#ffffff finished #19846d"..position..(suffix[position]).." this round!")
		end
	end
end)

--

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
		EVENT.time = {currentTime[1], currentTime[2]}
	end
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