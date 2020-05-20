local replaceTable = {{"infernus", 411}}
local components = {
	bumper_front = {"Tune_BumperF", 0, 4},
	bumper_rear = {"Tune_BumperR", 0, 4},
	side_skirt = {"Tune_Skirt", 1, 2},
	cover_headlights = {"Tune_HLCover", 1, 3},
	cover_taillights = {"Tune_TLCover", 1, 3},
	spoiler = {"Tune_Spoiler", 1, 6}
}
addEvent("custom:onClientVehicleStreamIn", true)
addEvent("custom:onClientPlayerVehicleEnter", true)

addEventHandler("onClientResourceStart", resourceRoot,
function()
	local key = "fFssUx"
	for k, v in pairs(replaceTable) do
		local txd, dff = "model/"..v[1]..".txd.c", "model/"..v[1]..".dff.c"
		local txdFile = fileExists(txd) and fileOpen(txd, true)
		local dffFile = fileExists(dff) and fileOpen(dff, true)
		if txdFile then
			local txdContent = fileRead(txdFile, fileGetSize(txdFile))
			if txdContent then
				local decryptedString = base64Decode(teaDecode(txdContent, key))
				if decryptedString then
					local tempTXD = fileCreate("temp_"..v[1]..".txd")
					if tempTXD then
						fileWrite(tempTXD, decryptedString)
						fileClose(tempTXD)
					end
					local txd = engineLoadTXD("temp_"..v[1]..".txd")
					if txd then
						engineImportTXD(txd, v[2])
					end
					fileDelete("temp_"..v[1]..".txd")
				end
			end
			fileClose(txdFile)
		end
		if dffFile then
			local dffContent = fileRead(dffFile, fileGetSize(dffFile))
			if dffContent then
				local decryptedString = base64Decode(teaDecode(dffContent, key))
				if decryptedString then
					local tempDFF = fileCreate("temp_"..v[1]..".dff")
					if tempDFF then
						fileWrite(tempDFF, decryptedString)
						fileClose(tempDFF)
					end
					local dff = engineLoadDFF("temp_"..v[1]..".dff")
					if dff then
						engineReplaceModel(dff, v[2])
					end
					fileDelete("temp_"..v[1]..".dff")
				end
			end
			fileClose(dffFile)
		end
	end
	setTimer(function()
		for i, vehicle in pairs(getElementsByType("vehicle")) do
			if isElementStreamedIn(vehicle) then
				updateVehicleComponents(vehicle)
			end
		end
	end, 1000, 1)
	key = nil
end)

function updateVehicleComponents(vehicle, player)
	if isElement(vehicle) then
		local player = isElement(player) and player or getVehicleOccupant(vehicle)
		if not isElement(player) then
			return
		end
		if getElementModel(vehicle) == 411 then
			local _data = getElementData(player, "bodyparts") or {}
			for prefix, data in pairs(components) do
				for i = data[2], data[3] do
					setVehicleComponentVisible(vehicle, data[1]..i, tonumber(_data[prefix] or 0) == i)
				end
			end
			local roof = tonumber(_data.roof or 0)
			local podium = tonumber(_data.podium or 1)
			local spoiler = tonumber(_data.spoiler or 0)
			local spoilerNoneState, spoilerState, podiumState = false, false, false
			if spoiler == 0 then
				spoilerState = true
				if podium == 1 then
					podiumState = true
				end
			else
				if podium == 1 then
					podiumState = true
				else
					spoilerNoneState = true
				end
			end
			setVehicleComponentVisible(vehicle, "Tune_Roof0", roof == 0)
			setVehicleComponentVisible(vehicle, "Tune_Roof1", roof == 1)			
			setVehicleComponentVisible(vehicle, "Tune_SpoilerNone", spoilerNoneState)
			setVehicleComponentVisible(vehicle, "Tune_Spoiler0", spoilerState)
			setVehicleComponentVisible(vehicle, "Tune_SpoilerPodium", podiumState)
		end
	end
end
addEventHandler("custom:onClientVehicleStreamIn", root, updateVehicleComponents)
addEventHandler("custom:onClientPlayerVehicleEnter", root, updateVehicleComponents)

addEvent("onClientElementModelChange", true)
addEventHandler("onClientElementModelChange", root,
function()
	if getElementType(source) == "vehicle" then
		updateVehicleComponents(source)
	end
end)

addEventHandler("onClientElementDataChange", root,
function(dataName)
	if getElementType(source) == "player" and isElementStreamedIn(source) and dataName == "bodyparts" then
		updateVehicleComponents(getPedOccupiedVehicle(source), source)
	end
end)

_getVehicleOccupant = getVehicleOccupant
function getVehicleOccupant(vehicle)
	if isElement(vehicle) and getElementType(vehicle) == "vehicle" then
		if getElementData(vehicle, "garage.vehicle") then
			return localPlayer
		end
		return _getVehicleOccupant(vehicle)
	end
end

_getPedOccupiedVehicle = getPedOccupiedVehicle
function getPedOccupiedVehicle(player)
	if isElement(player) then
		if player == localPlayer then
			local garageVehicle = getElementData(localPlayer, "garage.vehicle")
			return isElement(garageVehicle) and garageVehicle or _getPedOccupiedVehicle(localPlayer)
		else
			return _getPedOccupiedVehicle(player)
		end
	end
end