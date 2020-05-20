addEvent("onRequestEnterTrainingMode", true)

addEventHandler("onResourceStart", resourceRoot,
function()
	addEventHandler("onRequestEnterTrainingMode", arena.element, onPlayerRequestEnterTrainingMode)
end)

function onPlayerRequestEnterTrainingMode(data)
	if type(data) == "table" and data.Model and data.Position and data.Rotation then
		local vehicle = arena.playerVehicles[source]
		if isElement(vehicle) then
			applyTrainingMode(source, vehicle, data)
		else
			arena.playerVehicles[source] = createVehicle(411, 0, 0, 0, 0, 0, 0)
			setElementDimension(arena.playerVehicles[source], arena.dimension)
			setElementSyncer(arena.playerVehicles[source], false)
			warpPedIntoVehicle(source, arena.playerVehicles[source])
			if arena.playerVehicles[source] then
				applyTrainingMode(source, arena.playerVehicles[source], data)
			end
		end
		setPlayerState(source, "training")
		triggerClientEvent(source, "onClientArenaTrainingModeStart", resourceRoot, arena.playerVehicles[source])
	end
end

function applyTrainingMode(player, vehicle, data)
	local model = data.Model or 411
	local posX, posY, posZ = data.Position.x, data.Position.y, data.Position.z
	local rotX, rotY, rotZ = data.Rotation.x, data.Rotation.y, data.Rotation.z
	local health = data.Health
	if(health <= 250) then
		health = 251
	end
	setElementModel(vehicle, model)
	setElementPosition(vehicle, posX, posY, posZ)
	setElementRotation(vehicle, rotX, rotY, rotZ)
	setElementVelocity(vehicle, 0, 0, 0)
	setVehicleTurnVelocity(vehicle, 0, 0, 0)
	fixVehicle(vehicle)
	if health then
		setElementHealth(vehicle, health)
	end
	spawnPlayer(player, posX, posY, posZ)
	setPedStat(player, 160, 1000)
	setPedStat(player, 229, 1000)
	setPedStat(player, 230, 1000)
	warpPedIntoVehicle(player, vehicle)
	if(not getPedOccupiedVehicle(player)) then
		outputChatBox("training debug :: "..getPlayerName(player).." is not in a vehicle (server side)", arena.element)
	end
	setVehicleDamageProof(vehicle, false)
	setElementCollisionsEnabled(vehicle, true)
end