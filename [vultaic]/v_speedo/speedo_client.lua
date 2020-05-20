local screenWidth, screenHeight = guiGetScreenSize()
local relativeFontScale = math.min(math.max(screenWidth/1600, 0.85), 1)
local speedo = {
	offsetX = 10,
	offsetY = 25
}
speedo.fontScale = 1
speedo.font = dxCreateFont(":v_locale/fonts/Roboto-Regular.ttf", math.floor(11 * relativeFontScale))
speedo.fontNeedle = dxCreateFont(":v_locale/fonts/Roboto-Regular.ttf", math.floor(20 * relativeFontScale))
speedo.fontHeight = dxGetFontHeight(speedo.fontScale, speedo.font)
speedo.interpolator = "Linear"
speedo.width, speedo.height = screenWidth - speedo.offsetX, screenHeight - speedo.offsetY
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
local math_abs = math.abs
local math_rad = math.rad
local math_deg = math.deg
local math_cos = math.cos
local math_sin = math.sin
local math_atan2 = math.atan2
local tableInsert = table.insert
local tableRemove = table.remove
local pairs = pairs
local interpolateBetween = interpolateBetween

addEventHandler("onClientResourceStart", resourceRoot,
function()
	local state = not (exports.v_settings:getClientVariable("disable_speedo") == "On")
	if state then
		speedo.setVisible(state)
	end
end)

addEvent("settings:onSettingChange", true)
addEventHandler("settings:onSettingChange", localPlayer,
function(variable, value)
	if variable == "disable_speedo" then
		local state = not (value == "On")
		speedo.setVisible(state, true)
	end
end)

function speedo.setVisible(visible, notifyDisplay)
	speedo.tick = getTickCount()
	speedo.visible = visible and true or false
	if speedo.visible then
		removeEventHandler("onClientRender", root, speedo.render)
		addEventHandler("onClientRender", root, speedo.render)
	end
	if notifyDisplay then
		triggerEvent("notification:create", localPlayer, "Speedometer", "Speedometer is now "..(speedo.visible and "visible" or "invisible"))
	end
end

function speedo.setOffset(offset)
	if type(offset) == "number" then
		speedo.offsetTick = getTickCount()
		speedo.extraOffset = math_max(offset, 0)
	end
end
addEvent("speedo:setOffset", true)
addEventHandler("speedo:setOffset", localPlayer, speedo.setOffset)

function speedo.render()
	local currentTick = getTickCount()
	local speedoTick = speedo.tick or 0
	speedo.alpha = interpolateBetween(speedo.alpha or 0, 0, 0, (not speedo.visible or getElementData(localPlayer, "panel.visible")) and 0 or 1, 0, 0, math_min(500, currentTick - speedoTick)/500, speedo.interpolator)
	if speedo.extraOffset then
		local speedoExtraOffsetTick = speedo.offsetTick or 0
		speedo.additionalOffset = interpolateBetween(speedo.additionalOffset or 0, 0, 0, speedo.extraOffset, 0, 0, math_min(500, currentTick - speedoExtraOffsetTick)/500, speedo.interpolator)
	end
	if not speedo.visible and speedo.alpha == 0 then
		return removeEventHandler("onClientRender", root, speedo.render)
	end
	local target = getCameraTarget() or localPlayer
	if isPedInVehicle(target) then
		local speed = getElementSpeed(getPedOccupiedVehicle(target))
		local speedStr = tostring(math_floor(speed))
		local height = speedo.height - (speedo.additionalOffset or 0)
		dxDrawText("KM/H", 0, 0, speedo.width, height, tocolor(255, 255, 255, 155 * speedo.alpha), speedo.fontScale, speedo.font, "right", "bottom", false, false, false, true)
		dxDrawText(speedStr, 0, 0, speedo.width, height - speedo.fontHeight, tocolor(255, 255, 255, 255 * speedo.alpha), speedo.fontScale, speedo.fontNeedle, "right", "bottom", false, false, false, true)
	end
end

addEvent("panel:onVisibilityChanged", true)
addEventHandler("panel:onVisibilityChanged", localPlayer,
function()
	if speedo.visible and not speedo.temporaryInvisible then
		speedo.tick = getTickCount()
	end
end)

function getElementSpeed(element)
	if isElement(element) then
		local x, y, z = getElementVelocity(element)
		return (x ^ 2 + y ^ 2 + z ^ 2) ^ 0.5 * 1.8 * 100
	else
		return 0
	end
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