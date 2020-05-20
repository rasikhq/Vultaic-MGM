addEventHandler("onResourceStart", resourceRoot,
function()
	local upgradePrices, exclusiveUpgrades = getTuningUpgrades()
	tintsPrice = upgradePrices["Tints"]
	for i, player in pairs(getElementsByType("player")) do
		updatePlayerTints(player)
	end
end)

function updatePlayerTints(player)
	if isElement(player) then
		local bought = getPlayerTuningStats(player, "tints_bought")
		if bought then
			setElementData(player, "tints_bought", true)
			local data = getPlayerTuningStats(player, "tints")
			if data then
				setElementData(player, "tints", data)
			end
		end
	end
end
addEvent("mysql:onPlayerLogin", true)
addEventHandler("mysql:onPlayerLogin", root, function() updatePlayerTints(source) end)

function handleTintsPurchase()
	if not getElementData(source, "LoggedIn") then
		return triggerClientEvent(source, "notification:create", source, "Purchase failed", "You are not logged in")
	end
	local bought = getPlayerTuningStats(source, "tints_bought")
	if bought then
		return triggerClientEvent(source, "notification:create", source, "Purchase failed", "You have already bought tints")
	end
	local money = tonumber(getElementData(source, "money") or 0)
	if money < tintsPrice then
		return triggerClientEvent(source, "notification:create", source, "Purchase failed", "You don't have enough money to buy tints")
	end
	setPlayerTuningStats(source, "tints_bought", "1")
	setElementData(source, "tints_bought", true)
	takePlayerStats(source, "money", tintsPrice)
	triggerClientEvent(source, "notification:create", source, "Purchase succeed", "You have successfully bought tints")
end
addEvent("purchaseTints", true)
addEventHandler("purchaseTints", root, handleTintsPurchase)

function handleTintsUpdate(data)
	if type(data) ~= "table" then
		return print("Failed to update tints for "..getPlayerName(source))
	end
	local bought = getPlayerTuningStats(source, "tints_bought")
	if not bought then
		return triggerClientEvent(source, "notification:create", source, "Update failed", "You didn't buy tints")
	end
	setPlayerTuningStats(source, "tints", data)
	setElementData(source, "tints", data)
	print(getPlayerName(source).." has just updated his tints")
	triggerClientEvent(source, "notification:create", source, "Updated", "You have successfully updated your tints")
end
addEvent("updateTints", true)
addEventHandler("updateTints", root, handleTintsUpdate)