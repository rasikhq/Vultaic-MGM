--[[
	Vultaic::Addon::CarHide
--]]
--
local pArena = getElementParent(localPlayer)
local _v_settings = getResourceFromName("v_settings")
--
local key_carhide = "F2"
local key_carfade = "F3"

local carhide = false
local carfade = false
--
local function setSetting(setting)
	return setting == true and "On" or "Off"
end
local function getSetting(setting)
	return setting == "On" and true or false
end
--
local function isEnabled()
	if not isElement(pArena) then
		return false
	end
	return getElementData(pArena, "ghostmodeEnabled")
end
local addon_ = isEnabled()
--
function onScriptLoad()
	if _v_settings and getResourceState(_v_settings) ~= "running" then
		startResource("v_settings")
	end
	bindKey(key_carhide, "down", toggleCarHide)
	bindKey(key_carfade, "down", toggleCarFade)
	--
	carhide = getSetting(exports.v_settings:getClientVariable("enable_carhide"))
	carfade = getSetting(exports.v_settings:getClientVariable("enable_carfade"))
	--
	addEventHandler("onClientRender", root, process_carhide)
end
addEventHandler("onClientResourceStart", resourceRoot, onScriptLoad)

addEvent("settings:onSettingChange", true)
addEventHandler("settings:onSettingChange", localPlayer, function(setting, value, class)
	local setting_update_carhide = false
	local setting_update_carfade = false
	if setting == "enable_carhide" then
		carhide = getSetting(value)
		setting_update_carhide = true
	elseif setting == "enable_carfade" then
		carfade = getSetting(value)
		setting_update_carfade = true
	end
	if setting_update_carhide then
		setClientCarhideEnabled(carhide, true)
	end
	if setting_update_carfade then
		setClientCarfadeMode(carfade, true)
	end
end)

addEvent("core:onClientJoinArena", true)
addEventHandler("core:onClientJoinArena", localPlayer,
function()
	pArena = getElementParent(localPlayer)
	addon_ = isEnabled()
end)

addEvent("core:onClientLeaveArena", true)
addEventHandler("core:onClientLeaveArena", localPlayer,
function()
	pArena = getElementParent(localPlayer)
	addon_ = false
end)

function toggleCarHide(key, state)
	if isCursorShowing() or not isEnabled() then
		return
	end
	local new_carhide = not carhide
	if not new_carhide and getGameSpeed() ~= 1 then
		return
	end
	exports.v_settings:setClientVariable("enable_carhide", setSetting(new_carhide))
end

function toggleCarFade(key, state)
	if isCursorShowing() or not isEnabled() then
		return
	end
	local new_carfade = not carfade
	exports.v_settings:setClientVariable("enable_carfade", setSetting(new_carfade))
end

function setClientCarhideEnabled(toggle, notify)
	if not isEnabled() then
		return
	end
	if not notify then
		return
	end
	if toggle then
		triggerEvent("notification:create", localPlayer, "Car Hide", "Hiding other vehicles!", nil, {30, 188, 97}, true)
	else
		triggerEvent("notification:create", localPlayer, "Car Hide", "Showing other vehicles!", nil, {231, 76, 60}, true)
	end
end

function setClientCarfadeMode(mode, notify)
	if not isEnabled() then
		return
	end
	if not notify then
		return
	end
	if mode then
		triggerEvent("notification:create", localPlayer, "Car Fade", "Nearby vehicles will be fading!", nil, {30, 188, 97}, true)
	else
		triggerEvent("notification:create", localPlayer, "Car Fade", "Nearby vehicles will no longer be fading!", nil, {30, 188, 97}, true)
	end
end
--
-- optimizations
local _getCameraTarget = getCameraTarget
local getElementData = getElementData
local getPedOccupiedVehicle = getPedOccupiedVehicle
local isElement = isElement
local getElementModel = getElementModel
local setElementDimension = setElementDimension
local getElementDimension = getElementDimension
local setElementAlpha = setElementAlpha
local getElementPosition = getElementPosition
local getDistanceBetweenPoints3D = getDistanceBetweenPoints3D
local getElementType = getElementType
local getVehicleOccupant = getVehicleOccupant
local math_max = math.max
local math_min = math.min
local function getCameraTarget()
	local target = _getCameraTarget()
	if isElement(target) and getElementType(target) == "vehicle" then
		target = getVehicleOccupant(target)
	end
	return target
end
--
function process_carhide()
	if not addon_ then
		return
	end
	--
	local localplayer_state = getElementData(localPlayer, "state")
	local localplayer_vehicle = getPedOccupiedVehicle(localPlayer)
	local localplayer_hunter = isElement(localplayer_vehicle) and getElementModel(localplayer_vehicle) == 425 or false
	local localplayer_target = getCameraTarget() or getElementData(localPlayer, "spectatedTarget")
	local localplayer_dimension = getElementDimension(localPlayer)
	--
	local carhide_dimension = localplayer_dimension+1
	--
	for _, arena_player in ipairs(getElementChildren(pArena, "player")) do
		if(arena_player ~= localPlayer) then
			--[[ Carhide ]]--
			local new_dimension = carhide and carhide_dimension or localplayer_dimension
			--
			local arena_player_state = getElementData(arena_player, "state")
			local arena_player_vehicle = getPedOccupiedVehicle(arena_player)
			local arena_player_hunter = isElement(arena_player_vehicle) and getElementModel(arena_player_vehicle) == 425 or false
			--
			if arena_player_hunter or localplayer_target == arena_player or localplayer_target == arena_player_vehicle or (localplayer_hunter and localplayer_state ~= "dead") then
				new_dimension = localplayer_dimension
			end
			if arena_player_state == "dead" or arena_player_state == "training" then
				new_dimension = carhide_dimension
			end
			--
			if isElement(arena_player_vehicle) then
				setElementDimension(arena_player_vehicle, new_dimension)
			end
			setElementDimension(arena_player, new_dimension)
			--[[ Carfade ]]--
			local new_alpha = carfade and 10 or 255
			if new_dimension ~= localplayer_dimension then
				new_alpha = 0
			end
			if carfade and new_alpha > 0 then
				local playerX, playerY, playerZ = getElementPosition(arena_player)
				local clientX, clientY, clientZ = getElementPosition(localplayer_target and localplayer_target or localPlayer)
				local distance = getDistanceBetweenPoints3D(clientX, clientY, clientZ, playerX, playerY, playerZ)
				new_alpha = math_max(math_min(distance, 255), 10)
			end
			if arena_player_hunter or localplayer_target == arena_player or localplayer_target == arena_player_vehicle or (localplayer_hunter and localplayer_state ~= "dead") then
				new_alpha = 255
			end
			--
			if isElement(arena_player_vehicle) then
				setElementAlpha(arena_player_vehicle, new_alpha)
			end
			setElementAlpha(arena_player, new_alpha)
		end
	end
end