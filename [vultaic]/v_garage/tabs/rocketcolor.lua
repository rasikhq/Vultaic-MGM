-- 'Rocket Color' tab
local settings = {id = 9, title = "Rocket Color"}
local content = nil
local items = {
	["button_apply"] = {type = "button", text = "Save", x = selector.width * 0.35, y = selector.height - 40, width = selector.width * 0.3, height = 35, backgroundColor = tocolor(25, 155, 255, 55), hoverColor = {25, 155, 255, 255}},
	["label_rocketcolor"] = {type = "label", text = "Rocket color", x = 10, y = 5, width = (selector.width - 20) * 0.5, height = 40},
	["input_rocketcolor"] = {type = "input", text = "#FFFFFFFF", x = selector.width * 0.5, y = 10, width = (selector.width - 20) * 0.5, height = 30, maxLength = 9},
	["colorpicker_rocketcolor"] = {type = "colorpicker", x = 10, y = 55, width = selector.width - 20, height = (selector.height - 45)/3 - 65},
	["label_info"] = {type = "label", text = "Set alpha to 0 to disable", x = 10, y = 150, width = selector.width - 20, height = 40, verticalAlign = "center", horizontalAlign = "center"},
	["image_rocketcolor_preview"] = {type = "image", path = "img/circle.png", x = 10, y = 290, width = selector.width - 20, height = selector.height - 435}
}

-- Initialization
local function initTab()
	-- Tab registration
	content = selector.initTab(settings.id, settings, items)
	-- Functions
	items["button_apply"].onClick = function()
		if not content.madeChanges then
			return triggerEvent("notification:create", localPlayer, "Tuning", "You did not make any changes yet")
		end
		if content.lastApplyTick and getTickCount() - content.lastApplyTick < 5000 then
			return triggerEvent("notification:create", localPlayer, "Tuning", "Please wait some while before saving your rocket color again")
		end
		local r, g, b, a = dxlib.getColorpickerRGB(items["colorpicker_rocketcolor"])
		triggerServerEvent("updateRocketColor", localPlayer, {color = rgbToHex(r, g, b, 255 * a)})
		content.lastApplyTick = getTickCount()
		resetElementData("rocketcolor")
		content.madeChanges = nil
	end
	items["input_rocketcolor"].onTextChange = function(text)
		local r, g, b, a = hexToRGB(text)
		r, g, b, a = (r or 255)/255, (g or 255)/255, (b or 255)/255, (a or 255)/255
		items["colorpicker_rocketcolor"].r, items["colorpicker_rocketcolor"].g, items["colorpicker_rocketcolor"].b, items["colorpicker_rocketcolor"].a = r, g, b, a
		updatePreviewColor()
		content.madeChanges = true
	end
	items["colorpicker_rocketcolor"].onUpdate = function(r, g, b, a)
		local hex = rgbToHex(r, g, b, 255 * a)
		items["input_rocketcolor"].text = hex
		updatePreviewColor()
		content.madeChanges = true
	end
end
addEventHandler("onClientResourceStart", resourceRoot, initTab)

function updatePreviewColor()
	local r, g, b, a = dxlib.getColorpickerRGB(items["colorpicker_rocketcolor"])
	items["image_rocketcolor_preview"].color = tocolor(r, g, b, 255 * a)
end

-- Cache rocket color
function cacheRocketColor()
	local rocketColor = getElementData(localPlayer, "rocketcolor") or {}
	local r, g, b, a = hexToRGB(rocketColor.color or "#FFFFFFFF")
	items["colorpicker_rocketcolor"].r, items["colorpicker_rocketcolor"].g, items["colorpicker_rocketcolor"].b, items["colorpicker_rocketcolor"].a = (r or 255)/255, (g or 255)/255, (b or 255)/255, (a or 255)/255
	updatePreviewColor()
	content.madeChanges = nil
end
addEvent("garage:onInit", true)
addEventHandler("garage:onInit", localPlayer, cacheRocketColor)