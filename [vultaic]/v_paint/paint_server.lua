addEventHandler("onResourceStart", resourceRoot,
function()
	local upgradePrices, exclusiveUpgrades = exports.v_tuning:getTuningUpgrades()
	stickersPrice = upgradePrices["Stickers"]
	for i, player in pairs(getElementsByType("player")) do
		updatePlayerStickers(player)
	end
end)

function updatePlayerStickers(player)
	if isElement(player) then
		local bought = getPlayerTuningStats(player, "stickers_bought")
		if bought then
			local premium = isPlayerDonator(player)
			local slots = premium and 32 or 16
			setElementData(player, "stickers_bought", true)
			setElementData(player, "paint_slots", slots)
			local data = getPlayerTuningStats(player, "stickers")
			if data then
				for i = 1, slots do
					local slot = data["slot_"..i] or nil
					if slot then
						for k, v in pairs(slot) do
							slot[k] = tostring(v)
						end
					end
					setElementData(player, "paint_slot_"..i, slot and toJSON(slot) or nil)
				end
			end
		end
	end
end
addEvent("mysql:onPlayerLogin", true)
addEventHandler("mysql:onPlayerLogin", root, function() updatePlayerStickers(source) end)
addEventHandler("onPlayerLogin", root, function() updatePlayerStickers(source) end)

function handleStickersPurchase()
	if not getElementData(source, "LoggedIn") then
		return triggerClientEvent(source, "notification:create", source, "Purchase failed", "You are not logged in")
	end
	local bought = getPlayerTuningStats(source, "stickers_bought")
	if bought then
		return triggerClientEvent(source, "notification:create", source, "Purchase failed", "You have already bought stickers")
	end
	local money = tonumber(getElementData(source, "money") or 0)
	if money < stickersPrice then
		return triggerClientEvent(source, "notification:create", source, "Purchase failed", "You don't have enough money to buy stickers")
	end
	local premium = isPlayerDonator(player)
	local slots = premium and 32 or 16
	setPlayerTuningStats(source, "stickers_bought", "1")
	setElementData(source, "stickers_bought", true)
	setElementData(source, "paint_slots", slots)
	takePlayerStats(source, "money", stickersPrice)
	triggerClientEvent(source, "notification:create", source, "Purchase successful", "You have successfully bought stickers")
end
addEvent("purchaseStickers", true)
addEventHandler("purchaseStickers", root, handleStickersPurchase)

function handleStickersUpdate(data)
	if type(data) ~= "table" then
		return print("Failed to update stickers for "..getPlayerName(source))
	end
	local bought = getPlayerTuningStats(source, "stickers_bought")
	if not bought then
		return triggerClientEvent(source, "notification:create", source, "Update failed", "You didn't buy stickers")
	end
	local slots = tonumber(getElementData(source, "paint_slots") or 16)
	if slots then
		for i = 1, slots do
			local slot = data["slot_"..i] or nil
			if slot then
				for k, v in pairs(slot) do
					slot[k] = tostring(v)
				end
			end
			setElementData(source, "paint_slot_"..i, slot and toJSON(slot) or nil)
		end
		setPlayerTuningStats(source, "stickers", data)
		print(getPlayerName(source).." has just updated his stickers")
		triggerClientEvent(source, "notification:create", source, "Updated", "You have successfully updated your stickers")
	end
end
addEvent("updateStickers", true)
addEventHandler("updateStickers", root, handleStickersUpdate)

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