addEventHandler("onResourceStart", resourceRoot,
function()
	local upgradePrices, exclusiveUpgrades = getTuningUpgrades()
	colorsPrice = upgradePrices["Colors"]
	rocketColorsPrice = upgradePrices["Rocket color"]
	for i, player in pairs(getElementsByType("player")) do
		updatePlayerColors(player)
	end
	for i, vehicle in pairs(getElementsByType("vehicle")) do
		updateVehicleColors(vehicle, getVehicleOccupant(vehicle))
	end
end)

function updatePlayerColors(player)
	if isElement(player) then
		do
			local bought = getPlayerTuningStats(player, "colors_bought")
			if bought then
				setElementData(player, "colors_bought", true)
				local data = getPlayerTuningStats(player, "colors")
				if data then
					setElementData(player, "colors", data)
				end
			end
		end
		do
			local bought = getPlayerTuningStats(player, "rocketcolor_bought")
			if bought then
				setElementData(player, "rocketcolor_bought", true)
				local data = getPlayerTuningStats(player, "rocketcolor")
				if data then
					setElementData(player, "rocketcolor", data)
				end
			end
		end
	end
end
addEvent("mysql:onPlayerLogin", true)
addEventHandler("mysql:onPlayerLogin", root, function() updatePlayerColors(source) end)

function handleColorsPurchase()
	if not getElementData(source, "LoggedIn") then
		return triggerClientEvent(source, "notification:create", source, "Purchase failed", "You are not logged in")
	end
	local bought = getPlayerTuningStats(source, "colors_bought")
	if bought then
		return triggerClientEvent(source, "notification:create", source, "Purchase failed", "You have already bought colors")
	end
	local money = tonumber(getElementData(source, "money") or 0)
	if money < colorsPrice then
		return triggerClientEvent(source, "notification:create", source, "Purchase failed", "You don't have enough money to buy colors")
	end
	setPlayerTuningStats(source, "colors_bought", "1")
	setElementData(source, "colors_bought", true)
	takePlayerStats(source, "money", colorsPrice)
	triggerClientEvent(source, "notification:create", source, "Purchase successful", "You have successfully bought colors")
end
addEvent("purchaseColors", true)
addEventHandler("purchaseColors", root, handleColorsPurchase)

function handleColorsUpdate(data)
	if type(data) ~= "table" then
		return print("Failed to update colors for "..getPlayerName(source))
	end
	local bought = getPlayerTuningStats(source, "colors_bought")
	if not bought then
		return triggerClientEvent(source, "notification:create", source, "Update failed", "You didn't buy colors")
	end
	setPlayerTuningStats(source, "colors", data)
	setElementData(source, "colors", data)
	print(getPlayerName(source).." has just updated his colors")
	triggerClientEvent(source, "notification:create", source, "Updated", "You have successfully updated your colors")
end
addEvent("updateColors", true)
addEventHandler("updateColors", root, handleColorsUpdate)

function updateVehicleColors(vehicle, player)
	if isElement(vehicle) then
		local player = isElement(player) and player or getVehicleOccupant(vehicle)
		local colors, wheels = {}, {}
		if isElement(player) then
			colors, wheels = getElementData(player, "colors") or {}, getElementData(player, "wheels") or {}
		end
		local r1, g1, b1 = hexToRGB(colors.color_1 or "#FFFFFF")
		local r2, g2, b2 = hexToRGB(colors.color_2 or "#FFFFFF")
		local r3, g3, b3 = hexToRGB(wheels.wheels_color or "#FFFFFF")
		setVehicleColor(vehicle, r1, g1, b1, r2, g2, b2, r3, g3, b3)
		setVehicleHeadLightColor(vehicle, hexToRGB(colors.color_headlights or "#FFFFFF"))
		setVehicleOverrideLights(vehicle, 2)
	end
end

addEventHandler("onPlayerVehicleEnter", root,
function(vehicle, seat)
	if seat == 0 then
		updateVehicleColors(vehicle, source)
	end	
end)

function handleRocketColorPurchase()
	if not getElementData(source, "LoggedIn") then
		return triggerClientEvent(source, "notification:create", source, "Purchase failed", "You are not logged in")
	end
	local bought = getPlayerTuningStats(source, "rocketcolor_bought")
	if bought then
		return triggerClientEvent(source, "notification:create", source, "Purchase failed", "You have already bought rocket color")
	end
	local money = tonumber(getElementData(source, "money") or 0)
	if money < rocketColorsPrice then
		return triggerClientEvent(source, "notification:create", source, "Purchase failed", "You don't have enough money to buy rocket color")
	end
	setPlayerTuningStats(source, "rocketcolor_bought", "1")
	setElementData(source, "rocketcolor_bought", true)
	takePlayerStats(source, "money", rocketColorsPrice)
	triggerClientEvent(source, "notification:create", source, "Purchase successful", "You have successfully bought rocket color")
end
addEvent("purchaseRocketColor", true)
addEventHandler("purchaseRocketColor", root, handleRocketColorPurchase)

function handleRocketColorUpdate(data)
	if type(data) ~= "table" then
		return print("Failed to update rocket color for "..getPlayerName(source))
	end
	local bought = getPlayerTuningStats(source, "rocketcolor_bought")
	if not bought then
		return triggerClientEvent(source, "notification:create", source, "Update failed", "You didn't buy rocket color")
	end
	setPlayerTuningStats(source, "rocketcolor", data)
	setElementData(source, "rocketcolor", data)
	print(getPlayerName(source).." has just updated his rocket color")
	triggerClientEvent(source, "notification:create", source, "Updated", "You have successfully updated your rocket color")
end
addEvent("updateRocketColor", true)
addEventHandler("updateRocketColor", root, handleRocketColorUpdate)