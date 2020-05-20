addEvent("PM:notify", true)
addEventHandler("PM:notify", localPlayer, function()
	playSound("notify.mp3")
end)