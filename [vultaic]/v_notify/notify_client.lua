local screenWidth, screenHeight = guiGetScreenSize()
local relativeScale, relativeFontScale = math.min(math.max(screenWidth/1600, 0.5), 1), math.min(math.max(screenWidth/1600, 0.85), 1)
local notifications = {}
notifications.list = {}
notifications.offset = 5
notifications.padding = 10
notifications.fontScale = 1
notifications.font = dxCreateFont(":v_locale/fonts/Roboto-Regular.ttf", math.floor(10 * relativeFontScale))
notifications.fontHeight = dxGetFontHeight(notifications.fontScale, notifications.font)
notifications.width = math.floor(360 * relativeScale)
notifications.height = math.floor(notifications.fontHeight + notifications.padding * 2)
notifications.maximumToShow = 3
notifications.iconSize = math.floor(20 * relativeScale * 0.7)
notifications.interpolator = "InOutQuad"
notifications.fadeOutTime = 5000
notifications.icons = {}
notifications.defaultIcon = dxCreateTexture("img/icons/default.png")
local colors = {
	white = {25, 132, 109},
	red = {255, 55, 0},
	green = {5, 255, 5},
	blue = {0, 55, 255},
	yellow = {255, 255, 5}
}
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

-- Add line
function createNotification(title, text, iconTexture, highlightColor, animate)
	local notification = {}
	notification.title = title or "Notification"
	notification.text = tostring(text or "Message")
	notification.textClean = notification.text:gsub("#%x%x%x%x%x%x", "")
	local texture = iconTexture
	if type(iconTexture) == "string" then
		if fileExists(iconTexture) then
			if not notifications.icons[iconTexture] then
				notifications.icons[iconTexture] = dxCreateTexture(iconTexture)
			end
			texture = notifications.icons[iconTexture]
		elseif fileExists("img/icons/"..iconTexture) then
			if not notifications.icons[iconTexture] then
				notifications.icons[iconTexture] = dxCreateTexture("img/icons/"..iconTexture)
			end
			texture = notifications.icons[iconTexture]
		end
	end
	notification.iconTexture = isElement(texture) and texture or notifications.defaultIcon
	notification.highlightColor = colors[tostring(highlightColor)] or colors.white
	notification.animate = animate and true or false
	local splitString = string.split(notification.text)
	local text, textWidth, textData = "", 0, {}
	local maxWidth = 0
	for i = 1, #splitString do
		if text == "" then
			text = text..splitString[i]
		else
			text = text.." "..splitString[i]
		end
		textWidth = dxGetTextWidth(text:gsub("#%x%x%x%x%x%x", ""), notifications.fontScale, notifications.font)
		if textWidth > notifications.width then
			table.insert(textData, text)
			if textWidth > maxWidth then
				maxWidth = textWidth
			end
			text = ""
			textWidth = 0
		elseif i == #splitString then
			table.insert(textData, text)
			if textWidth > maxWidth then
				maxWidth = textWidth
			end
		end
	end
	if #textData == 0 then
		text = ""
		for i = 1, #splitString do
			if text == "" then
				text = text..splitString[i]
			else
				text = text.." "..splitString[i]
			end
		end
		maxWidth = dxGetTextWidth(text:gsub("#%x%x%x%x%x%x", ""), notifications.fontScale, notifications.font)
		table.insert(textData, text)
	end
	local titleWidth = dxGetTextWidth(notification.title:gsub("#%x%x%x%x%x%x", ""), notifications.fontScale, notifications.font)
	notification.textData = textData
	notification.appearTick = getTickCount()
	notification.animationTick = getTickCount()
	notification.fadeTick = getTickCount()
	notification.progressFade = 0
	notification.progressFadeToGo = 1
	notification.alphaTick = 0
	notification.progressAlpha = 0
	notification.progressAlphaToGo = 0
	notification.display = true
	notification.width = math.max(titleWidth, maxWidth) + notifications.padding * 3 + notifications.iconSize
	notification.height = ((#notification.textData + 1) * notifications.fontHeight) + notifications.padding * 2
	notification.offsetX = screenWidth - (notification.width + notifications.offset)
	notification.animationState = 0.75
	table.insert(notifications.list, 1, notification)
	if #notifications.list > notifications.maximumToShow then
		for i, notification in pairs(notifications.list) do
			if i > notifications.maximumToShow and notification.display then
				notification.fadeTick = getTickCount()
				notification.alphaTick = getTickCount()
				notification.display = false
			end
		end
	elseif #notifications.list == 1 then
		removeEventHandler("onClientRender", root, renderNotifications)
		addEventHandler("onClientRender", root, renderNotifications, true, "low-3")
	end
end
addEvent("notification:create", true)
addEventHandler("notification:create", localPlayer, createNotification)

-- Rendering
function renderNotifications()
	local currentTick = getTickCount()
	local globalOffsetY = notifications.offset
	for i, notification in pairs(notifications.list) do
		if currentTick - notification.appearTick > notifications.fadeOutTime and notification.display then
			notification.fadeTick = getTickCount()
			notification.alphaTick = getTickCount()
			notification.display = false
		end
		local fadeTick = notification.fadeTick or 0
		notification.progressFade = interpolateBetween(notification.progressFade or 0, 0, 0, notification.progressFadeToGo, 0, 0, math_min(1000, currentTick - fadeTick)/1000, notifications.interpolator)
		if notification.display and notification.progressFade >= 0.8 and notification.progressAlphaToGo == 0 then
			notification.alphaTick = getTickCount()
			notification.progressAlphaToGo = 1
		end
		local alphaTick = notification.alphaTick or 0
		notification.progressAlpha = interpolateBetween(notification.progressAlpha or 0, 0, 0, notification.display and notification.progressAlphaToGo or 0, 0, 0, math_min(2000, currentTick - alphaTick)/2000, notifications.interpolator)
		if not notification.display and notification.progressAlpha <= 0.2 and notification.progressFadeToGo == 1 then
			notification.fadeTick = getTickCount()
			notification.progressFadeToGo = 0
		end	
		local animationProgress = 1
		if notification.animate then
			animationProgress = interpolateBetween(notification.animationState == 0.75 and 1 or 0.75, 0, 0, notification.animationState, 0, 0, math_min(500, currentTick - notification.animationTick)/500, notifications.interpolator)
			if notification.animationState == 0.75 and animationProgress <= 0.75 then
				notification.animationTick = getTickCount()
				notification.animationState = 1
			elseif notification.animationState == 1 and animationProgress >= 1 then
				notification.animationTick = getTickCount()
				notification.animationState = 0.75
			end
		end
		local r, g, b = notification.highlightColor[1] or 255, notification.highlightColor[2] or 255, notification.highlightColor[3] or 255
		local textOffset = notifications.iconSize + notifications.padding * 2
		local fadeDelay = notifications.fadeOutTime * 0.15
		local fadeFactor = math_min(fadeDelay, currentTick - notification.alphaTick)/fadeDelay
		dxDrawCurvedRectangle(notification.offsetX, globalOffsetY, notification.width, notification.height, tocolor(10, 10, 10, 185 * notification.progressAlpha * notification.progressFade), true)
		if isElement(notification.iconTexture) then
			dxDrawImageSection(notification.offsetX + notifications.padding, globalOffsetY + notifications.padding, notifications.iconSize, notifications.iconSize, 1, 1, 46, 46, notification.iconTexture, 0, 0, 0, tocolor(r, g, b, 255 * notification.progressAlpha * notification.progressFade * animationProgress), true)
			if fadeFactor > 0 then
				local fadeScale = notification.display and 20 * fadeFactor * notification.progressAlpha or 0	
				dxDrawImageSection(notification.offsetX + notifications.padding  - fadeScale/2, globalOffsetY + notifications.padding - fadeScale/2, notifications.iconSize + fadeScale, notifications.iconSize + fadeScale, 1, 1, 46, 46, notification.iconTexture, 0, 0, 0, tocolor(r, g, b, 255 * (1 - fadeFactor) * notification.progressFade * animationProgress), true)
			end
		end
		dxDrawText(notification.title, notification.offsetX + textOffset, globalOffsetY + notifications.padding, notification.width, notifications.fontHeight, tocolor(255, 255, 255, 255 * notification.progressAlpha * notification.progressFade), notifications.fontScale, notifications.font, "left", "top", false, false, true, true)
		local offsetY = notifications.fontHeight + notifications.padding + 2
		for k = 1, #notification.textData do
			dxDrawText(notification.textData[k], notification.offsetX + textOffset, globalOffsetY + offsetY, notification.width, notifications.fontHeight, tocolor(205, 205, 205, 255 * notification.progressAlpha * notification.progressFade), notifications.fontScale, notifications.font, "left", "top", false, false, true, true)
			offsetY = offsetY + notifications.fontHeight
		end
		globalOffsetY = math.ceil(globalOffsetY + (notification.height + 2) * notification.progressFade)
		if not notification.display and notification.progressAlpha == 0 then
			notifications.list[i] = nil
			if #notifications.list == 0 then
				removeEventHandler("onClientRender", root, renderNotifications)
			end
		end
	end
end

-- Useful functions
function dxDrawCurvedRectangle(x, y, width, height, color, postGUI)
	if type(x) ~= "number" or type(y) ~= "number" or type(width) ~= "number" or type(height) ~= "number" then
		return
	end
	local color = color or tocolor(25, 132, 109, 255)
	local postGUI = type(postGUI) == "boolean" and postGUI or false
	local edgeSize = height/2
	width = width - height
	dxDrawImageSection(x, y, edgeSize, edgeSize, 0, 0, 33, 33, "img/edge.png", 0, 0, 0, color, postGUI)
	dxDrawImageSection(x, y + edgeSize, edgeSize, edgeSize, 0, 33, 33, 33, "img/edge.png", 0, 0, 0, color, postGUI)
	dxDrawImageSection(x + width + edgeSize, y, edgeSize, edgeSize, 43, 0, 33, 33, "img/edge.png", 0, 0, 0, color, postGUI)
	dxDrawImageSection(x + width + edgeSize, y + edgeSize, edgeSize, edgeSize, 43, 33, 33, 33, "img/edge.png", 0, 0, 0, color, postGUI)
	if width > 0 then
		dxDrawImageSection(x + edgeSize, y, width, height, 33, 0, 10, 66, "img/edge.png", 0, 0, 0, color, postGUI)
	end
end

function string.split(str)
	if not str or type(str) ~= "string" then
		return false
	end
	return split(str, " ")
end