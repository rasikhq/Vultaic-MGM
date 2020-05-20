local data = {}

addEvent("mysql:onClientLogin", true)
addEventHandler("mysql:onClientLogin", localPlayer, function(_data)
	data = _data
end)

addEvent("CAccount:onClientStatsUpdate", true)
addEventHandler("CAccount:onClientStatsUpdate", localPlayer, function(key, value)
	if data["data"][key] then
		data["data"][key] = value
	elseif data["tuning"][key] then
		data["tuning"][key] = value
	else
		data["data"][key] = value
	end
end)

--[[ Exported functions ]]--
function getPlayerStats(key)
	if not getElementData(localPlayer, "LoggedIn") then
		return
	end
	if data["temporary"] ~= nil and data["temporary"][key] ~= nil then
		return data["temporary"][key]
	elseif getElementData(localPlayer, key) then
		return getElementData(localPlayer, key)
	end
	return data[key] or false
end

function getPlayerStats_data(key)
	if not getElementData(localPlayer, "LoggedIn") then
		return
	end
	return data["data"][key] or false
end

function getPlayerStats_tuning(key)
	if not getElementData(localPlayer, "LoggedIn") then
		return
	end
	return data["tuning"][key] or false
end