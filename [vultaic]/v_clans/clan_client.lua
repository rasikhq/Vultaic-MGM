Clans = {}
addEventHandler("onClientResourceStart", resourceRoot, function()
	triggerServerEvent("Clans:onPlayerRequestClans", resourceRoot)
end)

addEvent("Clans:onPlayerReceiveClans", true)
addEventHandler("Clans:onPlayerReceiveClans", resourceRoot, function(_Clans)
	Clans = _Clans
	triggerEvent("Clans:onClandataUpdate", root, Clans)
end)

addEvent("Clans:onClientReceiveClans", true)
addEventHandler("Clans:onClientReceiveClans", localPlayer, function(_Clans)
	Clans = _Clans
	triggerEvent("Clans:onClandataUpdate", root, Clans)
end)

addEvent("Clans:onPlayerReceiveClanUpdate", true)
addEventHandler("Clans:onPlayerReceiveClanUpdate", resourceRoot, function(_Clan)
	if type(_Clan) == "table" then
		Clans[_Clan.ClanID] = _Clan
	elseif type(_Clan) == "number" then
		Clans[_Clan] = nil
	end
	triggerEvent("Clans:onClandataUpdate", root, Clans)
end)

--[[ Exports ]]--
function getRegisteredClans()
	return Clans
end