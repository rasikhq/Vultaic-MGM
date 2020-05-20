addEvent("custom:onClientVehicleStreamIn", true)
addEvent("custom:onClientVehicleStreamOut", true)
addEvent("custom:onClientPlayerVehicleEnter", true)
addEvent("custom:onClientVehicleModelChange", true)
local streamed = {}

-- Stream in
addEventHandler("onClientElementStreamIn", root,
function()
	if getElementType(source) == "vehicle" and not streamed[source] then
		local occupant = getVehicleOccupant(source)
		triggerEvent("custom:onClientVehicleStreamIn", localPlayer, source, occupant)
	end
end)

-- Stream out
addEventHandler("onClientElementStreamOut", root,
function()
	if getElementType(source) == "vehicle" then
		local occupant = getVehicleOccupant(source)
		triggerEvent("custom:onClientVehicleStreamOut", localPlayer, source, occupant)
	end
end)

-- Vehicle enter
addEventHandler("onClientVehicleEnter", root,
function(player, seat)
	if isPlayerInClientArena(player) and seat == 0 then
		triggerEvent("custom:onClientPlayerVehicleEnter", localPlayer, source, player)
	end
end)

-- Model change
addEvent("onClientElementModelChange", true)
addEventHandler("onClientElementModelChange", resourceRoot,
function(vehicle, oldModel, newModel)
	local occupant = getVehicleOccupant(vehicle)
	triggerEvent("custom:onClientVehicleModelChange", localPlayer, vehicle, occupant, oldModel, newModel)
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

function isPlayerInClientArena(player)
	return isElement(player) and getElementParent(player) == getElementParent(localPlayer)
end

function hexToRGB(hex)
	hex = hex:gsub("#", "") 
	return tonumber("0x"..hex:sub(1, 2)) or 255, tonumber("0x"..hex:sub(3, 4)) or 255, tonumber("0x"..hex:sub(5, 6)) or 255, tonumber("0x"..hex:sub(7, 8)) or 255
end