core = {arenas = {}, resources = {}, dimensions = {}, ids = {}}

function getNextFreeDimension()
	local dimension = 1
	while core.dimensions[dimension] ~= nil do
		dimension = dimension + 1
	end
	return dimension
end

function registerArena(settings)
	-- Check the values first
	local id = settings.id
	if not id then
		outputDebugString("Invalid/non 'id' specified", 0, 25, 132, 109)
		return
	end
	if type(settings.name) ~= "string" then
		outputDebugString("Invalid/non 'name' specified", 0, 25, 132, 109)
		return
	end
	if type(settings.maximumPlayers) ~= "number" then
		settings.maximumPlayers = 0
	end
	if core.arenas[id] then
		outputDebugString("Avoiding arena duplication for ID "..tostring(id)..", it is being used already", 0, 25, 132, 109)
		return
	end
	closed = closed and true or false
	password = type(password) == "string" and password or nil
	local element = createElement("arena", id)
	if not isElement(element) then
		outputDebugString("Failed to create arena element", 0, 25, 132, 109)
		return
	end
	-- Register now
	local data = {}
	for i, v in pairs(settings) do
		setElementData(element, i, v)
		data[i] = v
	end
	setElementData(element, "resource", sourceResource)
	data.element = element
	data.resource = sourceResource
	data.dimension = getNextFreeDimension()
	setElementDimension(element, data.dimension)
	core.dimensions[data.dimension] = true
	core.arenas[id] = data
	core.resources[sourceResource] = data
	triggerClientEvent(root, "core:syncArenasData", root)
	outputDebugString("Registered arena ["..data.name.." - "..data.id.." - "..data.dimension.." - "..data.maximumPlayers.." "..tostring(data.closed).." "..tostring(data.password).."]", 0, 25, 132, 109)
	return data
end

addEventHandler("onResourceStop", root,
function(resource)
	if core.resources[resource] then
		local data = core.resources[resource]
		unregisterArena(data.id)
	end
end)

addEventHandler("onResourceStop", resourceRoot,
function()
	for i, player in pairs(getElementsByType("player")) do
		local arena = getElementData(player, "arena")
		if arena then
			removePlayerFromArena(player, arena)
			-- Move to lobby
			movePlayerToLobby(player)
		end
	end
end)

function unregisterArena(id)
	local arena = core.arenas[id]
	if arena then
		outputDebugString("Unregistering arena "..arena.name, 0, 25, 132, 109)
		triggerEvent("core:onArenaUnregister", arena.element)
		triggerClientEvent(arena.element, "notification:create", arena.element, "Arena", "The arena has been closed, please come back later")
		-- Move players to lobby
		for i, player in pairs(getElementChildren(arena.element, "player")) do
			removePlayerFromArena(player, id)
			movePlayerToLobby(player)
		end
		destroyElement(arena.element)
		if core.dimensions[arena.dimension] then
			core.dimensions[arena.dimension] = nil
		end
		arena = nil
	end
	core.arenas[id] = nil
	triggerClientEvent(root, "core:syncArenasData", root)
end

function movePlayerToArena(player, id)
	local arena = core.arenas[id]
	if isElement(player) then
		if not arena then
			outputChatBox("You have tried to join an invalid arena.", player, 255, 255, 255, true)
			return
		end
		if arena.resource and getResourceState(arena.resource) == "running" then
			cancelLatentsForPlayer(player)
			setElementParent(player, arena.element)
			setElementDimension(player, arena.dimension)
			setElementData(player, "arena", arena.id)
			triggerEvent("core:onPlayerJoinArena", player, arena)
			triggerClientEvent(player, "core:handleClientJoinArena", resourceRoot, arena)
			call(arena.resource, "movePlayerToArena", player)
			triggerClientEvent(arena.element, "notification:create", arena.element, "Arena", getPlayerName(player).." #FFFFFFhas joined the arena", "joinquit", "join")
		end
	end
end

function removePlayerFromArena(player, id)
	local arena = core.arenas[id]
	if isElement(player) and arena then
		if arena.resource and getResourceState(arena.resource) == "running" then
			call(arena.resource, "removePlayerFromArena", player)
		end
		triggerEvent("core:onPlayerLeaveArena", player, arena)
		triggerClientEvent(player, "core:handleClientLeaveArena", resourceRoot)
	end
	-- Just in case to avoid any bug
	setElementData(player, "spectating", nil, false)
end

function sendPlayerToLobby(player)
	if isElement(player) then
		local arena = getElementData(player, "arena")
		if not arena then
			return
		end
		removePlayerFromArena(player, arena)
		-- Move to lobby
		movePlayerToLobby(player)
	end
end

function assignPlayerID(player)
	if isElement(player) then
		local function getNextID()
			local id = 1
			while core.ids[id] ~= nil do
				id = id + 1
			end
			return id
		end
		local id = getNextID()
		core.ids[id] = player
		setElementData(player, "id", id)
	end
end

function deassignPlayerID(player)
	if isElement(player) then
		local id = getElementData(player, "id")
		if id and core.ids[id] then
			core.ids[id] = nil
		end
	end
end

function getPlayerFromID(id)
	if id and core.ids[id] then
		return core.ids[id]
	end
end

addEventHandler("onPlayerJoin", root,
function()
	movePlayerToLobby(source)
	assignPlayerID(source)
end)

addEventHandler("onPlayerQuit", root,
function()
	local arena = getElementData(source, "arena")
	if arena then
		removePlayerFromArena(source, arena)
		movePlayerToLobby(source)
	end
	deassignPlayerID(source)
end)

addEvent("core:onPlayerRequestJoinArena", true)
addEventHandler("core:onPlayerRequestJoinArena", root,
function(id)
	if type(id) == "string" then
		-- Remove from the current arena first
		local currentArena = getElementData(source, "arena")
		if currentArena == id then
			triggerClientEvent(source, "notification:create", resourceRoot, "Arena", "You are already in "..core.arenas[currentArena].name)
			return
		end
		if currentArena then
			removePlayerFromArena(source, currentArena)
		end
		local arena = core.arenas[id]		
		if not arena or not arena.resource or getResourceState(arena.resource) ~= "running" then
			-- Move to lobby to avoid getting stuck
			triggerClientEvent(source, "core:handleClientLeaveArena", resourceRoot)
			movePlayerToLobby(source)
			triggerClientEvent(source, "notification:create", resourceRoot, "Arena", "This arena is not available at the moment")
			return
		end
		if arena.requireLogin and not getElementData(source, "LoggedIn") then
			removePlayerFromArena(source, arena.id)
			-- Move to lobby
			movePlayerToLobby(source)
			return triggerClientEvent(source, "notification:create", resourceRoot, "Arena", "You have to be logged in to join "..arena.name)
		end
		if arena.locked and not hasObjectPermissionTo(source, "function.kickPlayer", true) then
			removePlayerFromArena(source, arena.id)
			-- Move to lobby
			movePlayerToLobby(source)
			return triggerClientEvent(source, "notification:create", resourceRoot, "Arena", "This arena is locked")
		end
		local playersCount, maximumPlayers = #getElementChildren(arena.element, "player"), getElementData(arena.element, "maximumPlayers") or 0
		if maximumPlayers > 0 and playersCount >= maximumPlayers and not hasObjectPermissionTo(source, "function.kickPlayer", true) then
			return triggerClientEvent(source, "notification:create", resourceRoot, "Arena", "This arena is full, please try again later")
		end
		-- Move to target arena
		movePlayerToArena(source, id)
	end
end)

addEvent("core:onPlayerRequestLeaveArena", true)
addEventHandler("core:onPlayerRequestLeaveArena", root,
function()
	local arena = getElementData(source, "arena")
	if not arena then
		return
	end
	removePlayerFromArena(source, arena)
	-- Move to lobby
	movePlayerToLobby(source)
end)

addEvent("onArenaStateChanging", true)
addEventHandler("onArenaStateChanging", root,
function(oldState, newState)
	setElementData(source, "state", newState)
end)

addEvent("onArenaMapStarting", true)
addEventHandler("onArenaMapStarting", root,
function(mapInfo)
	setElementData(source, "map", mapInfo.mapName)
	setElementData(source, "mapResourceName", mapInfo.resourceName)
end)

-- Spectate
addCommandHandler("manualspectate",
function(player, command)
	local arena = core.arenas[tostring(getElementData(player, "arena"))]
	if not arena then
		return
	end
	if arena.gamemode ~= "race" then
		return
	end
	local state = getElementData(arena.element, "state")
	local vehicle = getPedOccupiedVehicle(player)
	if getElementData(player, "state") == "spectating" and getElementData(player, "spectating") then
		triggerClientEvent(player, "spectate:stop", resourceRoot, true)
		setElementData(player, "spectating", nil, false)
		return
	end
	local arenaAllowsSpectate = arena.allowSpectating
	if (not hasObjectPermissionTo(player, "function.kickPlayer", true) and not arenaAllowsSpectate) or state ~= "running" then
		return
	end
	if getElementData(player, "state") == "alive" and isElement(vehicle) and not isElementFrozen(vehicle) then
		triggerClientEvent(player, "spectate:start", resourceRoot, true)
		setElementData(player, "state", "spectating")
		setElementData(player, "spectating", true, false)
		setElementFrozen(vehicle, true)
	end
end)

addEvent("spectate:unfreeze", true)
addEventHandler("spectate:unfreeze", root,
function()
	local vehicle = getPedOccupiedVehicle(source)
	if isElement(vehicle) then
		setElementFrozen(vehicle, false)
	end
	setElementData(source, "state", "alive")
end)

-- Maps
function getMapsCompatibleWithGamemode(gamemodeFilter)
	if type(gamemodeFilter) ~= "string" and type(gamemodeFilter) ~= "table" then
		return {}, {}
	end
	local maps = {}
	local mapNames = {}
	for i, resource in pairs(getResources()) do
		local resourceType = getResourceInfo(resource, "type")
		local resourceGamemodes = getResourceInfo(resource, "gamemodes")
		if resourceType == "map" and resourceGamemodes == "race" then
			local resourceName = getResourceName(resource)
			local mapName = getResourceInfo(resource, "name")
			if resourceName and mapName and isMapCompatibleWithGamemode(mapName, gamemodeFilter) then
				table.insert(maps, resourceName)
				mapNames[resourceName] = mapName
			end
		end
	end
	return maps, mapNames
end

function isMapCompatibleWithGamemode(mapName, gamemodeFilter)
	if type(mapName) == "string" then
		if type(gamemodeFilter) == "table" then
			for i, gamemode in pairs(gamemodeFilter) do
				if string.find(mapName:lower(), gamemode:lower(), 1, true) then
					return true
				end
			end
		elseif type(gamemodeFilter) == "string" and string.find(mapName:lower(), gamemodeFilter:lower(), 1, true) then
			return true
		end
	end
	return false
end

function refreshMaps(arena)
	refreshResources()
	triggerEvent("mapmanager:onMapsRefresh", isElement(arena) and arena or root)
	outputDebugString("Refreshed maps", 0, 25, 132, 109)
end

addCommandHandler("refreshmaps",
function(player, command, refreshAll)
	if hasObjectPermissionTo(player, "function.kickPlayer", true) then
		outputDebugString(getPlayerName(player):gsub("#%x%x%x%x%x%x", "").." is refreshing maps for "..(refreshAll == "all" and "all arenas" or getElementData(player, "arena")), 0, 25, 132, 109)
		refreshMaps(refreshAll == "all" and root or getElementParent(player))
	end
end)

function cancelLatentsForPlayer(player)
	if isElement(player) then
		local eventHandles = getLatentEventHandles(player)
		if eventHandles then
			for i = 1, #eventHandles do
				cancelLatentEvent(player, eventHandles[i])
			end
		end
	end
end

-- Dimension updates
addEventHandler("onPlayerSpawn", root,
function()
	local arena = core.arenas[tostring(getElementData(source, "arena"))]
	if arena then
		setElementDimension(source, arena.dimension)
	end
end)

addEventHandler("onVehicleEnter", root,
function(player, seat)
	if seat == 0 then
		local arena = core.arenas[tostring(getElementData(player, "arena"))]
		if arena then
			setElementDimension(player, arena.dimension)
			setElementDimension(source, arena.dimension)
		end
		setVehiclePlateText(source, getPlayerName(player):gsub("#%x%x%x%x%x%x", ""))
	end
end)