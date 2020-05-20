addEventHandler("onResourceStart", resourceRoot,
function()
	local upgradePrices, exclusiveUpgrades = exports.v_tuning:getTuningUpgrades()
	bodypartsPrice = upgradePrices["Body parts"]
	for i, player in pairs(getElementsByType("player")) do
		updatePlayerBodyparts(player)
	end
end)

function updatePlayerBodyparts(player)
	if isElement(player) then
		local bought = getPlayerTuningStats(player, "bodyparts_bought")
		if bought then
			setElementData(player, "bodyparts_bought", true)
			local data = getPlayerTuningStats(player, "bodyparts")
			if data then
				setElementData(player, "bodyparts", data)
			end
		end
	end
end
addEvent("mysql:onPlayerLogin", true)
addEventHandler("mysql:onPlayerLogin", root, function() updatePlayerBodyparts(source) end)

function handleBodypartsPurchase()
	if not getElementData(source, "LoggedIn") then
		return triggerClientEvent(source, "notification:create", source, "Purchase failed", "You are not logged in")
	end
	local bought = getPlayerTuningStats(source, "bodyparts_bought")
	if bought then
		return triggerClientEvent(source, "notification:create", source, "Purchase failed", "You have already bought body parts")
	end
	local money = tonumber(getElementData(source, "money") or 0)
	if money < bodypartsPrice then
		return triggerClientEvent(source, "notification:create", source, "Purchase failed", "You don't have enough money to buy body parts")
	end
	setPlayerTuningStats(source, "bodyparts_bought", "1")
	setElementData(source, "bodyparts_bought", true)
	takePlayerStats(source, "money", bodypartsPrice)
	triggerClientEvent(source, "notification:create", source, "Purchase successful", "You have successfully bought body parts")
end
addEvent("purchaseBodyparts", true)
addEventHandler("purchaseBodyparts", root, handleBodypartsPurchase)

function handleBodypartsUpdate(data)
	if type(data) ~= "table" then
		return print("Failed to update bodyparts for "..getPlayerName(source))
	end
	local bought = getPlayerTuningStats(source, "bodyparts_bought")
	if not bought then
		return triggerClientEvent(source, "notification:create", source, "Update failed", "You didn't buy body parts")
	end
	setPlayerTuningStats(source, "bodyparts", data)
	setElementData(source, "bodyparts", data)
	print(getPlayerName(source).." has just updated his body parts")
	triggerClientEvent(source, "notification:create", source, "Updated", "You have successfully updated your body parts")
end
addEvent("updateBodyparts", true)
addEventHandler("updateBodyparts", root, handleBodypartsUpdate)

setPlayerTuningStats = function(player, stats, value, ...)
	return exports.v_mysql:setPlayerTuningStats(player, stats, value, ...)
end

getPlayerTuningStats = function(player, stats, ...)
	return exports.v_mysql:getPlayerTuningStats(player, stats, ...)
end

takePlayerStats = function(player, stats, ...)
	return exports.v_mysql:takePlayerStats(player, stats, ...)
end