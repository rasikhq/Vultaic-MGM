addEvent("core:onPlayerLeaveArena", true)
addEventHandler("core:onPlayerLeaveArena", root,
function(arena)
	triggerClientEvent(arena.element, "overlays:destroyVehicleOverlays", resourceRoot, source)
end)