local function getPositionSlang(rank)
	return rank..((rank < 10 or rank > 20) and ({ [1] = "st", [2] = "nd", [3] = "rd" })[rank % 10] or "th")
end
function onPlayerFinish(player, place)
	if(place ~= 1) then
		setElementData(player, "winStreak", 0, false)
	end
	if arena.finishedPlayers[player] ~= nil then
		return true
	end
	outputChatBox("#49846d* #ffffffYou finished: #19846d"..getPositionSlang(place), player, 255, 255, 255, true)
	arena.finishedPlayers[player] = true
	if not arena.statsEnabled then
		return
	end
	local playerStreak = getElementData(player, "winStreak")
	local money = math.ceil(arena.statsEnabled*((arena.statsEnabled-place)/2)) * (playerStreak > 0 and playerStreak or 1)
	local points = math.ceil(arena.statsEnabled*((arena.statsEnabled-place)/17.5)) * (playerStreak > 0 and playerStreak or 1)
	if points > 0 then
		exports.v_mysql:givePlayerStats(player, arena.points_key or getElementData(arena.element, "id").."_points", points)
	end
	if money > 0 then
		exports.v_mysql:givePlayerStats(player, "money", money)
	end
	outputChatBox("#19846d* #ffffffYou received #19846d"..points.." #ffffffpoint"..(points == 1 and "" or "s").." and #19846d$"..money, player, 255, 255, 255, true)
end