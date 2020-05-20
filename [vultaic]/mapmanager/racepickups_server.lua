addEvent("onPlayerPickupRacepickupInternal", true)

function setVehiclePaintjobAndUpgrades(vehicle, paintjob, upgrades)
	if paintjob then
		setVehiclePaintjob(vehicle, paintjob)
	end
	if type(upgrades) == "table" then
		local appliedUpgrade
		local appliedUpgrades = getVehicleUpgrades(vehicle)
		local k
		for i = #appliedUpgrades, 1, -1 do
			appliedUpgrade = appliedUpgrades[1]
			k = tableFind(upgrades, appliedUpgrade)
			if k then
				table.remove(upgrades, k)
			else
				removeVehicleUpgrade(vehicle, appliedUpgrade)
			end
		end
		for id, upgrade in pairs(upgrades) do
			addVehicleUpgrade(vehicle, upgrade)
		end
	end
end

addEventHandler("onPlayerPickupRacepickupInternal", root,
function(pickup)
	local vehicle = getPedOccupiedVehicle(source)
	if type(pickup) ~= "table" or not isElement(vehicle) or isElementFrozen(vehicle) then
		return
	end
	local pickupID = pickup.id
	local respawnTime = pickup.respawn
	if respawnTime and tonumber(respawnTime) >= 50 then
		triggerClientEvent(root, "unloadPickup", resourceRoot, pickupID)
		setTimer(loadPickup, tonumber(respawnTime), 1, pickupID)
	end
	if pickup._type == "nitro" then
		--addVehicleUpgrade(vehicle, 1010)
	elseif pickup._type == "vehiclechange" then
		setElementModel(vehicle, pickup.vehicle)
		if pickup.paintjob or pickup.upgrades then
			setVehiclePaintjobAndUpgrades(vehicle, pickup.paintjob, pickup.upgrades)
		end
	end
	triggerEvent("racepickups:onPlayerPickupRacepickup", source, pickup._type, pickup.vehicle, vehicle)
end)

function loadPickup(pickupID)
	triggerClientEvent(root, "loadPickup", resourceRoot, pickupID)
end

function tableFind(_table, value)
	for id, item in pairs(_table) do
		if item == value then
			return id
		end
	end
	return false
end