addEventHandler("onResourceStart", resourceRoot,
function()
	local upgradePrices, exclusiveUpgrades = exports.v_tuning:getTuningUpgrades()
	overlaysPrice = upgradePrices["Overlays"]
	for i, player in pairs(getElementsByType("player")) do
		updatePlayerOverlays(player)
	end
end)

function updatePlayerOverlays(player)
	if isElement(player) then
		local bought = getPlayerTuningStats(player, "overlays_bought")
		if bought then
			if not isPlayerDonator(player) then
				return setElementData(player, "overlays_bought", "expired")
			end
			setElementData(player, "overlays_bought", true)
			local data = getPlayerTuningStats(player, "overlays")
			if data then
				setElementData(player, "overlay", data)
			end
		end
	end
end
addEvent("mysql:onPlayerLogin", true)
addEventHandler("mysql:onPlayerLogin", root, function() updatePlayerOverlays(source) end)
addEventHandler("onPlayerLogin", root, function() updatePlayerOverlays(source) end)

function handleOverlaysPurchase()
	if not getElementData(source, "LoggedIn") then
		return triggerClientEvent(source, "notification:create", source, "Purchase failed", "You are not logged in")
	end
	local bought = getPlayerTuningStats(source, "overlays_bought")
	if bought then
		return triggerClientEvent(source, "notification:create", source, "Purchase failed", "You have already bought overlays")
	end
	local premium = isPlayerDonator(source)
	if not premium then
		return triggerClientEvent(source, "notification:create", source, "Purchase failed", "Become a donator to buy overlays")
	end
	local money = tonumber(getElementData(source, "money") or 0)
	if money < overlaysPrice then
		return triggerClientEvent(source, "notification:create", source, "Purchase failed", "You don't have enough money to buy overlays")
	end
	setPlayerTuningStats(source, "overlays_bought", 1)
	setElementData(source, "overlays_bought", true)
	takePlayerStats(source, "money", overlaysPrice)
	triggerClientEvent(source, "notification:create", source, "Purchase successful", "You have successfully bought overlays")
end
addEvent("purchaseOverlays", true)
addEventHandler("purchaseOverlays", root, handleOverlaysPurchase)

function handleOverlaysUpdate(data)
	if type(data) ~= "table" then
		return print("Failed to update overlays for "..getPlayerName(source))
	end
	local bought = getPlayerTuningStats(source, "overlays_bought")
	if not bought then
		return triggerClientEvent(source, "notification:create", source, "Update failed", "You didn't buy overlays")
	end
	setPlayerTuningStats(source, "overlays", data)
	setElementData(source, "overlay", data)
	print(getPlayerName(source).." has just updated his overlays")
	triggerClientEvent(source, "notification:create", source, "Updated", "You have successfully updated your overlays")
end
addEvent("updateOverlays", true)
addEventHandler("updateOverlays", root, handleOverlaysUpdate)

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