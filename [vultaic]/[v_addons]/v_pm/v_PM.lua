--[[
	Vultaic::Addon::PM
--]]
local function getPlayerFromPartialName(name)
    local name = name and name:gsub("#%x%x%x%x%x%x", ""):lower() or nil
    if name then
        for _, player in ipairs(getElementsByType("player")) do
            local name_ = getPlayerName(player):gsub("#%x%x%x%x%x%x", ""):lower()
            if name_:find(name, 1, true) then
                return player
            end
        end
    end
end
local function getPlayerFromID(id)
	id = tonumber(id)
	if type(id) ~= "number" then
		return nil
	end
	for _, player in ipairs(getElementsByType("player")) do
		if getElementData(player, "id") == id then
			return player
		end
	end
	return nil
end
addEventHandler("onResourceStart", resourceRoot, function()
	for _, player in ipairs(getElementsByType("player")) do
		setElementData(player, "LastPM", nil)
	end
end)
function CMD_PM(player, command, givenPlr, ... )
	if isPlayerMuted(player) then
		return outputChatBox("* You can't PM while you are muted", player, 255, 0, 0)
	end
	local plr = getPlayerFromID(givenPlr) or getPlayerFromPartialName(tostring(givenPlr))
	local text = table.concat({...}, " ")
	if not plr then return outputChatBox( "#ff0000ERROR :: #ffffffPlayer not found!", player, 255, 255, 255, true ) end
	if plr == player then return outputChatBox( "#ff0000ERROR :: #ffffffYou can't PM yourself", player, 255, 255, 255, true ) end
	if exports.v_chat:isPlayerIgnoring(plr, player) then return outputChatBox( "#ff0000ERROR :: #ffffffThe player is ignoring you", player, 255, 255, 255, true ) end
	if exports.v_chat:isPlayerIgnoring(player, plr) then return outputChatBox( "#ff0000ERROR :: #ffffffYou are ignoring the player", player, 255, 255, 255, true ) end
	if getElementData(player, "private_messages") == "Off" then return outputChatBox( "#ff0000ERROR :: #ffffffYou have private messages off", player, 255, 255, 255, true ) end
	if getElementData(plr, "private_messages") == "Off" then return outputChatBox( "#ff0000ERROR :: #ffffffThe player has private messages turned off", player, 255, 255, 255, true ) end
	if not text or text == "" then return outputChatBox( "#ff0000ERROR :: #ffffffSyntax /PM [player] [message]", player, 255, 255, 255, true ) end
	outputChatBox("#19846dPM :: #ffffffTo "..getPlayerName(plr).."#ffffff: "..text, player, 255, 255, 255, true)
	outputChatBox("#19846dPM :: #ffffffFrom "..getPlayerName(player).."#ffffff: "..text, plr, 255, 255, 255, true)
	outputServerLog("[PM LOGS] :: "..(getPlayerName(player):gsub("#%x%x%x%x%x%x", "")).." PM >> "..(getPlayerName(plr):gsub("#%x%x%x%x%x%x", ""))..": "..text)
	setElementData(plr, "LastPM", player, false)
	triggerClientEvent(plr, "PM:notify", plr)
end
function CMD_Reply(player, command, ...)
	if isPlayerMuted(player) then
		return outputChatBox("* You can't PM while you are muted", player, 255, 0, 0)
	end
	local lastPM = getElementData(player, "LastPM")
	if not isElement(lastPM) then return end
	if exports.v_chat:isPlayerIgnoring(lastPM, player) then return outputChatBox( "#ff0000ERROR :: #ffffffThe player is ignoring you", player, 255, 255, 255, true ) end
	if exports.v_chat:isPlayerIgnoring(player, lastPM) then return outputChatBox( "#ff0000ERROR :: #ffffffYou are ignoring the player", player, 255, 255, 255, true ) end
	if getElementData(player, "private_messages") == "Off" then return outputChatBox( "#ff0000ERROR :: #ffffffYou have private messages off", player, 255, 255, 255, true ) end
	if getElementData(lastPM, "private_messages") == "Off" then return outputChatBox( "#ff0000ERROR :: #ffffffThe player has private messages turned off", player, 255, 255, 255, true ) end
	local text = table.concat({...}, " ")
	if not text or text == "" then return end
	outputChatBox("#19846dPM :: #ffffffTo "..getPlayerName(lastPM).."#ffffff: "..text, player, 255, 255, 255, true)
	outputChatBox("#19846dPM :: #ffffffFrom "..getPlayerName(player).."#ffffff: "..text, lastPM, 255, 255, 255, true)
	outputServerLog("[PM LOGS] :: "..(getPlayerName(player):gsub("#%x%x%x%x%x%x", "")).." PM >> "..(getPlayerName(lastPM):gsub("#%x%x%x%x%x%x", ""))..": "..text)
	setElementData(lastPM, "LastPM", player, false)
	triggerClientEvent(lastPM, "PM:notify", lastPM)
end
addCommandHandler("pm", CMD_PM)
addCommandHandler("r", CMD_Reply)
addCommandHandler("re", CMD_Reply)