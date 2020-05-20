local settings = {
	name = "Destruction Derby: Fun",
	id = "fdd",
	gamemode = "race",
	maximumPlayers = 32,
	closed = false,
	password = nil,
	ghostmodeEnabled = false,
	mapFilter = "[FDD]",
	killRewards = true,
}
arena = {
	points_key = "dd_points",
	maps = {},
	mapNames = {},
	players = {},
	waitingPlayers = {},
	alivePlayers = {},
	finishedPlayers = {},
	playerVehicles = {},
	raceCountdownStartTimer = Timer:create(),
	raceCountdown = Countdown:create(),
	countdownMaximumLimit = Timer:create(),
	nextmapStartTimer = Timer:create(),
	timeIsUpTimer = Timer:create(),
	statsEnabled = false
}
addEvent("mapmanager:onMapsRefresh", true)
addEvent("mapmanager:onPlayerLoadMap", true)
addEvent("onPlayerReady", true)
addEvent("onRequestKillPlayer", true)
addEvent("onArenaKill", true)

function setArenaData(...)
	return exports.v_utils:setArenaData(...)
end

addEventHandler("onResourceStart", resourceRoot,
function()
	local data = exports.core:registerArena(settings)
	if not data then
		outputDebugString("Failed to start arena")
		return
	end
	arena.element = data.element
	arena.dimension = data.dimension
	setState("waitingForPlayers")
	addEventHandler("mapmanager:onMapsRefresh", arena.element, cacheMaps)
	addEventHandler("mapmanager:onPlayerLoadMap", arena.element, handlePlayerLoad)
	addEventHandler("onPlayerReady", arena.element, handlePlayerReady)
	addEventHandler("onPlayerWasted", arena.element, handlePlayerWasted)
	addEventHandler("onRequestKillPlayer", arena.element, handlePlayerRequestKill)
	addEventHandler("onArenaKill", arena.element, handleArenaKill)
	addEventHandler("onVehicleStartExit", resourceRoot, cancelVehicleExit)
	addEventHandler("onVehicleExit", resourceRoot, handleVehicleExit)
	cacheMaps()
	local randomNextMap = getRandomNextMap()
	if randomNextMap then
		arena.currentMap = exports.mapmanager:loadMapData(arena.element, randomNextMap)
	end
	if not arena.currentMap then
		outputDebugString("No map found to start", 1)
	else
		cacheMapSettings()
	end
end)

addEventHandler("onResourceStop", resourceRoot,
function()
	unloadMap()
end)

function movePlayerToArena(player)
	tableInsert(arena.players, player)
	setPlayerState(player, "waiting")
	setElementData(player, "loaded", false, false)
	setElementData(player, "winStreak", 0, false)
	local mapInfo = arena.currentMap and arena.currentMap.info or {}
	local duration = arena.duration or 0
	if arena.timeIsUpTimer:isActive() then
		duration = arena.timeIsUpTimer:getDetails()
	end
	local vehicle = createVehicle(411, 0, 0, 0, 0, 0, 0)
	if vehicle then
		setElementFrozen(vehicle, true)
		setVehicleDamageProof(vehicle, true)
		setElementCollisionsEnabled(vehicle, false)
		setElementDimension(vehicle, arena.dimension)
		setElementSyncer(vehicle, false)
		arena.playerVehicles[player] = vehicle
	end
	triggerClientEvent(player, "onClientJoinArena", resourceRoot, {
		element = arena.element, 
		state = arena.state,
		players = arena.players,
		mapInfo = mapInfo, 
		nextMap = arena.nextMap and arena.mapNames[arena.nextMap] or nil, 
		duration = duration,
		vehicle = arena.playerVehicles[player]
	})
	triggerClientEvent(arena.element, "onClientPlayerJoinArena", resourceRoot, player)
	if #arena.players == 1 then
		setState("loadingMap")
		if arena.currentMap then
			loadMap()
		else
			loadNewMap()
		end
	else
		if arena.currentMap and not (arena.state == "changingMap" or arena.state == "loadingMap") then
			triggerClientEvent(player, "onClientArenaMapStarting", resourceRoot, arena.currentMap.info)
			exports.mapmanager:sendMapData(arena.element, arena.currentMap.info.resourceName, {player})
		end
		if arena.state == "running" and #arena.alivePlayers == 1 and not arena.nextmapStartTimer:isActive() then
			changeMap()
		end
	end
end

function removePlayerFromArena(player)
	tableRemove(arena.players, player)
	tableRemove(arena.waitingPlayers, player)
	setElementData(player, "state", nil)
	setElementData(player, "kill_count", 0, false)
	triggerClientEvent(player, "onClientLeaveArena", resourceRoot)
	triggerClientEvent(arena.element, "onClientPlayerLeaveArena", resourceRoot, player)
	if isElement(arena.playerVehicles[player]) then
		destroyElement(arena.playerVehicles[player])
		arena.playerVehicles[player] = nil
	end
	if #arena.players == 0 then
		killAllTimers()
		arena.players = {}
		arena.waitingPlayers = {}
		arena.alivePlayers = {}
		if arena.state ~= "spawningPlayers" then
			unloadMap()
		end
		setState("waitingForPlayers")
	elseif arena.state == "running" then
		local id = tableFind(arena.alivePlayers, player)
		if id then
			local place = #arena.alivePlayers
			table.remove(arena.alivePlayers, id)
			if place ~= 1 then
				triggerClientEvent(arena.element, "deathlist:add", arena.element, player, "died", place)
			end
			if #arena.alivePlayers == 0 and not arena.nextmapStartTimer:isActive() then
				changeMap()
			elseif #arena.alivePlayers == 1 then
				handlePlayerWin(arena.alivePlayers[1])
				onPlayerFinish(player, place)
				onPlayerFinish(arena.alivePlayers[1], 1)
				triggerClientEvent(arena.element, "deathlist:add", arena.element, arena.alivePlayers[1], "died", 1)
				changeMap()
			else
				onPlayerFinish(player, place)
			end
		end
	else
		if arena.state == "spawningPlayers" then
			checkForCountdown()
		end
		tableRemove(arena.alivePlayers, player)
	end
end

function setState(newState)
	triggerEvent("onArenaStateChanging", arena.element, arena.state, newState)
	triggerClientEvent(arena.element, "onClientArenaStateChanging", resourceRoot, arena.state, newState, {duration = arena.duration})
	arena.state = newState
	if(newState == "running") then
		if(#arena.players >= 3) then
			arena.statsEnabled = #arena.players
		else
			arena.statsEnabled = false
		end
	end
	outputDebugString("State >> "..newState)
end

function setPlayerState(player, state)
	if isElement(player) then
		setArenaData(player, "state", state)
	end
end

function cacheMapSettings()
	arena.duration = math.max(300000, tonumber(arena.currentMap.settings["duration"] * 1000) or 600000)
	if arena.duration > 900000 then
		arena.duration = 900000
	end
end

function loadNewMap()
	arena.alivePlayers = {}
	if #arena.maps == 0 then
		setState("waitingForPlayers")
		outputArenaMessage("Couldn't load map.")
		changeMap()
		return
	end
	local resourceName = getForcedNextMap()
	if not resourceName then
		setState("waitingForPlayers")
		arena.forcedNextMap = nil
		arena.nextMap = nil
		outputArenaMessage("Couldn't load map.")
		changeMap()
		return
	end
	if not arena.currentMap or resourceName ~= arena.currentMap.info.resourceName then
		unloadMap()
	end
	outputArenaMessage("Starting #19846D"..arena.mapNames[resourceName])
	arena.currentMap = exports.mapmanager:loadMapData(arena.element, resourceName)
	if not arena.currentMap then
		setState("waitingForPlayers")
		arena.forcedNextMap = nil
		arena.nextMap = nil
		outputArenaMessage("Couldn't load map.")
		changeMap()
		return
	end
	arena.forcedNextMap = nil
	if arena.savedNextMap then
		arena.nextMap = arena.savedNextMap
		arena.savedNextMap = nil
	else
		if arena.nextMap then
			triggerClientEvent(arena.element, "onClientArenaNextmapChanged", resourceRoot, nil)
		end
		arena.nextMap = nil
	end
	unloadMapClient()
	loadMap()
end

local COMMAND_PERMISSION = exports.v_admin:getCommandLevels()

function restartMap(player, command)
	if isPlayerInArena(player) then
		local player_level = getElementData(player, "admin_level") or 1
		if player_level < COMMAND_PERMISSION[command] then
			outputChatBox("Access denied.", player, 255, 255, 255, true)
			return
		end
		if not arena.currentMap then
			outputChatBox("There is no map to restart.", player, 255, 255, 255, true)
			return
		end
		if arena.nextMap then
			arena.savedNextMap = arena.nextMap
		end
		unloadMapClient()
		killAllTimers()
		setState("loadingMap")
		outputArenaMessage("Map restarted by "..getPlayerName(player))
		arena.forcedNextMap = arena.currentMap.info.resourceName
		arena.nextmapStartTimer:setTimer(function()
			loadNewMap()
		end, 250, 1)
	end
end
addCommandHandler("redo", restartMap)

function randomizeMap(player, command)
	if isPlayerInArena(player) then
		local player_level = getElementData(player, "admin_level") or 1
		if player_level < COMMAND_PERMISSION[command] then
			outputChatBox("Access denied.", player, 255, 255, 255, true)
			return
		end
		if arena.state == "changingMap" then
			outputChatBox("You can't randomize current map while a new one is already loading.", player, 255, 255, 255, true)
			return
		end
		unloadMapClient()
		killAllTimers()
		setState("loadingMap")
		outputArenaMessage("Map randomly changed by "..getPlayerName(player))
		arena.nextmapStartTimer:setTimer(function()
			loadNewMap()
		end, 250, 1)
	end
end
addCommandHandler("random", randomizeMap)

function setNextMap(map)
	if arena.nextMap then
		return "nextmap_is_set"
	end
	if not map then
		return "not_specified"
	end
	if not arena.mapNames[map] then
		return "not_found"
	elseif arena.nextMap and arena.nextMap == arena.mapNames[map] then
		return "map_is_already_set", arena.mapNames[arena.nextMap]
	end
	arena.nextMap = map
	triggerClientEvent(arena.element, "onClientArenaNextmapChanged", resourceRoot, arena.mapNames[arena.nextMap])
	return "success", arena.mapNames[arena.nextMap]
end

addCommandHandler("nextmap",
function(player, command, ...)
	if not isPlayerInArena(player) then
		return
	end
	local player_level = getElementData(player, "admin_level") or 1
	if player_level < COMMAND_PERMISSION[command] then
		outputChatBox("Access denied.", player, 255, 255, 255, true)
		return
	end
	if arena.nextMap and player_level < 4 then
		return outputChatBox("Next map is already set.", player, 255, 255, 255, true)
	end
	local query = #{...} > 0 and table.concat({...}, " ") or nil
	if not query then
		outputChatBox("Please enter a map name.", player, 255, 255, 255, true)
		return
	end
	query = removeUTF(query)
	if not query or query == "" then
		outputChatBox("Please enter a valid map name.", player, 255, 255, 255, true)
		return
	end
	query = query:lower()
	local results = {}
	if arena.mapNames[query] then
		table.insert(results, query)
	else
		query = query:lower()
		for i, v in pairs(arena.mapNames) do
			local mapName = v:lower()
			if mapName == query then
				table.insert(results, i)
				break
			elseif mapName:find(query, 1, true) then
				table.insert(results, i)
			end
		end
	end
	if #results > 1 then
		outputChatBox("Found "..#results.." results, please be more specific.", player, 255, 255, 255, true)
		return
	elseif #results == 0 then
		outputChatBox("No results found.", player, 255, 255, 255, true)
		return
	elseif arena.nextMap and arena.nextMap == results[1] then
		outputChatBox("Nextmap is already set to "..arena.mapNames[arena.nextMap], player, 255, 255, 255, true)
		return
	end
	arena.nextMap = results[1]
	triggerClientEvent(arena.element, "onClientArenaNextmapChanged", resourceRoot, arena.mapNames[arena.nextMap])
	outputArenaMessage("Next map has been set to #19846D"..arena.mapNames[arena.nextMap].." #FFFFFFby "..getPlayerName(player))
end)

function killAllTimers()
	arena.raceCountdownStartTimer:killTimer()
	arena.countdownMaximumLimit:killTimer()
	arena.raceCountdown:stop()
	arena.nextmapStartTimer:killTimer()
	arena.timeIsUpTimer:killTimer()
	gridCountdown(false)
end

function changeMap()
	if arena.nextmapStartTimer:isActive() then
		return
	end
	killAllTimers()
	setState("changingMap")
	arena.nextmapStartTimer:setTimer(loadNewMap, 4000, 1)
end

function loadMap()
	cacheMapSettings()
	for i, player in pairs(arena.players) do
		setPlayerState(player, "waiting")
		setElementData(player, "loaded", false, false)
		triggerClientEvent(player, "onClientArenaRequestSpectateEnd", resourceRoot)
	end
	arena.waitingPlayers = {}
	arena.alivePlayers = {}
	arena.spawnpoints = arena.currentMap.spawnpoints or {}
	if #arena.spawnpoints == 0 then
		outputArenaMessage("Couldn't load map.")
		changeMap()
		return
	end
	arena.countdownGrid = nil
	arena.currentSpawnpointID = math.random(#arena.spawnpoints)
	setState("spawningPlayers")
	triggerEvent("onArenaMapStarting", arena.element, arena.currentMap.info)
	triggerClientEvent(arena.element, "onClientArenaMapStarting", resourceRoot, arena.currentMap.info)
	exports.mapmanager:sendMapData(arena.element, arena.currentMap.info.resourceName)
end

function unloadMap(forceClient)
	if arena.currentMap then
		exports.mapmanager:unloadMapData(arena.element, arena.currentMap.info.resourceName, forceClient and true or false)	
		arena.currentMap = nil
	end
end

function unloadMapClient()
	triggerClientEvent(arena.element, "unloadMap", arena.element)
end

function handlePlayerLoad()
	if tableFind(arena.alivePlayers, source) then
		return
	end
	setPlayerState(source, "waiting")
	setElementData(source, "loaded", true, false)
	if arena.state == "spawningPlayers" then
		tableInsert(arena.alivePlayers, source)
		local spawnpoint = arena.spawnpoints[arena.currentSpawnpointID]
		spawnPlayerAtSpawnpoint(source, spawnpoint)
		arena.currentSpawnpointID = arena.currentSpawnpointID + 1
		if arena.currentSpawnpointID > #arena.spawnpoints then
			arena.currentSpawnpointID = 1
		end
	else
		tableRemove(arena.alivePlayers, source)
		if not tableFind(arena.waitingPlayers, source) then
			triggerClientEvent(source, "onClientArenaRequestSpectateStart", resourceRoot)
		end
	end
end

function spawnPlayerAtSpawnpoint(player, spawnpoint)
	if player and type(spawnpoint) == "table" and #spawnpoint >= 7 then
		if arena.playerVehicles[player] and isElement(arena.playerVehicles[player]) then
			destroyElement(arena.playerVehicles[player])
		end
		local model = spawnpoint[1]
		local posX, posY, posZ = spawnpoint[2], spawnpoint[3], spawnpoint[4]
		local rotX, rotY, rotZ = spawnpoint[5], spawnpoint[6], spawnpoint[7]
		arena.playerVehicles[player] = createVehicle(model, posX, posY, posZ, rotX, rotY, rotZ)
		spawnPlayer(player, posX, posY, posZ)
		freezePlayer(player)
		setPedStat(player, 160, 1000)
		setPedStat(player, 229, 1000)
		setPedStat(player, 230, 1000)
		warpPedIntoVehicle(player, arena.playerVehicles[player])
		setElementDimension(arena.playerVehicles[player], arena.dimension)
		setElementSyncer(arena.playerVehicles[player], false)
		triggerClientEvent(player, "onClientArenaSpawn", resourceRoot, arena.playerVehicles[player])
	end
end

function freezePlayer(player)
	if not isElement(player) then
		return
	end
	local vehicle = arena.playerVehicles[player]
	if isElement(vehicle) then
		setElementFrozen(vehicle, true)
		setVehicleDamageProof(vehicle, true)
		setElementCollisionsEnabled(vehicle, false)
	end
	setElementFrozen(player, true)
end

function unfreezePlayer(player)
	if not isElement(player) then
		return
	end
	local vehicle = arena.playerVehicles[player]
	if isElement(vehicle) then
		setElementFrozen(vehicle, false)
		setVehicleDamageProof(vehicle, false)
		setElementCollisionsEnabled(vehicle, true)
	end
	setElementFrozen(player, false)
end

function checkForCountdown()
	if arena.countdownGrid or arena.state == "running" then
		return
	end
	if #arena.alivePlayers >= #arena.players * 0.75 and not arena.raceCountdown:isActive() then
		arena.raceCountdownStartTimer:setTimer(function()
			arena.countdownMaximumLimit:killTimer()
			arena.raceCountdown:start(gridCountdown, 4)
		end, 5000, 1)
		arena.countdownGrid = true
	elseif #arena.alivePlayers >= 1 and not arena.countdownMaximumLimit:isActive() then
		arena.countdownMaximumLimit:setTimer(function()
			if arena.state ~= "running" then
				if arena.countdownGrid or arena.raceCountdownStartTimer:isActive() then
					return arena.countdownMaximumLimit:killTimer()
				end
				arena.raceCountdownStartTimer:setTimer(function()
					arena.raceCountdownStartTimer:killTimer()
					arena.raceCountdown:start(gridCountdown, 4)
				end, 5000, 1)
				arena.countdownGrid = true
				outputDebugString("Forced countdown to start after 15 seconds")
			end
		end, 15000, 1)
	end
end

function handlePlayerReady()
	tableInsert(arena.alivePlayers, source)
	setPlayerState(source, "alive")
	checkForCountdown()
	if arena.state == "running" then
		if arena.playerVehicles[source] then
			unfreezePlayer(source)
		end
	end
end

function gridCountdown(countdown)
	arena.countdown = countdown
	triggerClientEvent(arena.element, "onClientArenaGridCountdown", resourceRoot, countdown)
	if countdown == 0 then
		launchRace()
	end
end

function launchRace()
	arena.waitingPlayers = {}
	arena.finishedPlayers = {}
	for i, player in pairs(arena.players) do
		if tableFind(arena.alivePlayers, player) and isPedInVehicle(player) and arena.playerVehicles[player] and isElement(arena.playerVehicles[player]) then
			unfreezePlayer(player)
		else
			setPlayerState(player, "waiting")
			tableRemove(arena.alivePlayers, player)
			table.insert(arena.waitingPlayers, player)
			triggerClientEvent(player, "onClientArenaRequestSpectateStart", resourceRoot)
		end
	end
	if #arena.alivePlayers == 0 then
		changeMap()
		return
	end	
	arena.timeIsUpTimer:setTimer(timeIsUp, arena.duration, 1)
	setState("running")
end

function timeIsUp()
	outputArenaMessage("Time is up!")
	for i, player in pairs(arena.alivePlayers) do
		setElementHealth(player, 0)
	end
	for i, player in pairs(arena.players) do
		toggleAllControls(player, false, true, false)
	end
	changeMap()
end

function handlePlayerWasted()
	local id = tableFind(arena.alivePlayers, source)
	if not id then
		return
	end
	if arena.state == "spawningPlayers" then
		if not getElementData(source, "loaded") then
			return
		end
		if arena.playerVehicles[source] and isElement(arena.playerVehicles[source]) then
			local x, y, z = getElementPosition(source)
			spawnPlayer(source, x, y, z)
			fixVehicle(arena.playerVehicles[source])
			warpPedIntoVehicle(source, arena.playerVehicles[source])
			setCameraTarget(source, source)
		else
			local spawnpoint = arena.spawnpoints[arena.currentSpawnpointID]
			spawnPlayerAtSpawnpoint(source, spawnpoint)
		end
	elseif arena.state == "running" then
		local place = #arena.alivePlayers
		table.remove(arena.alivePlayers, id)
		if place ~= 1 then
			triggerClientEvent(arena.element, "deathlist:add", arena.element, source, "died", place)
		end
		if #arena.alivePlayers == 0 and not arena.nextmapStartTimer:isActive() then
			changeMap()
		elseif #arena.alivePlayers == 1 then
			handlePlayerWin(arena.alivePlayers[1])
			onPlayerFinish(source, place)
			onPlayerFinish(arena.alivePlayers[1], 1)
			triggerClientEvent(arena.element, "deathlist:add", arena.element, arena.alivePlayers[1], "died", 1)
			changeMap()
		else
			onPlayerFinish(source, place)
		end
		setPlayerState(source, "dead")
		triggerClientEvent(source, "onClientArenaWasted", resourceRoot)
	else
		onPlayerFinish(source, #arena.alivePlayers)
		tableRemove(arena.alivePlayers, source)
		setPlayerState(source, "dead")
		triggerClientEvent(source, "onClientArenaRequestSpectateStart", resourceRoot)
	end
end

function handlePlayerWin(player)
	setElementData(player, "winStreak", (getElementData(player, "winStreak") or 0)+1, false)
	outputArenaMessage(getPlayerName(player).." #FFFFFFhas won as the last player alive [Streak: "..getElementData(player, "winStreak").."]")
end

function handlePlayerRequestKill()
	if arena.state == "running" and (getElementData(source, "state") == "alive" or getElementData(source, "state") == "training") then
		setElementHealth(source, 0)
	end
end

function handleArenaKill(killer, player)
	setElementData(killer, "kill_count", (getElementData(killer, "kill_count") or 0)+1, false)
	local money = 100
	local points = 5
	exports.v_mysql:givePlayerStats(killer, "money", money)
	exports.v_mysql:givePlayerStats(killer,	arena.points_key or getElementData(arena.element, "id").."_points", points)
	outputChatBox("#19846d* #ffffffYou received #19846d"..points.." #ffffffpoint"..(points == 1 and "" or "s").." and #19846d$"..money.." #fffffffor eliminating a player", killer, 255, 255, 255, true)	
end

function cancelVehicleExit()
	cancelEvent()
	return
end

function handleVehicleExit(player)
	if arena.state == "spawningPlayers" then
		if not getElementData(player, "loaded") then
			return
		end
		if arena.playerVehicles[player] and isElement(arena.playerVehicles[player]) then
			local x, y, z = getElementPosition(player)
			spawnPlayer(player, x, y, z)
			fixVehicle(arena.playerVehicles[player])
			warpPedIntoVehicle(player, arena.playerVehicles[player])
			setCameraTarget(player, player)
		else
			local spawnpoint = arena.spawnpoints[arena.currentSpawnpointID]
			spawnPlayerAtSpawnpoint(player, spawnpoint)
		end
		outputDebugString(getPlayerName(player).." was out of vehicle")
	elseif arena.state == "running" then
		if isElement(arena.playerVehicles[player]) then
			warpPedIntoVehicle(player, arena.playerVehicles[player])
		else
			setElementHealth(player, 0)
		end
	end
end

function getForcedNextMap()
	local forcedNextMap = nil
	if arena.forcedNextMap then
		if arena.mapNames[arena.forcedNextMap] then
			forcedNextMap = arena.forcedNextMap
		end
	elseif arena.nextMap then
		if arena.mapNames[arena.nextMap] then
			forcedNextMap = arena.nextMap
		end
	end
	if not forcedNextMap then
		forcedNextMap = getRandomNextMap()
	end
	return forcedNextMap
end

function getRandomNextMap()
	if #arena.maps > 0 then
		math.randomseed(getTickCount())
		local id = math.random(#arena.maps)
		return arena.maps[id]
	end
	return
end

function cacheMaps()
	arena.maps, arena.mapNames = exports.core:getMapsCompatibleWithGamemode(settings.mapFilter)
	outputDebugString("Refreshed maps [Total: "..#arena.maps.."]")
end

local ArenaPrefix = "#19846D["..settings.id:upper().."]"
function outputArenaMessage(message)
	outputChatBox(ArenaPrefix.."#FFFFFF "..message, arena.element, 255, 255, 255, true)
end

function isPlayerInArena(player)
	if not isElement(player) or getElementType(player) ~= "player" then
		return false
	end
	return getElementParent(player) == arena.element
end

_outputDebugString = outputDebugString
function outputDebugString(message)
	return _outputDebugString(message:gsub("#%x%x%x%x%x%x", ""), 0, 180, 180, 180)
end

local illegalChars = {"%!", "%'", "%^", "%+", "%%", "%&", "%/", "%(", "%)", "%=", "%?", "%_", "%;"}
function convertToMySQLString(str)
	for i, char in pairs(illegalChars) do
		str = str:gsub(char, "")
	end
	return str
end

function removeUTF(str)
	local asciiStr = ""
	for i = 1, utfLen(str) do
		local c = utfSub(str, i, i)
		if not bitTest(0x80, string.byte(c)) then
			asciiStr = asciiStr..c
		end
	end
	return convertToMySQLString(asciiStr)
end