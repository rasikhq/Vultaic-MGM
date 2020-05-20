--[[
	Vultaic::Addon::HiddenObjectManager
--]]
local function tableFind(_table, value)
	for i, item in pairs(_table) do
		if item == value then
			return i
		end
	end
	return false
end
local _v_settings = getResourceFromName("v_settings")
local pArena = getElementParent(localPlayer)
local HOM = {Key = "F6", hidden = false, scaledObjects = {}, doubleSidedObjects = {}, alphaObjects = {}, interiorObjects = {}}
local settings = {}
function settings.getSetting(str_value)
	return str_value == "On" and true or false
end
function settings.getStringSetting(bool_value)
	return bool_value == true and "On" or "Off"
end
addEventHandler("onClientResourceStart", resourceRoot, function()
	if _v_settings and getResourceState(_v_settings) ~= "running" then
		startResource("v_settings")
	end
	HOM.hidden = settings.getSetting(exports.v_settings:getClientVariable("enable_hom"))
	if not getElementData(pArena, "ghostmodeEnabled") then
		HOM.toggle(false, false)
	end
	bindKey(HOM.Key, "down", HOM.toggleKey)
end)
addEvent("settings:onSettingChange", true)
addEventHandler("settings:onSettingChange", localPlayer, function(setting, value, class)
	local setting_update = false
	if setting == "enable_hom" then
		value = settings.getSetting(value)
		setting_update = true
	end
	if setting_update and getElementData(pArena, "ghostmodeEnabled") then
		HOM.hidden = value
		HOM.toggle(HOM.hidden, true)
	end
end)
addEvent("onClientJoinArena", true)
addEventHandler("onClientJoinArena", root,
function()
	pArena = getElementParent(localPlayer)
	if getElementData(pArena, "ghostmodeEnabled") then
		HOM.toggle(HOM.hidden, false)
	end
end)
addEvent("onClientLeaveArena", true)
addEventHandler("onClientLeaveArena", root,
function()
	pArena = getElementParent(localPlayer)
	HOM.toggle(false)
end)
function HOM.toggleKey(key, keyState)
	if not getElementData(pArena, "ghostmodeEnabled") or isCursorShowing() then
		return
	end
	HOM.hidden = not HOM.hidden
	exports.v_settings:setClientVariable("enable_hom", settings.getStringSetting(HOM.hidden))
end
function HOM.toggle(tog, notify)
	if tog then
		local pInterior = getElementInterior(localPlayer)
		for _, object in pairs(getElementsByType("object")) do
			if not getElementData(object, "decoration") then
				local model = getElementModel(object)
				local scale = getObjectScale(object)
				local alpha = getElementAlpha(object)
				local interior = getElementInterior(object)
				local doubleSided = isElementDoubleSided(object)
				if(scale == 0) then
					HOM.scaledObjects[object] = scale
					setObjectScale(object, 1)
				end
				if(model == 8171) then
					HOM.doubleSidedObjects[object] = doubleSided
					setElementDoubleSided(object, true)
				end
				if(alpha == 0) then
					HOM.alphaObjects[object] = model
					setElementAlpha(object, 255)
				end
				if(interior ~= pInterior) then
					HOM.interiorObjects[object] = interior
					setElementInterior(object, pInterior)
				end
			end
		end
		if notify then
			triggerEvent("notification:create", localPlayer, "Hidden Objects", "Invisible objects are now visible!", ":v_hom/img/icon.png", "green", true)
		end
	else
		for object, defaultValue in pairs(HOM.scaledObjects) do
			if(object and isElement(object)) then
				setObjectScale(object, defaultValue)
			end
		end
		for object, defaultValue in pairs(HOM.doubleSidedObjects) do
			if(object and isElement(object)) then
				setElementDoubleSided(object, defaultValue)
			end
		end
		for object, defaultValue in pairs(HOM.alphaObjects) do
			if(object and isElement(object)) then
				setElementAlpha(object, defaultValue)
			end
		end
		for object, defaultValue in pairs(HOM.interiorObjects) do
			if(object and isElement(object)) then
				setElementInterior(object, defaultValue)
			end
		end
		if notify then
			triggerEvent("notification:create", localPlayer, "Hidden Objects", "Invisible objects are no longer visible!", ":v_hom/img/icon.png", "yellow", true)
		end
		HOM.reset()
	end
end
function HOM.reset()
	HOM.scaledObjects = {}
	HOM.doubleSidedObjects = {}
	HOM.alphaObjects = {}
	HOM.interiorObjects = {}
end
addEvent("mapmanager:onMapLoad", true)
addEvent("scriptloader:onScriptsLoaded", true)
function onMapLoad()
	if HOM.hidden then
		HOM.toggle(false)
		HOM.toggle(true)
	end
end
addEventHandler("mapmanager:onMapLoad", localPlayer, onMapLoad)
function onScriptsLoad()
	if HOM.hidden then
		HOM.toggle(false)
		HOM.toggle(true)
	end
end
addEventHandler("scriptloader:onScriptsLoaded", localPlayer, onScriptsLoad)