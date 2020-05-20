-- 'Stickers Catalog' tab
local settings = {id = 5.1, title = "Stickers"}
local content = nil
local items = {
	["button_goback"] = {type = "button", text = "Cancel", x = selector.width * 0.2 - 2.5, y = selector.height - 40, width = selector.width * 0.3, height = 35, backgroundColor = tocolor(255, 25, 0, 55), hoverColor = {255, 25, 0, 255}},
	["button_select"] = {type = "button", text = "Select", x = selector.width * 0.5 + 2.5, y = selector.height - 40, width = selector.width * 0.3, height = 35, backgroundColor = tocolor(25, 155, 255, 55), hoverColor = {25, 155, 255, 255}},
	["selector_category"] = {type = "selector", x = 10, y = 0, width = selector.width - 20, height = 40},
	["gridlist_catalog"] = {type = "gridlist", x = 0, y = 40, width = selector.width, height = selector.height - 85, columns = 3, customBlockHeight = (selector.height - 80) * 0.2},
	["input_text"] = {type = "input", placeholder = "Enter text here", x = 10, y = 45, width = selector.width - 20, height = 40, horizontalAlign = "center", maxLength = 15}
}

-- Calculations
local function precacheStuff()
	content.stickerSize = math.min(items["gridlist_catalog"].blockWidth, items["gridlist_catalog"].blockHeight) * 0.8
	content.stickerOffsetX, content.stickerOffsetY = (items["gridlist_catalog"].blockWidth - content.stickerSize)/2, (items["gridlist_catalog"].blockHeight - content.stickerSize)/2
end

-- Initialization
local function initTab()
	-- Tab registration
	content = selector.initTab(settings.id, settings, items)
	precacheStuff()
	-- Customization
	items["gridlist_catalog"].customBlockRendering = function(x, y, row, item, i)
		local path = ":v_paint/img/"..row.text
		if fileExists(path) then
			dxDrawImage(x + content.stickerOffsetX, y + content.stickerOffsetY, content.stickerSize, content.stickerSize, path, 0, 0, 0, tocolor(255, 255, 255, 255))
		end
	end
	-- Functions
	-- 'go back'
	items["button_goback"].onClick = function()
		selector.switch(math.floor(settings.id))
	end
	-- 'select'
	items["button_select"].onClick = function()
		local row, id = dxlib.getGridlistSelectedRow(items["gridlist_catalog"])
		if row and items["selector_category"].values[selected] ~= "Text" then
			updateSelectedSlot(1, row.text, true)
			selector.switch(math.floor(settings.id))
		else
			local selected = tonumber(items["selector_category"].currentID or 1)
			if items["selector_category"].values[selected] == "Text" then
				updateSelectedSlot(1, "tx."..items["input_text"].text or "", true)
				selector.switch(math.floor(settings.id))
			end
		end
	end
	items["selector_category"].onSelect = function(i)
		updateStickersCatalog(i)
	end
end
addEventHandler("onClientResourceStart", resourceRoot, initTab)

function cacheStickerCategories()
	items["selector_category"].values = {}
	for category, data in pairs(stickerCategories) do
		table.insert(items["selector_category"].values, tostring(data.title))
	end
	table.insert(items["selector_category"].values, "Text")
	updateStickersCatalog(1)
end

function updateStickersCatalog(i)
	local selected = tonumber(i) or tonumber(items["selector_category"].currentID or 1)
	local category = stickerCategories[selected]
	if category then
		dxlib.setGridlistContent(items["gridlist_catalog"], category.stickers or {})
		dxlib.setItemVisible(content, items["gridlist_catalog"], true)
		dxlib.setItemVisible(content, items["input_text"], false)
	elseif items["selector_category"].values[selected] == "Text" then
		dxlib.setItemVisible(content, items["gridlist_catalog"], false)
		dxlib.setItemVisible(content, items["input_text"], true)
	end
end