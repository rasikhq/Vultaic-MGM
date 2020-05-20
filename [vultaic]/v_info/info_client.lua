local IS_MINIMIZED = false
addEvent("mapmanager:onMapLoad", true)
addEventHandler("mapmanager:onMapLoad", localPlayer, function()
	if IS_MINIMIZED then
		setWindowFlashing(true)
	end
end)

addEventHandler("onClientMinimize", root, function()
	IS_MINIMIZED = true
end)

addEventHandler("onClientRestore", root, function()
	IS_MINIMIZED = false
end)