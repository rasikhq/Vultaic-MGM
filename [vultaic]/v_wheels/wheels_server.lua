addEventHandler("onResourceStart", resourceRoot,
function()
	local upgradePrices, exclusiveUpgrades = exports.v_tuning:getTuningUpgrades()
	wheelsPrice = upgradePrices["Wheels"]
	for i, player in pairs(getElementsByType("player")) do
		updatePlayerWheels(player)
	end
	for i, vehicle in pairs(getElementsByType("vehicle")) do
		upgradeVehicleWheels(vehicle, getVehicleOccupant(vehicle))
	end
end)

function updatePlayerWheels(player)
	if isElement(player) then
		local bought = getPlayerTuningStats(player, "wheels_bought")
		if bought then
			setElementData(player, "wheels_bought", true)
			local data = getPlayerTuningStats(player, "wheels")
			if data then
				setElementData(player, "wheels", data)
			end
		end
	end
end
addEvent("mysql:onPlayerLogin", true)
addEventHandler("mysql:onPlayerLogin", root, function() updatePlayerWheels(source) end)

function handleWheelsPurchase()
	if not getElementData(source, "LoggedIn") then
		return triggerClientEvent(source, "notification:create", source, "Purchase failed", "You are not logged in")
	end
	local bought = getPlayerTuningStats(source, "wheels_bought")
	if bought then
		return triggerClientEvent(source, "notification:create", source, "Purchase failed", "You have already bought wheels")
	end
	local money = tonumber(getElementData(source, "money") or 0)
	if money < wheelsPrice then
		return triggerClientEvent(source, "notification:create", source, "Purchase failed", "You don't have enough money to buy wheels")
	end
	setPlayerTuningStats(source, "wheels_bought", "1")
	setElementData(source, "wheels_bought", true)
	takePlayerStats(source, "money", wheelsPrice)
	triggerClientEvent(source, "notification:create", source, "Purchase successful", "You have successfully bought wheels")
end
addEvent("purchaseWheels", true)
addEventHandler("purchaseWheels", root, handleWheelsPurchase)

function handleWheelsUpdate(data)
	if type(data) ~= "table" then
		return print("Failed to update wheels for "..getPlayerName(source))
	end
	local bought = getPlayerTuningStats(source, "wheels_bought")
	if not bought then
		return triggerClientEvent(source, "notification:create", source, "Update failed", "You didn't buy wheels")
	end
	setPlayerTuningStats(source, "wheels", data)
	setElementData(source, "wheels", data)
	print(getPlayerName(source).." has just updated his wheels")
	triggerClientEvent(source, "notification:create", source, "Updated", "You have successfully updated your wheels")
end
addEvent("updateWheels", true)
addEventHandler("updateWheels", root, handleWheelsUpdate)

function upgradeVehicleWheels(vehicle, player)
	if isElement(vehicle) then
		local player = isElement(player) and player or getVehicleOccupant(vehicle)
		local data = isElement(player) and getElementData(player, "wheels") or {}
		addVehicleUpgrade(vehicle, tonumber(data.wheels_model or 1082))
		if not isElement(player) then
			local r1, g1, b1, r2, g2, b2 = getVehicleColor(vehicle, true)
			setVehicleColor(vehicle, r1, g1, b1, r2, g2, b2, 255, 255, 255)
		end
	end
end

addEventHandler("onPlayerVehicleEnter", root,
function(vehicle, seat)
	if seat == 0 then
		upgradeVehicleWheels(vehicle, source)
	end	
end)

addEvent("racepickups:onPlayerPickupRacepickup", true)
addEventHandler("racepickups:onPlayerPickupRacepickup", root,
function(pickupType, pickupVehicle, vehicle)
	if pickupType == "vehiclechange" then
		upgradeVehicleWheels(vehicle, source)
	end
end)

addEventHandler("onElementModelChange", root,
function(oldModel, newModel)
	if getElementType(source) == "vehicle" then
		local player = getVehicleOccupant(source)
		if not isElement(player) then
			return
		end
		local vehicle = source
		setTimer(upgradeVehicleWheels, 50, 1, vehicle, player)
	end
end)

setPlayerTuningStats = function(player, stats, value, ...)
	return exports.v_mysql:setPlayerTuningStats(player, stats, value, ...)
end

getPlayerTuningStats = function(player, stats, ...)
	return exports.v_mysql:getPlayerTuningStats(player, stats, ...)
end

takePlayerStats = function(player, stats, ...)
	return exports.v_mysql:takePlayerStats(player, stats, ...)
end