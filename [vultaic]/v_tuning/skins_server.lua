addEventHandler("onResourceStart", resourceRoot,
function()
	local upgradePrices, exclusiveUpgrades = getTuningUpgrades()
	skinsPrice = upgradePrices["Skins"]
	for i, player in pairs(getElementsByType("player")) do
		updatePlayerSkin(player)
	end
end)

function updatePlayerSkin(player)
	if isElement(player) then
		local bought = getPlayerTuningStats(player, "skins_bought")
		if bought then
			setElementData(player, "skins_bought", true)
			local data = getPlayerTuningStats(player, "custom_skin")
			if data then
				setElementData(player, "custom_skin", data)
			end
		end
	end
end
addEvent("mysql:onPlayerLogin", true)
addEventHandler("mysql:onPlayerLogin", root, function() updatePlayerSkin(source) end)

function handleSkinsPurchase()
	if not getElementData(source, "LoggedIn") then
		return triggerClientEvent(source, "notification:create", source, "Purchase failed", "You are not logged in")
	end
	local bought = getPlayerTuningStats(source, "skins_bought")
	if bought then
		return triggerClientEvent(source, "notification:create", source, "Purchase failed", "You have already bought skins")
	end
	local money = tonumber(getElementData(source, "money") or 0)
	if money < skinsPrice then
		return triggerClientEvent(source, "notification:create", source, "Purchase failed", "You don't have enough money to skins")
	end
	setPlayerTuningStats(source, "skins_bought", "1")
	setElementData(source, "skins_bought", true)
	takePlayerStats(source, "money", skinsPrice)
	triggerClientEvent(source, "notification:create", source, "Purchase successful", "You have successfully bought skins")
end
addEvent("purchaseSkins", true)
addEventHandler("purchaseSkins", root, handleSkinsPurchase)

function handleSkinsUpdate(data)
	local bought = getPlayerTuningStats(source, "skins_bought")
	if not bought then
		return triggerClientEvent(source, "notification:create", source, "Update failed", "You didn't buy skins")
	end
	setPlayerTuningStats(source, "custom_skin", data)
	setElementData(source, "custom_skin", data)
	print(getPlayerName(source).." has just updated his skin")
	triggerClientEvent(source, "notification:create", source, "Updated", "You have successfully updated your skin")
end
addEvent("updateSkins", true)
addEventHandler("updateSkins", root, handleSkinsUpdate)

addEventHandler("onPlayerSpawn", root,
function()
	local skin = tonumber(getElementData(source, "custom_skin")) or 0
	setElementModel(source, skin)
end)