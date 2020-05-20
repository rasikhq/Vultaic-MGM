local screenWidth, screenHeight = guiGetScreenSize()
local textureWidth, textureHeight = 1024, 720
local data = {}
categories = {}
addEvent("custom:onClientVehicleStreamIn", true)
addEvent("custom:onClientPlayerVehicleEnter", true)

addEventHandler("onClientResourceStart", resourceRoot,
function()
	local metaFile = xmlLoadFile("meta.xml")
	if metaFile then
		for i, node in pairs (xmlNodeGetChildren(metaFile)) do
			local info = xmlNodeGetAttributes(node)
			if xmlNodeGetName(node) == "file" and info["sticker"] then
				local path = string.sub(info["src"], 5, string.len(info["src"]))
				local category = info["category"] or "Misc"
				if not categories[category] then
					categories[category] = {}
				end
				table.insert(categories[category], path)
			end
		end
		xmlUnloadFile(metaFile)
	end
	triggerEvent("paints:onUpdateStickers", localPlayer, categories)
	handleRestore()
end)

function updateVehiclePaints(vehicle, player)
	if isElement(player) and isElement(vehicle) then
		if getElementModel(vehicle) ~= 411 then
			if data[player] then
				engineRemoveShaderFromWorldTexture(data[player].shader, "vehiclegrunge256", vehicle)
				data[player].vehicle = nil
			end
			return
		end
		local slots = tonumber(getElementData(player, "paint_slots"))
		if not slots then
			return
		end
		if not data[player] then
			data[player] = {}
			data[player].shader = dxCreateShader("fx/replace.fx", 10, 80, true, "vehicle")
			data[player].texture = dxCreateRenderTarget(textureWidth, textureHeight, true)
			if not isElement(data[player].shader) or not isElement(data[player].texture) then
				destroyVehiclePaints(player)
				return --print("Failed to create paints for "..getPlayerName(player))
			end
			data[player].vehicle = vehicle
			engineApplyShaderToWorldTexture(data[player].shader, "vehiclegrunge256", vehicle)
			--print("Created paints for "..getPlayerName(player))
		end
		local _slots = {}
		for i = 1, slots do
			local slot = getElementData(player, "paint_slot_"..i)
			if slot then
				slot = fromJSON(slot)
				if type(slot) == "table" then
					local priority = math.max(tonumber(slot[8]) or 0, 0)
					table.insert(_slots, priority == 0 and i or priority, slot)
				end
			end
		end
		dxSetRenderTarget(data[player].texture, true)
		dxSetBlendMode("modulate_add")
		for k, slot in pairs(_slots) do
			local path = slot[1]
			local x = tonumber(slot[2] or 0)
			local y = tonumber(slot[3] or 0)
			local width = tonumber(slot[4] or 0)
			local height = tonumber(slot[5] or 0)
			local rotation = tonumber(slot[6] or 0)
			local color = slot[7] or "#FFFFFF"
			local scale = tonumber(slot[9] or 1)		
			x, y, width, height = x * textureWidth, y * textureHeight, width * textureWidth, height * textureHeight
			local r, g, b = hexToRGB(color or "#FFFFFF")
			local isText = string.sub(path, 1, 3) == "tx."
			if fileExists("img/"..path) then
				width, height = width * scale, height * scale
				dxDrawImage(x, y, width, height, "img/"..path, rotation, 0, 0, tocolor(r, g, b, 255))
			elseif isText then
				local text = string.sub(path, 4, string.len(path))
				dxDrawText(tostring(text), x, y, x + width, y + height, tocolor(r, g, b, 255), tonumber(scale or 1), "default-bold", "center", "center", false, false, false, false, false, rotation)
			end
		end
		dxSetBlendMode("blend")
		dxSetRenderTarget()
		dxSetShaderValue(data[player].shader, "tex", data[player].texture)
		if not isElement(data[player].vehicle) or data[player].vehicle ~= vehicle then
			engineApplyShaderToWorldTexture(data[player].shader, "vehiclegrunge256", vehicle)
			data[player].vehicle = vehicle
		end
	end
end
addEventHandler("custom:onClientVehicleStreamIn", root, updateVehiclePaints, true, "high")
addEventHandler("custom:onClientPlayerVehicleEnter", root, updateVehiclePaints, true, "high")

function handleDataChange(dataName)
	if dataName:find("paint_slot", 1, true) and isElementStreamedIn(source) then
		updateVehiclePaints(getPedOccupiedVehicle(source), source)
	end
end
addEventHandler("onClientElementDataChange", root, handleDataChange)

function destroyVehiclePaints(player)
	if isElement(player) and data[player] then
		for i, v in pairs(data[player]) do
			if isElement(v) then
				destroyElement(v)
			end
		end
		data[player] = nil
		--print("Destroyed paints for "..getPlayerName(player))
	end
end
addEvent("paints:destroyPlayerPaints", true)
addEventHandler("paints:destroyPlayerPaints", resourceRoot, destroyVehiclePaints)

function handleRestore()
	for i, vehicle in pairs(getElementsByType("vehicle")) do
		if isElementStreamedIn(vehicle) then
			updateVehiclePaints(vehicle, getVehicleOccupant(vehicle))
		end
	end
end
addEventHandler("onClientRestore", root, handleRestore, true, "high+5")

function clearAllPaints()
	for player in pairs(data) do
		destroyElement(data[player].shader)
		destroyElement(data[player].texture)
	end
	data = {}
	--print("Cleared all paints")
end
addEvent("core:onClientLeaveArena", true)
addEventHandler("core:onClientLeaveArena", localPlayer, clearAllPaints)
addEventHandler("onClientResourceStop", resourceRoot, clearAllPaints)

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

function getStickers()
	return categories
end