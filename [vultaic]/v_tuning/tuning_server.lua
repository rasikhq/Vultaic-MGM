local upgradePrices = {
	["Colors"] = 15000,
	["Tints"] = 50000,
	["Wheels"] = 25000, --150000
	["Body parts"] = 200000,
	["Stickers"] = 50000, --150000
	["Lights"] = 50000,
	["Overlays"] = 50000,
	["Neons"] = 50000,
	["Rocket color"] = 25000,
	["Skins"] = 15000
}
local exclusiveUpgrades = {
	["Overlays"] = true,
	["Neons"] = true,
	["Dynamic lights"] = true
}

function getTuningUpgrades()
	if client then
		triggerClientEvent(client, "onClientReceiveTuningUpgrades", client, upgradePrices, exclusiveUpgrades)
	else
		return upgradePrices, exclusiveUpgrades
	end
end
addEvent("getTuningUpgrades", true)
addEventHandler("getTuningUpgrades", root, getTuningUpgrades)

function getPremiumStatus(player)
	if isElement(player) then
		return getElementData(player, "donator") or getElementData(player, "member") and true or false
	end
end

--[[addEventHandler("onElementModelChange", root,
function(oldModel, newModel)
	if getElementType(source) == "vehicle" then
		local occupant = getVehicleOccupant(source)
		if not isElement(occupant) then
			return
		end
		triggerClientEvent(getElementParent(occupant), "onClientElementModelChange", resourceRoot, source, oldModel, newModel)
	end
end)]]--

function hexToRGB(hex)
	hex = hex:gsub("#", "") 
	return tonumber("0x"..hex:sub(1, 2)) or 255, tonumber("0x"..hex:sub(3, 4)) or 255, tonumber("0x"..hex:sub(5, 6)) or 255
end

setPlayerTuningStats = function(player, stats, value, ...)
	return exports.v_mysql:setPlayerTuningStats(player, stats, value, ...)
end

getPlayerTuningStats = function(player, stats, ...)
	return exports.v_mysql:getPlayerTuningStats(player, stats, ...)
end

takePlayerStats = function(player, stats, ...)
	return exports.v_mysql:takePlayerStats(player, stats, ...)
end