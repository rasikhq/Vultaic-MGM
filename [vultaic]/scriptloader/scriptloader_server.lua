addEvent("sandbox:syncFunction", true)
addEventHandler("sandbox:syncFunction", root,
function(functionName, ...)
	if functionName == "setElementModel" then
		local args = {...}
		local vehicle = args[1]
		local model = args[2]
		if isElement(vehicle) and not isElementFrozen(vehicle) and model then
			setElementModel(vehicle, model)
			outputDebugString("Synced function >> "..functionName, 0)
		end
	--[[elseif functionName == "addVehicleUpgrade" then
		local args = {...}
		local vehicle = args[1]
		local upgrade = args[2]
		if isElement(vehicle) and not isElementFrozen(vehicle) and not upgrade then
			addVehicleUpgrade(vehicle, upgrade)
			outputDebugString("Synced function >> "..functionName, 0)
		end
	]]
	elseif functionName == "setVehicleHandling" then
		local args = {...}
		local vehicle = args[1]
		local property = args[2]
		local value = args[3]
		if isElement(vehicle) and property and value then
			setVehicleHandling(vehicle, property, value)
			outputDebugString("Synced function >> "..functionName, 0)
		end
	elseif functionName == "fixVehicle" then
		local args = {...}
		local vehicle = args[1]
		if isElement(vehicle) then
			fixVehicle(vehicle)
			outputDebugString("Synced function >> "..functionName, 0)
		end
	end
end)

addEvent("scriptloader:onClientResourceStart", true)
addEventHandler("scriptloader:onClientResourceStart", resourceRoot, function()
	triggerClientEvent(client, "scriptloader:setCacheDirectory", resourceRoot, getServerPort())
end)