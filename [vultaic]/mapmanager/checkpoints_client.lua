local checkpointContainer = createElement("checkpointContainer", "checkpointContainer_client")
local checkpoints = {}
local currentCheckPointID = 0
addEvent("core:onClientCameraTargetChange", true)

function createCheckpoints(data)
	destroyCheckpoints()
	if type(data) == "table" then
		savedCheckpoints = data
		local checkpointData = {}
		local firstCheckpoint = nil
		for i, checkpoint in pairs(data) do
			checkpointData[checkpoint[7]] = {
				position = {checkpoint[1], checkpoint[2], checkpoint[3]},
				markerType = checkpoint[4],
				markerSize = checkpoint[5],
				markerColor = checkpoint[6],
				id = checkpoint[7],
				nextId = checkpoint[8],
				vehicle = checkpoint[9],
				paintjob = checkpoint[10],
				upgrades = checkpoint[11]
			}
			if checkpointData[checkpoint[7]].vehicle == 0 then
				checkpointData[checkpoint[7]].vehicle = nil
			end
			-- Find the first checkpoint if not found
			if not firstCheckpoint and checkpointData[checkpoint[7]].nextId then
				firstCheckpoint = checkpointData[checkpoint[7]]
			end
		end
		local nextCheckpoint = firstCheckpoint
		for i = 1, #data do
			if nextCheckpoint then
				table.insert(checkpoints, nextCheckpoint)
			else
				break
			end
			if nextCheckpoint.nextId then
				nextCheckpoint = checkpointData[nextCheckpoint.nextId] or nil
			end
		end
		showNextCheckpoint()
		setElementData(localPlayer, "totalCheckpoints", #data, false)
		addEventHandler("core:onClientCameraTargetChange", localPlayer, updateCheckpointsForTarget)
		addEventHandler("onClientElementDataChange", root, checkCheckpointsForTarget)
		triggerEvent("onClientCheckpointsGenerated", localPlayer)
		outputDebugString("Checkpoints have been created")
	end
end

function resetCheckpoints()
	if savedCheckpoints then
		createCheckpoints(savedCheckpoints)
	end
end
addEvent("checkpoints:reset", true)
addEventHandler("checkpoints:reset", localPlayer, resetCheckpoints)

function destroyCheckpoints()
	if isElement(checkpointContainer) then
		destroyElement(checkpointContainer)
	end
	checkpointContainer = createElement("checkpointContainer", "checkpointContainer_client")
	checkpoints = {}
	currentCheckPointID = 0
	removeEventHandler("core:onClientCameraTargetChange", localPlayer, updateCheckpointsForTarget)
	removeEventHandler("onClientElementDataChange", root, checkCheckpointsForTarget)
	setElementData(localPlayer, "checkpoint", 0)
	setElementData(localPlayer, "totalCheckpoints", 0, false)
	setElementData(localPlayer, "checkpointPosition", nil)
end

function createCheckpoint(id)
	if type(id) == "number" then
		local checkpoint = checkpoints[id]
		if checkpoint and not isElement(checkpoint.marker) then
			local x, y, z = unpack(checkpoint.position)
			local r, g, b, a = getColorFromString(checkpoint.markerColor)
			checkpoint.marker = createMarker(x, y, z, checkpoint.markerType, checkpoint.markerSize, r, g, b, a)
			if isElement(checkpoint.marker) then
				setElementParent(checkpoint.marker, checkpointContainer)
				setElementDimension(checkpoint.marker, getElementDimension(localPlayer))
			end
		end
	end
end

function makeCheckpointCurrent(id)
	if type(id) == "number" then
		local checkpoint = checkpoints[id]
		if checkpoint then
			-- Avoid duplicates
			if not isElement(checkpoint.colshape) then
				checkpoint.colshape = createColCircle(checkpoint.position[1], checkpoint.position[2], checkpoint.markerSize + 4)
				-- Add event so it can be reached
				if isElement(checkpoint.colshape) then
					setElementParent(checkpoint.colshape, checkpointContainer)
					addEventHandler("onClientColShapeHit", checkpoint.colshape, checkpointReached)
				end
			end
		end
	end
end

function destroyCheckpoint(id)
	if type(id) == "number" then
		local checkpoint = checkpoints[id]
		if checkpoint then
			if isElement(checkpoint.marker) then
				destroyElement(checkpoint.marker)
			end
			if isElement(checkpoint.colshape) then
				destroyElement(checkpoint.colshape)
			end
			checkpoint.marker = nil
			checkpoint.colshape = nil
		end
	end
end

function showNextCheckpoint()
	-- Remove the current one first
	destroyCheckpoint(currentCheckPointID)
	-- Create the actual one by increasing the ID
	currentCheckPointID = currentCheckPointID + 1
	if currentCheckPointID <= #checkpoints then
		createCheckpoint(currentCheckPointID)
	end
	-- Mark it as current
	makeCheckpointCurrent(currentCheckPointID)
	-- Change marker icon	
	if currentCheckPointID == #checkpoints then
		setMarkerIcon(checkpoints[currentCheckPointID].marker, "finish")
	elseif currentCheckPointID < #checkpoints then
		-- Show the next one
		createCheckpoint(currentCheckPointID + 1)
		setMarkerTarget(checkpoints[currentCheckPointID].marker, unpack(checkpoints[currentCheckPointID + 1].position))
	end
	-- Update 'checkpoint' data
	setElementData(localPlayer, "checkpoint", currentCheckPointID - 1)
	if checkpoints[currentCheckPointID] then
		setElementData(localPlayer, "checkpointPosition", checkpoints[currentCheckPointID].position)
	end
end

function checkpointReached(element)
	local vehicle = getPedOccupiedVehicle(localPlayer)
	if not vehicle or (element ~= vehicle and element ~= localPlayer) or isVehicleBlown(vehicle) or getElementHealth(localPlayer) == 0 then
		return
	end
	local currentCheckpoint = checkpoints[currentCheckPointID]
	if currentCheckpoint.vehicle and currentCheckpoint.vehicle ~= getElementModel(vehicle) then
		previousVehicleHeight = getElementDistanceFromCentreOfMassToBaseOfModel(vehicle)
		local health = nil
		alignVehicleWithUp()
		if checkModelIsAirplane(currentCheckpoint.vehicle) then
			local health = getElementHealth(vehicle)
		end
		setElementModel(vehicle, currentCheckpoint.vehicle)
		if health then
			fixVehicle(vehicle)
			setElementHealth(vehicle, health)
		end
		vehicleChanging(currentCheckpoint.vehicle)
	end
	triggerServerEvent("onPlayerReachCheckpointInternal", localPlayer, currentCheckPointID, checkpoints[currentCheckPointID], #checkpoints)
	triggerEvent("checkpoints:onClientPlayerReachCheckpoint", localPlayer, currentCheckPointID, #checkpoints)
	playSoundFrontEnd(43)
	if currentCheckPointID < #checkpoints then
		showNextCheckpoint()
	else
		local currentCheckpoint = checkpoints[currentCheckPointID]
		if currentCheckpoint then
			if isElement(currentCheckpoint.marker) then
				destroyElement(currentCheckpoint.marker)
			end
			if isElement(currentCheckpoint.colshape) then
				destroyElement(currentCheckpoint.colshape)
			end
		end
		triggerEvent("checkpoints:onClientFinish", localPlayer)
		setElementData(localPlayer, "checkpoint", currentCheckPointID)
		setElementData(localPlayer, "checkpointPosition", checkpoints[currentCheckPointID].position)
	end
end

function showTargetCheckpoint(id)
	if type(id) == "number" then
		id = id + 1
		-- Remove current checkpoints if ID is not equal
		if id ~= currentCheckPointID then
			destroyCheckpoint(currentCheckPointID)
			destroyCheckpoint(currentCheckPointID + 1)
		end
		currentCheckPointID = id
		-- Create checkpoint
		createCheckpoint(currentCheckPointID)
		-- Change marker icon
		if currentCheckPointID == #checkpoints then
			setMarkerIcon(checkpoints[currentCheckPointID].marker, "finish")
		elseif currentCheckPointID < #checkpoints then
			-- Show the next one
			createCheckpoint(currentCheckPointID + 1)
			setMarkerTarget(checkpoints[currentCheckPointID].marker, unpack(checkpoints[currentCheckPointID + 1].position))
		end
	end
end

function updateCheckpointsForTarget(target)
	if isElement(target) then
		if target == localPlayer then
			-- Remove te useless target checkpoint
			destroyCheckpoint(currentCheckPointID)
			destroyCheckpoint(currentCheckPointID + 1)
			-- Create local player's checkpoint
			local checkpoint = getElementData(localPlayer, "checkpoint")
			currentCheckPointID = checkpoint
			showNextCheckpoint()
		else
			local checkpoint = getElementData(target, "checkpoint")
			showTargetCheckpoint(checkpoint)
		end
	end
end

function checkCheckpointsForTarget(dataName)
	if dataName == "checkpoint" and source ~= localPlayer and source == getCameraTarget() then
		local checkpoint = getElementData(source, "checkpoint")
		showTargetCheckpoint(checkpoint)
	end
end