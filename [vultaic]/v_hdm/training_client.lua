training = {
	stats = {
		active = false,
		allowRespawn = false,
		ready = false,
		spawnSet = false
	},
	data = {},
	index = 1,
	speed = 1,
	state = "neutral",
	startTimer = Timer:create()
}
local waterCraftIDS = {
	[539] = true,
	[460] = true,
	[417] = true,
	[447] = true,
	[472] = true,
	[473] = true,
	[493] = true,
	[595] = true,
	[484] = true,
	[430] = true,
	[453] = true,
	[452] = true,
	[446] = true,
	[454] = true
}
function training.toggle()
	if not training.stats.allowRespawn then
		if not training.stats.spawnSet and arena.state == "running" and getElementData(localPlayer, "state") ~= "alive" and getElementData(localPlayer, "state") ~= "training" then
			training.reset()
			training.setspawn()
			training.stats.allowRespawn = true
			training.toggle()
		end
		return
	elseif training.state == "finish" then
		return
	elseif arena.state ~= "running" then
		training.reset()
		return
	end
	spectate.stop()
	setCameraMatrix(getCameraMatrix())
	training.startTimer:killTimer()
	training.startTimer:setTimer(triggerServerEvent, 100, 1, "onRequestEnterTrainingMode", localPlayer, training.data[training.index])
	training.stats.allowRespawn = false
	training.stats.active = true
	if arena.vehicle and isElement(arena.vehicle) then
		setVehicleDamageProof(arena.vehicle, false)
	end
	triggerEvent("onClientNotifyTrainingMessage", localPlayer, false)
end
function training.setState(newState)
	local oldState = training.state
	training.state = newState
	training.onStateChange(oldState, newState)
end
function training.initialize()
	addEventHandler("onClientRender", root, training.processing)
	bindKey("backspace", "both", training.toggleRewind)
	bindKey("lshift", "both", training.toggleSpeed)
	bindKey("rshift", "both", training.toggleSpeed)
	bindKey("space", "down", training.toggle)
	addEventHandler("mapmanager:onMapLoad", localPlayer, onMapLoad)
end
function training.setspawn()
	local spawnpoint = getElementsByType("mapmanager:spawnpoint")
	if #spawnpoint > 0 then
		spawnpoint = spawnpoint[math.random(#getElementsByType("mapmanager:spawnpoint"))] -- Get a random spawnpoint
		if not training.data[training.index] then
			training.data[training.index] = {}
		end
		training.data[training.index].Model = getElementData(spawnpoint, "model")
		training.data[training.index].Position = {
			x = getElementData(spawnpoint, "posX"),
			y = getElementData(spawnpoint, "posY"),
			z = getElementData(spawnpoint, "posZ")
		}
		training.data[training.index].Rotation = {
			x = getElementData(spawnpoint, "rotX"),
			y = getElementData(spawnpoint, "rotY"),
			z = getElementData(spawnpoint, "rotZ")
		}
		training.data[training.index].Velocity = {
			x = 0,
			y = 0,
			z = 0
		}
		training.data[training.index].TurnVelocity = {
			x = 0,
			y = 0,
			z = 0
		}
		training.data[training.index].Camera = nil
		training.data[training.index].Nitro = {
			Amount = nil,
			Active = false
		}
		training.data[training.index].Health = 1000
		training.stats.spawnSet = true
	end
end
function training.reset()
	training.stats = {
		active = false,
		allowRespawn = false,
		spawnSet = false
	}
	training.data = {}
	training.index = 1
	training.speed = 1
	training.state = "neutral"
	training.startTimer:killTimer()
	triggerEvent("onClientNotifyTrainingMessage", localPlayer, false)
end
function training.deinitialize()
	training.startTimer:killTimer()
	removeEventHandler("onClientRender", root, training.processing)
	unbindKey("backspace", "both", training.toggleRewind)
	unbindKey("lshift", "both", training.toggleSpeed)
	unbindKey("rshift", "both", training.toggleSpeed)
	unbindKey("space", "down", training.toggle)
	removeEventHandler("mapmanager:onMapLoad", localPlayer, onMapLoad)
	triggerEvent("onClientNotifyTrainingMessage", localPlayer, false)
end
function training.toggleRewind(key, state)
	if not training.stats.active or not training.stats.ready then
		return
	end
	if training.startTimer:isActive() then
		training.startTimer:killTimer()
	end
	if state == "down" then
		training.setState("playback")
	elseif state == "up" then
		training.setState("recording")
		setCameraTarget(localPlayer)
		training.playback(true)
		setGravity(0.008)
		setGameSpeed(1)
	end
end
function training.toggleSpeed(key, state)
	if state == "down" then
		training.speed = 3
	elseif state == "up" then
		training.speed = 1
	end
end
function training.record()
	local vehicle = arena.vehicle
	if not vehicle or not isElement(vehicle) or isVehicleBlown(vehicle) or isPedDead(localPlayer) or training.state ~= "recording" or getCameraTarget() ~= localPlayer then
		return
	end
	if not waterCraftIDS[getElementModel(vehicle)] then
		local x, y, z = getElementPosition(localPlayer)
		local waterZ = getWaterLevel(x, y, z)
		if waterZ and z < waterZ - 0.5 and not isPlayerDead(localPlayer) then
			return
		end
	end
	local currentIndex = training.index
	local newIndex = currentIndex+1
	training.data[newIndex] = {
		Model = getVehicleModel(vehicle),
		Position = {},
		Rotation = {},
		Velocity = {},
		TurnVelocity = {},
		Camera = {},
		Nitro = {
			Amount = nil,
			Active = false
		},
		Health = getElementHealth(vehicle)
	}
	--[[if training.data[newIndex].Health < 250 then
		return
	end--]]
	training.data[newIndex].Position.x, training.data[newIndex].Position.y, training.data[newIndex].Position.z = getElementPosition(vehicle)
	training.data[newIndex].Rotation.x, training.data[newIndex].Rotation.y, training.data[newIndex].Rotation.z = getElementRotation(vehicle)
	training.data[newIndex].Velocity.x, training.data[newIndex].Velocity.y, training.data[newIndex].Velocity.z = getElementVelocity(vehicle)
	training.data[newIndex].TurnVelocity.x, training.data[newIndex].TurnVelocity.y, training.data[newIndex].TurnVelocity.z = getVehicleTurnVelocity(vehicle)
	training.data[newIndex].Camera.x, training.data[newIndex].Camera.y, training.data[newIndex].Camera.z, training.data[newIndex].Camera.lx, training.data[newIndex].Camera.ly, training.data[newIndex].Camera.lz = getCameraMatrix()
	training.data[newIndex].Nitro.Amount = getVehicleNitroLevel(vehicle) or nil
	training.data[newIndex].Nitro.Active = training.data[newIndex].Nitro.Amount and isVehicleNitroActivated(vehicle) or false
	training.index = newIndex
end
function training.playback(unfreeze)
	unfreeze = unfreeze or false
	local vehicle = arena.vehicle
	if not vehicle or not isElement(vehicle) or isPedDead(localPlayer) then
		return
	elseif arena.state ~= "running" then
		training.reset()
		return
	end
	local currentIndex = training.index
	local playbackIndex = currentIndex-training.speed
	if currentIndex == 1 or not training.data[playbackIndex] then
		setCameraTarget(localPlayer)
		training.setState("recording")
		return
	end
	playbackIndex = playbackIndex <= 0 and 1 or playbackIndex
	if(isVehicleBlown(vehicle)) then
		setElementHealth(localPlayer, 0)
		return
	end
	setVehicleModel(vehicle, training.data[playbackIndex].Model)
	if(unfreeze) then
		setElementFrozen(vehicle, false)
	end
	setElementPosition(vehicle, training.data[playbackIndex].Position.x, training.data[playbackIndex].Position.y, training.data[playbackIndex].Position.z)
	setElementRotation(vehicle, training.data[playbackIndex].Rotation.x, training.data[playbackIndex].Rotation.y, training.data[playbackIndex].Rotation.z)
	setElementVelocity(vehicle, training.data[playbackIndex].Velocity.x, training.data[playbackIndex].Velocity.y, training.data[playbackIndex].Velocity.z)
	if training.data[playbackIndex].Camera and not unfreeze then
		setCameraMatrix(training.data[playbackIndex].Camera.x, training.data[playbackIndex].Camera.y, training.data[playbackIndex].Camera.z, training.data[playbackIndex].Camera.lx, training.data[playbackIndex].Camera.ly, training.data[playbackIndex].Camera.lz)
	end
	setVehicleTurnVelocity(vehicle, training.data[playbackIndex].TurnVelocity.x, training.data[playbackIndex].TurnVelocity.y, training.data[playbackIndex].TurnVelocity.z)
	-- Dealing with nitro
	if training.data[playbackIndex].Nitro.Amount then
		addVehicleUpgrade(vehicle, 1010)
		setVehicleNitroLevel(vehicle, training.data[playbackIndex].Nitro.Amount)
		setVehicleNitroActivated(vehicle, training.data[playbackIndex].Nitro.Active)
	else
		removeVehicleUpgrade(vehicle, 1010)
	end
	setElementHealth(vehicle, training.data[playbackIndex].Health)
	training.index = playbackIndex
end
function training.onStateChange(oldState, newState)
	local vehicle = arena.vehicle
	if(newState == "playback") then
		setElementFrozen(vehicle, true)
	elseif(newState == "recording") then
		setElementFrozen(vehicle, false)
	end
end
function training.processing()
	if training.state == "recording" then
		training.record()
	elseif training.state == "playback" then
		training.playback()
	end
end
addEventHandler("onClientJoinArena", resourceRoot,
function(data)
	training.initialize()
	training.setState("neutral")
end)
function onMapLoad(...)
	if arena.state == "running" then
		if getElementData(localPlayer, "state") ~= "dead" and getElementData(localPlayer, "state") ~= "waiting" then
			return
		end
		training.reset()
		training.setspawn()
		training.startTimer:setTimer(function()
			training.stats.allowRespawn = true
			triggerEvent("onClientNotifyTrainingMessage", localPlayer, true)
		end, 1000, 1)
	end
end
addEventHandler("onClientLeaveArena", resourceRoot,
function()
	training.reset()
	training.deinitialize()
end)
addEventHandler("onClientArenaStateChanging", resourceRoot,
function(currentState, newState, data)
	if newState ~= "running" then
		training.reset()
	end
	if newState == "running" and #arena.players > 1 then
		training.setState("recording")
	end
end)
addEventHandler("onClientArenaSpawn", resourceRoot,
function()
	training.reset()
	training.setspawn()
end)
addEventHandler("onClientArenaWasted", resourceRoot,
function()
	training.stats.ready = false
	if training.state == "finish" then
		return
	elseif arena.state ~= "running" then
		training.reset()
		return
	end
	training.setState("paused")
	training.stats.allowRespawn = false
	training.stats.active = false
	training.startTimer:killTimer()
	training.startTimer:setTimer(function()
		training.stats.allowRespawn = true
		triggerEvent("onClientNotifyTrainingMessage", localPlayer, true)
	end, 1000, 1)
end)
addEvent("onClientArenaTrainingModeStart", true)
addEventHandler("onClientArenaTrainingModeStart", resourceRoot,
function(vehicle)
	training.stats.active = true
	setCameraTarget(localPlayer)
	arena.vehicle = vehicle
	if not vehicle or not isElement(vehicle) then
		return
	end
	if(getPedOccupiedVehicle(localPlayer) ~= vehicle) then
		outputChatBox("Training error: Occupied vehicle ~= localPlayer arena.vehicle")
		outputChatBox("vehicle: "..type(vehicle).." | isElement: "..tostring(isElement(vehicle)))
		outputChatBox("getPedOccupiedVehicle: "..type(getPedOccupiedVehicle(localPlayer)).." | isElement: "..tostring(isElement(getPedOccupiedVehicle(localPlayer))))
	end
	triggerEvent("racepickups:updateVehicleWeapons", localPlayer)
	if training.state == "paused" then
		-- Get the last data on recording
		local currentIndex = training.index
		local playbackIndex = currentIndex-training.speed
		playbackIndex = playbackIndex <= 0 and 1 or playbackIndex
		while(training.data[playbackIndex].Health < 250) do
			playbackIndex = playbackIndex-1
			if playbackIndex <= 1 then
				break
			end
		end
		setVehicleModel(vehicle, training.data[playbackIndex].Model or 411)
		setElementPosition(vehicle, training.data[playbackIndex].Position.x, training.data[playbackIndex].Position.y, training.data[playbackIndex].Position.z)
		setElementRotation(vehicle, training.data[playbackIndex].Rotation.x, training.data[playbackIndex].Rotation.y, training.data[playbackIndex].Rotation.z)
		setElementHealth(vehicle, training.data[playbackIndex].Health)
		-- Unfreezing when ready
		if arena.state ~= "running" then
			training.reset()
			return
		end
		training.startTimer:setTimer(function(vehicle, rewindData)
			local cameraTarget = getCameraTarget()
			if cameraTarget == localPlayer or cameraTarget == vehicle and isPedInVehicle(localPlayer) then
				setElementFrozen(vehicle, false)
				setElementVelocity(vehicle, rewindData.Velocity.x, rewindData.Velocity.y, rewindData.Velocity.z)
				setVehicleTurnVelocity(vehicle, rewindData.TurnVelocity.x, rewindData.TurnVelocity.y, rewindData.TurnVelocity.z)
				-- Dealing with nitro
				if rewindData.Nitro.Amount then
					addVehicleUpgrade(vehicle, 1010)
					setVehicleNitroLevel(vehicle, rewindData.Nitro.Amount)
					setVehicleNitroActivated(vehicle, rewindData.Nitro.Active)
				else
					removeVehicleUpgrade(vehicle, 1010)
				end
				training.setState("recording")
				training.startTimer:killTimer()
			end
		end, 1000, 0, vehicle, training.data[playbackIndex])
		training.index = playbackIndex
	elseif training.state == "neutral" then
		-- Get the first one [Spawn point]
		local currentIndex = 0
		local playbackIndex = currentIndex-training.speed
		playbackIndex = playbackIndex <= 0 and 1 or playbackIndex
		if not training.data[playbackIndex] then
			return
		end
		setVehicleModel(vehicle, training.data[playbackIndex].Model or 411)
		setElementPosition(vehicle, training.data[playbackIndex].Position.x, training.data[playbackIndex].Position.y, training.data[playbackIndex].Position.z)
		setElementRotation(vehicle, training.data[playbackIndex].Rotation.x, training.data[playbackIndex].Rotation.y, training.data[playbackIndex].Rotation.z)
		setElementHealth(vehicle, training.data[playbackIndex].Health)
		-- Unfreezing when ready
		if arena.state ~= "running" then
			training.reset()
			return
		end
		training.startTimer:setTimer(function(vehicle, rewindData)
			local cameraTarget = getCameraTarget()
			if cameraTarget == localPlayer or cameraTarget == vehicle and isPedInVehicle(localPlayer) then
				setElementFrozen(vehicle, false)
				setElementVelocity(vehicle, rewindData.Velocity.x, rewindData.Velocity.y, rewindData.Velocity.z)
				setVehicleTurnVelocity(vehicle, rewindData.TurnVelocity.x, rewindData.TurnVelocity.y, rewindData.TurnVelocity.z)
				-- Dealing with nitro
				if rewindData.Nitro.Amount then
					addVehicleUpgrade(vehicle, 1010)
					setVehicleNitroLevel(vehicle, rewindData.Nitro.Amount)
					setVehicleNitroActivated(vehicle, rewindData.Nitro.Active)
				else
					removeVehicleUpgrade(vehicle, 1010)
				end
				training.setState("recording")
				training.startTimer:killTimer()
			end
		end, 1000, 0, vehicle, training.data[playbackIndex])
		training.index = playbackIndex
	end
	training.stats.ready = true
end)
addEventHandler("racepickups:onClientPickupRacepickup", localPlayer,
function(pickupType, pickupVehicle)
	if pickupType == "vehiclechange" and pickupVehicle == 425 then
		training.reset()
		training.setspawn()
		if training.stats.active or getElementData(source, "state") == "training" then
			requestKill()
		end
	end
end)