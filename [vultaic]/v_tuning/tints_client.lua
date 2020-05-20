local data = {}

addEventHandler("onClientResourceStart", resourceRoot,
function()
	invisibleTintShader = dxCreateShader("fx/tint_type1.fx")
	dxSetShaderValue(invisibleTintShader, "rgba", 0, 0, 0, 0)
	for i, vehicle in pairs(getElementsByType("vehicle")) do
		if isElementStreamedIn(vehicle) then
			updateVehicleTints(vehicle)
		end
	end
end)

function updateVehicleTints(vehicle, player)
	if isElement(vehicle) then
		destroyVehicleTints(player)
		local player = isElement(player) and player or getVehicleOccupant(vehicle)
		if not isElement(player) then
			return
		end
		if getElementModel(vehicle) ~= 411 then
			return destroyVehicleTints(player, true)
		end
		local tints = getElementData(player, "tints")
		if type(tints) ~= "table" then
			return destroyVehicleTints(player)
		end
		local _type = tonumber(tints.tint_type or 1)
		local path = "fx/tint_type".._type..".fx"
		if not fileExists(path) then
			return destroyVehicleTints(player)
		end
		if not data[player] then
			data[player] = dxCreateShader(path)
			--print("Created tints for "..getPlayerName(player))
		end
		local r, g, b = hexToRGB(tints.color_tint or "#FFFFFFF")
		local opacity = tonumber(tints.tint_opacity or 0.5)
		local visible = tonumber(tints.tint_visible or 1)
		dxSetShaderValue(data[player], "rgba", r/255, g/255, b/255, opacity)
		engineApplyShaderToWorldTexture(data[player], "Tune_Window", vehicle)
		if visible == 1 then
			engineApplyShaderToWorldTexture(data[player], "Tune_Sidewindows", vehicle)
		else
			engineRemoveShaderFromWorldTexture(data[player], "Tune_Sidewindows", vehicle)
			engineApplyShaderToWorldTexture(invisibleTintShader, "Tune_Sidewindows", vehicle)
		end
	end
end
addEventHandler("custom:onClientVehicleStreamIn", root, updateVehicleTints)
addEventHandler("custom:onClientPlayerVehicleEnter", root, updateVehicleTints)
addEventHandler("custom:onClientVehicleModelChange", root, updateVehicleTints)

function destroyVehicleTints(player, removeOnly)
	if player and data[player] then
		engineRemoveShaderFromWorldTexture(data[player], "Tune_Window", vehicle)
		engineRemoveShaderFromWorldTexture(invisibleTintShader, "Tune_Sidewindows", vehicle)
		if not removeOnly then
			destroyElement(data[player])
			data[player] = nil
			--print("Destroyed tints of "..getPlayerName(player))
		end
	end
end

addEventHandler("onClientElementDataChange", root,
function(dataName)
	if getElementType(source) == "player" and isElementStreamedIn(source) and dataName == "tints" then
		updateVehicleTints(getPedOccupiedVehicle(source), source)
	end
end)

addEventHandler("onClientPlayerQuit", root,
function()
	if data[source] then
		destroyVehicleTints(source)
	end
end)

addEvent("core:onClientLeaveArena", true)
addEventHandler("core:onClientLeaveArena", localPlayer,
function()
	for player, shader in pairs(data) do
		if isElement(shader) then
			destroyElement(shader)
		end
	end
	data = {}
	--print("Destroyed all tints")
end)