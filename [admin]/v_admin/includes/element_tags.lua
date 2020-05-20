function givePlayerTag(player, tag)
	local logged_in = getElementData(player, "LoggedIn")
	if logged_in then
		tag = tostring(tag)
		local player_tags = exports.v_mysql:getPlayerStats(player, "tags") or {}
		if not player_tags[tag] then
			player_tags[tag] = 1
			exports.v_mysql:setPlayerStats(player, "tags", player_tags)
			outputChatBox("#19846d[TAG]#FFFFFF You have been given #19846d+"..tag.."#FFFFFF tag.", player, 255, 255, 255, true)
			return true
		else
			return "#19846d[TAG]#FFFFFF Player already has the entered tag."
		end
	else
		return "#19846d[TAG]#FFFFFF Player is not logged in"
	end
end

function removePlayerTag(player, tag)
	local logged_in = getElementData(player, "LoggedIn")
	if logged_in then
		tag = tostring(tag)
		local player_tags = exports.v_mysql:getPlayerStats(player, "tags") or {}
		if player_tags[tag] then
			player_tags[tag] = nil
			exports.v_mysql:setPlayerStats(player, "tags", player_tags)
			outputChatBox("#19846d[TAG]#FFFFFF Your #19846d+"..tag.."#FFFFFF tag has been removed.", player, 255, 255, 255, true)
			return true
		else
			return "#19846d[TAG]#FFFFFF Player does not have the entered tag."
		end
	else
		return "#19846d[TAG]#FFFFFF Player is not logged in"
	end
end

function getPlayerTag(player, tag)
	local logged_in = getElementData(player, "LoggedIn")
	if logged_in then
		tag = tostring(tag)
		local player_tags = exports.v_mysql:getPlayerStats(player, "tags") or {}
		if player_tags[tag] then
			return true
		else
			return false
		end
	else
		return false
	end
end
