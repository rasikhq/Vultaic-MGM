-- 'Tints' tab
local settings = {id = 2, title = "Tints"}
local content = nil
local tints = {}
local items = {
	["button_apply"] = {type = "button", text = "Save", x = selector.width * 0.35, y = selector.height - 40, width = selector.width * 0.3, height = 35, backgroundColor = tocolor(25, 155, 255, 55), hoverColor = {25, 155, 255, 255}},
	["label_info"] = {type = "label", text = "Color", x = 10, y = 5, width = (selector.width - 20) * 0.5, height = 40},
	["input_hex"] = {type = "input", text = "#FFFFFFFF", x = selector.width * 0.5, y = 10, width = (selector.width - 20) * 0.5, height = 30, maxLength = 9},
	["colorpicker"] = {type = "colorpicker", x = 10, y = 55, width = selector.width - 20, height = 85},
	["selector_visible"] = {type = "selector", values = {"Show side tints", "Hide side tints"}, x = 10, y = 150, width = selector.width - 20, height = 40},
	["selector_type"] = {type = "selector", values = {"Show side tints", "Hide side tints"}, x = 10, y = 190, width = selector.width - 20, height = 40}
}
-- Initialization
local function initTab()
	-- Tab registration
	content = selector.initTab(settings.id, settings, items)
	items["selector_type"].values = {"Classic", "Wireframe", "Classic wireframe"}
	-- Functions
	-- 'apply'
	items["button_apply"].onClick = function()
		if not content.madeChanges then
			return triggerEvent("notification:create", localPlayer, "Tuning", "You did not make any changes yet")
		end
		if content.lastApplyTick and getTickCount() - content.lastApplyTick < 5000 then
			return triggerEvent("notification:create", localPlayer, "Tuning", "Please wait some while before saving your tints again")
		end
		triggerServerEvent("updateTints", localPlayer, tints)
		content.lastApplyTick = getTickCount()
		resetElementData("tints")
		content.madeChanges = nil
	end
	-- 'input'
	items["input_hex"].onTextChange = function(text)
		local r, g, b, a = hexToRGB(text)
		tints.color_tint = rgbToHex(r, g, b)
		tints.tint_opacity = a
		setElementData(localPlayer, "tints", tints)
		r, g, b, a = (r or 255)/255, (g or 255)/255, (b or 255)/255, (a or 255)/255
		items["colorpicker"].r, items["colorpicker"].g, items["colorpicker"].b, items["colorpicker"].a = r, g, b, a
		content.madeChanges = true
	end
	items["colorpicker"].onUpdate = function(r, g, b, a)
		local hex = rgbToHex(r, g, b, 255 * a)
		items["input_hex"].text = hex
		tints.color_tint = rgbToHex(r, g, b)
		tints.tint_opacity = a
		setElementData(localPlayer, "tints", tints)
		content.madeChanges = true
	end
	items["selector_visible"].onSelect = function(id)
		tints.tint_visible = items["selector_visible"].currentID == 1 and 1 or 0
		setElementData(localPlayer, "tints", tints)
		content.madeChanges = true
	end
	items["selector_type"].onSelect = function(id)
		tints.tint_type = id
		setElementData(localPlayer, "tints", tints)
		content.madeChanges = true
	end
end
addEventHandler("onClientResourceStart", resourceRoot, initTab)

-- Cache tints
function cacheVehicleTints()
	tints = getElementData(localPlayer, "tints")
	tints = type(tints) == "table" and tints or {}
	local color = tints.color_tint or "#FFFFFF"
	local r, g, b = hexToRGB(color)
	local opacity = tonumber(tints.tint_opacity or 0.5)
	local visible = tonumber(tints.tint_visible or 1)
	items["colorpicker"].r, items["colorpicker"].g, items["colorpicker"].b, items["colorpicker"].a = r/255, g/255, b/255, opacity
	items["input_hex"].text = color
	items["selector_visible"].currentID = visible == 1 and 1 or 2
	items["selector_type"].currentID = tonumber(tints.tint_type or 1)
	content.madeChanges = nil
end
addEvent("garage:onInit", true)
addEventHandler("garage:onInit", localPlayer, cacheVehicleTints)