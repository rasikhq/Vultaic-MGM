local screenWidth, screenHeight = guiGetScreenSize()
local relativeScale, relativeFontScale = math.min(math.max(screenWidth/1600, 0.5), 1), math.min(math.max(screenWidth/1600, 0.85), 1)
local hud = {}
hud.fontScale = 1
hud.font = dxCreateFont(":v_locale/fonts/Roboto-Regular.ttf", math.floor(10 * relativeFontScale))
hud.fontBig = dxCreateFont(":v_locale/fonts/Roboto-Medium.ttf", math.floor(16 * relativeFontScale))
hud.fontHeight = dxGetFontHeight(hud.fontScale, hud.font)
hud.offset = 5
hud.padding = 5
hud.interpolator = "Linear"
-- Map display
hud.mapDisplayWidth = 0
hud.mapDisplayHeight = math.floor(hud.fontHeight * 2)
hud.mapDisplayX = hud.offset
hud.mapDisplayY = screenHeight - hud.mapDisplayHeight - hud.offset
hud.mapDisplayIconSize = math.floor(hud.mapDisplayHeight * 0.4)
hud.mapDisplayIconOffset = (hud.mapDisplayHeight - hud.mapDisplayIconSize)/2
-- Next map display
hud.nextMapDisplayWidth = 0
hud.nextMapDisplayHeight = math.floor(hud.fontHeight * 2)
hud.nextMapDisplayX = hud.offset
hud.nextMapDisplayY = hud.mapDisplayY - hud.nextMapDisplayHeight - hud.offset
hud.nextMapDisplayIconSize = math.floor(hud.nextMapDisplayHeight * 0.4)
hud.nextMapDisplayIconOffset = (hud.nextMapDisplayHeight - hud.nextMapDisplayIconSize)/2
-- Time display
hud.timeDisplayWidth = 0
hud.timeDisplayHeight = math.floor(hud.fontHeight * 2)
hud.timeDisplayX = screenWidth/2
hud.timeDisplayY = hud.offset
hud.timeDisplayIconSize = math.floor(hud.timeDisplayHeight * 0.6)
hud.timeDisplayIconOffset = (hud.timeDisplayHeight - hud.timeDisplayIconSize)/2
-- Countdown display
hud.countdownSize = math.floor(220 * relativeScale)
hud.countdownX, hud.countdownY = (screenWidth - hud.countdownSize)/2, (screenHeight - hud.countdownSize)/2
-- Checkpoint display
hud.checkpointDisplayWidth = math.floor(350 * relativeScale)
hud.checkpointDisplayHeight = 10
hud.checkpointDisplayX = (screenWidth - hud.checkpointDisplayWidth)/2
hud.checkpointDisplayY = screenHeight - hud.checkpointDisplayHeight
-- Shooter projection display
hud.projectionDisplaySize = math.floor(48 * relativeScale)
hud.projectionDisplayX = (screenWidth - hud.projectionDisplaySize)/2
hud.projectionDisplayY = screenHeight - hud.projectionDisplaySize - hud.padding
hud.projectionDisplayIconSize = math.floor(hud.projectionDisplaySize * 0.6)
hud.projectionDisplayIconOffset = (hud.projectionDisplaySize - hud.projectionDisplayIconSize)/2
-- Optimization
local dxCreateRenderTarget = dxCreateRenderTarget
local dxSetRenderTarget = dxSetRenderTarget
local dxSetBlendMode = dxSetBlendMode
local dxDrawRectangle = dxDrawRectangle
local dxDrawText = dxDrawText
local dxDrawImage = dxDrawImage
local dxDrawImageSection = dxDrawImageSection
local unpack = unpack
local tocolor = tocolor
local math_min = math.min
local math_max = math.max
local math_floor = math.floor
local tableInsert = table.insert
local tableRemove = table.remove
local pairs = pairs
local interpolateBetween = interpolateBetween
addEvent("onClientArenaStateChanging", true)
addEvent("onClientArenaMapStarting", true)
addEvent("onClientArenaGridCountdown", true)
addEvent("onClientArenaNextmapChanged", true)
addEvent("onClientArenaDurationChange", true)
addEvent("onClientNotifyTrainingMessage", true)
addEvent("onClientNotifyRespawnMessage", true)
addEvent("onClientCheckpointsGenerated", true)
addEvent("checkpoints:onClientPlayerReachCheckpoint", true)
addEvent("core:onClientCameraTargetChange", true)
addEvent("onClientProjectionStateChange", true)
addEvent("onClientTimeIsUpDisplayRequest", true)
addEvent("mapmanager:onMapLoad", true)

function hud.show(data)
	if hud.visible then
		return
	end
	hud.visible = true
	hud.tick = getTickCount()
	hud.mapDisplayWidth = 0
	hud.nextMapDisplayWidth = 0
	hud.mapDisplayProgress = 0
	hud.nextMapDisplayProgress = 0
	hud.nextMapDisplayInnerProgress = 0
	hud.nextMapDisplayVisible = false
	hud.nextMapDisplayUpdatedInner = nil
	hud.countdownProgress = 0
	hud.countdownValue = nil
	hud.timeDisplayProgress = 0
	hud.timeDisplayInnerProgress = 0
	hud.timeDisplayUpdatedInner = nil
	hud.resetRadarOffset = nil
	removeEventHandler("onClientRender", root, hud.render)
	addEventHandler("onClientRender", root, hud.render)
	addEventHandler("onClientArenaStateChanging", root, hud.handleStateChange)
	addEventHandler("onClientArenaMapStarting", root, hud.handleMapStart)
	addEventHandler("onClientArenaGridCountdown", root, hud.gridCountdown)
	addEventHandler("onClientArenaNextmapChanged", root, hud.handleNextmapChange)
	addEventHandler("onClientArenaDurationChange", root, hud.handleDurationChange)
	addEventHandler("onClientNotifyTrainingMessage", root, hud.handleNotifyTrainingMessage)
	addEventHandler("onClientNotifyRespawnMessage", root, hud.handleNotifyRespawnMessage)
	addEventHandler("onClientCheckpointsGenerated", root, hud.handleCheckpointsGeneration)
	addEventHandler("core:onClientCameraTargetChange", root, hud.handleCameraTargetChange)
	addEventHandler("onClientElementDataChange", root, hud.handleDataChange)
	addEventHandler("onClientProjectionStateChange", root, hud.handleProjectionStateChange)
	addEventHandler("onClientTimeIsUpDisplayRequest", root, hud.handleTimeIsUpDisplayRequest)
	addEventHandler("mapmanager:onMapLoad", root, hud.notifyReady)
	bindKey("F10", "down", hud.toggleTemporary)
	if data and data.mapName then
		hud.update("mapName", data.mapName)
	end
	if data and data.nextMapName then
		hud.update("nextMapName", data.nextMapName)
	end
	if hud.nextMapDisplayVisible then
		triggerEvent("radar:setOffset", localPlayer, hud.mapDisplayHeight + hud.nextMapDisplayHeight + hud.offset * 3)
	else
		triggerEvent("radar:setOffset", localPlayer, hud.mapDisplayHeight + hud.offset * 2)
	end
	if data and data.state == "running" and data.timeIsUpStartTick and data.timeIsUpDuration then
		hud.timeDisplayTick = getTickCount()
		hud.timeDisplayVisible = true
		hud.timeDisplayWidth = math.max(dxGetTextWidth(msToTimeString(data.timeIsUpDuration), hud.fontScale, hud.font), dxGetTextWidth(msToTimeString(0), hud.fontScale, hud.font)) * 2
		hud.timeIsUpStartTick = data.timeIsUpStartTick
		hud.timeIsUpTick = data.timeIsUpStartTick + data.timeIsUpDuration
		hud.timePassedText = msToTimeString(0)
		hud.timeLeftText = msToTimeString(data.timeIsUpDuration)
		removeEventHandler("onClientRender", root, hud.updateTimes)
		addEventHandler("onClientRender", root, hud.updateTimes)
	end
end
addEvent("racehud:show", true)
addEventHandler("racehud:show", localPlayer, hud.show)

function hud.toggleTemporary()
	hud.tick = getTickCount()
	hud.temporaryInvisible = not hud.temporaryInvisible
	if hud.temporaryInvisible then
		triggerEvent("notification:create", localPlayer, "Interface", "Hud interface is now invisible", "interface.png")
	else
		if hud.nextMapDisplayVisible then
			triggerEvent("radar:setOffset", localPlayer, hud.mapDisplayHeight + hud.nextMapDisplayHeight + hud.offset * 3)
		else
			triggerEvent("radar:setOffset", localPlayer, hud.mapDisplayHeight + hud.offset * 2)
		end
		removeEventHandler("onClientRender", root, hud.render)
		addEventHandler("onClientRender", root, hud.render)
		hud.resetRadarOffset = nil
		triggerEvent("notification:create", localPlayer, "Interface", "Hud interface is now visible", "interface.png")
	end
	triggerEvent("racehud:onTemporaryVisibilityChanged", localPlayer, hud.temporaryInvisible)
end

addEvent("panel:onVisibilityChanged", true)
addEventHandler("panel:onVisibilityChanged", localPlayer,
function()
	if hud.visible and not hud.temporaryInvisible then
		hud.tick = getTickCount()
	end
end)

function hud.hide()
	if not hud.visible then
		return
	end
	hud.visible = false
	hud.tick = getTickCount()
	hud.nextMapDisplayTick = getTickCount()
	hud.nextMapDisplayVisible = false
	hud.timeDisplayTick = getTickCount()
	hud.timeDisplayVisible = false
	if hud.nextMapDisplayUpdatedInner then
		hud.nextMapDisplayInnerTick = getTickCount()
	end
	hud.gridCountdown(false)
	hud.trainingMessageTick = getTickCount()
	hud.trainingMessageVisible = false
	hud.respawnMessageTick = getTickCount()
	hud.respawnMessageVisible = false
	hud.checkpointDisplayTick = getTickCount()
	hud.checkpointDisplayVisible = false
	hud.checkpointDisplayProgress = 0
	hud.checkpointDisplayProgressToGo = 0
	hud.projectionDisplayVisible = false
	hud.forceUpdateTimes = nil
	removeEventHandler("onClientRender", root, hud.updateTimes)
	removeEventHandler("onClientArenaStateChanging", root, hud.handleStateChange)
	removeEventHandler("onClientArenaMapStarting", root, hud.handleMapStart)
	removeEventHandler("onClientArenaGridCountdown", root, hud.gridCountdown)
	removeEventHandler("onClientArenaNextmapChanged", root, hud.handleNextmapChange)
	removeEventHandler("onClientArenaDurationChange", root, hud.handleDurationChange)
	removeEventHandler("onClientNotifyTrainingMessage", root, hud.handleNotifyTrainingMessage)
	removeEventHandler("onClientNotifyRespawnMessage", root, hud.handleNotifyRespawnMessage)
	removeEventHandler("onClientCheckpointsGenerated", root, hud.handleCheckpointsGeneration)
	removeEventHandler("core:onClientCameraTargetChange", root, hud.handleCameraTargetChange)
	removeEventHandler("onClientElementDataChange", root, hud.handleDataChange)
	removeEventHandler("onClientProjectionStateChange", root, hud.handleProjectionStateChange)
	removeEventHandler("onClientTimeIsUpDisplayRequest", root, hud.handleTimeIsUpDisplayRequest)
	removeEventHandler("mapmanager:onMapLoad", root, hud.notifyReady)
	unbindKey("F10", "down", hud.toggleTemporary)
end
addEvent("racehud:hide", true)
addEventHandler("racehud:hide", localPlayer, hud.hide)
addEvent("core:onClientLeaveArena", true)
addEventHandler("core:onClientLeaveArena", localPlayer, hud.hide)

function hud.update(data, value)
	if data == "mapName" then
		hud.mapDisplayTick = getTickCount()
		hud.mapName = tostring(value)
		local savedWidth = hud.mapDisplayWidth * (hud.mapDisplayProgress or 0)
		hud.mapDisplayWidth = dxGetTextWidth(hud.mapName:gsub("#%x%x%x%x%x%x", ""), hud.fontScale, hud.font)
		if savedWidth then
			hud.mapDisplayProgress = savedWidth/hud.mapDisplayWidth
		end
	elseif data == "nextMapName" then
		if value then
			if not hud.nextMapDisplayVisible then
				hud.nextMapDisplayTick = getTickCount()
				hud.nextMapDisplayVisible = true
			end
			hud.nextMapName = tostring(value)
			local savedWidth = hud.nextMapDisplayWidth * (hud.nextMapDisplayProgress or 0)
			hud.nextMapDisplayWidth = dxGetTextWidth(hud.nextMapName:gsub("#%x%x%x%x%x%x", ""), hud.fontScale, hud.font)
			if savedWidth and hud.nextMapDisplayInnerProgress then
				hud.nextMapDisplayInnerTick = getTickCount()
				hud.nextMapDisplayInnerProgress = savedWidth/hud.nextMapDisplayWidth
			end
			if hud.visible and not hud.temporaryInvisible then
				triggerEvent("radar:setOffset", localPlayer, hud.mapDisplayHeight + hud.nextMapDisplayHeight + hud.offset * 3)
			end
		elseif hud.nextMapDisplayVisible then
			hud.nextMapDisplayTick = getTickCount()
			hud.nextMapDisplayVisible = false
			if hud.nextMapDisplayUpdatedInner then
				hud.nextMapDisplayInnerTick = getTickCount()
			end
		end
	end
end

function hud.gridCountdown(countdown)
	if countdown then
		if not hud.countdownVisible then
			hud.countdownVisible = true
		end
		hud.countdownTick = getTickCount()
		hud.countdownValue = countdown
		hud.countdownProgress = 0
		if hud.countdownValue == 0 then
			hud.countdownEndTimer = setTimer(hud.gridCountdown, 1000, 1, false)
		end
		local sfxPath = countdown == 0 and "sfx/countdown_go.wav" or "sfx/countdown.wav"
		if fileExists(sfxPath) then
			playSound(sfxPath, false)
		end
	else
		if hud.countdownEndTimer and isTimer(hud.countdownEndTimer) then
			killTimer(hud.countdownEndTimer)
		end
		hud.countdownTick = getTickCount()
		hud.countdownVisible = false
	end
end

function hud.updateTimes()
	hud.timeLeftText = msToTimeString(math_max(hud.timeIsUpTick - getTickCount(), 0))
	if getElementData(localPlayer, "state") == "alive" or hud.forceUpdateTimes then
		hud.timePassedText = msToTimeString(getTickCount() - hud.timeIsUpStartTick)
	end
end

function hud.render()
	local currentTick = getTickCount()
	local hudTick = hud.tick or 0
	hud.alpha = interpolateBetween(hud.alpha or 0, 0, 0, (not hud.visible or hud.temporaryInvisible or getElementData(localPlayer, "panel.visible")) and 0 or 1, 0, 0, math_min(500, currentTick - hudTick)/500, hud.interpolator)
	if not hud.visible and hud.alpha == 0 then
		removeEventHandler("onClientRender", root, hud.render)
		return
	elseif hud.temporaryInvisible and hud.alpha == 0 and not hud.resetRadarOffset then
		triggerEvent("radar:setOffset", localPlayer, 0)
		hud.resetRadarOffset = true
	end
	-- Map display
	do
		local mapDisplayTick = hud.mapDisplayTick or 0
		hud.mapDisplayProgress = interpolateBetween(hud.mapDisplayProgress or 0, 0, 0, 1, 0, 0, math_min(5000, currentTick - mapDisplayTick)/5000, hud.interpolator)
		local text = hud.mapName or ""
		local width = hud.mapDisplayWidth > 0 and (hud.mapDisplayWidth + hud.padding * 4) * hud.mapDisplayProgress or 0
		local fadeDelay = 500
		local fadeFactor = math_min(fadeDelay, currentTick - mapDisplayTick)/fadeDelay
		dxDrawCurvedRectangle(hud.mapDisplayX, hud.mapDisplayY, width, hud.mapDisplayHeight, tocolor(10, 10, 10, 185 * hud.alpha), false)
		dxDrawCurvedRectangle(hud.mapDisplayX + 2, hud.mapDisplayY + 2, 0, hud.mapDisplayHeight - 4, tocolor(25, 25, 25, 105 * hud.alpha), false)
		dxDrawCurvedBorder(hud.mapDisplayX, hud.mapDisplayY, width, hud.mapDisplayHeight, tocolor(25, 25, 25, 245 * hud.alpha), false)
		if fadeFactor < 1 then
			dxDrawCurvedRectangle(hud.mapDisplayX + 2, hud.mapDisplayY + 2, 0, hud.mapDisplayHeight - 4, tocolor(25, 132, 109, 55 * (1 - fadeFactor) * hud.alpha), false)
		end
		dxDrawImageSection(hud.mapDisplayX + hud.mapDisplayIconOffset, hud.mapDisplayY + hud.mapDisplayIconOffset, hud.mapDisplayIconSize, hud.mapDisplayIconSize, 1, 1, 30, 30, "img/current.png", 0, 0, 0, tocolor(25, 132, 109, 255 * hud.alpha))
		dxDrawText(text, hud.mapDisplayX + hud.mapDisplayHeight + hud.padding, hud.mapDisplayY, hud.mapDisplayX + hud.mapDisplayHeight + width - hud.padding, hud.mapDisplayY + hud.mapDisplayHeight, tocolor(255, 255, 255, 255 * hud.alpha), hud.fontScale, hud.font, "left", "center", true)
	end
	-- Next map display
	do
		local nextMapDisplayTick = hud.nextMapDisplayTick or 0
		hud.nextMapDisplayProgress = interpolateBetween(hud.nextMapDisplayProgress or 0, 0, 0, (hud.nextMapDisplayVisible or hud.nextMapDisplayUpdatedInner) and 1 or 0, 0, 0, math_min(5000, currentTick - nextMapDisplayTick)/5000, hud.interpolator)
		if hud.nextMapDisplayVisible and hud.nextMapDisplayProgress >= 0.99 and not hud.nextMapDisplayUpdatedInner then
			hud.nextMapDisplayInnerTick = getTickCount()
			hud.nextMapDisplayUpdatedInner = true
		elseif not hud.nextMapDisplayVisible and hud.nextMapDisplayInnerProgress and hud.nextMapDisplayInnerProgress <= 0.01 and hud.nextMapDisplayUpdatedInner then
			hud.nextMapDisplayTick = getTickCount()
			hud.nextMapDisplayUpdatedInner = false
			triggerEvent("radar:setOffset", localPlayer, hud.mapDisplayHeight + hud.offset * 2)
		end
		local nextMapDisplayInnerTick = hud.nextMapDisplayInnerTick or 0
		hud.nextMapDisplayInnerProgress = interpolateBetween(hud.nextMapDisplayInnerProgress or 0, 0, 0, (hud.nextMapDisplayVisible and hud.nextMapDisplayUpdatedInner) and 1 or 0, 0, 0, math_min(3000, currentTick - nextMapDisplayInnerTick)/3000, hud.interpolator)
		if hud.nextMapDisplayProgress > 0 then
			local text = hud.nextMapName or ""
			local width = hud.nextMapDisplayWidth > 0 and (hud.nextMapDisplayWidth + hud.padding * 4) * hud.nextMapDisplayInnerProgress or 0
			local fadeDelay = 500
			local fadeFactor = hud.nextMapDisplayVisible and math_min(fadeDelay, currentTick - nextMapDisplayInnerTick)/fadeDelay or 0
			dxDrawCurvedRectangle(hud.nextMapDisplayX, hud.nextMapDisplayY, width, hud.nextMapDisplayHeight, tocolor(10, 10, 10, 185 * hud.nextMapDisplayProgress * hud.alpha), false)
			dxDrawCurvedRectangle(hud.nextMapDisplayX + 2, hud.nextMapDisplayY + 2, 0, hud.nextMapDisplayHeight - 4, tocolor(25, 25, 25, 105 * hud.nextMapDisplayProgress * hud.alpha), false)
			dxDrawCurvedBorder(hud.nextMapDisplayX, hud.nextMapDisplayY, width, hud.nextMapDisplayHeight, tocolor(25, 25, 25, 245 * hud.nextMapDisplayProgress * hud.alpha), false)
			if fadeFactor < 1 then
				dxDrawCurvedRectangle(hud.nextMapDisplayX + 2, hud.nextMapDisplayY + 2, 0, hud.nextMapDisplayHeight - 4, tocolor(25, 132, 109, 55 * (1 - fadeFactor) * hud.nextMapDisplayProgress * hud.alpha), false)
			end
			dxDrawImageSection(hud.nextMapDisplayX + hud.nextMapDisplayIconOffset, hud.nextMapDisplayY + hud.nextMapDisplayIconOffset, hud.nextMapDisplayIconSize, hud.nextMapDisplayIconSize, 1, 1, 30, 30, "img/next.png", 0, 0, 0, tocolor(25, 132, 109, 255 * hud.nextMapDisplayProgress * hud.alpha))
			dxDrawText(text, hud.nextMapDisplayX + hud.nextMapDisplayHeight + hud.padding, hud.nextMapDisplayY, hud.nextMapDisplayX + hud.nextMapDisplayHeight + width - hud.padding, hud.nextMapDisplayY + hud.nextMapDisplayHeight, tocolor(255, 255, 255, 255 * hud.nextMapDisplayProgress * hud.alpha), hud.fontScale, hud.font, "left", "center", true)
		end
	end
	-- Time display
	do
		local timeDisplayTick = hud.timeDisplayTick or 0
		hud.timeDisplayProgress = interpolateBetween(hud.timeDisplayProgress or 0, 0, 0, (hud.timeDisplayVisible or hud.timeDisplayUpdatedInner) and 1 or 0, 0, 0, math_min(5000, currentTick - timeDisplayTick)/5000, hud.interpolator)
		if hud.timeDisplayVisible and hud.timeDisplayProgress >= 0.99 and not hud.timeDisplayUpdatedInner then
			hud.timeDisplayInnerTick = getTickCount()
			hud.timeDisplayUpdatedInner = true
		elseif not hud.timeDisplayVisible and hud.timeDisplayInnerProgress and hud.timeDisplayInnerProgress <= 0.01 and hud.timeDisplayUpdatedInner then
			hud.timeDisplayTick = getTickCount()
			hud.timeDisplayUpdatedInner = false
		end
		local timeDisplayInnerTick = hud.timeDisplayInnerTick or 0
		hud.timeDisplayInnerProgress = interpolateBetween(hud.timeDisplayInnerProgress or 0, 0, 0, (hud.timeDisplayVisible and hud.timeDisplayUpdatedInner) and 1 or 0, 0, 0, math_min(1000, currentTick - timeDisplayInnerTick)/1000, hud.interpolator)
		if hud.timeDisplayProgress > 0 then
			local width = hud.timeDisplayWidth > 0 and (hud.timeDisplayWidth + hud.padding * 6) * hud.timeDisplayProgress or 0
			local offsetX = hud.timeDisplayX - width/2
			local rotationHours, rotationMinutes = math.fmod(getTickCount() * 360/5000, 360), math.fmod(getTickCount() * 360/60000, 360)
			dxDrawCurvedRectangle(offsetX - hud.timeDisplayHeight/2, hud.timeDisplayY, width, hud.timeDisplayHeight, tocolor(10, 10, 10, 185 * hud.timeDisplayProgress * hud.alpha), false, "img/edge-time.png")
			dxDrawImageSection(hud.timeDisplayX - hud.timeDisplayIconSize/2, hud.timeDisplayY + hud.timeDisplayIconOffset, hud.timeDisplayIconSize, hud.timeDisplayIconSize, 1, 1, 40, 40, "img/time-h.png", rotationHours, 0, 0, tocolor(25, 132, 109, 255 * hud.timeDisplayProgress * hud.alpha))
			dxDrawImageSection(hud.timeDisplayX - hud.timeDisplayIconSize/2, hud.timeDisplayY + hud.timeDisplayIconOffset, hud.timeDisplayIconSize, hud.timeDisplayIconSize, 1, 1, 40, 40, "img/time-m.png", rotationMinutes, 0, 0, tocolor(25, 132, 109, 255 * hud.timeDisplayProgress * hud.alpha))
			dxDrawText(hud.timePassedText, offsetX, hud.timeDisplayY, offsetX + width, hud.timeDisplayY + hud.timeDisplayHeight, tocolor(255, 255, 255, 255 * hud.timeDisplayProgress * hud.timeDisplayInnerProgress * hud.alpha), hud.fontScale, hud.font, "left", "center", true)
			dxDrawText(hud.timeLeftText, offsetX, hud.timeDisplayY, offsetX + width, hud.timeDisplayY + hud.timeDisplayHeight, tocolor(255, 255, 255, 255 * hud.timeDisplayProgress * hud.timeDisplayInnerProgress * hud.alpha), hud.fontScale, hud.font, "right", "center", true)
		end
	end
	-- Countdown
	do
		local countdownTick = hud.countdownTick or 0
		hud.countdownProgress = interpolateBetween(hud.countdownProgress or 0, 0, 0, hud.countdownVisible and 1 or 0, 0, 0, math_min(1000, currentTick - countdownTick)/1000, hud.interpolator)
		if hud.countdownProgress > 0 then
			local path = hud.countdownValue and "img/countdown_"..hud.countdownValue..".png" or nil
			if path and fileExists(path) then
				local scale = 20 - 20 * hud.countdownProgress
				dxDrawImage(hud.countdownX - scale/2, hud.countdownY - scale/2, hud.countdownSize + scale, hud.countdownSize + scale, path, 0, 0, 0, tocolor(255, 255, 255, 205 * hud.countdownProgress), false)
			end
		end
	end
	-- Press 'SPACE' to respawn
	do
		local messageTick = hud.trainingMessageTick or 0
		hud.trainingMessageProgress = interpolateBetween(hud.trainingMessageProgress or 0, 0, 0, hud.trainingMessageVisible and 1 or 0, 0, 0, math_min(1000, currentTick - messageTick)/1000, hud.interpolator)
		if hud.trainingMessageProgress > 0 then
			local distance = 40 * (1 - hud.trainingMessageProgress)
			dxDrawText("Press SPACE to respawn", 0, 0, screenWidth, screenHeight * 0.95 + distance, tocolor(255, 255, 255, 255 * hud.trainingMessageProgress * hud.alpha), hud.fontScale, hud.fontBig, "center", "bottom", false, false, false, true)
			if hud.trainingMessageProgress > 0.95 then
				dxDrawText("BACKSPACE to rewind, LSHIFT to speed up", 0, 0, screenWidth, screenHeight * 0.95 + hud.fontHeight, tocolor(255, 255, 255, 255 * hud.trainingMessageProgress * hud.alpha), hud.fontScale, hud.font, "center", "bottom", false, false, false, true)
			end
		end
	end
	-- Respawn message
	do
		local messageTick = hud.respawnMessageTick or 0
		hud.respawnMessageProgress = interpolateBetween(hud.respawnMessageProgress or 0, 0, 0, hud.respawnMessageVisible and 1 or 0, 0, 0, math_min(1000, currentTick - messageTick)/1000, hud.interpolator)
		if hud.respawnMessageProgress > 0 then
			local seconds = math_floor((math_max(hud.respawnMessageEndTick - getTickCount(), 0))/1000)
			if seconds < 1 and hud.respawnMessageVisible then
				hud.respawnMessageTick = getTickCount()
				hud.respawnMessageVisible = false
			end
			local distance = math_floor(-20 * (1 - hud.respawnMessageProgress))
			dxDrawText("Respawning in "..seconds, 0, 0, screenWidth, screenHeight * 0.3 + distance, tocolor(255, 255, 255, 255 * hud.respawnMessageProgress * hud.alpha), hud.fontScale, hud.fontBig, "center", "bottom", false, false, false, true)
		end
	end
	-- Checkpoints display
	do
		local checkpointsTick = hud.checkpointDisplayTick or 0
		hud.checkpointDisplayProgress = interpolateBetween(hud.checkpointDisplayProgress or 0, 0, 0, hud.checkpointDisplayVisible and 1 or 0, 0, 0, math_min(1000, currentTick - checkpointsTick)/1000, hud.interpolator)
		hud.checkpointDisplayCurrentProgress = interpolateBetween(hud.checkpointDisplayCurrentProgress or 0, 0, 0, hud.checkpointDisplayProgressToGo or 0, 0, 0, math_min(1000, currentTick - (hud.checkpointDisplayHitTick or 0))/1000, hud.interpolator)
		if hud.checkpointDisplayProgress > 0 then
			local width = hud.checkpointDisplayWidth * hud.checkpointDisplayCurrentProgress
			local textX = hud.checkpointDisplayX + width
			local rankText = hud.rankText or ""
			dxDrawRectangle(hud.checkpointDisplayX, hud.checkpointDisplayY, hud.checkpointDisplayWidth, hud.checkpointDisplayHeight, tocolor(10, 10, 10, 185 * hud.checkpointDisplayProgress * hud.alpha), false)
			dxDrawRectangle(hud.checkpointDisplayX, hud.checkpointDisplayY, width, hud.checkpointDisplayHeight, tocolor(25, 132, 109, 255 * hud.checkpointDisplayProgress * hud.alpha), false)
			dxDrawText(hud.checkpointDisplayText..rankText, textX, 0, screenWidth, hud.checkpointDisplayY - 5, tocolor(255, 255, 255, 255 * hud.checkpointDisplayProgress * hud.alpha), hud.fontScale, hud.font, "left", "bottom", true)
		end
	end
	do
		local projectionTick = hud.projectionDisplayTick or 0
		hud.projectionDisplayProgress = interpolateBetween(hud.projectionDisplayProgress or 0, 0, 0, hud.projectionDisplayVisible and 1 or 0, 0, 0, math_min(1000, currentTick - projectionTick)/1000, hud.interpolator)
		if hud.projectionDisplayProgress > 0 then
			local fadeDelay = 500
			local fadeFactor = math_min(fadeDelay, currentTick - projectionTick)/fadeDelay
			dxDrawImageSection(hud.projectionDisplayX, hud.projectionDisplayY, hud.projectionDisplaySize, hud.projectionDisplaySize, 1, 1, 50, 50, "img/circle.png", 0, 0, 0, tocolor(10, 10, 10, 185 * hud.projectionDisplayProgress * hud.alpha), false)
			if fadeFactor < 1 then
				local scale = 20 * fadeFactor
				dxDrawImageSection(hud.projectionDisplayX + hud.projectionDisplayIconOffset - scale/2, hud.projectionDisplayY + hud.projectionDisplayIconOffset - scale/2, hud.projectionDisplayIconSize + scale, hud.projectionDisplayIconSize + scale, 1, 1, 46, 46, "img/missile.png", 0, 0, 0, tocolor(255, 255, 255, 255 * (1 - fadeFactor) * hud.projectionDisplayProgress * hud.alpha), false)
			end
			dxDrawImageSection(hud.projectionDisplayX + hud.projectionDisplayIconOffset, hud.projectionDisplayY + hud.projectionDisplayIconOffset, hud.projectionDisplayIconSize, hud.projectionDisplayIconSize, 1, 1, 46, 46, "img/missile.png", 0, 0, 0, tocolor(255, 255, 255, 255 * hud.projectionDisplayProgress * hud.alpha), false)
		end
	end
end

function hud.handleStateChange(currentState, newState, data)
	if newState == "running" then
		hud.timeDisplayTick = getTickCount()
		hud.timeDisplayVisible = true
		hud.timeDisplayWidth = math.max(dxGetTextWidth(msToTimeString(data.duration), hud.fontScale, hud.font), dxGetTextWidth(msToTimeString(0), hud.fontScale, hud.font)) * 2
		hud.timeIsUpStartTick = getTickCount()
		hud.timeIsUpTick = hud.timeIsUpStartTick + data.duration
		hud.timePassedText = msToTimeString(0)
		hud.timeLeftText = msToTimeString(data.duration)
		removeEventHandler("onClientRender", root, hud.updateTimes)
		addEventHandler("onClientRender", root, hud.updateTimes)
	else
		if hud.timeDisplayVisible then
			hud.timeDisplayTick = getTickCount()
			hud.timeDisplayVisible = false
			if hud.timeDisplayUpdatedInner then
				hud.timeDisplayInnerTick = getTickCount()
			end
		end
		if hud.respawnMessageVisible then
			hud.respawnMessageTick = getTickCount()
			hud.respawnMessageVisible = false
		end
		if hud.checkpointDisplayVisible then
			hud.checkpointDisplayTick = getTickCount()
			hud.checkpointDisplayVisible = false
			hud.rankText = nil
		end
		removeEventHandler("onClientRender", root, hud.updateTimes)
	end
end

function hud.handleMapStart(mapInfo)
	hud.update("mapName", mapInfo.mapName)
	if not hud.nextMapDisplayVisible then
		triggerEvent("radar:setOffset", localPlayer, hud.mapDisplayHeight + hud.offset * 2)
	end
end

function hud.handleNextmapChange(nextMap)
	hud.update("nextMapName", nextMap)
end

function hud.handleDurationChange(duration)
	if duration then
		hud.timeIsUpTick = getTickCount() + duration
		hud.timeLeftText = msToTimeString(duration)
		local newWidth = math.max(dxGetTextWidth(msToTimeString(duration), hud.fontScale, hud.font), dxGetTextWidth(msToTimeString(0), hud.fontScale, hud.font)) * 2
		hud.timeDisplayProgress = newWidth/hud.timeDisplayWidth
		hud.timeDisplayWidth = newWidth
	end
end

function hud.handleNotifyTrainingMessage(visible)
	hud.trainingMessageTick = getTickCount()
	hud.trainingMessageVisible = visible and true or false
end

function hud.handleNotifyRespawnMessage(duration)
	local duration = tonumber(duration)
	if duration then
		hud.respawnMessageTick = getTickCount()
		hud.respawnMessageVisible = true
		hud.respawnMessageEndTick = getTickCount() + duration
	end
end

function hud.handleCheckpointsGeneration()
	hud.checkpointDisplayTick = getTickCount()
	hud.checkpointDisplayVisible = true
	hud.checkpointDisplayCurrentProgress = 0
	hud.checkpointDisplayProgressToGo = 0
	hud.checkpointDisplayText = tostring("0/"..tonumber(getElementData(localPlayer, "totalCheckpoints") or 0))
	hud.rankText = ""
end

function hud.handleCameraTargetChange(target)
	if hud.checkpointDisplayVisible then
		local current, total = tonumber(getElementData(target, "checkpoint") or 0), tonumber(getElementData(localPlayer, "totalCheckpoints") or 0)
		local rank = tonumber(getElementData(target, "race.rank"))
		hud.checkpointDisplayHitTick = getTickCount()
		hud.checkpointDisplayProgressToGo = tonumber(math_max(math_min((current/total) or 0, 1), 0) or 0)
		hud.checkpointDisplayText = tostring(current.."/"..total)
		if rank then
			hud.rankText = "("..rank..((rank < 10 or rank > 20) and ({ [1] = "st", [2] = "nd", [3] = "rd" })[rank % 10] or "th")..")"
		else
			hud.rankText = ""
		end
	end
end

function hud.handleDataChange(dataName)
	if hud.checkpointDisplayVisible and (source == localPlayer or source == getCameraTarget()) then
		if dataName == "checkpoint" then
			local current, total = tonumber(getElementData(source, "checkpoint") or 0), tonumber(getElementData(localPlayer, "totalCheckpoints") or 0)
			hud.checkpointDisplayHitTick = getTickCount()
			hud.checkpointDisplayProgressToGo = tonumber(math_max(math_min((current/total) or 0, 1), 0) or 0)
			hud.checkpointDisplayText = tostring(current.."/"..total)
		elseif dataName == "race.rank" then
			local rank = tonumber(getElementData(source, "race.rank"))
			if rank then
				hud.rankText = "("..rank..((rank < 10 or rank > 20) and ({ [1] = "st", [2] = "nd", [3] = "rd" })[rank % 10] or "th")..")"
			else
				hud.rankText = ""
			end
		end
	end
end

function hud.handleProjectionStateChange(state)
	hud.projectionDisplayTick = getTickCount()
	hud.projectionDisplayVisible = state and true or false
end

function hud.handleTimeIsUpDisplayRequest(data)
	if type(data) ~= "table" then
		data = {}
	end
	if not data.duration then
		data.duration = 0
	end
	hud.timeDisplayTick = getTickCount()
	hud.timeDisplayVisible = true
	hud.timeDisplayWidth = math.max(dxGetTextWidth(msToTimeString(data.duration), hud.fontScale, hud.font), dxGetTextWidth(msToTimeString(0), hud.fontScale, hud.font)) * 2
	hud.timeIsUpStartTick = getTickCount()
	hud.timeIsUpTick = hud.timeIsUpStartTick + data.duration
	hud.timePassedText = msToTimeString(0)
	hud.timeLeftText = msToTimeString(data.duration)
	hud.forceUpdateTimes = true
	removeEventHandler("onClientRender", root, hud.updateTimes)
	addEventHandler("onClientRender", root, hud.updateTimes)
end

function hud.notifyReady()
	createTrayNotification("Don't sleep! Round is about to start.", "default", true)
end

function dxDrawCurvedRectangle(x, y, width, height, color, postGUI, texture)
	if type(x) ~= "number" or type(y) ~= "number" or type(width) ~= "number" or type(height) ~= "number" then
		return
	end
	local texture = texture or "img/edge.png"
	local color = color or tocolor(25, 132, 109, 255)
	local postGUI = type(postGUI) == "boolean" and postGUI or false
	local edgeSize = height/2
	dxDrawImageSection(x, y, edgeSize, edgeSize, 0, 0, 33, 33, texture, 0, 0, 0, color, postGUI)
	dxDrawImageSection(x, y + edgeSize, edgeSize, edgeSize, 0, 33, 33, 33, texture, 0, 0, 0, color, postGUI)
	dxDrawImageSection(x + width + edgeSize, y, edgeSize, edgeSize, 43, 0, 33, 33, texture, 0, 0, 0, color, postGUI)
	dxDrawImageSection(x + width + edgeSize, y + edgeSize, edgeSize, edgeSize, 43, 33, 33, 33, texture, 0, 0, 0, color, postGUI)
	if width > 0 then
		dxDrawImageSection(x + edgeSize, y, width, height, 33, 0, 10, 66, texture, 0, 0, 0, color, postGUI)
	end
end

function dxDrawCurvedBorder(x, y, width, height, color, postGUI, texture)
	if type(x) ~= "number" or type(y) ~= "number" or type(width) ~= "number" or type(height) ~= "number" then
		return
	end
	local texture = texture or "img/border.png"
	local color = color or tocolor(25, 132, 109, 255)
	local postGUI = type(postGUI) == "boolean" and postGUI or false
	local edgeSize = height/2
	width = width + height
	local lineWidth = math_max(width - height, 0)
	dxDrawImageSection(x + edgeSize, y, lineWidth, height, 90, 1, 10, 50, texture, 0, 0, 0, color, postGUI)
	dxDrawImageSection(x, y, edgeSize, height, 1, 1, 25, 50, texture, 0, 0, 0, color, postGUI)
	dxDrawImageSection(x + width - edgeSize, y, edgeSize, height, 26, 1, 25, 50, texture, 0, 0, 0, color, postGUI)
end

function msToTimeString(ms)
	if not ms then
		return ""
	end
	local centiseconds = tostring(math.floor(math.fmod(ms, 1000)/10))
	if #centiseconds == 1 then
		centiseconds = "0"..centiseconds
	end
	local s = math.floor(ms/1000)
	local seconds = tostring(math.fmod(s, 60))
	if #seconds == 1 then
		seconds = "0"..seconds
	end
	local minutes = math.floor(s/60)
	return tostring((minutes < 10 and "0"..minutes or minutes))..":"..seconds..":"..centiseconds	
end

-- Replacements
_getCameraTarget = getCameraTarget
function getCameraTarget()
	local target = _getCameraTarget()
	if isElement(target) and getElementType(target) == "vehicle" then
		target = getVehicleOccupant(target)
	end
	return target
end