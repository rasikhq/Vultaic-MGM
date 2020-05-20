-- 'Colors' tab
local settings = {id = 1, title = "Colors"}
local content = nil
local items = {
	["button_apply"] = {type = "button", text = "Save", x = selector.width * 0.35, y = selector.height - 40, width = selector.width * 0.3, height = 35, backgroundColor = tocolor(25, 155, 255, 55), hoverColor = {25, 155, 255, 255}},
	["label_1"] = {type = "label", text = "Primary", x = 10, y = 5, width = (selector.width - 20) * 0.5, height = 40},
	["input_1"] = {type = "input", text = "#FFFFFFFF", x = selector.width * 0.5, y = 10, width = (selector.width - 20) * 0.5, height = 30, maxLength = 9},
	["colorpicker_1"] = {type = "colorpicker", x = 10, y = 55, width = selector.width - 20, height = (selector.height - 45)/3 - 65},	
	["label_2"] = {type = "label", text = "Secondary", x = 10, y = (selector.height - 45)/3 + 5, width = (selector.width - 20) * 0.5, height = 40},
	["input_2"] = {type = "input", text = "#FFFFFFFF", x = selector.width * 0.5, y = (selector.height - 45)/3 + 10, width = (selector.width - 20) * 0.5, height = 30, maxLength = 9},
	["colorpicker_2"] = {type = "colorpicker", x = 10, y = (selector.height - 45)/3 + 55, width = selector.width - 20, height = (selector.height - 45)/3 - 65},
	["label_3"] = {type = "label", text = "Headlights", x = 10, y = ((selector.height - 45)/3) * 2 + 5, width = (selector.width - 20) * 0.5, height = 40},
	["input_3"] = {type = "input", text = "#FFFFFFFF", x = selector.width * 0.5, y = ((selector.height - 45)/3) * 2 + 10, width = (selector.width - 20) * 0.5, height = 30, maxLength = 9},
	["colorpicker_3"] = {type = "colorpicker", x = 10, y = ((selector.height - 45)/3) * 2 + 55, width = selector.width - 20, height = (selector.height - 45)/3 - 65}
}

-- Initialization
local function initTab()
	-- Tab registration
	content = selector.initTab(settings.id, settings, items)
	-- Functions
	-- 'apply'
	items["button_apply"].onClick = function()
		if not content.madeChanges then
			return triggerEvent("notification:create", localPlayer, "Tuning", "You did not make any changes yet")
		end
		if content.lastApplyTick and getTickCount() - content.lastApplyTick < 5000 then
			return triggerEvent("notification:create", localPlayer, "Tuning", "Please wait some while before saving your colors again")
		end
		local r1, g1, b1 = dxlib.getColorpickerRGB(items["colorpicker_1"], true)
		local r2, g2, b2 = dxlib.getColorpickerRGB(items["colorpicker_2"], true)
		local hr, hg, hb = dxlib.getColorpickerRGB(items["colorpicker_3"], true)
		triggerServerEvent("updateColors", localPlayer, {color_1 = rgbToHex(r1, g1, b1), color_2 = rgbToHex(r2, g2, b2), color_headlights = rgbToHex(hr, hg, hb)})
		content.lastApplyTick = getTickCount()
		resetElementData("colors")
		content.madeChanges = nil
	end
	-- 'input'
	items["input_1"].onTextChange = function(text)
		local r, g, b, a = hexToRGB(text)
		r, g, b, a = (r or 255)/255, (g or 255)/255, (b or 255)/255, (a or 255)/255
		items["colorpicker_1"].r, items["colorpicker_1"].g, items["colorpicker_1"].b, items["colorpicker_1"].a = r, g, b, a
		updateVehicleColors()
	end
	items["input_2"].onTextChange = function(text)
		local r, g, b, a = hexToRGB(text)
		r, g, b, a = (r or 255)/255, (g or 255)/255, (b or 255)/255, (a or 255)/255
		items["colorpicker_2"].r, items["colorpicker_2"].g, items["colorpicker_2"].b, items["colorpicker_2"].a = r, g, b, a
		updateVehicleColors()
	end
	items["input_3"].onTextChange = function(text)
		local r, g, b, a = hexToRGB(text)
		r, g, b, a = (r or 255)/255, (g or 255)/255, (b or 255)/255, (a or 255)/255
		items["colorpicker_3"].r, items["colorpicker_3"].g, items["colorpicker_3"].b, items["colorpicker_3"].a = r, g, b, a
		updateVehicleColors()
	end
	items["colorpicker_1"].onUpdate = function(r, g, b, a)
		local hex = rgbToHex(r, g, b, 255 * a)
		items["input_1"].text = hex
		updateVehicleColors()
	end
	items["colorpicker_2"].onUpdate = function(r, g, b, a)
		local hex = rgbToHex(r, g, b, 255 * a)
		items["input_2"].text = hex
		updateVehicleColors()
	end
	items["colorpicker_3"].onUpdate = function(r, g, b, a)
		local hex = rgbToHex(r, g, b, 255 * a)
		items["input_3"].text = hex
		updateVehicleColors()
	end
end
addEventHandler("onClientResourceStart", resourceRoot, initTab)

-- Update vehicle colors
function updateVehicleColors()
	local r1, g1, b1 = dxlib.getColorpickerRGB(items["colorpicker_1"], true)
	local r2, g2, b2 = dxlib.getColorpickerRGB(items["colorpicker_2"], true)
	setVehicleColor(garage.vehicle, r1, g1, b1, r2, g2, b2)
	setVehicleHeadLightColor(garage.vehicle, dxlib.getColorpickerRGB(items["colorpicker_3"], true))
	setVehicleOverrideLights(garage.vehicle, 2)
	content.madeChanges = true
end

-- Cache vehicle colors
function cacheVehicleColors()
	local colors = getElementData(localPlayer, "colors")
	colors = type(colors) == "table" and colors or {}
	local r1, g1, b1 = hexToRGB(colors.color_1 or "#FFFFFF")
	local r2, g2, b2 = hexToRGB(colors.color_2 or "#FFFFFF")
	local hr, hb, hg = hexToRGB(colors.color_headlights or "#FFFFFF")
	items["colorpicker_1"].r, items["colorpicker_1"].g, items["colorpicker_1"].b = r1/255, g1/255, b1/255
	items["colorpicker_2"].r, items["colorpicker_2"].g, items["colorpicker_2"].b = r2/255, g2/255, b2/255
	items["colorpicker_3"].r, items["colorpicker_3"].g, items["colorpicker_3"].b = hr/255, hb/255, hg/255
	updateVehicleColors()
	content.madeChanges = nil
end
addEvent("garage:onInit", true)
addEventHandler("garage:onInit", localPlayer, cacheVehicleColors)