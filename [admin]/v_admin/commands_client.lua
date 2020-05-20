addEvent("admin:setClipboardText", true)
addEventHandler("admin:setClipboardText", resourceRoot, function(data)
	setClipboard(tostring(data))
end)