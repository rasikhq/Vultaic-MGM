local stationURL = "http://www.energy981.com/playlist/Energy98_128WM.asx"
local streamURL = "http://164.132.114.156:8000/stream"

function playRadio()
	if isElement(radioSound) then
		return
	end
	radioSound = playSound(stationURL)
	setElementData(radioSound, "sound_type", "radio", false)
	addEventHandler("onClientSoundChangedMeta", radioSound, getSoundMeta)
end

function stopRadio()
	if isElement(radioSound) then
		removeEventHandler("onClientSoundChangedMeta", radioSound, getSoundMeta)
		destroyElement(radioSound)
	end
end

function playStream()
	if isElement(radioSound) then
		return
	end
	streamSound = playSound(streamURL)
	setElementData(streamSound, "sound_type", "stream", false)
	addEventHandler("onClientSoundChangedMeta", streamSound, getSoundMeta)
end

function stopStream()
	if isElement(streamSound) then
		removeEventHandler("onClientSoundChangedMeta", streamSound, getSoundMeta)
		destroyElement(streamSound)
	end
end

addEventHandler("onClientResourceStart", resourceRoot,
function()
	if getElementData(localPlayer, "sound_mode") == "radio" then
		playRadio()
	elseif getElementData(localPlayer, "sound_mode") == "stream" then
		playStream()
	end
end)

function getSoundMeta(streamTitle)
	local meta = getSoundMetaTags(source)
	if previousStreamTitle and previousStreamTitle == streamTitle then
		return
	end
	iprint(meta)
	local stream_title = getElementData(localPlayer, "sound_mode") == "radio" and "Radio" or "Streamer: "..tostring(meta.stream_name or "None")
	if streamTitle then
		streamTitle = streamTitle:gsub(".mp3", "")
		previousStreamTitle = streamTitle
		triggerEvent("notification:create", localPlayer, stream_title, "Playing "..streamTitle)
	end
end

addEventHandler("onClientElementDataChange", localPlayer,
function(dataName)
	if dataName ~= "sound_mode" then
		return
	end
	if getElementData(localPlayer, "sound_mode") == "radio" then
		playRadio()
	else
		stopRadio()
	end
	if getElementData(localPlayer, "sound_mode") == "stream" then
		playStream()
	else
		stopStream()
	end
end)

addCommandHandler("livestream", function(command, ...)
	local stream_token, streamer = arg[1], arg[2] or getPlayerName(localPlayer)
	if not stream_token then
		return outputChatBox("* Error: Provide a valid stream title!", 255, 0, 0)
	end
	if not isElement(streamSound) then
		return outputChatBox("* Error: Server is not receiving any live stream data", 255, 0, 0)
	end
	local meta = getSoundMetaTags(streamSound)
	iprint(meta)
	if not meta.stream_name then
		return outputChatBox("* Error: No meta data for stream", 255, 0, 0)
	end
	if not meta.stream_name:find(stream_token, 1, true) --[[meta.stream_name ~= stream_token]] then
		return outputChatBox("* Error: Invalid Stream token", 255, 0, 0)
	end
	triggerServerEvent("Music:onStreamVerify", resourceRoot, streamer)
end)