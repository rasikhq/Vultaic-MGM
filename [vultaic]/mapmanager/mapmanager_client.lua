local mapData = {}
local activeDownloadQueue = {}
local IDForMarkerType = {
	[1] = "checkpoint",
	[2] = "ring",
	[3] = "cylinder",
	[4] = "arrow",
	[5] = "corona"
}

function setDownloadProgress(...)
	triggerEvent("fade:setProgress", localPlayer, ...)
end

local rampFile, rampFileData = fileOpen("model/garys_luv_ramp.col", true)
if rampFile then
	rampFileData = fileRead(rampFile, fileGetSize(rampFile))
	fileClose(rampFile)
end

function downloadMap(resourceName, elementsURL, storageURL, key, scripts, files, info, settings)
	unloadMap()
	setDownloadProgress(0)
	if type(resourceName) == "string" then
		mapData.resourceName = resourceName
		mapData.resourceNameHash = md5(resourceName)
		mapData.elementsURL = elementsURL
		mapData.storageURL = storageURL
		mapData.scripts = scripts
		mapData.files = files
		mapData.info = info
		mapData.settings = settings
		if settings["time"] then
			local _time = split(settings["time"], string.byte(":"))
			setTime(_time[1], _time[2])
		end
		if settings["weather"] then
			setWeather(settings["weather"])
		end
		if settings["duration"] then
			if settings["locked_time"] then
				setMinuteDuration(6000000)
			else
				setMinuteDuration(settings["duration"])
			end
		end
		if settings["gamespeed"] then
			setGameSpeed(settings["gamespeed"])
		end
		if settings["gravity"] then
			setGravity(settings["gravity"])
		end
		if settings["waveheight"] then
			setWaveHeight(0)
		end
		local mapWasReadFromCache = false
		if type(key) == "string" then
			local elementsCacheFile = nil
			if fileExists("cache/"..mapData.resourceNameHash..".edk") then
				elementsCacheFile = fileOpen("cache/"..mapData.resourceNameHash..".edk", true)
			end
			if elementsCacheFile then
				outputDebugString("Cached file exists for "..resourceName, 0, 255, 255, 255)
				-- Optimization: table.concat
				local content = {}
				while not fileIsEOF(elementsCacheFile) do
					table.insert(content, fileRead(elementsCacheFile, 1024))
				end
				content = table.concat(content, "")
				local decryptedString = teaDecode(content, key)
				if decryptedString then
					local elements = fromJSON(decryptedString)
					if type(elements) == "table" then
						loadMap(elements)
						mapWasReadFromCache = true
					end
				end
				fileClose(elementsCacheFile)
			end
		end
		if not mapWasReadFromCache then
			outputDebugString("Downloading elements for "..resourceName, 0, 255, 255, 255)
			fetchRemote(elementsURL, mapData.resourceNameHash, 1, saveMapElements, "", false, resourceName, key, getTickCount())
		end
	end
end
addEvent("downloadMap", true)
addEventHandler("downloadMap", resourceRoot, downloadMap)

function saveMapElements(responseData, errorNo, resourceName, key, startTick)
	local resourceNameHash = md5(resourceName)
	if errorNo == 0 then
		local savePath = "cache/"..resourceNameHash..".edk"
		filePut(savePath, responseData)
		outputDebugString("Downloaded & cached elements for "..resourceName.." in "..getTickCount() - startTick.." ms", 0, 255, 255, 255)
		if resourceName == mapData.resourceName then
			local decryptedString = teaDecode(responseData, key)
			if decryptedString then
				local elements = fromJSON(decryptedString)
				if type(elements) == "table" then
					loadMap(elements)
				end
			end
		end
	else
		outputDebugString("Failed to download map elements for "..resourceName.." [Error no: "..errorNo..", failed in: "..tostring((getTickCount() - startTick)/1000).." s, response: "..responseData.."]", 0, 255, 155, 55)
		if resourceName == mapData.resourceName and (errorNo == 200 or errorNo == 28) then
			outputDebugString("Retrying to download map elements...")
			fetchRemote(mapData.elementsURL, resourceNameHash, 1, saveMapElements, "", false, resourceName, key, startTick)
		end
	end
end

function buildMapCheckpoints(data)
	if type(data) == "table" then
		local checkpoints = {}
		for i = 1, #data[1] do
			checkpoints[#checkpoints + 1] = {
				data[1][i],
				data[2][i],
				data[3][i],
				data[4][i],
				data[5][i],
				data[6][i],
				data[7][i],
				data[8][i],
				data[9][i],
				data[10][i],
				data[11][i]
			}
		end
		if #checkpoints > 0 then
			createCheckpoints(checkpoints)
		end
	end
end
					
function buildMapObjects(data)
	if type(data) == "table" then
		local createObject = createObject
		local setElementAlpha = setElementAlpha
		local setElementCollisionsEnabled = setElementCollisionsEnabled
		local setObjectScale = setObjectScale
		local setElementInterior = setElementInterior
		local setElementDoubleSided = setElementDoubleSided
		local object = nil
		for i = 1, #data[1] do
			object = createObject(data[1][i], data[2][i], data[3][i], data[4][i], data[5][i], data[6][i], data[7][i])
			if object then
				if data[8][i] ~= 255 then
					setElementAlpha(object, data[8][i])
				end
				if data[9][i] == 0 then
					setElementCollisionsEnabled(object, false)
				end
				if data[10][i] ~= 1 then
					setObjectScale(object, data[10][i])
				end
				if data[11][i] ~= 0 then
					setElementInterior(object, data[11][i])
				end
				if data[12][i] == 1 then
					setElementDoubleSided(object, true)
				end
				--mapData.objectRotations[object] = {data[5][i], data[6][i], data[7][i]}
				setElementParent(object, mapData.parents.objects)
			end
		end
	end
end

function buildMapMarkers(data)
	if type(data) == "table" then
		local createMarker = createMarker
		local setMarkerColor = setMarkerColor
		local setElementID = setElementID
		local marker = nil
		for i = 1, #data[1] do
			local markerIDtype = data[4][i]
			local markerType = IDForMarkerType[markerIDtype]
			marker = createMarker(data[1][i], data[2][i], data[3][i], markerType, data[5][i], 255, 255, 255, 255)
			if marker then
				if data[6][i] ~= 0 then
					setMarkerColor(marker, hexToRGB(data[6][i]))
				end
				if data[7][i] ~= 0 then
					setElementID(marker, data[7][i])
				end
				setElementParent(marker, mapData.parents.markers)
			end
		end
	end
end

function buildMapVehicles(data)
	if type(data) == "table" then
		local createVehicle = createVehicle
		local setElementFrozen = setElementFrozen
		local setElementCollisionsEnabled = setElementCollisionsEnabled
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
					mapData.vehicleColors[vehicle] = color
				end
				setElementParent(vehicle, mapData.parents.vehicles)
			end
		end
	end
end

function buildMapPeds(data)
	if type(data) == "table" then
		local createPed = createPed
		local setElementInterior = setElementInterior
		local setElementFrozen = setElementFrozen
		local setElementCollisionsEnabled = setElementCollisionsEnabled
		local ped = nil
		for i = 1, #data[1] do
			ped = createPed(data[1][i], data[2][i], data[3][i], data[4][i], data[5][i])
			if ped then
				if data[6][i] ~= 0 then
					setElementInterior(ped, data[6][i])
				end
				if data[7][i] == 1 then
					setElementFrozen(ped, true)
				end
				setElementCollisionsEnabled(ped, false)
				setElementParent(ped, mapData.parents.peds)
			end
		end
	end
end

function buildMapRacepickups(data)
	if type(data) == "table" then
		for i = 1, #data[1] do
			createRacePickup(data[1][i], data[2][i], data[3][i], data[4][i], data[5][i], data[6][i], data[7][i], data[8][i])
		end
	end
end

function buildMapRemoveWorldModels(data)
	if type(data) == "table" then
		for i = 1, #data[1] do
			removeWorldModel(data[1][i], data[2][i], data[3][i], data[4][i], data[5][i], data[6][i])
			if data[7] and data[7][i] then
				removeWorldModel(data[7][i], data[2][i], data[3][i], data[4][i], data[5][i], data[6][i])
			end
		end
	end
end

function buildMapDataDependent(class, data)
	if type(data) == "table" then
		local createElement = createElement
		local setElementData = setElementData
		local setElementPosition = setElementPosition
		local setElementRotation = setElementRotation
		local element = nil
		for i = 1, #data do
			local v = data[i]
			local id = v.id
			element = createElement(class, id)
			for k, v in pairs(v) do
				setElementData(element, k, v, false)
			end
			local posX, posY, posZ = v.posX or 0, v.posY or 0, v.posZ or 0
			local rotX, rotY, rotZ = v.rotX or 0, v.rotY or 0, v.rotZ or 0
			setElementPosition(element, posX, posY, posZ)
			setElementRotation(element, rotX, rotY, rotZ)
			setElementParent(element, mapData.parents.misc)
		end
	end
end

function loadMap(data)
	if type(data) == "table" then
		local dimension = getElementDimension(localPlayer)
		local startTick = getTickCount()
		local arenaData = exports.core:getClientArenaData()
		if arenaData.checkpointsEnabled or getElementData(localPlayer, "checkpointsEnabled") then
			buildMapCheckpoints(data.checkpoint)
		end
		if(data.spawnpoint) then
			for i, spawnpoint in pairs(data.spawnpoint) do
				local element = createElement("mapmanager:spawnpoint")
				if element then
					setElementData(element, "model", spawnpoint[1])
					setElementData(element, "posX", spawnpoint[2])
					setElementData(element, "posY", spawnpoint[3])
					setElementData(element, "posZ", spawnpoint[4])
					setElementData(element, "rotX", spawnpoint[5])
					setElementData(element, "rotY", spawnpoint[6])
					setElementData(element, "rotZ", spawnpoint[7])
					setElementParent(element, mapData.parents.spawnpoints)
				end
			end
		else
			data.spawnpoint = {}
		end
		buildMapObjects(data.object)
		buildMapMarkers(data.marker)
		if not mapData.settings.not_create_vehicles then
			buildMapVehicles(data.vehicle)
		end
		buildMapPeds(data.ped)
		buildMapRacepickups(data.racepickup)
		buildMapRemoveWorldModels(data.removeWorldObject)
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
		for name, _ in pairs(dataDependent) do
			buildMapDataDependent(name, data[name])
		end
		--removeEventHandler("onClientElementStreamIn", mapData.parents.objects, fixObjectRotation)
		--addEventHandler("onClientElementStreamIn", mapData.parents.objects, fixObjectRotation)
		removeEventHandler("onClientElementStreamIn", mapData.parents.vehicles, fixVehicleColor)
		addEventHandler("onClientElementStreamIn", mapData.parents.vehicles, fixVehicleColor, true, "high+5")
		local dimension = getElementDimension(localPlayer)
		for i, element in pairs(mapData.parents) do
			if isElement(element) then
				setElementDimension(element, dimension)
			end
		end
		triggerEvent("mapmanager:onMapLoad", localPlayer)
		triggerServerEvent("onPlayerCompleteDownload", localPlayer)
		setElementData(localPlayer, "client.mapLoaded", true, false)
		outputDebugString("Map container has loaded in "..getTickCount() - startTick.." ms", 0, 255, 255, 255)
		checkFiles()
	end
end

--[[function fixObjectRotation()
	if mapData.objectRotations[source] then
		local rotX, rotY, rotZ = unpack(mapData.objectRotations[source])
		setElementRotation(source, rotX, rotY, rotZ)
		mapData.objectRotations[source] = nil
	end
end]]--

function fixVehicleColor()
	local vehicleColor = mapData.vehicleColors[source]
	if vehicleColor then
		setVehicleColor(source, unpack(vehicleColor))
		mapData.vehicleColors[source] = nil
	end
	if getVehicleType(source) == "Train" then
		setTrainDerailed(source, false)
	end
end

function resetParents()
	if mapData.parents then
		for i, element in pairs(mapData.parents) do
			if isElement(element) then
				destroyElement(element)
			end
		end
	end
	mapData.parents = {}
	mapData.parents.spawnpoints = createElement("arena.map", "mapmanager.spawnpoints")
	mapData.parents.objects = createElement("arena.map", "mapmanager.objects")
	mapData.parents.markers = createElement("arena.map", "mapmanager.markers")
	mapData.parents.vehicles = createElement("arena.map", "mapmanager.vehicles")
	mapData.parents.peds = createElement("arena.map", "mapmanager.peds")
	mapData.parents.misc = createElement("arena.map", "mapmanager.misc")
end

function unloadMap()
	local startTick = getTickCount()
	triggerEvent("sandbox:unload", localPlayer)
	destroyCheckpoints()
	destroyRacePickups()
	mapData.resourceName = nil
	mapData.resourceNameHash = nil
	mapData.elementsURL = nil
	mapData.storageURL = nil
	mapData.scripts = nil
	mapData.files = nil
	mapData.info = nil
	mapData.settings = nil
	--mapData.objectRotations = {}
	mapData.vehicleColors = {}
	mapData.filesToDownload = 0
	resetParents()
	activeDownloadQueue = {}
	savedCheckpoints = nil
	if rampFileData then
		engineReplaceCOL(engineLoadCOL(rampFileData), 1894)
	end
	triggerEvent("mapmanager:onMapUnload", localPlayer)
	setElementData(localPlayer, "client.mapLoaded", false, false)
	outputDebugString("Map container has been reset for "..getTickCount() - startTick.." ms", 0, 255, 255, 255)
end
addEvent("unloadMap", true)
addEventHandler("unloadMap", root, unloadMap)
addEvent("core:onClientLeaveArena", true)
addEventHandler("core:onClientLeaveArena", localPlayer, unloadMap)
addEventHandler("onClientResourceStop", resourceRoot, unloadMap)

function checkFiles()
	local resourceNameHash = md5(mapData.resourceName)
	local filesToDownload = {}
	local added = {}
	if mapData.scripts then
		for i, script in pairs(mapData.scripts) do
			local path = script.src
			local size = script.size
			local _file = nil
			if fileExists(resourceNameHash.."/"..path) then
				_file = fileOpen(resourceNameHash.."/"..path, true)
			end
			if _file then
				if fileGetSize(_file) ~= size then
					if not added[path] then
						table.insert(filesToDownload, {path = path, size = size})
						added[path] = true
					end
				end
				fileClose(_file)
			else
				if not added[path] then
					table.insert(filesToDownload, {path = path, size = size})
					added[path] = true
				end
			end
		end
	end
	if mapData.files then
		for i, file in pairs(mapData.files) do
			local path = file.src
			local size = file.size
			local _file = nil
			if fileExists(resourceNameHash.."/"..path) then
				_file = fileOpen(resourceNameHash.."/"..path, true)
			end
			if _file then
				if fileGetSize(_file) ~= size then
					if not added[path] then
						table.insert(filesToDownload, {path = path, size = size})
						added[path] = true
					end
				end
				fileClose(_file)
			else
				if not added[path] then
					table.insert(filesToDownload, {path = path, size = size})
					added[path] = true
				end
			end
		end
	end
	if #filesToDownload > 0 then
		mapData.filesToDownload = #filesToDownload
		downloadFiles(filesToDownload)
	else
		mapData.filesToDownload = 0
		outputDebugString("Nothing to fetch, loading sandbox...", 0, 105, 205, 105)
		setDownloadProgress(1)
		loadScripts()
	end
end

function downloadFiles(files)
	if type(files) == "table" and type(mapData.storageURL) == "string" then
		mapData.downloadedFiles = 0
		outputDebugString("Downloading "..#files.." file"..(#files > 1 and "s" or "").." for "..mapData.resourceName, 0, 105, 205, 105)
		for i, file in pairs(files) do
			local fileNameHash = md5(mapData.resourceName..file.path)
			if not activeDownloadQueue[fileNameHash] then
				fetchRemote(mapData.storageURL.."/"..file.path, fileNameHash, 1, 10000, saveDownloadedFile, "", false, mapData.resourceName, file.path, file.size, mapData.storageURL.."/"..file.path)
				activeDownloadQueue[fileNameHash] = true
			else
				outputDebugString("A download for file "..file.path.." is already active", 0, 105, 205, 105)
			end
		end
	end
end

function saveDownloadedFile(responseData, errorNo, resourceName, path, size, url)
	local fileNameHash = md5(resourceName..path)
	if errorNo == 0 then
		local resourceNameHash = md5(resourceName)
		local savePath = resourceNameHash.."/"..path
		filePut(savePath, responseData)
		outputDebugString("Saved file "..path, 0, 255, 255, 255)
		if resourceName == mapData.resourceName then
			mapData.downloadedFiles = mapData.downloadedFiles + 1
			outputDebugString("Downloaded file: "..mapData.downloadedFiles.." from "..mapData.filesToDownload, 0, 105, 205, 105)
			if mapData.downloadedFiles == mapData.filesToDownload then
				outputDebugString("All files were downloaded, loading sandbox...", 0, 105, 205, 105)
				setDownloadProgress(1)
				loadScripts()
			else
				setDownloadProgress(mapData.downloadedFiles/mapData.filesToDownload)
			end
		end
	else
		outputDebugString("Failed to download file "..path.." [Error no: "..errorNo..", response: "..responseData.."]", 0, 255, 155, 55)
		if resourceName == mapData.resourceName then
			if url and (errorNo == 200 or errorNo == 28) then
				fetchRemote(url, fileNameHash, 1, 10000, saveDownloadedFile, "", false, resourceName, path, size, url)
				outputDebugString("Retrying...", 0, 255, 155, 55)
			else
				mapData.downloadedFiles = mapData.downloadedFiles + 1
				if mapData.downloadedFiles == mapData.filesToDownload then
					outputDebugString("All downloadable files were downloaded, loading sandbox...", 0, 105, 205, 105)
					setDownloadProgress(1)
					loadScripts()
				else
					setDownloadProgress(mapData.downloadedFiles/mapData.filesToDownload)
				end
			end
		end
		return
	end
	if activeDownloadQueue[fileNameHash] then
		activeDownloadQueue[fileNameHash] = nil
	end
end

function loadScripts()
	local resourceNameHash = md5(mapData.resourceName)
	local scripts = {}
	for i, script in pairs(mapData.scripts) do
		local path = resourceNameHash.."/"..script.src
		if fileExists(path) then
			local file = fileOpen(resourceNameHash.."/"..script.src, true)
			if file then
				local content = fileRead(file, fileGetSize(file))
				table.insert(scripts, content)
				fileClose(file)
			end
		end
	end
	triggerEvent("sandbox:load", localPlayer, scripts, resourceNameHash, mapData.resourceName)
end