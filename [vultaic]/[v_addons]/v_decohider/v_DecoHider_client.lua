--[[
	Vultaic::Addon::DecoHider
--]]
local pArena = getElementParent(localPlayer) or localPlayer
local _v_settings = getResourceFromName("v_settings")
local Decoration = {Key = "F4", hidden = false, objects = {}, hiddenobjects = {}, iconTexture = dxCreateTexture("img/icon.png")}
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
	Decoration.hidden = settings.getSetting(exports.v_settings:getClientVariable("enable_decohider"))
	if not getElementData(pArena, "ghostmodeEnabled") then
		Decoration.toggle(false, false)
	end
	bindKey(Decoration.Key, "down", Decoration.toggleKey)
	triggerServerEvent("onClientRequestObjectList", resourceRoot)
end)
addEvent("settings:onSettingChange", true)
addEventHandler("settings:onSettingChange", localPlayer, function(setting, value, class)
	local setting_update = false
	if setting == "enable_decohider" then
		value = settings.getSetting(value)
		setting_update = true
	end
	if setting_update and getElementData(pArena, "ghostmodeEnabled") then
		Decoration.hidden = value
		Decoration.toggle(Decoration.hidden, true)
	end
end)
addEvent("onClientJoinArena", true)
addEventHandler("onClientJoinArena", root,
function()
	pArena = getElementParent(localPlayer)
	if getElementData(pArena, "ghostmodeEnabled") then
		Decoration.toggle(Decoration.hidden, false)
	end
end)
addEvent("onClientLeaveArena", true)
addEventHandler("onClientLeaveArena", root,
function()
	pArena = getElementParent(localPlayer)
	Decoration.toggle(false, false)
end)
function Decoration.toggleKey(key, keyState)
	if not getElementData(pArena, "ghostmodeEnabled") or isCursorShowing() then
		return
	end
	Decoration.hidden = not Decoration.hidden
	exports.v_settings:setClientVariable("enable_decohider", settings.getStringSetting(Decoration.hidden))
end
function Decoration.toggle(tog, notify, clear)
	if tog then
		for _, object in pairs(getElementsByType("object")) do
			local model = getElementModel(object)
			if Decoration.objects[model] then
				--[[local cols = getElementCollisionsEnabled(object)
				if cols then
					setElementAlpha(object, 0)
				else
					setElementDimension(object, getElementDimension(localPlayer)*2)
				end--]]
				setElementDimension(object, getElementDimension(localPlayer)*2)
				setElementData(object, "decoration", true, false)
				table.insert(Decoration.hiddenobjects, object)
			end
		end
		if notify then
			triggerEvent("notification:create", localPlayer, "Decorations", "Decorations are now hidden. This might improve your FPS.", Decoration.iconTexture, "green", true)
		end
	else
		for _, object in pairs(Decoration.hiddenobjects) do
			if not isElement(object) then
				break
			end
			local model = getElementModel(object)
			if Decoration.objects[model] then
				--[[local cols = getElementCollisionsEnabled(object)
				if cols then
					setElementAlpha(object, 255)
				else
					setElementDimension(object, getElementDimension(localPlayer))
				end]]
				setElementDimension(object, getElementDimension(localPlayer))
				setElementData(object, "decoration", false, false)
			end
		end
		if notify then
			triggerEvent("notification:create", localPlayer, "Decorations", "Decorations are now visible", Decoration.iconTexture, "yellow", true)
		end
		Decoration.hiddenobjects = {}
	end
end
addEvent("onClientReceiveObjectsList", true)
addEventHandler("onClientReceiveObjectsList", resourceRoot, function(list)
	Decoration.objects = list
	if Decoration.hidden then
		Decoration.toggle(false)
		Decoration.toggle(true)
	end	
end)
addEvent("mapmanager:onMapLoad", true)
function onMapLoad()
	if Decoration.hidden then
		Decoration.toggle(false)
		Decoration.toggle(true)
	end
end
addEventHandler("mapmanager:onMapLoad", localPlayer, onMapLoad)