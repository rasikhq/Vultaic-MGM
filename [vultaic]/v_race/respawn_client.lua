local respawn = {
	savedCheckpoints = {},
	startTimer = Timer:create(),
	readyTimer = Timer:create()
}

-- Part 1: Saving
function respawn.saveCheckpoint()
	if isElement(arena.vehicle) then
		local checkpoint = {
			model = getElementModel(arena.vehicle),
			position = {getElementPosition(arena.vehicle)},
			rotation = {getElementRotation(arena.vehicle)},
			velocity = {getElementVelocity(arena.vehicle)},
			turnVelocity = {getVehicleTurnVelocity(arena.vehicle)},
			upgrades = getVehicleUpgrades(arena.vehicle)
		}
		table.insert(respawn.savedCheckpoints, checkpoint)
	end
end
addEvent("checkpoints:onClientPlayerReachCheckpoint", true)
addEventHandler("checkpoints:onClientPlayerReachCheckpoint", localPlayer, respawn.saveCheckpoint)

-- Part 2: Loading
function respawn.loadCheckpoint()
	if #respawn.savedCheckpoints == 0 then
		return
	end
	if isElement(arena.vehicle) then
		currentCheckpoint = respawn.savedCheckpoints[#respawn.savedCheckpoints]
		setElementVelocity(arena.vehicle, 0, 0, 0)
		setVehicleTurnVelocity(arena.vehicle, 0, 0, 0)
		setElementFrozen(arena.vehicle, true)
		for i, upgrade in pairs(getVehicleUpgrades(arena.vehicle)) do
			removeVehicleUpgrade(arena.vehicle, upgrade)
		end
	end
	if currentCheckpoint then
		triggerServerEvent("onRequestRespawn", localPlayer, currentCheckpoint)
	end
end

-- Part 3: Unloading
function respawn.removeLastCheckpoint()
	if not (#respawn.savedCheckpoints > 1) then -- Don't remove spawnpoint
		return
	end
	table.remove(respawn.savedCheckpoints, #respawn.savedCheckpoints)
end

function respawn.resetAllCheckpoints(keepFirst)
	respawn.readyTimer:killTimer()
	if keepFirst and #respawn.savedCheckpoints > 1 then
		local savedCheckpoint = respawn.savedCheckpoints[1]
		local newCheckpoint = {
			model = savedCheckpoint.model,
			position = savedCheckpoint.position,
			rotation = savedCheckpoint.rotation,
			velocity = savedCheckpoint.velocity,
			turnVelocity = savedCheckpoint.turnVelocity,
			upgrades = savedCheckpoint.upgrades
		}
		respawn.savedCheckpoints = {}
		table.insert(respawn.savedCheckpoints, newCheckpoint)
	else
		respawn.savedCheckpoints = {}
	end
end

-- Part 4: Entering
function respawn.enter()
	if respawn.startTimer:isActive() then
		return
	end
	spectate.stop()
	setCameraMatrix(getCameraMatrix())
	respawn.startTimer:setTimer(respawn.loadCheckpoint, 250, 1)
end

-- Part 5: Handlers
addEvent("onClientArenaStateChanging", true)
addEventHandler("onClientArenaStateChanging", resourceRoot,
function(currentState, newState, data)
	if arena.state ~= "running" then
		respawn.startTimer:killTimer()
		respawn.readyTimer:killTimer()
		respawn.resetAllCheckpoints()
	end
end)

addEvent("onClientLeaveArena", true)
addEventHandler("onClientLeaveArena", resourceRoot,
function()
	respawn.startTimer:killTimer()
	respawn.resetAllCheckpoints()
end)

addEvent("onClientArenaSpawn", true)
addEventHandler("onClientArenaSpawn", resourceRoot,
function()
	respawn.startTimer:killTimer()
	respawn.resetAllCheckpoints()
	respawn.saveCheckpoint()
end)

addEvent("onClientArenaWasted", true)
addEventHandler("onClientArenaWasted", resourceRoot,
function()
	respawn.readyTimer:killTimer()
	if respawn.startTimer:isActive() then
		return
	end
	if respawn.lastTick and getTickCount() - respawn.lastTick < 3000 then
		respawn.removeLastCheckpoint()
	end
	respawn.startTimer:setTimer(respawn.enter, 5000, 1)
	triggerEvent("onClientNotifyRespawnMessage", localPlayer, 5000)
end)

addEvent("onClientArenaFinished", true)
addEventHandler("onClientArenaFinished", resourceRoot,
function()
	respawn.startTimer:killTimer()
	respawn.readyTimer:killTimer()
	respawn.resetAllCheckpoints()
end)

addEvent("onClientArenaRespawnStart", true)
addEventHandler("onClientArenaRespawnStart", resourceRoot,
function()
	if isElement(arena.vehicle) and currentCheckpoint then
		setCameraTarget(localPlayer)
		respawn.readyTimer:setTimer(function()
			local cameraTarget = getCameraTarget()
			if cameraTarget == localPlayer and isPedInVehicle(localPlayer) then
				if isElement(arena.vehicle) and currentCheckpoint then
					setElementFrozen(arena.vehicle, false)
					setVehicleDamageProof(arena.vehicle, false)
					setElementVelocity(arena.vehicle, unpack(currentCheckpoint.velocity))
					setVehicleTurnVelocity(arena.vehicle, unpack(currentCheckpoint.turnVelocity))
					respawn.lastTick = getTickCount()
				end
				respawn.readyTimer:killTimer()
				triggerServerEvent("onRequestUnfreeze", localPlayer)
			end
		end, 1000, 0)
	end
end)