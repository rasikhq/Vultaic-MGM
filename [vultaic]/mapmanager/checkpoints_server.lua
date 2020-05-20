addEvent("onPlayerReachCheckpointInternal", true)

function onPlayerReachCheckpoint(checkpointID, checkpoint, length)
	local vehicle = getPedOccupiedVehicle(source) or nil
	if isElement(vehicle) and checkpoint.vehicle and getElementModel(vehicle) ~= tonumber(checkpoint.vehicle) then
		removeVehicleUpgrade(vehicle, 1010)
		setElementModel(vehicle, checkpoint.vehicle)
		if checkpoint.paintjob or checkpoint.upgrades then
			setVehiclePaintjobAndUpgrades(vehicle, checkpoint.paintjob, checkpoint.upgrades)
		end
	end
	if checkpointID < length then
		triggerEvent("checkpoints:onPlayerReachCheckpoint", source, checkpointID)
	else
		triggerEvent("checkpoints:onPlayerFinish", source)
	end
end
addEventHandler("onPlayerReachCheckpointInternal", root, onPlayerReachCheckpoint)