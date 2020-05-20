local screenWidth, screenHeight = guiGetScreenSize()
local screenSource = dxCreateScreenSource(screenWidth, screenHeight)
-- Optimization
local tocolor = tocolor
local math_min = math.min
local math_max = math.max
local math_floor = math.floor
local interpolateBetween = interpolateBetween

addEventHandler("onClientResourceStart", resourceRoot,
function()
	darkShader = dxCreateShader("fx/dark.fx")
end)

function setProgress(newProgress)
	newProgress = tonumber(newProgress) or nil
	if newProgress then
		if newProgress == 0 then
			effectTick = getTickCount()
			progress = 1
			progressToGo = 1
			removeEventHandler("onClientRender", root, renderEffect)
			addEventHandler("onClientRender", root, renderEffect, true, "high+5")
		elseif newProgress == 1 then
			effectTick = getTickCount()
			progressToGo = 0
		else
			effectTick = getTickCount()
			progressToGo = (1 - newProgress)
		end
	else
		effectTick = getTickCount()
		progressToGo = 0
	end
end
addEvent("fade:setProgress", true)
addEventHandler("fade:setProgress", localPlayer, setProgress)

function renderEffect()
	local currentTick = getTickCount()
	local tick = effectTick or 0
	progress = interpolateBetween(progress or 1, 0, 0, progressToGo or 1, 0, 0, math_min(2000, currentTick - tick)/2000, "Linear")
	if progressToGo == 0 and progress == 0 then
		removeEventHandler("onClientRender", root, renderEffect)
		return
	end
	dxUpdateScreenSource(screenSource)
    dxSetShaderValue(darkShader, "ScreenSource", screenSource)
    dxSetShaderValue(darkShader, "Alpha", progress * 0.5)
    dxDrawImage(0, 0, screenWidth, screenHeight, darkShader, 0, 0, 0, tocolor(255, 255, 255, 255), false)
end