local pickupContainer = createElement("pickupContainer", "pickupContainer_client_racepickups")
local pickups = {}
local pickupID = {}
local visiblePickups = {}
local startTick = getTickCount()
local modelForPickupType = {
	nitro = 2221, 
	repair = 2222, 
	vehiclechange = 2223
}
local armedVehicleIDs = {
	[425] = true,
	[447] = true,
	[520] = true,
	[430] = true,
	[464] = true,
	[432] = true
}
local startTick = getTickCount()
local handleHitPickupTimer = nil
addEvent("mapmanager:onMapLoad", true)
addEvent("loadPickup", true)
addEvent("unloadPickup", true)
addEvent("racepickups:checkAllPickups", true)
addEvent("racepickups:removeVehicleNitro", true)
addEvent("racepickups:updateVehicleWeapons", true)

addEventHandler("mapmanager:onMapLoad", localPlayer,
function()
	for name, i in pairs(modelForPickupType) do
		engineImportTXD(engineLoadTXD("model/"..name..".txd"), i)
		engineReplaceModel(engineLoadDFF("model/"..name..".dff"), i)
		engineSetModelLODDistance(i, 60)
	end
	updateVehicleWeapons()
	checkVehicleIsHelicopter()
	removeVehicleNitro()
end)

function createRacePickup(id, vehicle, respawn, x, y, z, paintjob, upgrades)
	if not modelForPickupType[id] or type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then
		return
	end
	local dimension = getElementDimension(localPlayer)
	local object = createObject(modelForPickupType[id], x, y, z)
	if object then
		setElementCollisionsEnabled(object, false)
		setElementDimension(object, dimension)
		setElementParent(object, pickupContainer)
		local colsphere = createColSphere(x, y, z, 3.5)
		if colsphere then
			setElementDimension(colsphere, dimension)
			setElementParent(colsphere, pickupContainer)
			attachElements(colsphere, object)
			local index = #pickups + 1
			local uniqueID = md5(tostring(x)..tostring(y)..tostring(z)..tostring(id)..tostring(vehicle)..tostring(paintjob)..tostring(respawn))
			pickups[index] = {
				id = uniqueID,
				_type = id,
				vehicle = vehicle,
				respawn = respawn,
				x = x,
				y = y,
				z = z,
				paintjob = paintjob,
				upgrades = upgrades,
				object = object,
				colshape = colsphere,
				_load = true,
				vehicleName = id == "vehiclechange" and getVehicleNameFromModel(vehicle) or nil
			}
			pickupID[colsphere] = index
			pickupID[object] = index
			if #pickups == 1 then
				removeEventHandler("onClientRender", root, updatePickups)
				addEventHandler("onClientRender", root, updatePickups)
			end
			return pickups[index]
		end
	end
end

function destroyRacePickups()
	if handleHitPickupTimer and isTimer(handleHitPickupTimer) then
		killTimer(handleHitPickupTimer)
	end
	if isElement(pickupContainer) then
		destroyElement(pickupContainer)
	end
	pickupContainer = createElement("pickupContainer", "pickupContainer_client_racepickups")
	pickups = {}
	pickupID = {}
	visiblePickups = {}
	giveNitroAfterVehicleChange = nil
	removeEventHandler("onClientRender", root, updatePickups)
end

function vehicleChanging(newModel)
	local vehicle = getPedOccupiedVehicle(localPlayer)
	if getElementModel(vehicle) ~= newModel then
		outputDebugString("Vehicle change model mismatch ("..tostring(getElementModel(vehicle)).."/"..tostring(newModel)..")")
	end
	local newVehicleHeight = getElementDistanceFromCentreOfMassToBaseOfModel(vehicle)
	local x, y, z = getElementPosition(vehicle)
	if previousVehicleHeight and newVehicleHeight > previousVehicleHeight then
		z = z - previousVehicleHeight + newVehicleHeight
	end
	z = z + 1
	setElementPosition(vehicle, x, y, z)
	previousVehicleHeight = nil
	updateVehicleWeapons()
	checkVehicleIsHelicopter()
end

function updateVehicleWeapons()
	local vehicle = getPedOccupiedVehicle(localPlayer)
	if isElement(vehicle) then
		local model = getElementModel(vehicle)
		local weapons = not armedVehicleIDs[model] or true
		toggleControl("vehicle_fire", weapons)
		if model == 425 then
			weapons = false
		end
		toggleControl("vehicle_secondary_fire", weapons)
	end
end
addEventHandler("onClientPlayerSpawn", localPlayer, updateVehicleWeapons)
addEventHandler("onClientPlayerVehicleEnter", localPlayer, updateVehicleWeapons)

addEventHandler("onClientColShapeHit", root,
function(element)
	local index = pickupID[source]
	local pickup = nil
	if type(index) == "number" then
		pickup = pickups[index]
	end
	if not pickup then
		return
	end
	local vehicle = getPedOccupiedVehicle(localPlayer)
	if element ~= vehicle or isVehicleBlown(vehicle) or isElementFrozen(vehicle) or getElementHealth(localPlayer) == 0 then
		return
	end
	if pickup._load then
		handleHitPickup(pickup)
	end
end)

function handleHitPickup(pickup)
	local vehicle = getPedOccupiedVehicle(localPlayer)
	if pickup._type == "vehiclechange" then
		if (handleHitPickupTimer and isTimer(handleHitPickupTimer)) or pickup.vehicle == getElementModel(vehicle) then
			return
		end
		local health = checkModelIsAirplane(pickup.vehicle) and getElementHealth(vehicle) or nil
		previousVehicleHeight = getElementDistanceFromCentreOfMassToBaseOfModel(vehicle)
		-- Fix for crash issue
		local model = pickup.vehicle
		handleHitPickupTimer = setTimer(function()
			if isElement(vehicle) then
				alignVehicleWithUp()
				setElementModel(vehicle, model)
				vehicleChanging(pickup.vehicle)
				if lastNosTick and getTickCount() - lastNosTick < 450 then
					addVehicleUpgrade(vehicle, 1010)
					lastNosTick = nil
				end
			end
		end, 75, 1)
		if health then
			fixVehicle(vehicle)
			setElementHealth(vehicle, health)
		end
	elseif pickup._type == "nitro" then
		if not lastNosTick or (getTickCount() - lastNosTick > 100) then
			addVehicleUpgrade(vehicle, 1010)
			lastNosTick = getTickCount()
		end
	elseif pickup._type == "repair" then
		fixVehicle(vehicle)
	end
	triggerEvent("racepickups:onClientPickupRacepickup", localPlayer, pickup._type, pickup.vehicle)
	triggerServerEvent("onPlayerPickupRacepickupInternal", localPlayer, pickup)
	playSoundFrontEnd(46)
end

addEventHandler("loadPickup", resourceRoot,
function(pickupID)
	for i, pickup in pairs(pickups) do
		if pickup.id == pickupID then
			pickup._load = true
			setElementAlpha(pickup.object, 255)
			local vehicle = getPedOccupiedVehicle(localPlayer)
			if isElement(vehicle) then
				if isElementWithinColShape(vehicle, pickup.colshape) then
					previousVehicleHeight = getElementDistanceFromCentreOfMassToBaseOfModel(vehicle)
					handleHitPickup(pickup)
				end
			end
			return
		end
	end
end)

addEventHandler("unloadPickup", resourceRoot,
function(pickupID)
	for i, pickup in pairs(pickups) do
		if pickup.id == pickupID then
			pickup._load = false
			setElementAlpha(pickup.object, 0)
			return
		end
	end
end)

addEventHandler("racepickups:checkAllPickups", root,
function()
	local vehicle = getPedOccupiedVehicle(localPlayer)
	if isElement(vehicle) then
		for i, pickup in pairs(pickups) do
			if isElementWithinColShape(vehicle, pickup.colshape) then
				previousVehicleHeight = getElementDistanceFromCentreOfMassToBaseOfModel(vehicle)
				handleHitPickup(pickup)
			end
		end
	end
end)

function removeVehicleNitro()
	local vehicle = getPedOccupiedVehicle(localPlayer)
	if isElement(vehicle) then
		removeVehicleUpgrade(vehicle, 1010)
	end
end
addEventHandler("removeVehicleNitro", root, removeVehicleNitro)

function checkVehicleIsHelicopter()
	local vehicle = getPedOccupiedVehicle(localPlayer)
	if isElement(vehicle) then
		local model = getElementModel(vehicle)
		if model == 417 or model == 425 or model == 447 or model == 465 or model == 469 or model == 487 or model == 488 or model == 497 or model == 501 or model == 548 or model == 563 then
			setHelicopterRotorSpeed(vehicle, 0.2)
		end
	end
end

function checkModelIsAirplane(model)
	if model == 592 or model == 577 or model == 511 or model == 512 or model == 593 or model == 520 or model == 553 or model == 476 or model == 519 or model == 460 or model == 512 or model == 539 then
		return true
	end
end

-- Make vehicle upright
function directionToRotation2D(x, y)
	return rem(math.atan2(y, x) * (360/6.28) - 90, 360)
end

function alignVehicleWithUp()
	local vehicle = getPedOccupiedVehicle(localPlayer)
	if not vehicle then
		return
	end
	local matrix = getElementMatrix(vehicle)
	local Right = Vector3D:new(matrix[1][1], matrix[1][2], matrix[1][3])
	local Forwards = Vector3D:new(matrix[2][1], matrix[2][2], matrix[2][3])
	local Up = Vector3D:new(matrix[3][1], matrix[3][2], matrix[3][3])
	local Velocity = Vector3D:new(getElementVelocity(vehicle))
	local rotZ
	if Velocity:Length() > 0.05 and Up.z < 0.001 then
		rotZ = directionToRotation2D(Velocity.x, Velocity.y)
	else
		rotZ = directionToRotation2D(Forwards.x, Forwards.y)
	end
	setElementRotation(vehicle, 0, 0, rotZ)
end

addEventHandler("onClientElementStreamIn", root,
function()
	local colshape = pickupID[source]
	if colshape then
		local pickup = pickups[colshape]
		local vehicle = getPedOccupiedVehicle(localPlayer)
		if isElement(vehicle) then
			if isElementWithinColShape(vehicle, pickup.colshape) then
				previousVehicleHeight = getElementDistanceFromCentreOfMassToBaseOfModel(vehicle)
				handleHitPickup(pickup)
			end
		end
		if pickup._type == "vehiclechange" then
			pickup.isStreamed = true
		end
		visiblePickups[colshape] = source
	end
end)

addEventHandler("onClientElementStreamOut", root,
function()
	local colshape = pickupID[source]
	if colshape then
		local pickup = pickups[colshape]
		pickup.isStreamed = false
		visiblePickups[colshape] = nil
	end
end)

function updatePickups()
	local angle = math.fmod((getTickCount() - startTick) * 360/2000, 360)
	local pickup, x, y, cX, cY, cZ, pickX, pickY, pickZ
	for colshape, element in pairs(visiblePickups) do
		pickup = pickups[colshape]
		if pickup._load then
			setElementRotation(element, 0, 0, angle)
			cX, cY, cZ = getCameraMatrix()
			pickX, pickY, pickZ = pickup.x, pickup.y, pickup.z
			x, y = getScreenFromWorldPosition(pickX, pickY, pickZ + 2.85, 0.08)
			local distanceToPickup = getDistanceBetweenPoints3D(cX, cY, cZ, pickX, pickY, pickZ)
			if pickup.isStreamed and distanceToPickup < 60 and isLineOfSightClear(cX, cY, cZ, pickX, pickY, pickZ, true, false, false, true, false) and x and y then
				local scale = (60/distanceToPickup) * 0.7
				dxDrawText(pickup.vehicleName, x + 1, y + 1, x, y, tocolor(0, 0, 0, 255), scale, "default-bold", "center", "center", false, false, false, true)
				dxDrawText(pickup.vehicleName, x, y, x, y, tocolor(255, 255, 255, 255), scale, "default-bold", "center", "center", false, false, false, true)
			end
		end
	end
end