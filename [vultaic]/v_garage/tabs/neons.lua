-- 'neon' tab
local settings = {id = 8, title = "Neons"}
local content = nil
local neon = {}
local items = {
	["button_apply"] = {type = "button", text = "Save", x = selector.width * 0.35, y = selector.height - 40, width = selector.width * 0.3, height = 35, backgroundColor = tocolor(25, 155, 255, 55), hoverColor = {25, 155, 255, 255}},
	["label_info"] = {type = "label", text = "Color", x = 10, y = 5, width = (selector.width - 20) * 0.5, height = 40},
	["input_hex"] = {type = "input", text = "#FFFFFFFF", x = selector.width * 0.5, y = 10, width = (selector.width - 20) * 0.5, height = 30, maxLength = 9},
	["colorpicker"] = {type = "colorpicker", x = 10, y = 55, width = selector.width - 20, height = 85},
	["selector_type"] = {type = "selector", x = 10, y = 150, width = selector.width - 20, height = 40},
	["selector_rate"] = {type = "selector", x = 10, y = 190, width = selector.width - 20, height = 40},
	["gridlist_textures"] = {type = "gridlist", x = 0, y = 230, width = selector.width, height = selector.height - 275, columns = 2, customBlockHeight = (selector.height - 230) * 0.5},
}

-- Calculations
local function precacheStuff()
	content.imageSize = math.min(items["gridlist_textures"].blockWidth, items["gridlist_textures"].blockHeight) * 0.8
	content.imageOffsetX, content.imageOffsetY = (items["gridlist_textures"].blockWidth - content.imageSize)/2, (items["gridlist_textures"].blockHeight - content.imageSize)/2
end

local neonTypes = {"Glow", "Blink", "Wave", "Image", "Image glow", "Image blink"}

-- Initialization
local function initTab()
	-- Tab registration
	content = selector.initTab(settings.id, settings, items)
	precacheStuff()
	items["selector_type"].values = {}
	table.insert(items["selector_type"].values, "None")
	for i = 1, 6 do
		table.insert(items["selector_type"].values, tostring(neonTypes[i]))
	end
	items["selector_rate"].values = {}
	local rate = 0.25
	for i = 1, 20 do
		table.insert(items["selector_rate"].values, tostring("Rate x"..rate))
		rate = rate + 0.25
	end
	-- Customization
	items["gridlist_textures"].customBlockRendering = function(x, y, row, item, i)
		local path = ":v_neons/"..row.text
		if fileExists(path) then
			dxDrawImage(x + content.imageOffsetX, y + content.imageOffsetY, content.imageSize, content.imageSize, path, 0, 0, 0, tocolor(255, 255, 255, 255))
		end
	end
	-- Functions
	-- 'apply'
	items["button_apply"].onClick = function()
		if not content.madeChanges then
			return triggerEvent("notification:create", localPlayer, "Tuning", "You did not make any changes yet")
		end
		if content.lastApplyTick and getTickCount() - content.lastApplyTick < 5000 then
			return triggerEvent("notification:create", localPlayer, "Tuning", "Please wait some while before saving your neon again")
		end
		triggerServerEvent("updateNeons", localPlayer, neon)
		content.lastApplyTick = getTickCount()
		resetElementData("neon")
		content.madeChanges = nil
	end
	-- 'input'
	items["input_hex"].onTextChange = function(text)
		local r, g, b, a = hexToRGB(text)
		local hex = rgbToHex(r, g, b, a)
		neon.neon_color = hex
		setElementData(localPlayer, "neon", neon, false)
		r, g, b, a = (r or 255)/255, (g or 255)/255, (b or 255)/255, (a or 255)/255
		items["colorpicker"].r, items["colorpicker"].g, items["colorpicker"].b, items["colorpicker"].a = r, g, b, a
		content.madeChanges = true
	end
	items["colorpicker"].onUpdate = function(r, g, b, a)
		local hex = rgbToHex(r * a, g * a, b * a)
		items["input_hex"].text = hex
		neon.neon_color = hex
		setElementData(localPlayer, "neon", neon)
		content.madeChanges = true
	end
	items["selector_type"].onSelect = function(i)
		local _type = i == 1 and 0 or tonumber(i - 1)
		neon.neon_type = _type
		setElementData(localPlayer, "neon", neon)
		content.madeChanges = true
	end
	items["selector_rate"].onSelect = function(i)
		local rate = i * 0.25
		neon.neon_rate = rate
		setElementData(localPlayer, "neon", neon)
		content.madeChanges = true
	end
	-- 'select'
	items["gridlist_textures"].onSelect = function(i)
		local texture = tostring(items["gridlist_textures"].rows[i].text)
		neon.neon_texture = texture
		setElementData(localPlayer, "neon", neon)
		content.madeChanges = true
	end
end
addEventHandler("onClientResourceStart", resourceRoot, initTab)

function getNeonTextures(data)
	local data = type(data) == "table" and data or (getResourceState(getResourceFromName("v_neons")) == "running" and exports.v_neons:getNeonTextures() or {})
	if not data then
		return
	end
	dxlib.setGridlistContent(items["gridlist_textures"], data)
end
addEvent("neon:onTexturesUpdate", true)
addEventHandler("neon:onTexturesUpdate", localPlayer, function() getNeonTextures(textures) end)

-- Cache neon
function cacheNeons()
	getNeonTextures()
	neon = getElementData(localPlayer, "neon") or {}
	local r, g, b, a = hexToRGB(neon.neon_color or "#FFFFFFFF")
	items["colorpicker"].r, items["colorpicker"].g, items["colorpicker"].b, items["colorpicker"].a = tonumber(r or 255)/255, tonumber(g or 255)/255, tonumber(b or 255)/255, tonumber(a or 255)/255
	items["input_hex"].text = neon.neon_color
	items["selector_type"].currentID = tonumber(neon.neon_type or 0) == 0 and 1 or tonumber(neon.neon_type + 1)
	items["selector_rate"].currentID = math.floor(tonumber(neon.neon_rate or 0.25) * 4)
end
addEvent("garage:onInit", true)
addEventHandler("garage:onInit", localPlayer, cacheNeons)