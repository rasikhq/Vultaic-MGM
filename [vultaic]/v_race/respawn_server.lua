addEvent("onRequestRespawn", true)
addEvent("onRequestUnfreeze", true)

addEventHandler("onResourceStart", resourceRoot,
function()
	addEventHandler("onRequestRespawn", arena.element, onPlayerRequestRespawn)
	addEventHandler("onRequestUnfreeze", arena.element, onPlayerRequestUnfreeze)
end)

function onPlayerRequestRespawn(data)
	if type(data) == "table" and data.model and data.position and data.rotation then
		local vehicle = arena.playerVehicles[source]
		if isElement(vehicle) then
			local model = data.model or 411
			local posX, posY, posZ = unpack(data.position)
			local rotX, rotY, rotZ = unpack(data.rotation)
			local upgrades = type(data.upgrades) == "table" and data.upgrades or {}
			setElementModel(vehicle, model)
			setElementPosition(vehicle, posX, posY, posZ)
			setElementRotation(vehicle, rotX, rotY, rotZ)
			setElementVelocity(vehicle, 0, 0, 0)
			setVehicleTurnVelocity(vehicle, 0, 0, 0)
			fixVehicle(vehicle)
			spawnPlayer(source, posX, posY, posZ)
			setPedStat(source, 160, 1000)
			setPedStat(source, 229, 1000)
			setPedStat(source, 230, 1000)
			warpPedIntoVehicle(source, vehicle)
			setVehicleDamageProof(vehicle, false)
			setElementCollisionsEnabled(vehicle, true)
			for i, upgrade in pairs(getVehicleUpgrades(vehicle)) do
				removeVehicleUpgrade(vehicle, upgrade)
			end
			if upgrades then
				for i, upgrade in pairs(upgrades) do
					addVehicleUpgrade(vehicle, upgrade)
				end
			end
		end
		tableInsert(arena.alivePlayers, source)
		setPlayerState(source, "alive")
		triggerClientEvent(source, "onClientArenaRespawnStart", resourceRoot)
	end
end

function onPlayerRequestUnfreeze()
	unfreezePlayer(source)
end