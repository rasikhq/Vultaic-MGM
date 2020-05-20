local syncElement = createElement("scoreboard.syncElement", "scoreboard.syncElement")
setElementData(syncElement, "serverName", tostring(getServerName()))
setElementData(syncElement, "maximumPlayers", getMaxPlayers())

addEventHandler("onResourceStart", resourceRoot,
function()
	for i, player in pairs(getElementsByType("player")) do
		updatePlayerCountry(player)
	end
end)

addEventHandler("onPlayerJoin", root,
function()
	updatePlayerCountry(source)
end)

function updatePlayerCountry(player)
	if player then
		fetchRemote("http://api.ipinfodb.com/v3/ip-country/?key=e865d96b7c0266c2b999598ec728386193141fa7dde10af5696615f5a1b3cae1&format=json&ip="..getPlayerIP(player), md5(getPlayerName(player)), 5, 5000,
		function(responseData, errorNo, player)
			if errorNo == 0 and isElement(player) then
				local data = fromJSON(responseData) or {}
				setElementData(player, "countryCode", data.countryCode or "N/A")
				setElementData(player, "countryName", data.countryName or "N/A")
				triggerEvent("onPlayerCountryDetected", player, data)
			end
		end, "", false, player)
	end
end