local screenWidth, screenHeight = guiGetScreenSize()
local g_Settings = nil
-- UI
local relativeScale = math.min(math.max(screenWidth/1600, 0.5))
local HUD_FONT_SCALE = 1
local HUD_FONT = "default-bold"
local HUD_FONT_HEIGHT = dxGetFontHeight(HUD_FONT_SCALE, HUD_FONT)

local HUD_WIDTH = 220 * relativeScale
local HUD_ROW_HEIGHT = HUD_FONT_HEIGHT + 15
local HUD_OFFSET_X = screenWidth - HUD_WIDTH - 5
local HUD_OFFSET_Y = (screenHeight-(HUD_ROW_HEIGHT*4))/2

local HUD_PLAYERS_TO_SHOW = 3

local HUD_STATE_TEXTS = {
	["starting"] = "#FFFF00Starting",
	["running"] = "#00FF00Running",
	["finished"] = "#FF0000Finished"
}

local function getLocalplayerRankIndex()
	if not g_Settings then
		return nil
	end
	for i = 1, #g_Settings.players do
		local data = g_Settings.players[i]
		if data and isElement(data[1]) and data[1] == localPlayer then
			return i;
		end
	end
end

addEvent("event:onReceiveSettings", true)

addEventHandler("onClientResourceStart", resourceRoot, function()
	addEventHandler("event:onReceiveSettings", resourceRoot, onSettingsReceive)
end)

function onSettingsReceive(data)
	g_Settings = data
end

addEvent("event:onPlayerReceiveInfo", true)
addEventHandler("event:onPlayerReceiveInfo", resourceRoot, function(settings)
	if not settings then
		g_Settings = nil
		toggleHud(false)
		return
	end
	g_Settings = settings
	if g_Settings.state ~= "waiting" and g_Settings.state ~= "finished" then
		toggleHud(true)
	else
		toggleHud(false)
	end
end)

function renderClanwarHud()
	if not g_Settings then
		return
	end
	-- Details
	local state = HUD_STATE_TEXTS[g_Settings.state] or "None"
	local round = g_Settings.current_round
	local max_rounds = g_Settings.max_rounds
	local localPlayer_Display
	
	local OFFSET_Y = HUD_OFFSET_Y
	
	dxDrawRectangle(HUD_OFFSET_X, OFFSET_Y, HUD_WIDTH, HUD_ROW_HEIGHT, tocolor(15, 15, 15, 245), false)
	dxDrawText(state..": #FFFFFF"..round.."/"..max_rounds, HUD_OFFSET_X, OFFSET_Y, HUD_OFFSET_X + HUD_WIDTH, OFFSET_Y + HUD_ROW_HEIGHT, tocolor(255, 255, 255, 255), HUD_FONT_SCALE, HUD_FONT, "center", "center", false, false, false, true)
	OFFSET_Y = OFFSET_Y + HUD_ROW_HEIGHT + 1

	dxDrawRectangle(HUD_OFFSET_X, OFFSET_Y, HUD_WIDTH, HUD_ROW_HEIGHT, tocolor(18, 18, 18, 245), false)
	dxDrawText("WFF Leaderboard", HUD_OFFSET_X, OFFSET_Y, HUD_OFFSET_X + HUD_WIDTH, OFFSET_Y + HUD_ROW_HEIGHT, teamAColor, HUD_FONT_SCALE, HUD_FONT, "center", "center", true)
	OFFSET_Y = OFFSET_Y + HUD_ROW_HEIGHT
	
	for i = 1, HUD_PLAYERS_TO_SHOW do
		local data = g_Settings.players[i]
		if data and isElement(data[1]) then
			if data[1] == localPlayer then
				localPlayer_Display = i
			end
			local playerName = getPlayerName(data[1])
			local playerAlpha = 255 --getElementData(data[1], "state") == "alive" and 255 or 55
			dxDrawRectangle(HUD_OFFSET_X, OFFSET_Y, HUD_WIDTH, HUD_ROW_HEIGHT, tocolor(10, 10, 10, 205), false)
			dxDrawText("#"..i.." "..playerName, HUD_OFFSET_X + 10, OFFSET_Y, HUD_OFFSET_X + HUD_WIDTH - 10, OFFSET_Y + HUD_ROW_HEIGHT, tocolor(255, 255, 255, playerAlpha), HUD_FONT_SCALE, HUD_FONT, "left", "center", false, false, false, true)
			--dxDrawText("-", HUD_OFFSET_X + 10, OFFSET_Y, HUD_OFFSET_X + HUD_WIDTH - 10, OFFSET_Y + HUD_ROW_HEIGHT, tocolor(255, 255, 255, playerAlpha), HUD_FONT_SCALE, HUD_FONT, "center", "center", false, false, false, true)
			dxDrawText(data[2], HUD_OFFSET_X + 10, OFFSET_Y, HUD_OFFSET_X + HUD_WIDTH - 10, OFFSET_Y + HUD_ROW_HEIGHT, tocolor(255, 255, 255, playerAlpha), HUD_FONT_SCALE, HUD_FONT, "right", "center", false, false, false, true)
			OFFSET_Y = OFFSET_Y + HUD_ROW_HEIGHT
		else
			local playerName = "None"
			local playerAlpha = 255 --getElementData(data[1], "state") == "alive" and 255 or 55
			dxDrawRectangle(HUD_OFFSET_X, OFFSET_Y, HUD_WIDTH, HUD_ROW_HEIGHT, tocolor(10, 10, 10, 205), false)
			dxDrawText("None", HUD_OFFSET_X + 10, OFFSET_Y, HUD_OFFSET_X + HUD_WIDTH - 10, OFFSET_Y + HUD_ROW_HEIGHT, tocolor(255, 255, 255, playerAlpha), HUD_FONT_SCALE, HUD_FONT, "left", "center", false, false, false, true)
			--dxDrawText("-", HUD_OFFSET_X + 10, OFFSET_Y, HUD_OFFSET_X + HUD_WIDTH - 10, OFFSET_Y + HUD_ROW_HEIGHT, tocolor(255, 255, 255, playerAlpha), HUD_FONT_SCALE, HUD_FONT, "center", "center", false, false, false, true)
			dxDrawText("n/a", HUD_OFFSET_X + 10, OFFSET_Y, HUD_OFFSET_X + HUD_WIDTH - 10, OFFSET_Y + HUD_ROW_HEIGHT, tocolor(255, 255, 255, playerAlpha), HUD_FONT_SCALE, HUD_FONT, "right", "center", false, false, false, true)
			OFFSET_Y = OFFSET_Y + HUD_ROW_HEIGHT
		end
	end
	
	-- Local player's rank
	if not localPlayer_Display then
		localPlayer_Display = getLocalplayerRankIndex()
	end
	if localPlayer_Display and localPlayer_Display > 3 then
		dxDrawRectangle(HUD_OFFSET_X, OFFSET_Y, HUD_WIDTH, HUD_ROW_HEIGHT, tocolor(15, 15, 15, 225), false)
		dxDrawText("#"..localPlayer_Display.." "..getPlayerName(localPlayer), HUD_OFFSET_X + 10, OFFSET_Y, HUD_OFFSET_X + HUD_WIDTH - 10, OFFSET_Y + HUD_ROW_HEIGHT, tocolor(255, 255, 255, playerAlpha), HUD_FONT_SCALE, HUD_FONT, "left", "center", false, false, false, true)
		dxDrawText(g_Settings.players[localPlayer_Display][2], HUD_OFFSET_X + 10, OFFSET_Y, HUD_OFFSET_X + HUD_WIDTH - 10, OFFSET_Y + HUD_ROW_HEIGHT, tocolor(255, 255, 255, playerAlpha), HUD_FONT_SCALE, HUD_FONT, "right", "center", false, false, false, true)
		OFFSET_Y = OFFSET_Y + HUD_ROW_HEIGHT
	end
	
	OFFSET_Y = OFFSET_Y + 1
	dxDrawRectangle(HUD_OFFSET_X, OFFSET_Y, HUD_WIDTH, HUD_ROW_HEIGHT, tocolor(15, 15, 15, 225), false)
	dxDrawText("Press U to hide this window", HUD_OFFSET_X, OFFSET_Y, HUD_OFFSET_X + HUD_WIDTH, OFFSET_Y + HUD_ROW_HEIGHT, tocolor(255, 255, 255, 255), HUD_FONT_SCALE, HUD_FONT, "center", "center", false, false, false, true)
end

addCommandHandler("y", function(cmd, arg)
	--HUD_OFFSET_Y = tonumber(arg) or 5
end)

function toggleHud(toggle)
	HUD_VISIBLE = toggle
	removeEventHandler("onClientRender", root, renderClanwarHud)
	if HUD_VISIBLE then
		addEventHandler("onClientRender", root, renderClanwarHud)
	end
end

addEventHandler("onClientPlayerJoinArena", resourceRoot,
function(player)
	if player ~= localPlayer then
		return
	end
	toggleHud(true)
end)

addEventHandler("onClientPlayerLeaveArena", resourceRoot,
function(player)
	if player ~= localPlayer then
		return
	end
	toggleHud(false)
end)

bindKey("u", "down",
function()
	if not g_Settings then
		return
	end
	if g_Settings.state == "waiting" or g_Settings.state == "finished" then
		return
	end
	toggleHud(not HUD_VISIBLE)
	outputChatBox("[Interface] #FFFFFFWFF event hud is now "..(HUD_VISIBLE and "#00FF00visible" or "#FF0000invisible"), 25, 132, 109, true)
end)