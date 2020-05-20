local sound = {current = 3}
sound.modes = {
	[1] = {mode = "none", title = "none"},
	[2] = {mode = "map_music", title = "map music"},
	[3] = {mode = "radio", title = "radio"},
	[4] = {mode = "stream", title = "stream"}
}

addEventHandler("onClientResourceStart", resourceRoot,
function()
	sound.switch()
end)

function sound.switch()
	sound.mode = sound.modes[sound.current].mode
	setElementData(localPlayer, "sound_mode", sound.mode)
	sound.toggleAll()
end

function sound.next()
	sound.current = sound.current + 1
	if sound.current > #sound.modes then
		sound.current = 1
	end
	sound.switch()
	local message = "Switched to "..sound.modes[sound.current].title
	triggerEvent("notification:create", localPlayer, "Music", message, ":scriptloader/img/music.png")
end
bindKey("M", "down", sound.next)

function sound.toggleAll()
	for i, v in pairs(getElementsByType("sound")) do
		local soundType = getElementData(v, "sound_type")
		if soundType then
			setSoundVolume(v, soundType == sound.mode and 1 or 0)
		end
	end
end

addEventHandler("onClientElementDataChange", root,
function(dataName)
	if getElementType(source) == "sound" and dataName == "sound_type" then
		local soundType = getElementData(source, "sound_type")
		setSoundVolume(source, soundType == sound.mode and 1 or 0)
	end
end)

addCommandHandler("song", function()
	for i, v in pairs(getElementsByType("sound")) do
		local soundType = getElementData(v, "sound_type")
		if soundType and soundType == sound.mode then
			local meta = getSoundMetaTags(v)
			local isRadio = meta and meta.stream_title or nil
			if isRadio then
				return outputChatBox("#19846d[SONG] #ffffff"..isRadio, 255, 255, 255, true)
			elseif not isRadio and meta and meta.title and meta.artist then
				return outputChatBox("#19846d[SONG] #ffffff" .. meta.artist .. " - " .. meta.title, 255, 255, 255, true)
			else
				return outputChatBox("#19846d[SONG] #ffffffSong meta information empty.", 255, 255, 255, true)
			end
		end
	end
	outputChatBox("#19846d[SONG] #ffffffNo song playing", 255, 255, 255, true)
end)