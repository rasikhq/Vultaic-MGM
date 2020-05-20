panel = {}

function panel.displayMessage(player, title, message, ...)
	if isElement(player) then
		triggerClientEvent("notification:create", player, tostring(title), tostring(message), ...)
	end
end

function isPlayerDonator(player)
	return exports.v_donatorship:isPlayerDonator(player)
end

setPlayerStats = function(player, stats, value, ...)
	return exports.v_mysql:setPlayerStats(player, stats, value, ...)
end

getPlayerStats = function(player, stats, ...)
	return exports.v_mysql:getPlayerStats(player, stats, ...)
end

takePlayerStats = function(player, stats, ...)
	return exports.v_mysql:takePlayerStats(player, stats, ...)
end