local settings = {
	name = "Training: Deathmatch",
	id = "dm training",
	gamemode = "training",
	maximumPlayers = 256,
	closed = false,
	password = nil,
	ghostmodeEnabled = true,
	mapFilter = "[DM]" --, [HDM], [OS]
}
arena = {
	maps = {},
	mapNames = {},
	players = {},
	playerVehicles = {},
	playerMaps = {},
	mapsLoaded = {}
}

-- Main events
addEvent("mapmanager:onMapsRefresh", true)
addEvent("mapmanager:onPlayerLoadMap", true)
addEvent("onRequestKillPlayer", true)
-- Custom training events
addEvent("training:onPlayerRequestAddToptime", true)
addEvent("training:onClientRequestTrainMap", true)

--[[ Functions::Main ]]--

addEventHandler("onResourceStart", resourceRoot,
function()
	local data = exports.core:registerArena(settings)
	if not data then
		outputDebugString("Failed to start arena")
		return
	end
	arena.element = data.element
	arena.dimension = data.dimension
	addEventHandler("mapmanager:onMapsRefresh", arena.element, cacheMaps)
	addEventHandler("mapmanager:onPlayerLoadMap", arena.element, handlePlayerLoad)
	addEventHandler("onPlayerWasted", arena.element, handlePlayerWasted)
	addEventHandler("onRequestKillPlayer", arena.element, handlePlayerRequestKill)
	addEventHandler("onVehicleStartExit", resourceRoot, cancelVehicleExit)
	addEventHandler("onVehicleExit", resourceRoot, handleVehicleExit)
	addEventHandler("training:onClientRequestTrainMap", resourceRoot, onClientRequestTrainMap)
	cacheMaps()
end)

addEventHandler("onResourceStop", resourceRoot,
function()
	for player, mapData in pairs(arena.playerMaps) do
		removePlayerMap(player)
	end
end)

function movePlayerToArena(player)
	tableInsert(arena.players, player)
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
		players = arena.players,
		vehicle = arena.playerVehicles[player],
		maps	= arena.mapNames
	})
	triggerClientEvent(arena.element, "onClientPlayerJoinArena", resourceRoot, player)
	-- Temporary
	--setPlayerMap(player, "[DM]DizzasTeR-Dark-Wheels")
end

function removePlayerFromArena(player)
	tableRemove(arena.players, player)
	if arena.playerMaps[player] then
		removePlayerMap(player)
	end
	triggerClientEvent(player, "onClientLeaveArena", resourceRoot)
	triggerClientEvent(arena.element, "onClientPlayerLeaveArena", resourceRoot, player)
	if isElement(arena.playerVehicles[player]) then
		destroyElement(arena.playerVehicles[player])
		arena.playerVehicles[player] = nil
	end
end

--[[ Functions::Core ]]--

function handlePlayerLoad()
	freezePlayer(source)
	respawnPlayer(source)
end

function handlePlayerWasted()
	setTimer(respawnPlayer, 1000, 1, source)
	triggerClientEvent(source, "onClientArenaWasted", resourceRoot)
end

function handlePlayerRequestKill()
	if isPlayerFrozen(source) or isPedDead(source) then
		return
	end
	setElementHealth(source, 0)
end

function cancelVehicleExit()
	cancelEvent()
	return
end

function handleVehicleExit(player)
	setElementHealth(player, 0)
end

function onClientRequestTrainMap(map)
	setPlayerMap(client, map)
end

addEventHandler("training:onPlayerRequestAddToptime", resourceRoot, function(timePassed)
	local player_mapData = arena.playerMaps[client]
	triggerEvent("toptimes:onPlayerRequestAddToptime", client, timePassed, player_mapData.resourceName, {sendToPlayers = arena.mapsLoaded[player_mapData.resourceName].players})
end)

--[[ Functions::Misc ]]--

function respawnPlayer(player)
	if not isElement(player) or not tableFind(arena.players, player) then
		return error("respawnPlayer: player does not exist")
	end
	local map = arena.playerMaps[player]
	if not map then return error("Player has not loaded any map data") end
	if arena.playerVehicles[player] and isElement(arena.playerVehicles[player]) then
		local spawnpoint = map.spawnpoints[math.random(#map.spawnpoints)]
		local model = spawnpoint[1]
		local posX, posY, posZ = spawnpoint[2], spawnpoint[3], spawnpoint[4]
		local rotX, rotY, rotZ = spawnpoint[5], spawnpoint[6], spawnpoint[7]
		destroyElement(arena.playerVehicles[player])
		arena.playerVehicles[player] = createVehicle(model, posX, posY, posZ, rotX, rotY, rotZ)
		freezePlayer(player)
		spawnPlayer(player, posX, posY, posZ)
		setPedStat(player, 160, 1000)
		setPedStat(player, 229, 1000)
		setPedStat(player, 230, 1000)
		warpPedIntoVehicle(player, arena.playerVehicles[player])
		setElementSyncer(arena.playerVehicles[player], false)
		setTimer(unfreezePlayer, 3000, 1, player)
		triggerClientEvent(player, "onClientArenaSpawn", resourceRoot, arena.playerVehicles[player])
	end
end

function setPlayerMap(player, resourceName)
	if arena.playerMaps[player] then
		removePlayerMap(player)
	end
	if arena.mapsLoaded[resourceName] then
		local mapData = arena.mapsLoaded[resourceName]
		if not mapData then return end
		triggerEvent("toptimes:loadToptimesForMap", arena.element, settings.id, resourceName, arena.mapsLoaded[resourceName].info.mapName)
		arena.playerMaps[player] = {
			resourceName = mapData.info.resourceName,
			mapName = mapData.info.mapName,
			spawnpoints = mapData.spawnpoints
		}
		triggerClientEvent(player, "training:onClientMapSet", resourceRoot, arena.playerMaps[player])
		call(getResourceFromName("mapmanager"), "sendMapData", arena.element, resourceName, {player})
		tableInsert(arena.mapsLoaded[resourceName].players, player)
		outputDebugString("[Training] Loaded "..resourceName.." for "..(#arena.mapsLoaded[resourceName].players).." players", 0, 150, 150, 0)
	else
		arena.mapsLoaded[resourceName] = call(getResourceFromName("mapmanager"), "loadMapData", arena.element, resourceName)
		if not arena.mapsLoaded[resourceName] then
			triggerClientEvent(player, "notification:create", player, "Error", "Unable to load map")
			return
		end	
		local mapData = arena.mapsLoaded[resourceName]
		if not mapData then return end
		triggerEvent("toptimes:loadToptimesForMap", arena.element, settings.id, resourceName, arena.mapsLoaded[resourceName].info.mapName)
		mapData.players = {}
		arena.playerMaps[player] = {
			resourceName = mapData.info.resourceName,
			mapName = mapData.info.mapName,
			spawnpoints = mapData.spawnpoints
		}
		triggerClientEvent(player, "training:onClientMapSet", resourceRoot, arena.playerMaps[player])
		call(getResourceFromName("mapmanager"), "sendMapData", arena.element, resourceName, {player})
		tableInsert(mapData.players, player)
		outputDebugString("[Training] Loaded "..resourceName.." for "..(#arena.mapsLoaded[resourceName].players).." players", 0, 150, 150, 0)
	end
	setElementData(player, "training.map", resourceName, false)
end

function removePlayerMap(player)
	if arena.playerMaps[player] == nil then return end
	local player_mapData = arena.playerMaps[player]
	local mapData = arena.mapsLoaded[player_mapData.resourceName]
	tableRemove(mapData.players, player)
	outputDebugString("[Training] Loaded "..player_mapData.resourceName.." for "..(#mapData.players).." players", 0, 150, 150, 0)
	if #mapData.players > 0 then
		triggerClientEvent(player, "unloadMap", resourceRoot)
	else
		call(getResourceFromName("mapmanager"), "unloadMapData", arena.element, player_mapData.resourceName, true, {player})
		triggerEvent("toptimes:unloadToptimesForMap", arena.element, settings.id, player_mapData.resourceName)
		arena.mapsLoaded[player_mapData.resourceName] = nil
	end
	arena.playerMaps[player] = nil
	triggerClientEvent(player, "training:onClientMapRemove", resourceRoot)
	setElementData(player, "training.map", nil, false)
	for key, _player in pairs(arena.players) do
		if(player ~= _player and getCameraTarget(_player) == player) then
			CMD_Spectate(_player, "spec", "off")
		end
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

function unfreezePlayer(player, timer_reset)
	timer_reset = timer_reset == nil and true or false
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
	setCameraTarget(player, player)
	if timer_reset then
		triggerClientEvent(player, "training:onPlayerStart", resourceRoot)
	end
end

function isPlayerFrozen(player)
	if not isElement(player) then
		return
	end
	local f = 0
	local vehicle = arena.playerVehicles[player]
	if isElement(vehicle) then
		if isElementFrozen(vehicle) then
			f = f + 1
		end
	end
	if isElementFrozen(player) then
		f = f + 1
	end
	return (f > 0 and true or false)
end

function cacheMaps()
    arena.maps, arena.mapNames = {}, {}
    do
        local maps, mapNames = exports.core:getMapsCompatibleWithGamemode("[DM]")
        for i, map in pairs(maps) do
            table.insert(arena.maps, map)
        end
        for resourceName, mapName in pairs(mapNames) do
            arena.mapNames[resourceName] = mapName
        end
    end
	do
        local maps, mapNames = exports.core:getMapsCompatibleWithGamemode("[OS]")
        for i, map in pairs(maps) do
            table.insert(arena.maps, map)
        end
        for resourceName, mapName in pairs(mapNames) do
            arena.mapNames[resourceName] = mapName
        end
    end
    do
        local maps, mapNames = exports.core:getMapsCompatibleWithGamemode("[HDM]")
        for i, map in pairs(maps) do
            table.insert(arena.maps, map)
        end
        for resourceName, mapName in pairs(mapNames) do
            arena.mapNames[resourceName] = mapName
        end
    end
    outputDebugString("Refreshed maps [Total: "..#arena.maps.."]")
end

function error(msg)
	outputDebugString(msg, 0, 100, 0, 0)
end

--[[ Functions::Exports ]]--

function getPlayersTrainingMap(resourceName)
	return arena.mapsLoaded[resourceName].players
end

function CMD_Spectate(player, command, plr)
	if tableFind(arena.players, player) then
		if not plr then
			return outputChatBox("#19846dSYNTAX ERROR ::#ffffff /"..command.." [Nick/ID or off]", player, 255, 255, 255, true)
		end
		if string.lower(tostring(plr)) == "off" then
			if getCameraTarget(player) ~= player then
				setCameraTarget(player, player)
				unfreezePlayer(player, false)
			end
			return
		elseif isPlayerFrozen(player) or isPedDead(player) then
			return
		end
		plr = getPlayerFromID(plr) or getPlayerFromPartialName(plr)
		if not isElement(plr) then
			return outputChatBox("#19846dERROR :: #ffffffPlayer not found!", player, 255, 255, 255, true)
		elseif plr == player then
			return
		end
		local player_map, plr_map = getElementData(player, "training.map"), getElementData(plr, "training.map")
		local spectate_toggle = exports.v_mysql:getPlayerStats(plr, "training_spectate") or 1
		if player_map == nil then
			return
		end
		if player_map ~= plr_map then
			return outputChatBox("#19846dERROR :: #ffffffCannot spectate "..getPlayerName(plr).."#ffffff since the requested player is not training the same map as you. #19846d("..(plr_map and arena.mapNames[plr_map] or "Requested player is selecting a map")..")", player, 255, 255, 255, true)
		elseif spectate_toggle == 0 then
			return outputChatBox("#19846dERROR :: #ffffffRequested player has disabled people from spectating him", player, 255, 255, 255, true)
		end
		setCameraTarget(player, plr)
		freezePlayer(player)
		outputChatBox("#19846dSPEC :: #ffffffTo turn spectate off use /spec off", player, 255, 255, 255, true)
	end
end
addCommandHandler("spec", CMD_Spectate)

function CMD_SpectateToggle(player, command)
	if tableFind(arena.players, player) then
		local spectate_toggle = exports.v_mysql:getPlayerStats(player, "training_spectate") or 1
		spectate_toggle = spectate_toggle == 1 and 0 or 1
		exports.v_mysql:setPlayerStats(player, "training_spectate", spectate_toggle, true)
		outputChatBox("#19846dSPEC :: #ffffffPlayers can spectate you: "..(spectate_toggle == 1 and "#00ff00enabled" or "#ff0000disabled"), player, 255, 255, 255, true)
	end
end
addCommandHandler("togspec", CMD_SpectateToggle)

function trainMap(player, command, ...)
	if tableFind(arena.players, player) then
		local query = #{...} > 0 and table.concat({...}, " ") or nil
		if not query then
			outputChatBox("Please enter a map name.", player, 255, 255, 255, true)
			return
		end
		query = query:lower()
		local results = {}
		for i, v in pairs(arena.mapNames) do
			local mapName = v:lower()
			if mapName:find(query) then
				table.insert(results, i)
			end
		end
		if #results > 1 then
			outputChatBox("Found "..#results.." results, please be more specific.", player, 255, 255, 255, true)
			return
		elseif #results == 0 then
			outputChatBox("No results found.", player, 255, 255, 255, true)
			return
		end
		local resourceName = results[1]
		setPlayerMap(player, resourceName)
	end
end
addCommandHandler("train", trainMap)

function getPlayerFromPartialName(name)
    local name = name and name:gsub("#%x%x%x%x%x%x", ""):lower() or nil
    if name then
        for _, player in ipairs(getElementsByType("player", arena.element, true)) do
            local name_ = getPlayerName(player):gsub("#%x%x%x%x%x%x", ""):lower()
            if name_:find(name, 1, true) then
                return player
            end
        end
    end
end

function getPlayerFromID(id)
	id = tonumber(id)
	if type(id) ~= "number" then
		return nil
	end
	for _, player in ipairs(getElementsByType("player", arena.element, true)) do
		if getElementData(player, "id") == id then
			return player
		end
	end
	return nil
end