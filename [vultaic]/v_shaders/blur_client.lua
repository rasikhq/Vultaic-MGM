local screenWidth, screenHeight = guiGetScreenSize()
local settings = {
	blurFactor = 2,
	brightness = 0.5,
	desaturate = 0.5,
	resolution = {1, 1}
}
local data = {}
local handlers = {}
-- Optimization
local tocolor = tocolor
local math_min = math.min
local math_max = math.max
local math_floor = math.floor
local interpolateBetween = interpolateBetween

function data.createShader()
	data.screenSource = dxCreateScreenSource(screenWidth * settings.resolution[1], screenHeight * settings.resolution[2])
	local x, y = dxGetMaterialSize(data.screenSource)
	data.renderTarget = dxCreateRenderTarget(x, y, true)
	data.colorShader = dxCreateShader("fx/fxColor.fx")
	data.blurShaderH = dxCreateShader("fx/fxBlurH.fx")
	data.blurShaderV = dxCreateShader("fx/fxBlurV.fx")
	local loaded = isElement(data.colorShader) and isElement(data.blurShaderH) and isElement(data.blurShaderV) and true or false
	if loaded then
		print("[Blur Shader] Successfully initialized")
	else
		print("[Blur Shader] Failed to initialize")
	end
end
addEventHandler("onClientResourceStart", resourceRoot, data.createShader)

function data.applyColor(screenSource, x, y, brightness, desaturate)
	if not isElement(screenSource) then
		return nil
	end
	local width, height = dxGetMaterialSize(screenSource)
	dxSetRenderTarget(data.renderTarget, true) 
	dxSetShaderValue(data.colorShader, "TEX0", screenSource)
	dxSetShaderValue(data.colorShader, "fBrightness", brightness)
	dxSetShaderValue(data.colorShader, "fDesaturate", desaturate)
	dxSetShaderValue(data.colorShader, "TexSize", x, y)
	dxDrawImage(0, 0, width, height, data.colorShader)
	return data.renderTarget
end

function data.applyBlurH(screenSource, x, y, blur)
	if not isElement(screenSource) then
		return nil
	end
	local width, height = dxGetMaterialSize(screenSource)
	dxSetRenderTarget(data.renderTarget, true) 
	dxSetShaderValue(data.blurShaderH, "TEX0", screenSource)
	dxSetShaderValue(data.blurShaderH, "TexSize", x, y)
	dxSetShaderValue(data.blurShaderH, "gBlurFac", blur)
	dxDrawImage(0, 0, width, height, data.blurShaderH)
	return data.renderTarget
end

function data.applyBlurV(screenSource, x, y, blur)
	if not isElement(screenSource) then
		return nil
	end
	local width, height = dxGetMaterialSize(screenSource)
	dxSetRenderTarget(data.renderTarget, true) 
	dxSetShaderValue(data.blurShaderV, "TEX0", screenSource)
	dxSetShaderValue(data.blurShaderV, "TexSize", x, y)
	dxSetShaderValue(data.blurShaderV, "gBlurFac", blur)
	dxDrawImage(0, 0, width, height, data.blurShaderV)
	return data.renderTarget
end

function data.show(handler)
	if handler and type(handler) == "string" then
		local found = false
		for i, v in pairs(handlers) do
			if v == handler then
				found = true
				break
			end
		end
		if not found then
			table.insert(handlers, handler)
		end
	end
	if data.visible then
		return
	end
	data.tick = getTickCount()
	data.visible = true
	removeEventHandler("onClientRender", root, data.render)
	addEventHandler("onClientRender", root, data.render, true, "low-1")
end
addEvent("blur:enable", true)
addEventHandler("blur:enable", localPlayer, data.show)

function data.hide(handler)
	if handler then
		for i, v in pairs(handlers) do
			if v == handler then
				table.remove(handlers, i)
				break
			end
		end
	end
	if not data.visible then
		return
	end
	if #handlers > 0 then
		return
	end
	data.tick = getTickCount()
	data.visible = false
end
addEvent("blur:disable", true)
addEventHandler("blur:disable", localPlayer, data.hide)

function data.render()
	local currentTick = getTickCount()
	local tick = tonumber(data.tick or 0)
	data.progress = interpolateBetween(data.progress or 0, 0, 0, data.visible and 1 or 0, 0, 0, math_min(500, currentTick - tick)/500, "Linear")
	if not data.visible and data.progress == 0 then
		removeEventHandler("onClientRender", root, data.render)
		return
	end
	dxUpdateScreenSource(data.screenSource, true)
	local currentBox = data.screenSource
	currentBox = data.applyColor(currentBox, screenWidth, screenHeight, settings.brightness, settings.desaturate)
	currentBox = data.applyBlurH(currentBox, screenWidth, screenHeight, settings.blurFactor)
	currentBox = data.applyBlurV(currentBox, screenWidth, screenHeight, settings.blurFactor)
	dxSetRenderTarget()
	dxDrawImage(0, 0, screenWidth, screenHeight, currentBox, 0, 0, 0, tocolor(255, 255, 255, 255 * data.progress), false)
end