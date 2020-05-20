addEventHandler("onResourceStart", resourceRoot,
function()
	local upgradePrices, exclusiveUpgrades = exports.v_tuning:getTuningUpgrades()
	lightsPrice = upgradePrices["Lights"]
	for i, player in pairs(getElementsByType("player")) do
		updatePlayerLights(player)
	end
end)

function updatePlayerLights(player)
	if isElement(player) then
		local bought = getPlayerTuningStats(player, "lights_bought")
		if bought then
			setElementData(player, "lights_bought", true)
			local data = getPlayerTuningStats(player, "lights")
			if data then
				if data.lights_dynamic == 1 and not isPlayerDonator(player) then
					data.lights_dynamic = 0
				end
				setElementData(player, "lights", data)
			end
		end
	end
end
addEvent("mysql:onPlayerLogin", true)
addEventHandler("mysql:onPlayerLogin", root, function() updatePlayerLights(source) end)
addEventHandler("onPlayerLogin", root, function() updatePlayerLights(source) end)

function handleLightsPurchase()
	if not getElementData(source, "LoggedIn") then
		return triggerClientEvent(source, "notification:create", source, "Purchase failed", "You are not logged in")
	end
	local bought = getPlayerTuningStats(source, "lights_bought")
	if bought then
		return triggerClientEvent(source, "notification:create", source, "Purchase failed", "You have already bought lights")
	end
	local money = tonumber(getElementData(source, "money") or 0)
	if money < lightsPrice then
		return triggerClientEvent(source, "notification:create", source, "Purchase failed", "You don't have enough money to buy lights")
	end
	setPlayerTuningStats(source, "lights_bought", "1")
	setElementData(source, "lights_bought", true)
	takePlayerStats(source, "money", lightsPrice)
	triggerClientEvent(source, "notification:create", source, "Purchase successful", "You have successfully bought lights")
end
addEvent("purchaseLights", true)
addEventHandler("purchaseLights", root, handleLightsPurchase)

function handleLightsUpdate(data)
	if type(data) ~= "table" then
		return print("Failed to update lights for "..getPlayerName(source))
	end
	local bought = getPlayerTuningStats(source, "lights_bought")
	if not bought then
		return triggerClientEvent(source, "notification:create", source, "Update failed", "You didn't buy lights")
	end
	if getElementData(source, "lights_dynamic") == 1 and not isPlayerDonator(source) then
		return triggerClientEvent(source, "notification:create", source, "Update failed", "Dynamic lights are exclusive for donators")
	end
	setPlayerTuningStats(source, "lights", data)
	setElementData(source, "lights", data)
	print(getPlayerName(source).." has just updated his lights")
	triggerClientEvent(source, "notification:create", source, "Updated", "You have successfully updated your lights")
end
addEvent("updateLights", true)
addEventHandler("updateLights", root, handleLightsUpdate)

setPlayerTuningStats = function(player, stats, value, ...)
	return exports.v_mysql:setPlayerTuningStats(player, stats, value, ...)
end

getPlayerTuningStats = function(player, stats, ...)
	return exports.v_mysql:getPlayerTuningStats(player, stats, ...)
end

takePlayerStats = function(player, stats, ...)
	return exports.v_mysql:takePlayerStats(player, stats, ...)
end

function isPlayerDonator(player)
	return exports.v_donatorship:isPlayerDonator(player)
end