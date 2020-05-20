--[[
	Vultaic::Addon::Killdetector
--]]
function onPlayerKill(killer)
	if(killer == client) then
		--outputChatBox(("#19846dKill :: #FFFFFF%s#FFFFFF killed himself!"):format(getPlayerName(killer)), getElementParent(killer), 255, 255, 255, true);
	else
		triggerClientEvent(client, "killmessage:create", client, {player = killer, action = "killer"})
		triggerClientEvent(killer, "killmessage:create", killer, {player = client, action = "killed"})
		triggerEvent("onArenaKill", getElementParent(killer), killer, player)
	end
end
addEvent("onPlayerKill", true)
addEventHandler("onPlayerKill", root, onPlayerKill)