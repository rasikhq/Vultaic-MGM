local shaders, data, dynamicTable = {}, {}, {}
textures = {}
dynamicTextures = {}
addEvent("custom:onClientVehicleStreamIn", true)
addEvent("custom:onClientPlayerVehicleEnter", true)
addEvent("custom:onClientVehicleModelChange", true)

function initLights()
	local metaFile = xmlLoadFile("meta.xml")
	if metaFile then
		for i, node in pairs (xmlNodeGetChildren(metaFile)) do
			local info = xmlNodeGetAttributes(node)
			if xmlNodeGetName(node) == "file" then
				if info["light"] then
					local path = string.sub(info["src"], 5, string.len(info["src"]) - 4)
					table.insert(textures, path)
				elseif info["dynamic"] then
					local path = string.sub(info["src"], 11, string.len(info["src"]) - 3)
					table.insert(dynamicTextures, path)
				end
			end
		end
		xmlUnloadFile(metaFile)
	end
	triggerEvent("lights:onUpdateLightTextures", localPlayer, textures, dynamicTextures)
	for i, vehicle in pairs(getElementsByType("vehicle")) do
		if isElementStreamedIn(vehicle) then
			loadVehicleLights(vehicle, getVehicleOccupant(vehicle))
		end
	end
end
addEventHandler("onClientResourceStart", resourceRoot, initLights)

function loadVehicleLights(vehicle, player)
	if isElement(player) and isElement(vehicle) then
		local lights = getElementData(player, "lights")
		if not lights or type(lights) ~= "table" then
			return unloadVehicleLights(player, vehicle)
		end
		local _type = lights.lights_type or nil
		if not _type or _type == 0 then
			return unloadVehicleLights(player, vehicle)
		end
		local dynamic = tonumber(lights.lights_dynamic or 0)
		if dynamic == 1 then
			local path = "fx/dynamic".._type..".fx"
			if not fileExists(path) then
				return unloadVehicleLights(player, vehicle)
			end
			if not shaders[player] or not dynamicTable[player] or dynamicTable[player].type ~= _type or not dynamicTable[player] or dynamicTable[player].vehicle ~= vehicle then
				if shaders[player] then
					destroyElement(shaders[player])
				end
				shaders[player] = dxCreateShader(path, 10, 80, false, "vehicle")
				engineApplyShaderToWorldTexture(shaders[player], "vehiclelightson128", vehicle)
				engineApplyShaderToWorldTexture(shaders[player], "taillights_dummy", vehicle)
				dynamicTable[player] = {}
				dynamicTable[player].shader = shaders[player]
				dynamicTable[player].type = _type
				dynamicTable[player].vehicle = vehicle
				--print("Created dynamic texture: "..path.." for player "..getPlayerName(player))
			end
			local hex = lights.lights_color or "#FFFFFF"
			local r, g, b = hexToRGB(hex)
			dxSetShaderValue(shaders[player], "color", r/255, g/255, b/255)
		else
			unloadVehicleLights(player, vehicle)
			local path = "img/".._type..".png"
			if not fileExists(path) then
				return
			end
			if not data[path] then
				data[path] = {}
				data[path].shader = dxCreateShader("fx/lights.fx", 10, 80, false, "vehicle")
				data[path].texture = dxCreateTexture(path)
				dxSetShaderValue(data[path].shader, "gTexture", data[path].texture)
				--print("Created light texture: "..path)
			end
			local current = shaders[player]
			if current then
				engineRemoveShaderFromWorldTexture(data[current].shader, "vehiclelights128", vehicle)
				engineRemoveShaderFromWorldTexture(data[current].shader, "vehiclelightson128", vehicle)
			end
			shaders[player] = path
			engineApplyShaderToWorldTexture(data[path].shader, "vehiclelights128", vehicle)
			engineApplyShaderToWorldTexture(data[path].shader, "vehiclelightson128", vehicle)
		end
	end
end
addEventHandler("custom:onClientVehicleStreamIn", root, loadVehicleLights, true)
addEventHandler("custom:onClientPlayerVehicleEnter", root, loadVehicleLights, true)

function unloadVehicleLights(player, vehicle)
	if isElement(player) and shaders[player] then
		local vehicle = isElement(vehicle) and vehicle or getPedOccupiedVehicle(player)
		if data[shaders[player]] and isElement(vehicle) then
			engineRemoveShaderFromWorldTexture(data[shaders[player]].shader, "vehiclelights128", vehicle)
			engineRemoveShaderFromWorldTexture(data[shaders[player]].shader, "vehiclelightson128", vehicle)
		end
		if isElement(shaders[player]) then
			destroyElement(shaders[player])
		end
		shaders[player] = nil
		dynamicTable[player] = nil
		--print("Unloaded lights for "..getPlayerName(player))
	end
end

function destroyAllLights()
	for path in pairs(data) do
		destroyElement(data[path].shader)
		destroyElement(data[path].texture)
	end
	shaders, data, dynamicTable = {}, {}, {}
	--print("Destroyed all lights")
end
addEvent("core:onClientLeaveArena", true)
addEventHandler("core:onClientLeaveArena", localPlayer, destroyAllLights)

function getElementSpeed(element)
    return isElement(element) and (Vector3(getElementVelocity(element))).length or 0
end

function renderDynamicLights()
	local sound = getActiveGlobalSound()
	if not isElement(sound) then
		return
	end
 	local ls, rs = getSoundLevelData(sound)
	ls, rs = tonumber(ls or 1)/32768, tonumber(rs or 1)/32768
	local average = 0.1 + ls * rs
	for player in pairs(dynamicTable) do
		while true do
			if not isElement(player) then
				unloadVehicleLights(player)
				break
			end
			local vehicle = getPedOccupiedVehicle(player)
			if not isElement(vehicle) then
				unloadVehicleLights(player)
				break
			end
			local data = dynamicTable[player]
			dxSetShaderValue(data.shader, "intensity", data.nobeat and 1 or average)
			dxSetShaderValue(data.shader, "speed", data.nobeat and 1 or getElementSpeed(vehicle))
			break
		end
	end
end
addEventHandler("onClientPreRender", root, renderDynamicLights)

function handleDataChange(dataName)
	if dataName == "lights" and getElementType(source) == "player" and isElementStreamedIn(source) then
		loadVehicleLights(getPedOccupiedVehicle(source), source)
	end
end
addEventHandler("onClientElementDataChange", root, handleDataChange)

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

function hexToRGB(hex)
	hex = hex:gsub("#", "") 
	return tonumber("0x"..hex:sub(1, 2)) or 255, tonumber("0x"..hex:sub(3, 4)) or 255, tonumber("0x"..hex:sub(5, 6)) or 255
end

function getLightTextures()
	return textures
end

function getDynamicLightTextures()
	return dynamicTextures
end

function hexToRGB(hex)
	hex = hex:gsub("#", "") 
	return tonumber("0x"..hex:sub(1, 2)) or 255, tonumber("0x"..hex:sub(3, 4)) or 255, tonumber("0x"..hex:sub(5, 6)) or 255
end

function getActiveGlobalSound()
	local soundType = getElementData(localPlayer, "sound_mode")
	for i, sound in pairs(getElementsByType("sound")) do
		if getElementData(sound, "sound_type") == soundType then
			return sound
		end
	end
end