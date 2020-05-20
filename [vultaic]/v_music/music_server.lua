addEvent("Music:onStreamVerify", true)
addEventHandler("Music:onStreamVerify", resourceRoot, function(streamer)
	outputChatBox("#00ff00[Live Stream] #ffffffLive stream is online! Streamer: "..streamer.."#ffffff. M -> Stream to tune in!", root, 255, 255, 255, true)
end)