local settings = {
	name = "Garage",
	id = "garage",
	requireLogin = true
}
local garage = {}
addEvent("mapmanager:onPlayerLoadMap", true)

addEventHandler("onResourceStart", resourceRoot,
function()
	local data = exports.core:registerArena(settings)
	if not data then
		outputDebugString("Failed to start arena")
		return
	end
	garage.element = data.element
	garage.dimension = data.dimension
	garage.map = exports.mapmanager:loadMapData(garage.element, "vultaic-garage-map-new")
	addEventHandler("mapmanager:onPlayerLoadMap", garage.element, handlePlayerLoad)
	if not garage.map then
		print("Failed to load garage map!")
	end
end)

addEventHandler("onResourceStop", resourceRoot,
function()
	exports.mapmanager:unloadMapData(garage.element, garage.map.info.resourceName)
end)

function movePlayerToArena(player)
	exports.mapmanager:sendMapData(garage.element, garage.map.info.resourceName, {player})
end

function removePlayerFromArena(player)
	triggerClientEvent(player, "garage:onClientLeaveGarage", resourceRoot)
end

function handlePlayerLoad()
	triggerClientEvent(source, "garage:onClientJoinGarage", resourceRoot)
end