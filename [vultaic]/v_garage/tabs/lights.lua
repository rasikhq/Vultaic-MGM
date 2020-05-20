-- 'Lights' tab
local settings = {id = 6, title = "Lights"}
local content = nil
local lights, lightTextures = {}, {}
local items = {
	["button_apply"] = {type = "button", text = "Save", x = selector.width * 0.35, y = selector.height - 40, width = selector.width * 0.3, height = 35, backgroundColor = tocolor(25, 155, 255, 55), hoverColor = {25, 155, 255, 255}},
	["selector_type"] = {type = "selector", x = 10, y = 5, width = selector.width - 20, height = 40},
	["gridlist_catalog"] = {type = "gridlist", x = 0, y = 50, width = selector.width, height = selector.height - 255},
	["label"] = {type = "label", text = "Color", x = 10, y = selector.height - 200, width = (selector.width - 20) * 0.5, height = 40},
	["input"] = {type = "input", text = "#FFFFFFFF", x = selector.width * 0.5, y = selector.height - 195, width = (selector.width - 20) * 0.5, height = 30, maxLength = 9},
	["colorpicker"] = {type = "colorpicker", x = 10, y = selector.height - 160, width = selector.width - 20, height = 65}
}

-- Calculations
local function precacheStuff()
	content.imageSize = math.min(items["gridlist_catalog"].blockWidth, items["gridlist_catalog"].blockHeight) * 0.8
	content.imageOffsetX, content.imageOffsetY = (items["gridlist_catalog"].blockWidth - content.imageSize)/2, (items["gridlist_catalog"].blockHeight - content.imageSize)/2
end

-- Initialization
local function initTab()
	-- Tab registration
	content = selector.initTab(settings.id, settings, items)
	precacheStuff()
	-- Functions
	-- 'apply'
	items["button_apply"].onClick = function()
		if not content.madeChanges then
			return triggerEvent("notification:create", localPlayer, "Tuning", "You did not make any changes yet")
		end
		if content.lastApplyTick and getTickCount() - content.lastApplyTick < 5000 then
			return triggerEvent("notification:create", localPlayer, "Tuning", "Please wait some while before saving your lights again")
		end
		triggerServerEvent("updateLights", localPlayer, lights)
		content.lastApplyTick = getTickCount()
		resetElementData("lights")
		lights = {}
		content.madeChanges = nil
	end
	-- 'catalog update'
	items["selector_type"].onSelect = function(i)
		updateCatalog()
		local dynamic = i == 2 and 1 or 0
		lights.lights_dynamic = dynamic
		setElementData(localPlayer, "lights", lights)
		content.madeChanges = true
	end
	-- 'select'
	items["gridlist_catalog"].onSelect = function(i)
		local dynamic = items["selector_type"].currentID == 2 and 1 or 0
		local _type = tostring(items["gridlist_catalog"].rows[i].text)
		lights.lights_dynamic = dynamic
		lights.lights_type = _type
		setElementData(localPlayer, "lights", lights)
		content.madeChanges = true
		return true
	end
	items["input"].onTextChange = function(text)
		local r, g, b, a = hexToRGB(text)
		r, g, b, a = (r or 1), (g or 1), (b or 1), (a or 1)
		local hex = rgbToHex(r * a, g * a, b * a)
		lights.lights_color = hex
		items["colorpicker"].r, items["colorpicker"].g, items["colorpicker"].b, items["colorpicker"].a = r/255, g/255, b/255, a
		setElementData(localPlayer, "lights", lights)
		content.madeChanges = true
	end
	items["colorpicker"].onUpdate = function(r, g, b, a)
		local hex = rgbToHex(r * a, g * a, b * a)
		items["input"].text = hex
		lights.lights_color = hex
		setElementData(localPlayer, "lights", lights)
		content.madeChanges = true
	end
	getLightTextures()
end
addEventHandler("onClientResourceStart", resourceRoot, initTab)

function cacheLights()
	lights = getElementData(localPlayer, "lights") or {}
	local hex = lights.lights_color or "#FFFFFFFF"
	local r, g, b, a = hexToRGB(hex)
	content.madeChanges = nil
	items["input"].text = hex
	items["colorpicker"].r, items["colorpicker"].g, items["colorpicker"].b, items["colorpicker"].a = tonumber(r or 255)/255, tonumber(g or 255)/255, tonumber(b or 255)/255, tonumber(a or 255)/255
end

function updateCatalog()
	if getElementData(localPlayer, "donator") then
		items["selector_type"].values = {"Normal", "Dynamic (exclusive)"}
	else
		items["selector_type"].values = {"Normal"}
		if items["selector_type"].currentID ~= 1 then
			items["selector_type"].currentID = 1
		end
	end
	local id = tonumber(items["selector_type"].currentID) or 1
	if id == 1 then
		dxlib.setItemVisible(content, items["colorpicker"], false)
		dxlib.setItemVisible(content, items["label"], false)
		dxlib.setItemVisible(content, items["input"], false)
		dxlib.setItemData(items["gridlist_catalog"], "height", selector.height - 100)
		dxlib.setGridlistContent(items["gridlist_catalog"], lightTextures)
	else
		dxlib.setItemVisible(content, items["colorpicker"], true)
		dxlib.setItemVisible(content, items["label"], true)
		dxlib.setItemVisible(content, items["input"], true)
		dxlib.setItemData(items["gridlist_catalog"], "height", selector.height - 255)
		dxlib.setGridlistContent(items["gridlist_catalog"], dynamicLightTextures)
	end
end
addEvent("garage:onInit", true)
addEventHandler("garage:onInit", localPlayer, function() cacheLights() updateCatalog() end)

-- Get textures
function getLightTextures(textures, dynamicTextures)
	lightTextures = type(textures) == "table" and textures or (getResourceState(getResourceFromName("v_lights")) == "running" and exports.v_lights:getLightTextures() or {})
	dynamicLightTextures = type(dynamicTextures) == "table" and dynamicTextures or exports.v_lights:getDynamicLightTextures()
	if not lightTextures then
		lightTextures = {}
	end
	if not dynamicLightTextures then
		dynamicLightTextures = {}
	end
	table.insert(lightTextures, 1, "None")
	table.insert(dynamicLightTextures, 1, "None")
	updateCatalog()
end
addEvent("lights:onUpdateLightTextures", true)
addEventHandler("lights:onUpdateLightTextures", localPlayer, function() getLightTextures(textures, dynamicTextures) end)