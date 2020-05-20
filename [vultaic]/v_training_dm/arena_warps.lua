addEvent("syncPlayerVehicle", true)
addEventHandler("syncPlayerVehicle", resourceRoot, function(clientVehicle, newModel)
	clientVehicle:setModel(newModel)
end)