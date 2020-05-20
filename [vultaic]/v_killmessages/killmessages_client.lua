local screenWidth, screenHeight = guiGetScreenSize()
local relativeScale, relativeFontScale = math.min(math.max(screenWidth/1600, 0.5), 1), math.min(math.max(screenWidth/1600, 0.85), 1)
local killmessages = {}
killmessages.list = {}
killmessages.offset = math.floor(screenHeight * 0.8)
killmessages.padding = 5
killmessages.fontScale = 1
killmessages.font = dxCreateFont(":v_locale/fonts/Roboto-Regular.ttf", math.floor(10 * relativeFontScale))
killmessages.fontHeight = dxGetFontHeight(killmessages.fontScale, killmessages.font)
killmessages.height = math.floor(killmessages.fontHeight * 2)
killmessages.maximumToShow = 2
killmessages.interpolator = "InOutQuad"
killmessages.fadeOutTime = 5000
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
	killmessages.maskShader = dxCreateShader("fx/mask.fx")
	killmessages.maskTexture = dxCreateTexture("img/circle.png")
	killmessages.defaultAvatar = dxCreateTexture(":v_avatars/img/default-avatar.png")
	dxSetShaderValue(killmessages.maskShader, "maskTexture", killmessages.maskTexture)
end)

-- Add line
function createMessage(details)
	local message = {}
	message.player = details.player
	message.action = details.action
	if not isElement(message.player) or not message.action then
		return
	end
	local text = message.action == "killed" and "You #00FF00killed #FFFFFF"..getPlayerName(message.player) or "You got #FF0000killed #FFFFFFby "..getPlayerName(message.player)
	message.text = text
	message.messageWidth = dxGetTextWidth(message.text:gsub("#%x%x%x%x%x%x", ""), killmessages.fontScale, killmessages.font) + killmessages.padding * 2
	message.appearTick = getTickCount()
	message.fadeTick = getTickCount()
	message.progressFade = 0
	message.progressFadeToGo = 1
	message.alphaTick = 0
	message.progressAlpha = 0
	message.progressAlphaToGo = 0
	message.display = true
	message.width = message.messageWidth + killmessages.padding * 2
	message.offsetX = (screenWidth - message.width)/2 - killmessages.height/2
	local avatar = exports.v_avatars:getAvatarTexture(message.player)
	if isElement(avatar) then
		message.avatar = avatar
	end
	table.insert(killmessages.list, 1, message)
	if #killmessages.list > killmessages.maximumToShow then
		for i, message in pairs(killmessages.list) do
			if i > killmessages.maximumToShow and message.display then
				message.fadeTick = getTickCount()
				message.alphaTick = getTickCount()
				message.display = false
			end
		end
	elseif #killmessages.list == 1 then
		removeEventHandler("onClientRender", root, renderKillmessages)
		addEventHandler("onClientRender", root, renderKillmessages, true, "low-2")
	end
end
addEvent("killmessage:create", true)
addEventHandler("killmessage:create", localPlayer, createMessage)

-- Rendering
function renderKillmessages()
	local currentTick = getTickCount()
	local globalOffsetY = killmessages.offset
	for i, message in pairs(killmessages.list) do
		if currentTick - message.appearTick > killmessages.fadeOutTime and message.display then
			message.fadeTick = getTickCount()
			message.alphaTick = getTickCount()
			message.display = false
		end
		local fadeTick = message.fadeTick or 0
		message.progressFade = interpolateBetween(message.progressFade or 0, 0, 0, message.progressFadeToGo, 0, 0, math_min(500, currentTick - fadeTick)/500, killmessages.interpolator)
		if message.display and message.progressFade >= 0.99 and message.progressAlphaToGo == 0 then
			message.alphaTick = getTickCount()
			message.progressAlphaToGo = 1
		end
		local alphaTick = message.alphaTick or 0
		message.progressAlpha = interpolateBetween(message.progressAlpha or 0, 0, 0, message.display and message.progressAlphaToGo or 0, 0, 0, math_min(2000, currentTick - alphaTick)/2000, killmessages.interpolator)
		if not message.display and message.progressAlpha <= 0.01 and message.progressFadeToGo == 1 then
			message.fadeTick = getTickCount()
			message.progressFadeToGo = 0
		end
		local x, y = message.offsetX, globalOffsetY
		dxDrawCurvedRectangle(x, y , message.width, killmessages.height, tocolor(10, 10, 10, 185 * message.progressAlpha * message.progressFade), false)	
		local avatar = isElement(message.avatar) and message.avatar or killmessages.defaultAvatar
		dxSetShaderValue(killmessages.maskShader, "imageTexture", avatar)
		local distance = message.width * 0.1 * (1 - message.progressFade)
		dxDrawImage(x + distance, y, killmessages.height, killmessages.height, "img/circle.png", 0, 0, 0, tocolor(10, 10, 10, 185 * message.progressFade), false)
		dxDrawImage(x + distance, y, killmessages.height, killmessages.height, killmessages.maskShader, 0, 0, 0, tocolor(255, 255, 255, 255 * message.progressFade), false)
		dxDrawText(message.text, x + killmessages.height + killmessages.padding, y, x + message.width, y + killmessages.height, tocolor(255, 255, 255, 255 * message.progressAlpha * message.progressFade), killmessages.fontScale, killmessages.font, "left", "center", false, false, false, true)
		globalOffsetY = math.ceil(globalOffsetY - (killmessages.height + 5) * message.progressFade)
		if not message.display and message.progressAlpha == 0 then
			killmessages.list[i] = nil
			if #killmessages.list == 0 then
				removeEventHandler("onClientRender", root, renderKillmessages)
			end
		end
	end
end

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