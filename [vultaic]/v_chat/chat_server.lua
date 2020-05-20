local avoidFlood = true
local messageColor = "#EBDDB2"
local lastMessageTick = {}
local ignore_list = {}
local disableGlobal = nil

local COMMAND_PERMISSION = exports.v_admin:getCommandLevels()
COMMAND_PERMISSION["tglobal"] = 3

addCommandHandler("tglobal",
function(player, command)
	local player_level = getElementData(player, "admin_level") or 1
	if player_level >= COMMAND_PERMISSION[command] then
		disableGlobal = not disableGlobal
		outputChatBox("Global chat has been "..(disableGlobal and "#FF0000disabled" or "#00FF00enabled").." #FFFFFFby "..getPlayerName(player), root, 255, 255, 255, true)
	end
end)

function handlePlayerChat(message, messageType)
	cancelEvent()
	if isPlayerMuted(source) then
		return outputChatBox("You are muted", source, 255, 0, 0, true)
	end
	if avoidFlood then
		local tick = lastMessageTick[source]
		if tick and getTickCount() - tick < 750 then
			lastMessageTick[source] = nil
			return outputChatBox("Please refrain from spamming", source, 255, 0, 0, true) 
		end		
	end
	local parent = getElementParent(source)
	if not isElement(parent) then
		return
	end
	-- 0: Arena chat
	-- 1: /me
	-- 2: Team chat
	-- 3: Global chat
	-- 4: Language chat
	if messageType == 0 then
		if getElementData(source, "disable_arenachat") == "On" then
			return outputChatBox("Arena chats are disabled for you", source, 255, 0, 0, true)
		end
		local var, spacesCount = string.gsub(message, " ", "")
		if (spacesCount > 0 and #var == 0) or #message < 1 then
			return outputChatBox("Your message seems to be empty", source, 255, 0, 0, true)
		end
		--if not isASCII(message) then
		--	return outputChatBox("Your message contains illegal characters", source, 255, 0, 0, true)
		--end
		local alphabetics = getAlphabetic(message)
		if #alphabetics > 4 and alphabetics == alphabetics:upper() then
			return outputChatBox("Stop shouting!", source, 255, 0, 0, true)
		end
		local r, g, b = getPlayerTeamColor(source)
		for i, player in pairs(getElementChildren(parent, "player")) do
			if getElementData(player, "disable_arenachat") ~= "On" then
				if not ignore_list[player][getPlayerSerial(source)] then
					outputChatBox(getPlayerName(source)..": "..messageColor..message, player, r, g, b, true)
				end
			end
		end
		outputServerLog(getPlayerName(source)..": "..messageColor..message)
	elseif messageType == 1 then
		return
	elseif messageType == 2 then
		local team = getPlayerTeam(source)
		if not team then
			return
		end
		local r, g, b = getTeamColor(team)
		for i, player in pairs(getPlayersInTeam(team)) do
			if not ignore_list[player][getPlayerSerial(source)] then
				outputChatBox("(Team) "..getPlayerName(source)..": "..messageColor..message, player, r, g, b, true)
			end
		end
		outputServerLog("(Team) "..getPlayerName(source)..": "..messageColor..message)
	elseif messageType == 3 then
		if disableGlobal then
			return outputChatBox("Global chat is disabled globally", source, 255, 0, 0, true)
		end
		if getElementData(source, "disable_globalchat") == "On" then
			return outputChatBox("Global chat is disabled for you", source, 255, 0, 0, true)
		end
		local var, spacesCount = string.gsub(message, " ", "")
		if (spacesCount > 0 and #var == 0) or #message < 1 then
			return outputChatBox("Your message seems to be empty", source, 255, 0, 0, true)
		end
		if not isASCII(message) then
			return outputChatBox("Your message contains illegal characters", source, 255, 0, 0, true)
		end
		local alphabetics = getAlphabetic(message)
		if #alphabetics > 4 and alphabetics == alphabetics:upper() then
			return outputChatBox("Stop shouting!", source, 255, 0, 0, true)
		end
		local r, g, b = getPlayerTeamColor(source)
		local hex = string.format("#%.2X%.2X%.2X", r, g, b)
		for i, player in pairs(getElementsByType("player")) do
			if getElementData(player, "disable_globalchat") ~= "On" then
				if not ignore_list[player][getPlayerSerial(source)] then
					outputChatBox("(Global) "..hex..getPlayerName(source)..": "..messageColor..message, player, 204, 221, 255, true)
				end
			end
		end
		outputServerLog("(Global) "..hex..getPlayerName(source)..": "..messageColor..message)
	elseif messageType == 4 then
		local var, spacesCount = string.gsub(message, " ", "")
		if spacesCount > 0 and #var == 0 then
			return outputChatBox("Your message seems to be empty", source, 255, 0, 0, true)
		end
		--[[if not isASCII(message) then
			return outputChatBox("Your message contains illegal characters", source, 255, 0, 0, true)
		end]]
		local alphabetics = getAlphabetic(message)
		if #alphabetics > 4 and alphabetics == alphabetics:upper() then
			return outputChatBox("Stop shouting!", source, 255, 0, 0, true)
		end
		local r, g, b = getPlayerTeamColor(source)
		local hex = string.format("#%.2X%.2X%.2X", r, g, b)
		local language = getElementData(source, "language")
		for i, player in pairs(getElementsByType("player")) do
			local country = getElementData(player, "language")
			if country and country == language then
				if not ignore_list[player][getPlayerSerial(source)] then
					outputChatBox("("..language..") #FFFFFF"..hex..getPlayerName(source)..": "..messageColor..message, player, 255, 0, 0, true)
				end
			end
		end
		outputServerLog("("..language..") #FFFFFF"..hex..getPlayerName(source)..": "..messageColor..message)
	end
	lastMessageTick[source] = getTickCount()
end
addEventHandler("onPlayerChat", root, handlePlayerChat)

addEventHandler("onResourceStart", resourceRoot,
function()
	for i, player in pairs(getElementsByType("player")) do
		--if(getElementData(getElementParent(player), "globalchatEnabled") ~= false) then
			bindKey(player, "g", "down", "chatbox", "global")
		--end
		ignore_list[player] = {}
	end
end)

function doGlobalChat(player, command, ...)
	triggerEvent("onPlayerChat", player, table.concat({...}, " "), 3)
end
addCommandHandler("global", doGlobalChat)

addEventHandler("onPlayerJoin", root,
function()
	bindKey(source, "g", "down", "chatbox", "global")
	ignore_list[source] = {}
end)

addEventHandler("onPlayerQuit", root,
function()
	lastMessageTick[source] = nil
	ignore_list[source] = nil
end)

addEvent("core:onPlayerJoinArena", true)
addEventHandler("core:onPlayerJoinArena", root, function(arena)
	if arena.globalchatEnabled == false then
		unbindKey(source, "g", "down", "chatbox", "global")
	end
end)

addEvent("core:onPlayerLeaveArena", true)
addEventHandler("core:onPlayerLeaveArena", root, function(arena)
	bindKey(source, "g", "down", "chatbox", "global")
end)

-- Ignore/Un-ignore

addCommandHandler("ignore", function(player, cmd, ...)
	local plr = getPlayer(arg[1])
	if plr then
		if plr == player then
			return outputChatBox("* You cannot ignore yourself.", player, 255, 0, 0, true)
		end
		local serial = getPlayerSerial(plr)
		if ignore_list[player][serial] then
			return outputChatBox("* You are already ignoring "..getPlayerName(plr), player, 255, 0, 0, true)
		end
		ignore_list[player][serial] = true
		outputChatBox("* You are now ignoring "..getPlayerName(plr).."#ffffff. Use /unignore to stop ignoring", player, 255, 255, 255, true)
	else
		return outputChatBox("* Invalid player ID/Name", player, 255, 0, 0, true)
	end
end)

addCommandHandler("unignore", function(player, cmd, ...)
	local plr = getPlayer(arg[1])
	if plr then
		if plr == player then
			return outputChatBox("* You never ignored yourself to begin with.", player, 255, 0, 0, true)
		end
		local serial = getPlayerSerial(plr)
		if not ignore_list[player][serial] then
			return outputChatBox("* You are not ignoring "..getPlayerName(plr), player, 255, 0, 0, true)
		end
		ignore_list[player][serial] = nil
		outputChatBox("* You are no longer ignoring "..getPlayerName(plr), player, 255, 255, 255, true)
	else
		return outputChatBox("* Invalid player ID/Name", player, 255, 0, 0, true)
	end
end)

-- Export

function isPlayerIgnoring(player, plr)
	return ignore_list[player][getPlayerSerial(plr)]
end

--
function isASCII(text)
	for i = 1, #text do
		local byte = text:byte(i, i)
		if byte > 127 then
			return false
		end
	end
	return true
end

function getAlphabetic(text)
	local ret = ""
	for i = 1, #text do
		local byte = text:byte(i, i)
		if byte > 64 and byte < 123 then
			ret = ret .. string.char(byte)
		end
	end
	return ret
end

_outputServerLog = outputServerLog
function outputServerLog(message)
	return _outputServerLog(message:gsub("#%x%x%x%x%x%x", ""))
end

function getPlayerTeamColor(player)
	if not isElement(player) then
		return 255, 255, 255
	end
	local team = getPlayerTeam(player)
	if team then
		return getTeamColor(team)
	end
	return 255, 255, 255
end