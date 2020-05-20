addEvent("core:onPlayerLeaveArena", true)
addEventHandler("core:onPlayerLeaveArena", root,
function(arena)
	triggerClientEvent(arena.element, "paints:destroyPlayerPaints", resourceRoot, source)
end)