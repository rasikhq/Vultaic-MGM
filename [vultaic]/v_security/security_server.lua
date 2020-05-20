-- Secure connections
addEventHandler("onPlayerConnect", root,
function(nick, ip, username, serial, versionNumber)
	if not serial then
		outputDebugString("Security: "..nick.." has tried to connect without a serial number")
		outputServerLog("Security: "..nick.." has tried to connect without a serial number")
		cancelEvent(true, "You are not allowed to play here without a serial")
	end
end)

local randomIDs = {}
local playerRandomID = {}
function getRandomID()
	local id = 100
	while randomIDs[id] ~= nil do
		id = id + 1
	end
	return id
end

addEventHandler("onPlayerJoin", root,
function()
	local clearName = getPlayerName(source):gsub("#%x%x%x%x%x%x", "")
	if #clearName < 3 then
		local randomID = getRandomID()
		setPlayerName(source, "RandomDude"..randomID)
		randomIDs[randomID] = true
		playerRandomID[source] = randomID
	end
end)

addEventHandler("onPlayerQuit", root,
function()
	local randomID = playerRandomID[source]
	if randomID then
		if randomIDs[randomID] then
			randomIDs[randomID] = nil
		end
		playerRandomID[source] = nil
	end
end)

addEventHandler("onPlayerChangeNick", root,
function(oldNick, newNick)
	local clearName = newNick:gsub("#%x%x%x%x%x%x", "")
	if #clearName < 3 then
		cancelEvent()
		outputChatBox("Your nickname must contain mimimum 3 characters.", source, 255, 0, 0, true)
		return
	end
	clearName = clearName:lower()
	for i, player in pairs(getElementsByType("player")) do
		if player ~= source then
			local _clearName = getPlayerName(player):gsub("#%x%x%x%x%x%x", "")
			if _clearName:lower() == clearName then
				cancelEvent()
				outputChatBox("This nickname is already in use.", source, 255, 0, 0, true)
				return
			end
		end
	end
end)

addCommandHandler("compileres",
function(player, command, resourceName)
	if not hasObjectPermissionTo(player, "function.startResource", false) or not resourceName then
		return
	end
	local metaFile = xmlLoadFile(":"..resourceName.."/meta.xml")
	if metaFile then
		outputChatBox("Compiling resource: "..resourceName, root, 255, 255, 0)
		for i, node in pairs (xmlNodeGetChildren(metaFile)) do
			local info = xmlNodeGetAttributes(node)
			if xmlNodeGetName(node) == "script" and info["type"] == "client" then
				local file = fileOpen(":"..resourceName.."/"..info["src"], true)
				if file then
					local savePath = ":"..resourceName.."/"..info["src"].."c"
					fetchRemote("http://luac.mtasa.com/?compile=1&debug=0&obfuscate=2",
						function(data)
							if fileExists(savePath) then
								fileDelete(savePath)
							end
							local compiledFile = fileCreate(savePath)
							if compiledFile then
								fileWrite(compiledFile, data)
								fileFlush(compiledFile)
								fileClose(compiledFile)
							end
					end, fileRead(file, fileGetSize(file)) , true )
					fileClose(file)
				end
			end
		end
		xmlUnloadFile(metaFile)
	end
end)

addEventHandler("onPlayerCommand", root,
function(command)
	outputServerLog(getPlayerName(source):gsub("#%x%x%x%x%x%x", "").." has just tried to use command: '"..command.."'")
	if command == "debugscript" and not hasObjectPermissionTo(source, "function.kickPlayer", false) then
		cancelEvent()
		return
	end
end)

addEventHandler("onPlayerChangeNick", root,
function()
	if isPlayerMuted(source) and not hasObjectPermissionTo(source, "function.kickPlayer", false) then
		kickPlayer(source, "Do not change your nickname while you are muted")
	end
end)