local _G = _G
local screenWidth, screenHeight = guiGetScreenSize()
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
--
local getClientVariable = function(...) return exports.v_settings:getClientVariable(...) end
local getNosAmount = function(...) return exports.v_nos:getNosAmount(...) end
-- Positioning and sizing
local radar = {}
radar.offsetX, radar.offsetY = 20, 10
radar.scale = math_min(math_max(screenWidth/1600, 0.5), 1)
radar.size = 220 * radar.scale
radar.interpolator = "Linear"
radar.x, radar.y = radar.offsetX, screenHeight - radar.size - radar.offsetY
radar.blipSize = {client = math_floor(10 * math_min(radar.scale, 1)), player = math_floor(6 * math_min(radar.scale, 1)), checkpoint = math_floor(15 * math_min(radar.scale, 1))}
radar.centerLeft = radar.x + radar.size/2
radar.centerTop = radar.y + radar.size/2
radar.range = 150
radar.zoomScale = 1

addEventHandler("onClientResourceStart", resourceRoot,
function()
	radar.backgroundTexture = dxCreateTexture("img/radar-background.png")
	radar.maskShader = dxCreateShader("fx/hud-mask.fx")	
	radar.mapTexture = dxCreateTexture("img/map.jpg")
	radar.healthCircleTexture = dxCreateTexture("img/health-circle.png")
	radar.circleShader = dxCreateShader("fx/circle.fx")
	dxSetShaderValue(radar.circleShader, "tex", radar.healthCircleTexture)
	dxSetShaderValue(radar.maskShader, "sPicTexture", radar.mapTexture)
	dxSetShaderValue(radar.maskShader, "sMaskTexture", radar.backgroundTexture)
end)

function radar.setVisible(visible, mapEnabled)
	radar.tick = getTickCount()
	radar.visible = visible and true or false
	removeEventHandler("onClientRender", root, radar.render)
	if radar.visible then
		radar.mapEnabled = mapEnabled and true or false
		radar.setOffset(0)
		addEventHandler("onClientRender", root, radar.render)
		bindKey("F9", "down", radar.toggleTemporary)
	else
		unbindKey("F9", "down", radar.toggleTemporary)
	end
end
addEvent("radar:setVisible", true)
addEventHandler("radar:setVisible", localPlayer, radar.setVisible)

function radar.toggleTemporary()
	radar.tick = getTickCount()
	radar.temporaryInvisible = not radar.temporaryInvisible
	if radar.temporaryInvisible then
		triggerEvent("notification:create", localPlayer, "Interface", "Mini map is now invisible", "interface.png")
	else
		removeEventHandler("onClientRender", root, radar.render)
		addEventHandler("onClientRender", root, radar.render)
		triggerEvent("notification:create", localPlayer, "Interface", "Mini map is now visible", "interface.png")
	end
end

addEvent("panel:onVisibilityChanged", true)
addEventHandler("panel:onVisibilityChanged", localPlayer,
function()
	if radar.visible and not radar.temporaryInvisible then
		radar.tick = getTickCount()
	end
end)

function radar.setOffset(offset)
	if not radar.visible or radar.temporaryInvisible then
		return
	end
	if type(offset) == "number" then
		radar.offsetTick = getTickCount()
		radar.extraOffset = math_max(offset, 0)
	end
end
addEvent("radar:setOffset", true)
addEventHandler("radar:setOffset", localPlayer, radar.setOffset)

local function findRotation(x1, y1, x2, y2)
	local t = -math_deg(math_atan2(x2 - x1, y2 - y1))
	local t = t < 0 and t + 360 or t
	return t
end

local function getDistanceRotation(distance, angle)
	local a = math_rad(90 - angle)
	local dx = math_cos(a) * distance
	local dy = math_sin(a) * distance
	return dx, dy
end

local function getElementSpeed(element, unit)
	return Vector3(getElementVelocity(element)).length * 180
end

addEvent("core:onClientLeaveArena", true)
addEventHandler("core:onClientLeaveArena", localPlayer,
function(data)
	radar.setVisible(false)
end)

local healthColor = {55/255, 255/255, 55/255}
local nitroColor = {55/255, 155/255, 255/255}

function radar.render()
	local currentTick = getTickCount()
	local radarTick = radar.tick or 0
	radar.alpha = interpolateBetween(radar.alpha or 0, 0, 0, (not radar.visible or radar.temporaryInvisible or getElementData(localPlayer, "panel.visible")) and 0 or 1, 0, 0, math_min(500, currentTick - radarTick)/500, radar.interpolator)
	if radar.extraOffset then
		local radarExtraOffsetTick = radar.offsetTick or 0
		radar.additionalOffset = interpolateBetween(radar.additionalOffset or 0, 0, 0, radar.extraOffset, 0, 0, math_min(500, currentTick - radarExtraOffsetTick)/500, radar.interpolator)
	end
	if not radar.visible and radar.alpha == 0 then
		removeEventHandler("onClientRender", root, radar.render)
		return
	end
	if radar.alpha > 0 then
		local parent, dimension = getElementParent(localPlayer), getElementDimension(localPlayer)
		local gamemode = getElementData(parent, "gamemode")
		local radarX, radarY = radar.x, radar.y - (radar.additionalOffset or 0)
		local centerLeft = radarX + radar.size/2
		local centerTop = radarY + radar.size/2
		local cameraTarget = getCameraTarget() or localPlayer
		local cameraTargetVehicle = getPedOccupiedVehicle(cameraTarget)
		-- Part: 1
		local vehicle = getPedOccupiedVehicle(cameraTarget)
		do
			local speed = isElement(vehicle) and getElementSpeed(vehicle, "km/h") or false
			if speed then
				local percentage = math_min(speed/100, 1)
				local power = percentage/3
				radar.zoomScale = 1 - power
				radar.range = 150 * (power + 1)/radar.scale
			else
				radar.zoomScale = 1
				radar.range = 150/radar.scale
			end
		end
		local posX, posY, posZ = getElementPosition(cameraTarget)
		local pedRotZ = getPedRotation(cameraTarget)
		local camX, camY, camZ, tX, tY, tZ = getCameraMatrix()
		local north = findRotation(camX, camY, tX, tY)
		local northInv = 180 - north
		-- Part: 2
		local xDiv, yDiv = posX/6000, posY/-6000
		dxSetShaderValue(radar.maskShader, "gUVPosition", xDiv, yDiv)
		local zoom = 20 * radar.scale * radar.zoomScale
		radar.range = 3000/zoom
		local zoomInv = 1/zoom
		dxSetShaderValue(radar.maskShader, "gUVScale", zoomInv)
		dxSetShaderValue(radar.maskShader, "gUVRotAngle", math_rad(-north))
		-- Part: 3
		if radar.mapEnabled then
			local distance, backgroundAlpha = 0.5 - math_max(math_abs(xDiv), math_abs(yDiv)), 0
			if distance < 0 then
				distance = math_min(math_abs(distance, 0.01))
				backgroundAlpha = math_min(math_floor(185 * distance * 100), 185) * radar.alpha
				if backgroundAlpha > 0 then
					dxDrawImage(radarX, radarY, radar.size, radar.size, radar.backgroundTexture, 0, 0, 0, tocolor(10, 10, 10, backgroundAlpha), false)
				end
			end
			if backgroundAlpha ~= 205 then
				dxDrawImage(radarX, radarY, radar.size, radar.size, radar.maskShader, 0, 0, 0, tocolor(255, 255, 255, (185 - backgroundAlpha) * radar.alpha), false)
			end
		else
			dxDrawImage(radarX, radarY, radar.size, radar.size, radar.backgroundTexture, 0, 0, 0, tocolor(10, 10, 10, 185 * radar.alpha), false)
		end
		-- Part: 3.1 - Players
		local setting_forcePlayerBlips = getClientVariable("force_player_blips") == "On" and true or false
		if isElement(parent) then
			for i, player in pairs(getElementChildren(parent, "player")) do
				if player ~= cameraTarget and (setting_forcePlayerBlips or getElementDimension(player) == dimension) and (gamemode ~= "race" or (gamemode == "race" and getElementData(player, "state") == "alive")) then
					local vehicle = getPedOccupiedVehicle(player) or player
					local _, _, rotation = getElementRotation(vehicle)
					local _posX, _posY, _posZ = getElementPosition(vehicle)
					local distance = math_min(getDistanceBetweenPoints2D(posX, posY, _posX, _posY), radar.range - radar.blipSize.player - 10)
					local angle = northInv + findRotation(posX, posY, _posX, _posY)	
					local cBlipX, cBlipY = getDistanceRotation(radar.size * (distance/radar.range)/2, angle)
					local blipX = centerLeft + cBlipX - (radar.blipSize.player)/2
					local blipY = centerTop + cBlipY - (radar.blipSize.player)/2
					local r, g, b, a = 255, 255, 255, 255 * radar.alpha
					local team = getPlayerTeam(player)
					if team then
						r, g, b = getTeamColor(team)
					end
					local diff = _posZ - posZ
					local blip = "img/blips/blip-player.png"
					if diff > 5 then
						blip = "img/blips/blip-up.png"
					elseif diff < -5 then
						blip = "img/blips/blip-down.png"
					end
					dxDrawImageSection(blipX, blipY, radar.blipSize.player, radar.blipSize.player, 1, 1, 50, 50, blip, 0, 0, 0, tocolor(r, g, b, a), false)
				end
			end
		end
		-- Part: 3.2 - Blips
		local blipSize = radar.blipSize.checkpoint
		local checkpointsParent = getElementByID("checkpointContainer_client")
		if isElement(checkpointsParent) then
			for i, element in pairs(getElementChildren(checkpointsParent, "marker")) do
				local alpha = getMarkerIcon(element) == "none" and 105 or 255
				local _posX, _posY, _posZ = getElementPosition(element)
				local distance = math_min(getDistanceBetweenPoints2D(posX, posY, _posX, _posY), radar.range - blipSize - 10)
				local angle = northInv + findRotation(posX, posY, _posX, _posY)
				local cBlipX, cBlipY = getDistanceRotation(radar.size * (distance/radar.range)/2, angle)
				local blipX = centerLeft + cBlipX - blipSize/2
				local blipY = centerTop + cBlipY - blipSize/2
				local r, g, b = getMarkerColor(element)
				dxDrawImageSection(blipX, blipY, blipSize, blipSize, 1, 1, 46, 46, "img/blips/blip-checkpoint.png", 0, 0, 0, tocolor(r or 255, g or 255, b or 255, alpha * radar.alpha), false)
			end
		end
		local blipSize = radar.blipSize.player
		local setting_showProjectiles = getClientVariable("radar_projectiles") == "On" and true or false
		if setting_showProjectiles then
			for i, element in pairs(getElementsByType("projectile")) do
				while true do
					local _posX, _posY, _posZ = getElementPosition(element)
					local distance = getDistanceBetweenPoints2D(posX, posY, _posX, _posY)
					if distance > radar.range then
						break
					end
					local angle = northInv + findRotation(posX, posY, _posX, _posY)
					local cBlipX, cBlipY = getDistanceRotation(radar.size * (distance/radar.range)/2, angle)
					local blipX = centerLeft + cBlipX - blipSize/2
					local blipY = centerTop + cBlipY - blipSize/2
					dxDrawRectangle(blipX, blipY, blipSize, blipSize, tocolor(255, 25, 0, 255 * radar.alpha), false)
					break
				end
			end
		end
		-- Part: 3.3 - North blip
		dxDrawImage(radarX, radarY, radar.size, radar.size, "img/blips/blip-north.png", north, 0, 0, tocolor(255, 255, 255, 255 * radar.alpha), false)
		-- Part: 3.4 - Local blip
		local blipX, blipY = centerLeft - radar.blipSize.client/2, centerTop - radar.blipSize.client/2
		dxDrawImageSection(blipX, blipY, radar.blipSize.client, radar.blipSize.client, 1, 1, 50, 50, "img/blips/blip-local.png", north - pedRotZ, 0, 0, tocolor(255, 255, 255, 255 * radar.alpha), false)
		--
		local health, nitroLevel, nitroRecharging = 0, 0, false
		local v_nos = getResourceFromName("v_nos")
		if cameraTargetVehicle then
			health = (getElementHealth(cameraTargetVehicle) - 250)/750
			nitroLevel = v_nos and getResourceState(v_nos) == "running" and getNosAmount() or getVehicleNitroLevel(cameraTargetVehicle) or 0
			nitroRecharging = isVehicleNitroRecharging (cameraTargetVehicle)
			health = math_max(0, health)
		elseif cameraTarget then
			health = getElementHealth(cameraTarget)/100
			health = math_max(0, health)
		end
		dxSetShaderValue(radar.circleShader, "dg1", health)
		dxSetShaderValue(radar.circleShader, "rgba1", healthColor[1], healthColor[2], healthColor[3], radar.alpha)
		dxSetShaderValue(radar.circleShader, "dg2", nitroLevel)
		dxSetShaderValue(radar.circleShader, "rgba2", nitroColor[1], nitroColor[2], nitroColor[3], radar.alpha)
		dxDrawImage(radarX, radarY, radar.size, radar.size, radar.circleShader, 180, 0, 0, tocolor(255, 255, 255, 255), false)
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