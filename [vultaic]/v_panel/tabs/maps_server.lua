local mapCache = {}
local lockTimers = {}
local settings = {
	price = 5000,
	lockInterval = 180 * 60000,
	customerInterval = 5 * 60000,
	discount = 0.5
}

function cacheMaps(arena, update)
	arena = isElement(arena) and arena or root
	mapCache = {}
	if arena == root then
		print("DEBUG >> Refreshing for root")
		for i, arena in pairs(getElementsByType("arena")) do
			local filter = getElementData(arena, "mapFilter")
			if filter then
				local maps, mapNames = exports.core:getMapsCompatibleWithGamemode(filter)
				mapCache[arena] = {
					real = mapNames,
					JSON = toJSON(mapNames)
				}
				if tostring(update) == "true" then
					triggerClientEvent(arena, "panel:onClientReceiveMaps", resourceRoot, mapCache[arena].JSON)
				end
			end
		end
	else
		print("DEBUG >> Refreshing for arena")
		local filter = getElementData(arena, "mapFilter")
		if filter then
			local maps, mapNames = exports.core:getMapsCompatibleWithGamemode(filter)
			mapCache[arena] = {
				real = mapNames,
				JSON = toJSON(mapNames)
			}
			if tostring(update) == "true" then
				triggerClientEvent(arena, "panel:onClientReceiveMaps", resourceRoot, mapCache[arena].JSON)
			end
		end
	end
end
addEventHandler("onResourceStart", resourceRoot, cacheMaps)
addEvent("mapmanager:onMapsRefresh", true)
addEventHandler("mapmanager:onMapsRefresh", root, function() cacheMaps(source, true) end)

addEvent("panel:onPlayerRequestMaps", true)
addEventHandler("panel:onPlayerRequestMaps", root,
function()
	local arena = getElementParent(source)
	if not isElement(arena) then
		return
	end
	if not mapCache[arena] then
		local filter = getElementData(arena, "mapFilter")
		if filter then
			local maps, mapNames = exports.core:getMapsCompatibleWithGamemode(filter)
			mapCache[arena] = {
				real = mapNames,
				JSON = toJSON(mapNames)
			}
		end
	end
	if mapCache[arena] then
		triggerClientEvent(source, "panel:onClientReceiveMaps", resourceRoot, mapCache[arena].JSON, lockTimers[arena])
	end
end)

addEvent("panel:onPlayerRequestBuyMap", true)
addEventHandler("panel:onPlayerRequestBuyMap", root,
function(resourceName)
	if not resourceName then
		return
	end
	local arena = getElementParent(source)
	if isElement(arena) and mapCache[arena] then
		local resource = getElementData(arena, "resource")
		if resource and getResourceState(resource) == "running" then
			local logged = getElementData(source, "LoggedIn")
			if not logged then
				return panel.displayMessage(source, "Maps", "You have to be logged in to buy maps", ":v_panel/img/maps.png")
			end
			if getElementData(arena, "disable_shop") == true then
				return panel.displayMessage(source, "Maps", "Map shop is disabled for this arena", ":v_panel/img/maps.png")
			end
			local mapResource = getResourceFromName(resourceName)
			if mapResource then
				local tags = getResourceInfo(mapResource, "tags")
				if tags then
					tags = split(tags, " ")
					for i = 1, #tags do
						if tags[i] == "training" then
							return panel.displayMessage(source, "Maps", "This map is available in Training Arena Only", ":v_panel/img/maps.png")
						end
					end
				end
			end
			local timer = isPlayerAbleToBuyMap(source)
			if timer then
				local details = timer:getDetails()
				local left = math.floor(details/1000/60)
				local prefix = "minute"
				if left == 0 then
					left = math.floor(details/1000)
					prefix = "second"
				end
				return panel.displayMessage(source, "Maps", "Please wait "..left.." "..prefix..(left == 1 and "" or "s").." to buy a map again", ":v_panel/img/maps.png")
			end
			local mapName = mapCache[arena].real[resourceName]
			if not mapName then
				return panel.displayMessage(source, "Maps", "Failed to buy map, please contact an administrator", ":v_panel/img/maps.png")
			end
			local timer = lockTimers[arena] and lockTimers[arena][resourceName] or nil
			if timer and timer:isActive() then
				local details = timer:getDetails()
				local left = math.floor(details/1000/60)
				return panel.displayMessage(source, "Maps", "This map will be unlocked in "..left.." "..(minute == 1 and "minute" or "minutes"), ":v_panel/img/maps.png")
			end
			local price = settings.price
			if isPlayerDonator(source) then
				price = price - price * settings.discount
			end
			local money = tonumber(getElementData(source, "money") or 0)
			if money < price then
				return panel.displayMessage(source, "Maps", "You don't have enough money to buy maps", ":v_panel/img/maps.png")
			end
			local result, info = call(resource, "setNextMap", resourceName)
			if result == "success" then
				takePlayerStats(source, "money", price)
				if not lockTimers[arena] then
					lockTimers[arena] = {}
				end
				lockTimers[arena][resourceName] = Timer:create(true)
				lockTimers[arena][resourceName]:setTimer(function() 
					panel.displayMessage(arena, "Maps", "Map "..mapName.." is now available", ":v_panel/img/maps.png")
					lockTimers[arena][resourceName] = nil
					triggerClientEvent(arena, "panel:onClientReceiveLockTable", resourceRoot, lockTimers[arena])
				end, settings.lockInterval, 1)
				local serial = getPlayerSerial(source)
				lockTimers[serial] = Timer:create(true)
				local player = source
				lockTimers[serial]:setTimer(function()
					panel.displayMessage(player, "Maps", "You can buy a map again now", ":v_panel/img/maps.png")
					lockTimers[serial] = nil
				end, settings.customerInterval, 1)
				triggerClientEvent(arena, "panel:onClientReceiveLockTable", resourceRoot, lockTimers[arena])
				panel.displayMessage(source, "Maps", "You bought "..mapName.." as the next map for $"..price, ":v_panel/img/maps.png")
				outputChatBox("#19846D[Maps] #FFFFFF"..getPlayerName(source).." #FFFFFFhas just bought #19846D"..info.." #FFFFFFas the next map", arena, 255, 255, 255, true)
			elseif result == "nextmap_is_set" then
				return panel.displayMessage(source, "Maps", "Next map is already set", ":v_panel/img/maps.png")
			elseif result == "not_specified" or result == "not_found" then
				return panel.displayMessage(source, "Maps", "Unknown error, please contact an administrator", ":v_panel/img/maps.png")
			elseif result == "map_is_already_set" then
				return panel.displayMessage(source, "Maps", "This map is already bought as the next map", ":v_panel/img/maps.png")
			end
		end
	end
end)

function isPlayerAbleToBuyMap(player)
	if isElement(player) then
		local serial = getPlayerSerial(player)
		if lockTimers[serial] then
			return lockTimers[serial]
		end
	end
end

addEvent("core:onArenaUnregister", true)
addEventHandler("core:onArenaUnregister", root,
function()
	if mapCache[source] then
		mapCache[source] = nil
	end
	if lockTimers[source] then
		for i, timer in pairs(lockTimers[source]) do
			timer:destroy()
		end
		lockTimers[source] = nil
	end
end)