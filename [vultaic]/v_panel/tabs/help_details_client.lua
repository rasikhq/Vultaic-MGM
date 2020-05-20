-- 'Settings' tab
local settings = {id = 6.1, title = "Help"}
local content = nil
local items = {
	["button_return"] = {type = "button", text = "Return", x = 5, y = 5, width = 100, height = 35},
	["label_title"] = {type = "label", text = "Title goes here", x = 0, y = 55, width = panel.width, height = 40, font = dxlib.getFont("RobotoCondensed-Regular", 16), horizontalAlign = "center", verticalAlign = "center"},
	["gridlist_rows"] = {type = "gridlist", x = 0, y = 130, width = panel.width, height = panel.height - 130, customBlockHeight = (panel.height - 130) * 0.15, readOnly = true}
}
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
local tableInsert = table.insert
local tableRemove = table.remove
local pairs = pairs
local interpolateBetween = interpolateBetween

-- Initialization
local function initTab()
	-- Tab registration
	content = panel.initTab(settings.id, settings, items)
	-- Customization
	items["gridlist_rows"].customBlockRendering = function(x, y, row, item, i)
		dxDrawRectangle(x, y, 2, item.blockHeight, tocolor(25, 132, 109, 255))
		dxDrawText(row.text, x + 20, y, x + item.blockWidth, y + item.blockHeight, tocolor(255, 255, 255, 255), item.fontScale, item.font, "left", "center", true)
	end
	-- Functions
	-- 'return'
	items["button_return"].onClick = function()
		panel.switch(math.floor(settings.id))
	end
end
addEventHandler("onClientResourceStart", resourceRoot, initTab)

function viewHelp(i)
	if helpTable[i] then
		items["label_title"].text = helpTable[i].title
		dxlib.setGridlistContent(items["gridlist_rows"], helpTable[i].rows)
		panel.switch(settings.id)
	end
end