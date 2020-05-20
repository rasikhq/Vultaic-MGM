-- 'overlay' tab
local settings = {id = 7, title = "overlay"}
local content = nil
local overlay = {}
local items = {
	["button_apply"] = {type = "button", text = "Save", x = selector.width * 0.35, y = selector.height - 40, width = selector.width * 0.3, height = 35, backgroundColor = tocolor(25, 155, 255, 55), hoverColor = {25, 155, 255, 255}},
	["label_info"] = {type = "label", text = "Color", x = 10, y = 5, width = (selector.width - 20) * 0.5, height = 40},
	["input_hex"] = {type = "input", text = "#FFFFFFFF", x = selector.width * 0.5, y = 10, width = (selector.width - 20) * 0.5, height = 30, maxLength = 9},
	["colorpicker"] = {type = "colorpicker", x = 10, y = 55, width = selector.width - 20, height = 85},
	["label_type"] = {type = "label", text = "Type", x = 10, y = 150, width = (selector.width - 20) * 0.4, height = 40},
	["selector_type"] = {type = "selector", x = selector.width * 0.4, y = 150, width = (selector.width - 20) * 0.6, height = 40},
	
	["label_rate"] = {type = "label", text = "Speed", x = 10, y = 190, width = (selector.width - 20) * 0.4, height = 40},
	["selector_rate"] = {type = "scrollbar", x = selector.width * 0.4, y = 190, width = (selector.width - 20) * 0.6, height = 40},
	
	["label_nobeat"] = {type = "label", text = "Beats", x = 10, y = 230, width = (selector.width - 20) * 0.4, height = 40},
	["selector_nobeat"] = {type = "selector", values = {"On", "Off"}, x = selector.width * 0.4, y = 230, width = (selector.width - 20) * 0.6, height = 40}
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
			return triggerEvent("notification:create", localPlayer, "Tuning", "Please wait some while before saving your overlay again")
		end
		triggerServerEvent("updateOverlays", localPlayer, overlay)
		content.lastApplyTick = getTickCount()
		resetElementData("overlay")
		content.madeChanges = nil
	end
	-- 'updates'
	items["selector_type"].onSelect = function(id)
		local _type = tonumber(id - 1)
		overlay.overlay_type = _type
		setElementData(localPlayer, "overlay", overlay)
		content.madeChanges = true
	end
	items["selector_rate"].onUpdate = function(progress)
		overlay.overlay_rate = progress
		setElementData(localPlayer, "overlay", overlay)
		content.madeChanges = true
	end
	items["selector_nobeat"].onSelect = function(id)
		local nobeat = id == 1 and 0 or 1
		overlay.overlay_nobeat = nobeat
		setElementData(localPlayer, "overlay", overlay)
		content.madeChanges = true
	end
	items["input_hex"].onTextChange = function(text)
		local r, g, b, a = hexToRGB(text)
		r, g, b, a = (r or 255)/255, (g or 255)/255, (b or 255)/255, (a or 255)/255
		items["colorpicker"].r, items["colorpicker"].g, items["colorpicker"].b, items["colorpicker"].a = r, g, b, a
		r, g, b = dxlib.getColorpickerRGB(items["colorpicker"], true)
		local hex = rgbToHex(r, g, b)
		overlay.overlay_color = hex
		setElementData(localPlayer, "overlay", overlay)
		content.madeChanges = true
	end
	items["colorpicker"].onUpdate = function(r, g, b, a)
		local hex = rgbToHex(r, g, b)
		items["input_hex"].text = hex
		overlay.overlay_color = hex
		overlay.overlay_opacity = a
		setElementData(localPlayer, "overlay", overlay)
		content.madeChanges = true
	end
end
addEventHandler("onClientResourceStart", resourceRoot, initTab)

-- Cache overlay
function cacheoverlay()
	items["selector_type"].values = {}
	local amount = getElementData(localPlayer, "totalOverlays")
	if amount then
		for i = 0, amount do
			table.insert(items["selector_type"].values, tostring(i))
		end
	end
	overlay = getElementData(localPlayer, "overlay") or {}
	local r, g, b = hexToRGB(overlay.overlay_color)
	items["input_hex"].text = overlay.overlay_color or "#FFFFFFFF"
	items["colorpicker"].r, items["colorpicker"].g, items["colorpicker"].b, items["colorpicker"].b = r/255, g/255, b/255, overlay.overlay_opacity
	items["selector_type"].currentID = tonumber(overlay.overlay_type or 0) + 1
	items["selector_rate"].progress = tonumber(overlay.overlay_rate or 0.5)
	items["selector_nobeat"].currentID = overlay.overlay_nobeat == 1 and 2 or 1
	content.madeChanges = nil
end
addEvent("garage:onInit", true)
addEventHandler("garage:onInit", localPlayer, cacheoverlay)