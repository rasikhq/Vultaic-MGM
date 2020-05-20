--[[
	Vultaic::Addon::PingLimit
--]]
addEvent("core:onClientJoinArena", true)
addEvent("core:onClientLeaveArena", true)
local screenWidth, screenHeight = guiGetScreenSize()
local relativeFontScale = math.min(math.max(screenWidth/1600, 0.85), 1)
local pArena = getElementParent(localPlayer) or nil
local PingLimit = {
	data = {
		lastTick = 0,
		warns = 0,
		warnLimit = 3
	}
}
local afk = {
	startTick = nil,
	lastTick = 0,
	afkCount = 10,
	warns = 0,
	warnLimit = 3
}

local afkFontScale = 1
local afkFont = dxCreateFont(":v_locale/fonts/Roboto-Regular.ttf", math.floor(14 * relativeFontScale))
local afkFontBig = dxCreateFont(":v_locale/fonts/Roboto-Medium.ttf", math.floor(18 * relativeFontScale))
local afkProgress = 0
addEventHandler("core:onClientJoinArena", localPlayer,
function(arena)
	pArena = getElementParent(localPlayer) or nil
end)
addEventHandler("core:onClientLeaveArena", localPlayer,
function(arena)
	pArena = nil
end)
-- // Ping checks
function PingLimit:Refresh()
	PingLimit["dd"] = 300
	PingLimit["sh"] = 300
	PingLimit["hunter"] = 350
end
PingLimit:Refresh()
function v_PingCheck()
	if not isElement(pArena) then
		return
	end
	local arenaState = getElementData(pArena, "state")
	local arenaID = getElementData(pArena, "id")
	if arenaState ~= "running" or isElementFrozen(localPlayer) or not PingLimit[arenaID] then
		return
	end
	local tick = getTickCount()
	local pPing = getPlayerPing(localPlayer)
	local pLimit = PingLimit[arenaID] or pPing+1
	if tick - PingLimit.data.lastTick > 15 * 1000 and pPing >= pLimit then
		PingLimit.data.warns = PingLimit.data.warns+1
		PingLimit.data.lastTick = tick
		outputChatBox("#138c5eALERT :: #ffffffYou are having a high ping! #ff0000Warning#ffffff["..PingLimit.data.warns.."/"..PingLimit.data.warnLimit.."]", 255, 255, 255, true)
	end
	if PingLimit.data.warns >= PingLimit.data.warnLimit then
		PingLimit.data.lastTick = 0
		PingLimit.data.warns = 0
		executeCommandHandler("leave")
		outputChatBox("#138c5eALERT :: #ffffffExceeded ping limit warnings", 255, 255, 255, true)
	end
	if tick - PingLimit.data.lastTick > 60 * 1000 then
		PingLimit.data.lastTick = tick
	end
end
addEventHandler("onClientRender", root, v_PingCheck)
-- // AFK checks
function v_AFK_keyTick(key, state)
	if not isChatBoxInputActive() then
		if not pArena then
			return
		end
		local arenaState = getElementData(pArena, "state")
		if arenaState == "running" then
			afk.startTick = getTickCount()
			afk.displayTick = tick
			afk.running = false
		end
	end
end
bindKey("accelerate", "down", v_AFK_keyTick)
bindKey("brake_reverse", "down", v_AFK_keyTick)
bindKey("steer_forward", "down", v_AFK_keyTick)
bindKey("steer_back", "down", v_AFK_keyTick)
bindKey("handbrake", "down", v_AFK_keyTick)
bindKey("vehicle_left", "down", v_AFK_keyTick)
bindKey("vehicle_right", "down", v_AFK_keyTick)
function v_AFKCheck()
	if not isElement(pArena) then
		return
	end
	local tick = getTickCount()
	local arenaState = getElementData(pArena, "state")
	local arenaID = getElementData(pArena, "id")
	local pVehicle = getPedOccupiedVehicle(localPlayer) or localPlayer
	if arenaState ~= "running" or isElementFrozen(localPlayer) or isPedDead(localPlayer) or getElementData(localPlayer, "state") == "dead" or getElementData(localPlayer, "state") == "training" or getCameraTarget() ~= pVehicle and getCameraTarget() ~= localPlayer then
		if afk.startTick then
			afk.startTick = nil
		end
		afk.afkCount = 10
		afk.displayTick = tick
		afk.running = false
		return
	end
	afkProgress = interpolateBetween(afkProgress, 0, 0, afk.running and afk.afkCount > 0 and 1 or 0, 0, 0, math.min(1000, tick - (afk.displayTick or 0))/1000, "Linear")
	if afkProgress > 0 and afk.running then
		dxDrawRectangle(0, 0, screenWidth, screenHeight, tocolor(0, 0, 0, 185 * afkProgress), false)
		dxDrawText("DRIVE!", 0, 0, screenWidth, screenHeight * 0.5, tocolor(25, 132, 109, 255 * afkProgress), afkFontScale, afkFontBig, "center", "bottom", false, false, false, true)
		dxDrawText(".. or you will be killed in "..afk.afkCount.." seconds!", 0, screenHeight * 0.5, screenWidth, screenHeight, tocolor(255, 255, 255, 255 * afkProgress), afkFontScale, afkFont, "center", "top", false, false, false, true)
	end
	if arenaState == "running" and not afk.startTick then
		afk.startTick = getTickCount()
		afk.displayTick = tick
		afk.running = false
	end
	if afk.startTick and tick - afk.startTick > 20*1000 and not afk.running then
		afk.afkCount = 10
		afk.lastTick = tick
		afk.displayTick = tick
		afk.running = true
	end
	if tick - afk.lastTick > 1000 and afk.running then
		afk.afkCount = afk.afkCount-1
		afk.lastTick = tick
		if afk.afkCount < 4 then
			playSound("warn.wav", false)
		end
	end
	if afk.afkCount <= 0 and afk.running then
		executeCommandHandler("kill")
		afk.afkCount = 0
		afk.lastTick = 0
		afk.displayTick = tick
		afk.running = false
		afk.startTick = nil
		afk.warns = afk.warns + 1
		outputChatBox("#138c5eALERT :: #ffffffYou will be kicked from arena for being AFK! #ff0000Warning#ffffff["..afk.warns.."/"..afk.warnLimit.."]", 255, 255, 255, true)
		if afk.warns >= afk.warnLimit then
			afk.warns = 0
			executeCommandHandler("leave")
			outputChatBox("#138c5eALERT :: #ffffffExceeded AFK warnings limit", 255, 255, 255, true)
		end
	end
end
addEventHandler("onClientRender", root, v_AFKCheck)
-- // Draw Distance
local getElementModel = getElementModel
local engineSetModelLODDistance = engineSetModelLODDistance

addEvent("settings:onSettingChange", true)
addEventHandler("settings:onSettingChange", localPlayer, function(setting, value, class)
	if setting == "draw_distance" then
		value = value == "On" and true or false
		toggleExtremeDrawDistance(value)
	end
end)

addEvent("mapmanager:onMapLoad", true)
addEventHandler("mapmanager:onMapLoad", localPlayer, function()
	local state = exports.v_settings:getClientVariable("draw_distance") == "On" and true or false
	toggleExtremeDrawDistance(state)
end)

function toggleExtremeDrawDistance(state)
	if state then
		for i, v in ipairs(getElementsByType("object")) do
			local model = getElementModel(v)
			engineSetModelLODDistance(model, 300)
		end
	else
		for i, v in ipairs(getElementsByType("object")) do
			local model = getElementModel(v)
			engineSetModelLODDistance(model, 0)
		end
	end
end