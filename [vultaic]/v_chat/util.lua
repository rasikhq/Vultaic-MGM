function getPlayerFromID(id)
	id = tonumber(id)
	if type(id) ~= "number" then
		return nil
	end
	for _, player in ipairs(getElementsByType("player")) do
		if getElementData(player, "id") == id then
			return player
		end
	end
	return nil
end

function getPlayer(name, lookup)
	if tonumber(name) then
		return getPlayerFromID(tonumber(name))
	end
	--
	local name = name and name:gsub("#%x%x%x%x%x%x", ""):lower() or nil
	if not name then
		return
	end
	lookup = lookup or root
	--
	for _, player in ipairs(getElementsByType("player", lookup)) do
		local player_name = getPlayerName(player):gsub("#%x%x%x%x%x%x", ""):lower()
		if player_name:find(name, 1, true) then
			return player
		end
	end
end