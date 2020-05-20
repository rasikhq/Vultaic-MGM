g_Achievements = {}
p_Achievements = {}
addEventHandler("onClientResourceStart", resourceRoot, function()
	triggerServerEvent("Achievements:onPlayerRequestList", resourceRoot)
end)

addEvent("Achievements:onPlayerReceiveList", true)
addEventHandler("Achievements:onPlayerReceiveList", localPlayer, function(_g_Achievements, _p_Achievements)
	g_Achievements = _g_Achievements
	p_Achievements = _p_Achievements
	triggerEvent("Achievements:onClientUnlockAchievement", localPlayer)
	--print("Received g_Achievements list")
end)

addEvent("Achievements:onPlayerUnlockAchievement", true)
addEventHandler("Achievements:onPlayerUnlockAchievement", localPlayer, function(achievement_id)
	p_Achievements[achievement_id] = true
	triggerEvent("Achievements:onClientUnlockAchievement", localPlayer)
	-- UI
	local data = g_Achievements[achievement_id]
	displayMessage({name = data[2].." #19846D($"..data[5]..")", description = data[4]})
	--print("Received p_Achievements list")
end)

--[[ Exports ]]--
function getPlayerAchievements()
	if not getElementData(localPlayer, "LoggedIn") or type(p_Achievements) ~= "table" or type(g_Achievements) ~= "table" then
		return {}
	end
	local achievements = {}
	for achievement_id, achievement_data in pairs(g_Achievements) do
		--print("achievement_id: "..achievement_id)
		achievements[achievement_id] = {
			elementData = achievement_data[1],
			name = achievement_data[2],
			goal = achievement_data[3],
			description = achievement_data[4]
		}
		if p_Achievements[achievement_id] == true then
			achievements[achievement_id]["completed"] = true
		end
	end
	return achievements
end

-- UI
local screenWidth, screenHeight = guiGetScreenSize()
local relativeFontScale = math.min(math.max(screenWidth/1600, 0.85), 1)
local message = {interpolator = "Linear"}
message.fonts = {
	regular = {[13] = dxCreateFont(":v_locale/fonts/Roboto-Regular.ttf", math.floor(13 * relativeFontScale)), [16] = dxCreateFont(":v_locale/fonts/Roboto-Regular.ttf", math.floor(16 * relativeFontScale))}
}
message.title = "Achievement unlocked"
message.titleWidth = dxGetTextWidth(message.title, 1, message.fonts.regular[13])
message.fontHeight = {}
for family in pairs(message.fonts) do
	message.fontHeight[family] = {}
	for k, font in pairs(message.fonts[family]) do
		message.fontHeight[family][k] = dxGetFontHeight(1, font)
	end
end
message.height = message.fontHeight.regular[13] * 2 + message.fontHeight.regular[16] + 20
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

function displayMessage(data)
	if type(data) == "table" then
		message.name = tostring(data.name)
		message.description = tostring(data.description)
		message.nameWidth = dxGetTextWidth(data.name, 1, message.fonts.regular[16])
		message.descriptionWidth = dxGetTextWidth(data.description, 1, message.fonts.regular[13])
		message.width = math.floor(math.max(message.nameWidth, message.titleWidth, message.descriptionWidth)) + 40
		message.x = (screenWidth - message.width)/2
		message.tick = getTickCount()
		message.display = true
		message.progress = 0
		removeEventHandler("onClientRender", root, renderMessage)
		addEventHandler("onClientRender", root, renderMessage)
		if message.hideTimer and isTimer(message.hideTimer) then
			killTimer(message.hideTimer)
		end
		message.hideTimer = setTimer(function() message.tick = getTickCount() message.display = false end, 10000, 1)
		playSound("sfx/unlock.wav", false)
	end
end

function renderMessage()
	local currentTick = getTickCount()
	local tick = message.tick or 0
	message.progress = interpolateBetween(message.progress or 0, 0, 0, message.display and 1 or 0, 0, 0, math_min(500, currentTick - tick)/500, message.interpolator)
	if not message.display and message.progress == 0 then
		return removeEventHandler("onClientRender", root, renderMessage)
	end
	local x, y = message.x, screenHeight * 0.8 + 20 * (1 - message.progress)
	local x = message.height/2
	local iconSize = message.height * 0.45
	local iconOffset = (message.height - iconSize)/2
	do
		local x = message.x + message.height/2
		local y = y - 10
		dxDrawCurvedRectangle(x, y, message.width, message.height, tocolor(10, 10, 10, 185 * message.progress), false)
		dxDrawCurvedRectangle(x, y, 0, message.height, tocolor(25, 25, 25, 245 * message.progress), false)
	end
	dxDrawImageSection(message.x - message.height/2 + iconOffset, y - 10 + iconOffset, iconSize, iconSize, 1, 1, 62, 62, "img/unlock.png", 0, 0, 0, tocolor(55, 255, 55, 255 * message.progress), false)
	x = x + message.height * 0.25
	dxDrawText(message.title, x, y, screenWidth, screenHeight, tocolor(25, 132, 109, 255 * message.progress), 1, message.fonts.regular[13], "center", "top", false, false, false, true)
	y = y + message.fontHeight.regular[13]
	dxDrawText(message.name, x, y, screenWidth, screenHeight, tocolor(255, 255, 255, 255 * message.progress), 1, message.fonts.regular[16], "center", "top", false, false, false, true)
	y = y + message.fontHeight.regular[16]
	dxDrawText(message.description, x, y, screenWidth, screenHeight, tocolor(255, 255, 255, 155 * message.progress), 1, message.fonts.regular[13], "center", "top", false, false, false, true)
end

function dxDrawCurvedRectangle(x, y, width, height, color, postGUI, texture)
	if type(x) ~= "number" or type(y) ~= "number" or type(width) ~= "number" or type(height) ~= "number" then
		return
	end
	local texture = texture or "img/edge.png"
	local color = color or tocolor(25, 132, 109, 255)
	local postGUI = type(postGUI) == "boolean" and postGUI or false
	local edgeSize = height/2
	x = x - height
	dxDrawImageSection(x, y, edgeSize, edgeSize, 0, 0, 33, 33, texture, 0, 0, 0, color, postGUI)
	dxDrawImageSection(x, y + edgeSize, edgeSize, edgeSize, 0, 33, 33, 33, texture, 0, 0, 0, color, postGUI)
	dxDrawImageSection(x + width + edgeSize, y, edgeSize, edgeSize, 43, 0, 33, 33, texture, 0, 0, 0, color, postGUI)
	dxDrawImageSection(x + width + edgeSize, y + edgeSize, edgeSize, edgeSize, 43, 33, 33, 33, texture, 0, 0, 0, color, postGUI)
	if width > 0 then
		dxDrawImageSection(x + edgeSize, y, width, height, 33, 0, 10, 66, texture, 0, 0, 0, color, postGUI)
	end
end