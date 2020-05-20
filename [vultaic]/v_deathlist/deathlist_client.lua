local screenWidth, screenHeight = guiGetScreenSize()
local relativeScale, relativeFontScale = math.min(math.max(screenWidth/1600, 0.5), 1), math.min(math.max(screenWidth/1600, 0.85), 1)
local deathlist = {}
deathlist.messages = {}
deathlist.offset = 5
deathlist.padding = 5
deathlist.fontScale = 1
deathlist.font = dxCreateFont(":v_locale/fonts/Roboto-Regular.ttf", math.floor(10 * relativeFontScale))
deathlist.fontHeight = dxGetFontHeight(deathlist.fontScale, deathlist.font)
deathlist.maximumToShow = 3
deathlist.interpolator = "Linear"
deathlist.rowHeight = math.floor(deathlist.fontHeight * 2)
deathlist.avatarSize = deathlist.rowHeight
deathlist.avatarOffset = (deathlist.rowHeight - deathlist.avatarSize)/2
deathlist.x = screenWidth - deathlist.rowHeight - deathlist.offset
deathlist.y = screenHeight - (deathlist.maximumToShow * (deathlist.rowHeight + deathlist.padding)) - deathlist.offset - screenHeight * 0.025
deathlist.textures = {}
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

addEventHandler("onClientResourceStart", resourceRoot,
function()
	deathlist.maskShader = dxCreateShader("fx/mask.fx")
	deathlist.maskTexture = dxCreateTexture("img/circle.png")
	deathlist.defaultAvatar = dxCreateTexture(":v_avatars/img/default-avatar.png")
	dxSetShaderValue(deathlist.maskShader, "maskTexture", deathlist.maskTexture)
end)

-- Change visibility
function deathlist.setVisible(visible)
	deathlist.tick = getTickCount()
	deathlist.visible = visible and true or false
	if deathlist.resetTimer and isTimer(deathlist.resetTimer) then
		killTimer(deathlist.resetTimer)
	end
	for i, message in pairs(deathlist.messages) do
		if message.display then
			message.fadeTick = getTickCount()
			message.alphaTick = getTickCount()
			message.display = false
		end
	end
end
addEvent("core:onClientJoinArena", true)
addEventHandler("core:onClientJoinArena", localPlayer, function() deathlist.setVisible(true) end)
addEvent("core:onClientLeaveArena", true)
addEventHandler("core:onClientLeaveArena", localPlayer, function() deathlist.setVisible(false) end)

-- Catch state changes
addEvent("onClientArenaStateChanging", true)
addEventHandler("onClientArenaStateChanging", root,
function(currentState, newState)
	if newState ~= "running" then
		if deathlist.resetTimer and isTimer(deathlist.resetTimer) then
			killTimer(deathlist.resetTimer)
		end
		deathlist.resetTimer = setTimer(function()
			for i, message in pairs(deathlist.messages) do
				if message.display then
					message.fadeTick = getTickCount()
					message.alphaTick = getTickCount()
					message.display = false
				end
			end
		end, 2000, 1)
	end
end)

-- Add line
function createMessage(player, prefix, rank)
	rank = tonumber(rank) or nil
	if not isElement(player) or not rank then
		return
	end
	prefix = tostring(prefix or "died")
	local message = {}
	local text = ""
	if rank == 1 then
		if prefix == "died" then
			text = getPlayerName(player).." #FFFFFFhas won"
		elseif prefix == "finished" then
			local rankText = rank..((rank < 10 or rank > 20) and ({ [1] = "st", [2] = "nd", [3] = "rd" })[rank % 10] or "th")
			text = getPlayerName(player).." #FFFFFFfinished "..rankText 
		end
	else
		local rankText = rank..((rank < 10 or rank > 20) and ({ [1] = "st", [2] = "nd", [3] = "rd" })[rank % 10] or "th")
		text = getPlayerName(player).." #FFFFFF"..prefix.." "..rankText 
	end
	--[[local avatarHash = getElementData(player, "avatarHash")
	if avatarHash then
		local path = ":v_avatars/avatarcache/"..avatarHash
		if fileExists(path) then
			message.avatar = dxCreateTexture(path)
		end
	end]]--
	message.player = player
	message.rank = rank
	message.text = text
	message.appearTick = getTickCount()
	message.fadeTick = getTickCount()
	message.alphaTick = 0
	message.textTick = 0
	message.progressFade = 0
	message.progressAlpha = 0
	message.progressAlphaToGo = 0
	message.progressText = 0
	message.progressTextToGo = 0
	message.display = true
	message.width = dxGetTextWidth(message.text:gsub("#%x%x%x%x%x%x", ""), deathlist.fontScale, deathlist.font)
	table.insert(deathlist.messages, 1, message)
	if #deathlist.messages > deathlist.maximumToShow then
		for i, message in pairs(deathlist.messages) do
			if i > deathlist.maximumToShow and message.display then
				message.fadeTick = getTickCount()
				message.alphaTick = getTickCount()
				message.display = false
			end
		end
	elseif #deathlist.messages == 1 then
		removeEventHandler("onClientRender", root, renderMessages)
		addEventHandler("onClientRender", root, renderMessages)
	end
	if deathlist.resetTimer and isTimer(deathlist.resetTimer) then
		killTimer(deathlist.resetTimer)
	end
	triggerEvent("speedo:setOffset", localPlayer, screenHeight - deathlist.y - deathlist.offset)
end
addEvent("deathlist:add", true)
addEventHandler("deathlist:add", localPlayer, createMessage)

-- Toggle
addEvent("racehud:onTemporaryVisibilityChanged", true)
addEventHandler("racehud:onTemporaryVisibilityChanged", localPlayer,
function(state)
	deathlist.tick = getTickCount()
	deathlist.temporaryInvisible = state
	if not deathlist.temporaryInvisible then
		removeEventHandler("onClientRender", root, renderMessages)
		addEventHandler("onClientRender", root, renderMessages)
		if #deathlist.messages > 0 then
			triggerEvent("speedo:setOffset", localPlayer, screenHeight - deathlist.y - deathlist.offset)
		end
	else
		triggerEvent("speedo:setOffset", localPlayer, 0)
	end
end)

addEvent("panel:onVisibilityChanged", true)
addEventHandler("panel:onVisibilityChanged", localPlayer,
function()
	deathlist.tick = getTickCount()
end)

-- Render
function renderMessages()
	local currentTick = getTickCount()
	local deathlistTick = deathlist.tick or 0
	deathlist.alpha = interpolateBetween(deathlist.alpha or 0, 0, 0, (not deathlist.visible or deathlist.temporaryInvisible or getElementData(localPlayer, "panel.visible")) and 0 or 1, 0, 0, math_min(500, currentTick - deathlistTick)/500, deathlist.interpolator)
	if deathlist.temporaryInvisible and deathlist.alpha == 0 then
		removeEventHandler("onClientRender", root, renderMessages)
		return
	end
	local globalOffsetY = deathlist.y
	for i, message in pairs(deathlist.messages) do
		local fadeTick = message.fadeTick or 0
		message.progressPadding = interpolateBetween(message.progressPadding or 0, 0, 0, 1, 0, 0, math_min(1000, currentTick - fadeTick)/1000, deathlist.interpolator)
		message.progressFade = interpolateBetween(message.progressFade or 0, 0, 0, message.display and 1 or 0, 0, 0, math_min(1000, currentTick - fadeTick)/1000, deathlist.interpolator)
		if message.display and message.progressFade >= 0.99 and message.progressAlphaToGo == 0 then
			message.alphaTick = getTickCount()
			message.progressAlphaToGo = 1
		end
		local alphaTick = message.alphaTick or 0
		message.progressAlpha = interpolateBetween(message.progressAlpha or 0, 0, 0, message.progressAlphaToGo or 0, 0, 0, math_min(1000, currentTick - alphaTick)/1000, deathlist.interpolator)
		if message.display and message.progressAlpha >= 0.99 and message.progressTextToGo == 0 then
			message.textTick = getTickCount()
			message.progressTextToGo = 1
		end
		local textTick = message.textTick or 0
		message.progressText = interpolateBetween(message.progressText or 0, 0, 0, message.progressTextToGo, 0, 0, math_min(1000, currentTick - textTick)/1000, deathlist.interpolator)
		local width = (message.width + deathlist.padding * 4) * message.progressAlpha
		local offsetX = deathlist.x - width
		local fadeDelay = 500
		local fadeFactor = message.display and math_min(fadeDelay, currentTick - textTick)/fadeDelay or 0
		dxDrawCurvedRectangle(offsetX, globalOffsetY, width, deathlist.rowHeight, tocolor(10, 10, 10, 185 * message.progressFade * message.progressAlpha * deathlist.alpha), false)
		dxDrawCurvedBorder(offsetX, globalOffsetY, width, deathlist.rowHeight, tocolor(25, 25, 25, 245 * message.progressFade * message.progressAlpha * deathlist.alpha), false)
		dxDrawImage(deathlist.x, globalOffsetY, deathlist.rowHeight, deathlist.rowHeight, "img/circle.png", 0, 0, 0, tocolor(5, 5, 5, 205 * message.progressFade * message.progressAlpha * deathlist.alpha), false)
		if fadeFactor > 0 then
			local scale = 20 * fadeFactor * message.progressFade * message.progressAlpha
			dxDrawImage(deathlist.x - scale/2, globalOffsetY - scale/2, deathlist.rowHeight + scale, deathlist.rowHeight + scale, "img/circle.png", 0, 0, 0, tocolor(5, 5, 5, 205 * (1 - fadeFactor) * message.progressFade * message.progressAlpha * deathlist.alpha), false)
		end
		local avatar = message.avatar or deathlist.defaultAvatar
		dxSetShaderValue(deathlist.maskShader, "imageTexture", avatar)
		dxDrawImage(deathlist.x + deathlist.avatarOffset, globalOffsetY + deathlist.avatarOffset, deathlist.avatarSize, deathlist.avatarSize, deathlist.maskShader, 0, 0, 0, tocolor(255, 255, 255, 255 * message.progressFade * message.progressAlpha * deathlist.alpha), false)
		dxDrawText(message.text, offsetX + deathlist.padding * 2, globalOffsetY, offsetX + width, globalOffsetY + deathlist.rowHeight, tocolor(255, 255, 255, 255 * message.progressText * message.progressAlpha * message.progressFade * deathlist.alpha), deathlist.fontScale, deathlist.font, "center", "center", false, false, false, true)
		globalOffsetY = math.floor(globalOffsetY + (deathlist.rowHeight + deathlist.padding) * message.progressPadding)
		if not message.display and message.progressFade == 0 then
			if message.avatar then
				destroyElement(message.avatar)
			end
			deathlist.messages[i] = nil
			if #deathlist.messages == 0 then
				removeEventHandler("onClientRender", root, renderMessages)
				triggerEvent("speedo:setOffset", localPlayer, 0)
			end
		end
	end
end

-- Helpful functions
function dxDrawCurvedRectangle(x, y, width, height, color, postGUI)
	if type(x) ~= "number" or type(y) ~= "number" or type(width) ~= "number" or type(height) ~= "number" then
		return
	end
	local color = color or tocolor(25, 132, 109, 255)
	local postGUI = type(postGUI) == "boolean" and postGUI or false
	local edgeSize = height/2
	dxDrawImageSection(x, y, edgeSize, edgeSize, 0, 0, 33, 33, "img/edge.png", 0, 0, 0, color, postGUI)
	dxDrawImageSection(x, y + edgeSize, edgeSize, edgeSize, 0, 33, 33, 33, "img/edge.png", 0, 0, 0, color, postGUI)
	dxDrawImageSection(x + width + edgeSize, y, edgeSize, edgeSize, 43, 0, 33, 33, "img/edge.png", 0, 0, 0, color, postGUI)
	dxDrawImageSection(x + width + edgeSize, y + edgeSize, edgeSize, edgeSize, 43, 33, 33, 33, "img/edge.png", 0, 0, 0, color, postGUI)
	if width > 0 then
		dxDrawImageSection(x + edgeSize, y, width, height, 33, 0, 10, 66, "img/edge.png", 0, 0, 0, color, postGUI)
	end
end

function dxDrawCurvedBorder(x, y, width, height, color, postGUI)
	if type(x) ~= "number" or type(y) ~= "number" or type(width) ~= "number" or type(height) ~= "number" then
		return
	end
	local color = color or tocolor(25, 132, 109, 255)
	local postGUI = type(postGUI) == "boolean" and postGUI or false
	local edgeSize = height/2
	width = width + height
	local lineWidth = math_max(width - height, 0)
	dxDrawImageSection(x + edgeSize, y, lineWidth, height, 90, 1, 10, 50, "img/border.png", 0, 0, 0, color, postGUI)
	dxDrawImageSection(x, y, edgeSize, height, 1, 1, 25, 50, "img/border.png", 0, 0, 0, color, postGUI)
	dxDrawImageSection(x + width - edgeSize, y, edgeSize, height, 26, 1, 25, 50, "img/border.png", 0, 0, 0, color, postGUI)
end

function rgbToHex(r, g, b)
	return string.format("#%.2X%.2X%.2X", r or 255, g or 255, b or 255)
end

_getPlayerName = getPlayerName
function getPlayerName(player)
	local name = _getPlayerName(player)
	local team = getPlayerTeam(player)
	if team then
		local r, g, b = getTeamColor(team)
		name = rgbToHex(r, g, b)..name
	end
	return name
end