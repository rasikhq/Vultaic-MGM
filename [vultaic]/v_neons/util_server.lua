addEvent("core:onPlayerLeaveArena", true)
addEventHandler("core:onPlayerLeaveArena", root,
function(arena)
	triggerClientEvent(arena.element, "neons:destroyVehicleNeon", resourceRoot, source)
end)