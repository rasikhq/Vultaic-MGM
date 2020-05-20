local toptimes = {loaded = {}}
--
local COMMAND_PERMISSION = exports.v_admin:getCommandLevels()
COMMAND_PERMISSION["renametop"] = 3
COMMAND_PERMISSION["deletetop"] = 4
COMMAND_PERMISSION["deletealltops"] = 4
COMMAND_PERMISSION["droptops"] = 5
--
addEventHandler("onResourceStart", resourceRoot,
function()
	toptimes.connection = dbConnect("mysql", "dbname=mta_toptimes;host=127.0.0.1;port=3306", "root", "M1RAg3_Zz@ST3R")
	if not toptimes.connection then
		outputDebugString("Failed to connect", 0, 255, 0, 0)
	end
end)

addEventHandler("onResourceStop", resourceRoot,
function()
	if toptimes.connection then
		destroyElement(toptimes.connection)
	end
end)

function toptimes.loadToptimesForMap(arenaName, mapName, mapNameReal, forceReload)
	if not toptimes.connection then
		return
	end
	if type(arenaName) == "string" and type(mapName) == "string" then
		local arena = getElementByID(arenaName)
		if not isElement(arena) then
			return
		end
		-- Send 'mapNameReal' manually if arena has multiple maps running
		local mapNameReal = mapNameReal and mapNameReal or getElementData(arena, "map")
		local mapNameHash = md5(arenaName..mapName)
		if toptimes.loaded[mapNameHash] and not forceReload then
			return
		end
		dbExec(toptimes.connection, "CREATE TABLE IF NOT EXISTS `?` (`id` VARCHAR(33), `username` VARCHAR(30), `nickname` VARCHAR(30), `serial` VARCHAR(33), `time` INT, `dateRecorded` VARCHAR(50), `country` VARCHAR(30))", tostring(mapNameHash))
		dbQuery(toptimes.loadQuery, {arenaName, mapName, mapNameReal, mapNameHash, getTickCount()}, toptimes.connection, "SELECT * FROM `?`", tostring(mapNameHash))
	end
end
addEvent("toptimes:loadToptimesForMap", true)
addEventHandler("toptimes:loadToptimesForMap", root, toptimes.loadToptimesForMap)

function toptimes.loadQuery(query, arenaName, mapName, mapNameReal, mapNameHash, startTick)
	local result = dbPoll(query, 0)
	if not result then
		local errorCode, errorMessage = num_affected_rows, last_insert_id
		outputDebugString("dbPoll failed. Error code: "..tostring(errorCode)..", error message: "..tostring(errorMessage), 0, 255, 0, 0)
		return
	end
	toptimes.loaded[mapNameHash] = {}
	toptimes.loaded[mapNameHash].arenaName = arenaName
	toptimes.loaded[mapNameHash].mapName = mapName
	toptimes.loaded[mapNameHash].mapNameReal = mapNameReal
	toptimes.loaded[mapNameHash].mapNameHash = mapNameHash
	toptimes.loaded[mapNameHash].toptimes = {}
	for i, row in pairs(result) do
		table.insert(toptimes.loaded[mapNameHash].toptimes, {
			id = row["id"],
			username = row["username"],
			nickname = row["nickname"],
			serial = row["serial"],
			time = row["time"],
			dateRecorded = row["dateRecorded"],
			country = row["country"]
		})
	end
	table.sort(toptimes.loaded[mapNameHash].toptimes,
	function(a, b)
		return tonumber(a.time) < tonumber(b.time)
	end)
	outputDebugString("Loaded toptimes for "..mapName.." in "..(getTickCount() - startTick).." ms [Arena: "..arenaName.."]", 0)
end

function toptimes.unloadToptimesForMap(arenaName, mapName)
	if type(arenaName) == "string" and type(mapName) == "string" then
		local mapNameHash = md5(arenaName..mapName)
		if toptimes.loaded[mapNameHash] then
			toptimes.loaded[mapNameHash] = nil
		end
	end
end
addEvent("toptimes:unloadToptimesForMap", true)
addEventHandler("toptimes:unloadToptimesForMap", root, toptimes.unloadToptimesForMap)

function toptimes.findPlayerToptime(mapNameHash, player)
	if type(mapNameHash) == "string" and toptimes.loaded[mapNameHash] and player then
		local serial = getPlayerSerial(player)
		local id = getElementData(player, "LoggedIn") and getElementData(player, "account_id") or serial
		if #toptimes.loaded[mapNameHash].toptimes > 0 then
			for i, toptime in pairs(toptimes.loaded[mapNameHash].toptimes) do
				if toptime.id == id or toptime.serial == serial then
					return toptime, i
				end
			end
		end
		return nil
	end
	return nil
end

function toptimes.addToptime(arenaName, mapName, player, time, settings)
	if not toptimes.connection then
		return
	end
	if type(arenaName) == "string" and type(mapName) == "string" and player and type(time) == "number" then
		local mapNameHash = md5(arenaName..mapName)
		if not toptimes.loaded[mapNameHash] then
			return
		end
		local oldToptime, oldPosition = toptimes.findPlayerToptime(mapNameHash, player)
		if oldToptime then -- Player has an old toptime, check it
			if oldToptime.time <= time then -- Old time is better
				return
			end
			local serial = getPlayerSerial(player)
			local logged = getElementData(player, "LoggedIn")
			local id = oldToptime.id or (logged and getElementData(player, "account_id") or serial)
			local username = oldToptime.username or (logged and getElementData(player, "username") or "")
			local nickname = getPlayerName(player)
			local dateTime = getDateTime()
			local country = getElementData(player, "countryCode")
			dbExec(toptimes.connection, "UPDATE `?` SET `username` = ?, `nickname` = ?, `time` = ?, `dateRecorded` = ?, `country` = ? WHERE `serial` = ? OR `id` = ?", tostring(mapNameHash), username, nickname, time, dateTime, country, serial, id)
			oldToptime.id = id
			oldToptime.username = username
			oldToptime.nickname = nickname
			oldToptime.serial = serial
			oldToptime.time = time
			oldToptime.dateRecorded = dateTime
			oldToptime.country = country
			table.sort(toptimes.loaded[mapNameHash].toptimes,
			function(a, b)
				return tonumber(a.time) < tonumber(b.time)
			end)
			local toptime, position = toptimes.findPlayerToptime(mapNameHash, player)
			if toptime then
				outputChatBox("#19846D[Toptimes] #FFFFFFYou have made a new toptime with the time #19846D"..msToTimeString(toptime.time).." #FFFFFFand position #19846D"..position, player, 255, 255, 255, true)
			end
			local arena = getElementParent(player)
			local players = getPlayersToSync(arena, player)
			for i, _player in pairs(players) do
				triggerClientEvent(_player, "toptimes:onClientReceiveToptimes", resourceRoot, toptimes.loaded[mapNameHash])
			end
			if position <= 8 and position <= oldPosition then
				-- Increase number of toptimes taken in statistics
				exports.v_mysql:givePlayerStats(player, "toptimes", 1, true)
			end
		else -- Player has just made a new toptime
			local serial = getPlayerSerial(player)
			local logged = getElementData(player, "LoggedIn")
			local id = logged and getElementData(player, "account_id") or serial
			local username = logged and getElementData(player, "username") or ""
			local nickname = getPlayerName(player)
			local dateTime = getDateTime()
			local country = getElementData(player, "countryCode")
			dbExec(toptimes.connection, "INSERT INTO `?` VALUES (?, ?, ?, ?, ?, ?, ?)", tostring(mapNameHash), id, username, nickname, serial, time, dateTime, country)
			table.insert(toptimes.loaded[mapNameHash].toptimes, {
				id = id,
				username = username,
				nickname = nickname,
				serial = serial,
				time = time,
				dateRecorded = dateTime,
				country = country
			})
			table.sort(toptimes.loaded[mapNameHash].toptimes,
			function(a, b)
				return tonumber(a.time) < tonumber(b.time)
			end)
			local toptime, position = toptimes.findPlayerToptime(mapNameHash, player)
			if toptime then
				outputChatBox("#19846D[Toptimes] #FFFFFFYou have made a new toptime with the time #19846D"..msToTimeString(toptime.time).." #FFFFFFand position #19846D"..position, player, 255, 255, 255, true)
			end
			local arena = getElementParent(player)
			local players = getPlayersToSync(arena, player)
			for i, _player in pairs(players) do
				triggerClientEvent(_player, "toptimes:onClientReceiveToptimes", resourceRoot, toptimes.loaded[mapNameHash])
			end
			if position <= 8 then
				-- Increase number of toptimes taken in statistics
				exports.v_mysql:givePlayerStats(player, "toptimes", 1, true)
			end
		end
	end
end

function toptimes.sendToptimesToPlayer()
	local mapNameHash = getPlayerMapResourceName(source)
	if not mapNameHash then
		return
	end
	if toptimes.loaded[mapNameHash] then
		triggerClientEvent(source, "toptimes:onClientReceiveToptimes", resourceRoot, toptimes.loaded[mapNameHash], true)
	end
end
addEvent("toptimes:onPlayerRequestToptimes", true)
addEventHandler("toptimes:onPlayerRequestToptimes", root, toptimes.sendToptimesToPlayer)

local hunterStatsEnabled = {
	["race"] = false,
	["dm training"] = false,
	["race training"] = false,
}
addEvent("toptimes:onPlayerRequestAddToptime", true)
addEventHandler("toptimes:onPlayerRequestAddToptime", root,
function(time, resourceName, ...)
	if type(time) ~= "number" then
		return
	end
	local arena = getElementParent(source)
	if not isElement(arena) then
		return
	end
	local arenaName = getElementData(arena, "id")
	local resourceName = resourceName and resourceName or getElementData(arena, "mapResourceName")
	if not arenaName or not resourceName then
		return
	end
	toptimes.addToptime(arenaName, resourceName, source, time, ...)
	if hunterStatsEnabled[arenaName] ~= false then
		exports.v_mysql:givePlayerStats(source, "hunters", 1, true)
	end
end)

addCommandHandler("renametop",
function(player, command, row, nickname, ...)
	local player_level = getElementData(player, "admin_level") or 1
	if player_level < COMMAND_PERMISSION[command] then
		outputChatBox("Access denied.", player, 255, 255, 255, true)
		return
	end
	local arena = getElementParent(player)
	if not isElement(arena) then
		return
	end
	local arenaName = getElementData(arena, "id")
	local resourceName = getElementData(player, "training.map") or getElementData(arena, "mapResourceName")
	local mapNameHash = md5(arenaName..resourceName)
	if not toptimes.loaded[mapNameHash] then
		return
	end
	row = tonumber(row) or nil
	if not row then
		return outputChatBox("Please specify a row.", player, 255, 0, 0, true)
	end
	local args = {...}
	local id = tonumber(nickname) or nil
	if args[1] and args[1] == "fromid" and id then
		local player = exports.core:getPlayerFromID(id)
		if player then
			nickname = getPlayerName(player)
		end
	end
	if not nickname then
		return outputChatBox("Please specify a nickname.", player, 255, 0, 0, true)
	end
	if #nickname == 0 then
		return outputChatBox("Nickname can't be empty.", player, 255, 0, 0, true)
	elseif #nickname:gsub("#%x%x%x%x%x%x", "") > 22 then
		return outputChatBox("Nickname can't be more than 22 characters long.", player, 255, 0, 0, true)
	end
	local toptime = toptimes.loaded[mapNameHash].toptimes[row]
	if not toptime then
		return outputChatBox("Couldn't find any toptime at this row.", player, 255, 0, 0, true)
	end
	local oldNickname = toptime.nickname
	local serial = toptime.serial
	local dateTime = toptime.dateRecorded
	local country = toptime.country
	dbExec(toptimes.connection, "UPDATE `?` SET `nickname` = ? WHERE `serial` = ?", tostring(mapNameHash), nickname, serial)
	toptime.nickname = nickname
	local players = getPlayersToSync(arena, player)
	for i, _player in pairs(players) do
		triggerClientEvent(_player, "toptimes:onClientReceiveToptimes", resourceRoot, toptimes.loaded[mapNameHash])
		outputChatBox("#19846D[Toptimes] #FFFFFF"..getPlayerName(player).." #FFFFFFhas renamed toptime #19846D"..row.." #FFFFFFfrom "..oldNickname.." #FFFFFFto "..nickname, _player, 255, 255, 255, true)
	end
end)

addCommandHandler("deletetop",
function(player, command, row)
	local player_level = getElementData(player, "admin_level") or 1
	if player_level < COMMAND_PERMISSION[command] then
		outputChatBox("Access denied.", player, 255, 255, 255, true)
		return
	end
	local arena = getElementParent(player)
	if not isElement(arena) then
		return
	end
	local arenaName = getElementData(arena, "id")
	local resourceName = getElementData(player, "training.map") or getElementData(arena, "mapResourceName")
	local mapNameHash = md5(arenaName..resourceName)
	if not toptimes.loaded[mapNameHash] then
		return
	end
	row = tonumber(row) or nil
	if not row then
		return outputChatBox("Please specify a row.", player, 255, 0, 0, true)
	end
	local toptime = toptimes.loaded[mapNameHash].toptimes[row]
	if not toptime then
		return outputChatBox("Couldn't find any toptime at this row.", player, 255, 0, 0, true)
	end
	dbExec(toptimes.connection, "DELETE FROM `?` WHERE `serial` = ?", tostring(mapNameHash), toptime.serial)
	table.remove(toptimes.loaded[mapNameHash].toptimes, row)
	local players = getPlayersToSync(arena, player)
	for i, _player in pairs(players) do
		triggerClientEvent(_player, "toptimes:onClientReceiveToptimes", resourceRoot, toptimes.loaded[mapNameHash])
		outputChatBox("#19846D[Toptimes] #FFFFFF"..getPlayerName(player).." #FFFFFFhas deleted toptime #19846D"..row.." #FFFFFFfrom "..toptime.nickname, _player, 255, 255, 255, true)
	end
end)

addCommandHandler("deletealltops",
function(player, command)
	local player_level = getElementData(player, "admin_level") or 1
	if player_level < COMMAND_PERMISSION[command] then
		outputChatBox("Access denied.", player, 255, 255, 255, true)
		return
	end
	local arena = getElementParent(player)
	if not isElement(arena) then
		return
	end
	local arenaName = getElementData(arena, "id")
	local resourceName = getElementData(player, "training.map") or getElementData(arena, "mapResourceName")
	local mapNameHash = md5(arenaName..resourceName)
	if not toptimes.loaded[mapNameHash] then
		return
	end
	dbExec(toptimes.connection, "DELETE FROM `?`", tostring(mapNameHash))
	toptimes.loaded[mapNameHash].toptimes = {}
	local players = getPlayersToSync(arena, player)
	for i, _player in pairs(players) do
		triggerClientEvent(_player, "toptimes:onClientReceiveToptimes", resourceRoot, toptimes.loaded[mapNameHash])
		outputChatBox("#19846D[Toptimes] #FFFFFF"..getPlayerName(player).." #FFFFFFhas deleted all toptimes from this map.", _player, 255, 255, 255, true)
	end
end)

addCommandHandler("droptops",
function(player, command)
	local player_level = getElementData(player, "admin_level") or 1
	if player_level < COMMAND_PERMISSION[command] then
		outputChatBox("Access denied.", player, 255, 255, 255, true)
		return
	end
	local arena = getElementParent(player)
	if not isElement(arena) then
		return
	end
	local arenaName = getElementData(arena, "id")
	local resourceName = getElementData(player, "training.map") or getElementData(arena, "mapResourceName")
	local mapNameHash = md5(arenaName..resourceName)
	if not toptimes.loaded[mapNameHash] then
		return
	end
	dbExec(toptimes.connection, "DROP TABLE `?`", tostring(mapNameHash))
	toptimes.loadToptimesForMap(arenaName, resourceName, toptimes.loaded[mapNameHash].mapNameReal, true)
	toptimes.loaded[mapNameHash].toptimes = {}
	local players = getPlayersToSync(arena, player)
	for i, _player in pairs(players) do
		triggerClientEvent(_player, "toptimes:onClientReceiveToptimes", resourceRoot, toptimes.loaded[mapNameHash])
		outputChatBox("#19846D[Toptimes] #FFFFFF"..getPlayerName(player).." #FFFFFFhas dropped all toptimes from this map.", _player, 255, 255, 255, true)
	end
end)

function getPlayerMapResourceName(player)
	local arena = getElementParent(player)
	if not isElement(arena) then
		return
	end
	local arenaName = getElementData(arena, "id")
	local arenaGamemode = getElementData(arena, "gamemode")
	local resourceName
	if arenaGamemode == "training" then
		resourceName = getElementData(player, "training.map")
	else
		resourceName = getElementData(arena, "mapResourceName")
	end
	if not resourceName then
		return
	end
	local mapNameHash = md5(arenaName..resourceName)
	if not toptimes.loaded[mapNameHash] then
		return
	end
	return mapNameHash
end

function getPlayersToSync(arena, basePlayer)
	if isElement(arena) then
		local arenaResource = getElementData(arena, "resource")
		local arenaGamemode = getElementData(arena, "gamemode")
		if arenaGamemode == "training" then
			if isElement(basePlayer) then
				local resourceName = getElementData(basePlayer, "training.map")
				local players = call(arenaResource, "getPlayersTrainingMap", resourceName) or {}
				return players
			end
		else
			return getElementChildren(arena, "player")
		end
	end
end

function getDateTime()
	local dateTime = getRealTime()
	if dateTime.monthday < 10 then
		dateTime.monthday = "0"..dateTime.monthday
	end
	if dateTime.month < 10 then
		dateTime.month = "0"..dateTime.month
	end
	return tostring(dateTime.monthday.."."..string.format("%02d", (dateTime.month + 1)).."."..(1900 + dateTime.year))
end

_getPlayerName = getPlayerName
function getPlayerName(player)
	local team = getPlayerTeam(player)
	if not team then
		return _getPlayerName(player)
	end
	local r, g, b = getTeamColor(team)
	return string.format("#%.2X%.2X%.2X", r, g, b).._getPlayerName(player)
end