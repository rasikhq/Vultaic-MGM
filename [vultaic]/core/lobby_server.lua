local lobbyElement = createElement("arena", "lobby")
local lobbyDimension = 0

function movePlayerToLobby(player)
	if isElement(player) then
		local arena = getElementParent(player)
		setElementParent(player, lobbyElement)
		setElementDimension(player, lobbyDimension)
		setElementData(player, "arena", "lobby")
		spawnPlayer(player, 0, 0, 5)
		setElementFrozen(player, true)
		setCameraMatrix(player, 554.77648925781, -1614.8415527344, 30.357982635498, 490.26504516602, -1538.7777099609, 37.608291625977)
		if isElement(arena) and arena ~= root and arena ~= lobbyElement then
			triggerClientEvent(arena, "notification:create", arena, "Arena", getPlayerName(player).." #FFFFFFhas left the arena", "joinquit", "leave")
		end
	end
end

-- Move everyone to lobby on resource start
addEventHandler("onResourceStart", resourceRoot,
function()
	setGameType("AURORAMTA.COM")
	setElementData(lobbyElement, "name", "Lobby")
	for i, player in pairs(getElementsByType("player")) do
		local arena = getElementData(source, "arena")
		if arena then
			removePlayerFromArena(player, arena)
		end
		movePlayerToLobby(player)
		assignPlayerID(player)
	end
end)