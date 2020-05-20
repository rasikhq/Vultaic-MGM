local shaders = {}
local overlaysAmount = 45
local models = {
	[411] = true,
	[472] = true,
	[462] = true,
	[530] = true,
	[463] = true,
	[595] = true,
	[572] = true,
	[515] = true
}
addEvent("custom:onClientVehicleStreamIn", true)
addEvent("custom:onClientPlayerVehicleEnter", true)

-- Toggle
function toggleFeature(state)
	featureEnabled = state
	print("Toggled overlays: "..tostring(featureEnabled))
	removeEventHandler("custom:onClientVehicleStreamIn", root, updateVehicleOverlays)
	removeEventHandler("custom:onClientPlayerVehicleEnter", root, updateVehicleOverlays)
	removeEventHandler("onClientElementDataChange", root, handleDataChange)
	removeEventHandler("onClientPreRender", root, renderOverlays)
	if featureEnabled then
		for i, vehicle in pairs(getElementsByType("vehicle")) do
			if isElementStreamedIn(vehicle) then
				updateVehicleOverlays(vehicle, getVehicleOccupant(vehicle))
			end
		end
		addEventHandler("custom:onClientVehicleStreamIn", root, updateVehicleOverlays, true, "low")
		addEventHandler("custom:onClientPlayerVehicleEnter", root, updateVehicleOverlays, true, "low")
		addEventHandler("onClientElementDataChange", root, handleDataChange, true, "low")
		addEventHandler("onClientPreRender", root, renderOverlays)
	else
		clearAllOverlays()
	end
end

function initOverlays()
	setElementData(localPlayer, "totalOverlays", overlaysAmount, false)
	local state = not (exports.v_settings:getClientVariable("disable_overlays") == "Off")
	toggleFeature(state)
end
addEventHandler("onClientResourceStart", resourceRoot, initOverlays)
addEventHandler("onClientRestore", root, initOverlays)

addEvent("settings:onSettingChange", true)
addEventHandler("settings:onSettingChange", localPlayer,
function(variable, value)
	if variable == "disable_overlays" then
		initOverlays()
	end
end)

function updateVehicleOverlays(vehicle, player)
	if isElement(player) and isElement(vehicle) then
		local overlay = getElementData(player, "overlay")
		if not overlay or type(overlay) ~= "table" then
			return destroyVehicleOverlays(player)
		end
		if not models[getElementModel(vehicle)] then
			if shaders[player] then
				engineRemoveShaderFromWorldTexture(shaders[player].shader, "vehiclegrunge256", vehicle)
			end
			return
		end
		local _type = tonumber(overlay.overlay_type) or nil
		if not _type then			
			return destroyVehicleOverlays(player)
		end
		local path = "fx/type".._type..".fx"
		if not fileExists(path) then
			return destroyVehicleOverlays(player)
		end
		if not shaders[player] then
			shaders[player] = {}
			print("Created overlays for "..getPlayerName(player))
		end
		if isElement(shaders[player].shader) then
			destroyElement(shaders[player].shader)
			shaders[player].type = _type
			shaders[player].nobeat = overlay.overlay_nobeat == 1
		end
		if not isElement(shaders[player].shader) then
			shaders[player].shader = dxCreateShader(path, 10, 80, true, "vehicle")
			if not isElement(shaders[player].shader) then
				destroyVehicleOverlays(player)
				return print("Failed to create overlay shader for "..getPlayerName(player))
			end
		end
		local hex = overlay.overlay_color or "#FFFFFF"
		local r, g, b = hexToRGB(hex)		
		shaders[player].opacity = tonumber(overlay.overlay_opacity or 0.5)
		shaders[player].rate = tonumber(overlay.overlay_rate or 0.5)
		dxSetShaderValue(shaders[player].shader, "color", r/255, g/255, b/255)
		dxSetShaderValue(shaders[player].shader, "rate", shaders[player].rate)
		engineApplyShaderToWorldTexture(shaders[player].shader, "vehiclegrunge256", vehicle, true)
		if overlay.overlay_nobeat and overlay.overlay_nobeat == 1 then
			shaders[player].nobeat = true
		end
	end
end

function handleDataChange(dataName)
	if dataName == "overlay" and isElementStreamedIn(source) then
		updateVehicleOverlays(getPedOccupiedVehicle(source), source)
	end
end

function destroyVehicleOverlays(player)
	if isElement(player) and shaders[player] then
		for i, v in pairs(shaders[player]) do
			if isElement(v) then
				destroyElement(v)
			end
		end
		shaders[player] = nil
		print("Destroyed overlays for "..getPlayerName(player))
	end
end
addEvent("overlays:destroyVehicleOverlays", true)
addEventHandler("overlays:destroyVehicleOverlays", resourceRoot, destroyVehicleOverlays)

function clearAllOverlays()
	for player in pairs(shaders) do
		for i, v in pairs(shaders[player]) do
			if isElement(v) then
				destroyElement(v)
			end
		end
	end
	shaders = {}
	print("Cleared all overlays")
end
addEvent("core:onClientLeaveArena", true)
addEventHandler("core:onClientLeaveArena", localPlayer, clearAllOverlays)
addEventHandler("onClientResourceStop", resourceRoot, clearAllOverlays)

function renderOverlays()
	local sound = getActiveGlobalSound()
	if not isElement(sound) then
		return
	end
 	local fft = getSoundFFTData(sound, 2048, 257) or {}
	local average = 0
	for i = 1, #fft/2 do
		average = average + fft[i]
	end
	average = average/3
	for player in pairs(shaders) do
		while true do
			if not isElement(player) then
				destroyVehicleOverlays(player)
				break
			end
			local vehicle = getPedOccupiedVehicle(player)
			if not isElement(vehicle) then
				break
			end
			local alpha = tonumber(getElementAlpha(vehicle) or 255)/255
			local data = shaders[player]
			dxSetShaderValue(data.shader, "intensity", data.nobeat and 1 or average)
			dxSetShaderValue(data.shader, "opacity", data.opacity * alpha)
			break
		end
	end
end

function getElementSpeed(element)
    return isElement(element) and (Vector3(getElementVelocity(element))).length or 0
end

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

function getActiveGlobalSound()
	local soundType = getElementData(localPlayer, "sound_mode")
	for i, sound in pairs(getElementsByType("sound")) do
		if getElementData(sound, "sound_type") == soundType then
			return sound
		end
	end
end