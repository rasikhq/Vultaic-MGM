addEventHandler("onResourceStart", resourceRoot,
function()
	local upgradePrices, exclusiveUpgrades = exports.v_tuning:getTuningUpgrades()
	neonsPrice = upgradePrices["Neons"]
	for i, player in pairs(getElementsByType("player")) do
		updatePlayerNeons(player)
	end
end)

function updatePlayerNeons(player)
	if isElement(player) then
		local bought = getPlayerTuningStats(player, "neons_bought")
		if bought then
			if not isPlayerDonator(player) then
				return setElementData(player, "neons_bought", "expired")
			end
			setElementData(player, "neons_bought", true)
			local data = getPlayerTuningStats(player, "neons")
			if data then
				setElementData(player, "neon", data)
			end
		end
	end
end
addEvent("mysql:onPlayerLogin", true)
addEventHandler("mysql:onPlayerLogin", root, function() updatePlayerNeons(source) end)
addEventHandler("onPlayerLogin", root, function() updatePlayerNeons(source) end)

function handleNeonsPurchase()
	if not getElementData(source, "LoggedIn") then
		return triggerClientEvent(source, "notification:create", source, "Purchase failed", "You are not logged in")
	end
	local bought = getPlayerTuningStats(source, "neons_bought")
	if bought then
		return triggerClientEvent(source, "notification:create", source, "Purchase failed", "You have already bought neons")
	end
	local premium = isPlayerDonator(source)
	if not premium then
		return triggerClientEvent(source, "notification:create", source, "Purchase failed", "Become a donator to buy neons")
	end
	local money = tonumber(getElementData(source, "money") or 0)
	if money < neonsPrice then
		return triggerClientEvent(source, "notification:create", source, "Purchase failed", "You don't have enough money to buy neons")
	end
	setPlayerTuningStats(source, "neons_bought", "1")
	setElementData(source, "neons_bought", true)
	takePlayerStats(source, "money", neonsPrice)
	triggerClientEvent(source, "notification:create", source, "Purchase successful", "You have successfully bought neons")
end
addEvent("purchaseNeons", true)
addEventHandler("purchaseNeons", root, handleNeonsPurchase)

function handleNeonsUpdate(data)
	if type(data) ~= "table" then
		return print("Failed to update neons for "..getPlayerName(source))
	end
	local bought = getPlayerTuningStats(source, "neons_bought")
	if not bought then
		return triggerClientEvent(source, "notification:create", source, "Update failed", "You didn't buy neons")
	end
	setPlayerTuningStats(source, "neons", data)
	setElementData(source, "neon", data)
	print(getPlayerName(source).." has just updated his neons")
	triggerClientEvent(source, "notification:create", source, "Updated", "You have successfully updated your neons")
end
addEvent("updateNeons", true)
addEventHandler("updateNeons", root, handleNeonsUpdate)

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