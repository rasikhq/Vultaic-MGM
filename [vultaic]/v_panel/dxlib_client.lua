-- Mirage's dynamic dxlib
-- Updates the specific container with all it's items
screenWidth, screenHeight = guiGetScreenSize()
relativeScale, relativeFontScale = math.min(math.max(screenWidth/1600, 0.5), 1), math.min(math.max(screenWidth/1600, 0.85), 1)
dxlib = {containers = {}}
dxlib.fonts = {}
dxlib.fontScale = 1
dxlib.ids = {}
dxlib.interpolator = "Linear"
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

function dxlib.getFont(path, size)
	if not dxlib.fonts[path] then
		dxlib.fonts[path] = {}
	end
	if not dxlib.fonts[path][size] then
		dxlib.fonts[path][size] = dxCreateFont(":v_locale/fonts/"..path..".ttf", size * relativeFontScale)
	end
	return dxlib.fonts[path][size]
end

function dxlib.getNextID()
	local id = 1
	while dxlib.ids[id] ~= nil do
		id = id + 1
	end
	dxlib.ids[id] = true
	return id
end

function dxlib.activate()
	dxlib.active = true
	guiSetInputMode("allow_binds")
end

function dxlib.setActiveContainer(container)
	if not container or not dxlib.containers[container] then
		return
	end
	if dxlib.activeContainer then
		dxlib.unhoverContainer(dxlib.containers[dxlib.activeContainer], true)
	end
	dxlib.activeContainer = container
	local container = dxlib.containers[container]
	if container and not container.init then
		local items = {}
		for type in pairs(container.items) do
			for i, item in pairs(container.items[type]) do
				table.insert(items, item)
			end
		end
		table.sort(items, function(a, b) return a.y + (a.size and a.size or a.height) > b.y + (b.size and b.size or b.height) end)
		if #items > 0 and items[1].y + (items[1].size and items[1].size or items[1].height) > container.height then
			local height = items[1].size and items[1].size or items[1].height
			local maximumScroll = math_max(items[1].y + height - container.height, 0)
			container.maximumScroll = maximumScroll + tonumber(container.margin or 0)
		end
		container.init = true
	end
end

function dxlib.deactivate()
	dxlib.active = false
	dxlib.cancelBackTrigger()
	dxlib.unhoverContainer(dxlib.containers[dxlib.activeContainer], true)
	guiSetInputMode("allow_binds")
end

function dxlib.unhoverContainer(container, clicked)
	if type(container) == "table" and container.items then
		for _type in pairs(container.items) do
			for i, item in pairs(container.items[_type]) do
				if _type == "input" then
					if item.text == "" then
						item.tick = getTickCount()
					end
				elseif type(item.hovered) == "boolean" and item.hovered then
					item.tick = getTickCount()
				end
				item.hovered = nil
				item.hoveredRow = nil
				item.dragging = nil
				if clicked then
					item.selected = nil
				end
			end
		end
	end
end

function dxlib.createContainer(data)
	if type(data) ~= "table" then
		return print("Failed to create container")
	end
	local container = {}
	for i, v in pairs(data) do
		container[i] = v
	end
	local id = dxlib.getNextID()
	container.id = id
	container.x = tonumber(data.x) or 0
	container.y = tonumber(data.y) or 0
	container.width = tonumber(data.width) or screenWidth
	container.height = tonumber(data.height) or screenHeight
	container.items = {}
	dxlib.containers[id] = container
	return container
end

local defaultFont = {button = dxlib.getFont("Roboto-Medium", 11), gridlist = dxlib.getFont("RobotoCondensed-Regular", 14)}

function dxlib.initItem(data)
	data.fontScale = tonumber(data.fontScale) or dxlib.fontScale
	data.font = data.font or (defaultFont[data.type] and defaultFont[data.type] or dxlib.getFont("Roboto-Regular", 11))
	data.fontHeight = dxGetFontHeight(data.fontScale, data.font)
	if data.type == "gridlist" then
		local customBlockHeight = data.customBlockHeight
		data.padding = tonumber(data.padding) or 2
		data.blockPadding = tonumber(data.blockPadding) or 10
		data.columns = tonumber(data.columns) or 1
		data.rowsToShow = math.floor(data.height/(customBlockHeight and customBlockHeight or (data.fontHeight + data.blockPadding * 2)))
		local totalWidth = data.width - (data.columns + 1) * data.padding - 6
		local totalHeight = data.height - (data.rowsToShow + 1) * data.padding
		data.blockWidth = totalWidth/data.columns
		data.blockHeight = totalHeight/data.rowsToShow
	elseif data.type == "colorpicker" then
		data.rowHeight = 18
		data.r, data.g, data.b, data.a = 1, 1, 1, 1
	end
	return data
end

function dxlib.registerItem(container, data)
	local container = container and dxlib.containers[container] or nil
	if not container then
		return print("Failed to register item, invalid container")
	end
	if type(data) ~= "table" then
		return print("Failed to register item")
	end
	local type, x, y, width, height, size = data.type, tonumber(data.x), tonumber(data.y), tonumber(data.width), tonumber(data.height), tonumber(data.size) or nil
	if not type or not x or not y or (not width and not size) or (not height and not size) then
		return print("Failed to register item, missing argument(-s)")
	end
	data = dxlib.initItem(data)
	if not container.items[type] then
		container.items[type] = {}
	end
	table.insert(container.items[type], 1, data)
end

function dxlib.renderContainer(container, renderTarget)
	local container = container and dxlib.containers[container] or nil
	if not container or not isElement(renderTarget) then
		return
	end
	local currentTick = getTickCount()
	if container.scrollToGo then
		local tick = container.scrollTick or 0
		container.scroll = interpolateBetween(container.scroll or 0, 0, 0, container.scrollToGo or 0, 0, 0, math_min(1000, currentTick - tick)/1000, dxlib.interpolator)
	end
	local scrollOffset = container.scroll or 0
	-- Pre render gridlists
	if container.items["gridlist"] then
		for i, item in pairs(container.items["gridlist"]) do
			local x, y = item.x, item.y - scrollOffset
			if y + item.height > 0 and y <= container.height then
				local materialWidth, materialHeight = 0, 0
				if isElement(item.renderTarget) then
					 materialWidth, materialHeight = dxGetMaterialSize(item.renderTarget)
				end
				if math_floor(materialWidth) ~= math_floor(item.width) or math_floor(materialHeight) ~= math_floor(item.height) then
					if isElement(item.renderTarget) then
						destroyElement(item.renderTarget)
					end
					item.renderTarget = dxCreateRenderTarget(item.width, item.height, true)
				end
				if item.scrollToGo then
					local tick = item.scrollTick or 0
					item.scroll = interpolateBetween(item.scroll or 0, 0, 0, item.scrollToGo or 0, 0, 0, math_min(1000, currentTick - tick)/1000, "OutQuad")
					if item.scroll ~= item.scrollToGo then
						dxlib.checkGridlistHover(container, item, scrollOffset)
					end
				end
				dxSetRenderTarget(item.renderTarget, true)
				dxSetBlendMode("modulate_add")
				if item.rows then
					local blockColor = item.blockColor or {255, 255, 255, 55}
					local scroll, maximumScroll = item.scroll or 0, item.maximumScroll or 0
					local delta, endIndex, maximumDelta = 1, 1, math_max(#item.rows - item.rowsToShow * item.columns - 1, 0)
					if scroll and maximumScroll then
						local percantage = scroll/(maximumScroll + item.height)
						delta = math_min(math_max(math_floor(#item.rows * percantage), 1), maximumDelta)
						endIndex = delta + item.rowsToShow * item.columns + 2
					end
					local offset = -scroll
					for i = delta, endIndex do
						local row = item.rows[i]
						if row then
							local tick = row.tick or 0
							local selected = (item.selectedRow == i or item.hoveredRow == i) and true or false
							local from, to = selected and 0 or 1, selected and 1 or 0
							local progress = interpolateBetween(from, 0, 0, to, 0, 0, math_min(150, currentTick - tick)/150, dxlib.interpolator)
							local x, y = row.x, row.y + offset
							local r, g, b, a = unpack(blockColor)
							if a > 0 then
								a = math_min(a + 10 * progress, 255)
								dxDrawRectangle(x, y, item.blockWidth, item.blockHeight, tocolor(r, g, b, a))
							end
							if item.customBlockRendering then
								item.customBlockRendering(x, y, row, item, i, progress)
							else
								dxDrawText(row.text, x + item.blockPadding, y, x + item.blockWidth - item.blockPadding, y + item.blockHeight, tocolor(255, 255, 255, 255), item.fontScale, item.font, "left", "center", true)
							end
						end
					end
					item.delta = delta
					item.endIndex = endIndex
				end
				dxDrawRectangle(item.width - 6, 0, 6, item.height, tocolor(25, 25, 25, 105))
				if item.maximumScroll and item.maximumScroll > 0 and item.scrollbarSize then
					local percantage = (item.scroll or 0)/(item.maximumScroll)
					local scrollbarOffset = (item.height - item.scrollbarSize) * percantage
					dxDrawRectangle(item.width - 6, scrollbarOffset, 6, item.scrollbarSize, tocolor(25, 132, 109, 255))
				end
				dxSetBlendMode("blend")
				dxSetRenderTarget()
			end
		end
	end
	-- Actual rendering part
	local backgroundColor = container.backgroundColor or tocolor(15, 15, 15, 245)
	dxSetRenderTarget(renderTarget, true)
	dxSetBlendMode("modulate_add")
	dxDrawRectangle(0, 0, container.width, container.height, backgroundColor)
	-- Rectangles
	if container.items["rectangle"] then
		for i, item in pairs(container.items["rectangle"]) do
			if not item.noDisplay then
				local x, y = item.x, item.y - scrollOffset
				if y + item.height > 0 and y <= container.height then
					local color = item.color or tocolor(255, 255, 255, 255)
					dxDrawRectangle(x, y, item.width, item.height, color)
					if item.borderColor then
						dxDrawBorder(x, y, item.width, item.height, 1, item.borderColor)
					end
				end
			end
		end
	end
	-- Custom stuff
	if container.items["custom"] then
		for i, item in pairs(container.items["custom"]) do
			local x, y = item.x, item.y - scrollOffset
			if y + item.height > 0 and y <= container.height then
				if item.renderingFunction then
					item.renderingFunction(x, y, item)
				end
			end
		end
	end
	-- Images
	if container.items["image"] then
		for i, item in pairs(container.items["image"]) do
			if item.path and fileExists(item.path) then
				local x, y = item.x, item.y - scrollOffset
				if y + item.height > 0 and y <= container.height then
					local size = math_min(item.width, item.height)
					local offsetX, offsetY = (item.width - size)/2, (item.height - size)/2
					local rotation = item.rotation or 0
					local color = item.color or tocolor(255, 255, 255, 255)
					dxDrawImage(x + offsetX, y + offsetY, size, size, item.path, rotation, 0, 0, color)
				end
			end
		end
	end
	-- Gridlists
	if container.items["gridlist"] then
		for i, item in pairs(container.items["gridlist"]) do
			local x, y = item.x, item.y - scrollOffset
			if isElement(item.renderTarget) and y + item.height > 0 and y <= container.height then
				dxDrawImage(x, y, item.width, item.height, item.renderTarget, 0, 0, 0, tocolor(255, 255, 255, 255))
			end
		end
	end
	-- Labels
	if container.items["label"] then
		for i, item in pairs(container.items["label"]) do
			local x, y = item.x, item.y - scrollOffset
			if y + item.height > 0 and y <= container.height then
				local color = item.color or tocolor(255, 255, 255, 255)
				local fontScale = item.fontScale or dxlib.fontScale
				local font = item.font or dxlib.getFont("Roboto-Medium", 11)
				local text = item.text or "Label #"..i
				local horizontalAlign = item.horizontalAlign or "left"
				local verticalAlign = item.verticalAlign or "center"
				local clip = item.clip or false
				local wordBreak = type(item.wordBreak) == "boolean" and item.wordBreak or true
				local colorcoded = item.colorcoded or false
				if wordBreak then
					text = string.shrinkToSize(text, fontScale, font, item.width - 5)
				end
				dxDrawText(text, x, y, x + item.width, y + item.height, color, fontScale, font, horizontalAlign, verticalAlign, clip, wordBreak, false, colorcoded)
			end
		end
	end
	-- Selectors
	if container.items["selector"] then
		for i, item in pairs(container.items["selector"]) do
			local x, y = item.x, item.y - scrollOffset
			if y + item.height > 0 and y <= container.height then
				local textColor = item.textColor or tocolor(255, 255, 255, 255)
				local fontScale = item.fontScale or dxlib.fontScale
				local font = item.font or dxlib.getFont("Roboto-Medium", 13)
				local currentID = item.currentID or 1
				local currentValue = item.values and item.values[currentID] or ""
				local iconSize = math_min(item.height * 0.25, 10)
				local offset = (item.height - iconSize)/2
				local width = item.width - iconSize
				currentValue = string.shrinkToSize(currentValue, fontScale, font, width - 20)
				local tick = item.tick or 0
				local from, to = item.hovered and 0 or 1, item.hovered and 1 or 0
				local progress = interpolateBetween(from, 0, 0, to, 0, 0, math_min(150, currentTick - tick)/150, dxlib.interpolator)
				local alpha, distance = 105 + 100 * progress, 5 * progress
				dxDrawText(currentValue, x + iconSize, y, x + width, y + item.height, textColor, fontScale, font, "center", "center", true)
				dxDrawImageSection(x + 5 - distance, y + offset, iconSize, iconSize, 1, 1, 46, 46, "img/dxlib/arrow.png", 180, 0, 0, tocolor(255, 255, 255, alpha))
				dxDrawImageSection(x + item.width - iconSize - 5 + distance, y + offset, iconSize, iconSize, 1, 1, 46, 46, "img/dxlib/arrow.png", 0, 0, 0, tocolor(255, 255, 255, alpha))
			end
		end
	end
	-- Checkboxes
	if container.items["checkbox"] then
		for i, item in pairs(container.items["checkbox"]) do
			local x, y = item.x, item.y - scrollOffset
			if y + item.height > 0 and y <= container.height then
				local tick = item.tick or 0
				local from, to = item.checked and 0 or 1, item.checked and 1 or 0
				local progress = interpolateBetween(from, 0, 0, to, 0, 0, math_min(150, currentTick - tick)/150, dxlib.interpolator)
				item.r, item.g, item.b = interpolateBetween(item.r or 0, item.g or 0, item.b or 0, item.checked and 55 or 255, item.checked and 255 or 25, item.checked and 55 or 0, math_min(500, currentTick - tick)/500, dxlib.interpolator)
				local circleSize = 32
				dxDrawRectangle(x + circleSize/2, y + (item.height - 3)/2, item.width - circleSize, 3, tocolor(25, 25, 25, 245)) 
				dxDrawImage(x + (item.width - circleSize) * progress, y + (item.height - circleSize)/2, circleSize, circleSize, "img/dxlib/check.png", 0, 0, 0, tocolor(item.r, item.g, item.b, 255))
			end
		end
	end
	-- Scrollbars
	if container.items["scrollbar"] then
		for i, item in pairs(container.items["scrollbar"]) do
			local x, y = item.x, item.y - scrollOffset
			local progress = item.progress or 0
			dxDrawRectangle(x + 8, y + (item.height - 3)/2, item.width - 16, 3, tocolor(255, 255, 255, 255))
			dxDrawImage(x + (item.width - 24) * progress, y + (item.height - 16)/2, 16, 16, "img/dxlib/selector.png", 0, 0, 0, tocolor(255, 255, 255, 255))
		end
	end
	-- Buttons
	if container.items["button"] then
		for i, item in pairs(container.items["button"]) do
			local x, y = item.x, item.y - scrollOffset
			if y + item.height > 0 and y <= container.height then
				local backgroundColor = item.backgroundColor or tocolor(25, 132, 109, 55)
				local hoverColor = item.hoverColor or {25, 132, 109, 255}
				local textAlign = item.textAlign or "center"
				local isIcon = item.isIcon or false
				local text = not isIcon and string.shrinkToSize(item.text or "Button #"..i, item.fontScale, item.font, item.width - 5) or item.text
				local hoverText = item.hoverText or nil
				local tick = item.tick or 0
				local from, to = item.hovered and 0 or 1, item.hovered and 1 or 0
				local progress = interpolateBetween(from, 0, 0, to, 0, 0, math_min(150, currentTick - tick)/150, dxlib.interpolator)
				if container.customButtonRendering then
					container.customButtonRendering(x, y, item)
				elseif item.customRendering then
					item.customRendering(x, y, item)
				else
					if isIcon and text and fileExists(text) then
						local size = item.iconSize or math_min(item.width, item.height)
						local rotation = item.rotation or 0
						dxDrawImage(x + (item.width - size)/2, y + (item.height - size)/2, size, size, text, rotation, 0, 0, tocolor(255, 255, 255, 255 - 255 * 0.5 + 255 * 0.5 * progress))
					else
						dxDrawCurvedRectangle(x, y, item.width, item.height, backgroundColor)
						if progress > 0 then
							local r, g, b, a = unpack(hoverColor)
							dxDrawCurvedBorder(x, y, item.width, item.height, tocolor(r, g, b, a * progress))
							if hoverText then
								hoverText = string.shrinkToSize(hoverText, item.fontScale, item.font, item.width - 5)
								dxDrawText(text:upper(), x, y, x + item.width, y + item.height, tocolor(255, 255, 255, 255 * (1 - progress)), item.fontScale, item.font, textAlign, "center", true)
								dxDrawText(hoverText:upper(), x, y, x + item.width, y + item.height, tocolor(255, 255, 255, 255 * progress), item.fontScale, item.font, textAlign, "center", true)
							else
								dxDrawText(text:upper(), x, y, x + item.width, y + item.height, tocolor(255, 255, 255, 255), item.fontScale, item.font, textAlign, "center", true)
							end
						else
							dxDrawText(text:upper(), x, y, x + item.width, y + item.height, tocolor(255, 255, 255, 255), item.fontScale, item.font, textAlign, "center", true)
						end
					end
				end
			end
		end
	end
	if container.items["input"] then
		for i, item in pairs(container.items["input"]) do
			local x, y = item.x, item.y - scrollOffset
			if y + item.height > 0 and y <= container.height then
				if item.passwordInput and not item.passwordText and item.text then
					for i = 1, string.len(item.text) do
						item.passwordText = (item.passwordText or "").."*"
					end
				end
				local backgroundColor = item.backgroundColor or {25, 25, 25, 245}
				local fontScale = item.fontScale or dxlib.fontScale
				local font = item.font or dxlib.getFont("Roboto-Medium", 13)
				local placeholder = item.placeholder
				local text = item.passwordText and item.passwordText or (item.text or "")
				local horizontalAlign = item.horizontalAlign or "left"
				local verticalAlign = item.verticalAlign or "center"
				local textWidth = dxGetTextWidth(text, fontScale, font)
				local tick = item.tick or 0
				local active = (item.selected or item.text)
				local from, to = active and 1 or 0, active and 0 or 1
				local progress = interpolateBetween(from, 0, 0, to, 0, 0, math_min(150, currentTick - tick)/150, dxlib.interpolator)
				if backgroundColor[4] and backgroundColor[4] > 0 then
					dxDrawRectangle(x, y, item.width, item.height, tocolor(unpack(backgroundColor)))
				end
				if progress > 0 and placeholder then
					placeholder = string.shrinkToSize(placeholder, item.fontScale, item.font, item.width - 5)
					dxDrawText(placeholder, x + 10, y, x + item.width - 10, y + item.height, tocolor(255, 255, 255, 255 * progress), fontScale, font, horizontalAlign, verticalAlign, true)
				end
				if textWidth and textWidth > item.width - 20 then
					horizontalAlign = "right"
				end
				if progress < 1 then
					dxDrawText(text, x + 10, y, x + item.width - 10, y + item.height, tocolor(255, 255, 255, 255 * (1 - progress)), fontScale, font, horizontalAlign, verticalAlign, true)
					if item.selected then
						local offset = 0
						if horizontalAlign == "left" then
							offset = (textWidth or 0) + 10
						elseif horizontalAlign == "center" then
							offset = item.width/2 + (textWidth or 0)/2
						elseif horizontalAlign == "right" then
							offset = item.width - 10
						end
						dxDrawRectangle(x + offset, y + (item.height - item.fontHeight)/2, 1, item.fontHeight, tocolor(255, 255, 255, 255 * (1 - progress)))
					end
				end
			end
		end
	end
	-- Colorpickers
	if container.items["colorpicker"] then
		for i, item in pairs(container.items["colorpicker"]) do
			local x, y = item.x, item.y - scrollOffset
			if y + item.height > 0 and y <= container.height then
				local _width = item.width - 16
				local offsetX, offsetY, lineOffset, selectorOffset = x, y, (item.rowHeight - 3)/2, (item.rowHeight  - 16)/2
				-- R
				dxDrawRectangle(offsetX + 8, offsetY + lineOffset, _width, 3, tocolor(255, 255, 255, 255))
				dxDrawImage(offsetX + _width * item.r, offsetY + selectorOffset, 16, 16, "img/dxlib/selector.png", 0, 0, 0, tocolor(255, 255, 255, 255))
				offsetY = offsetY + item.rowHeight
				-- G
				dxDrawRectangle(offsetX + 8, offsetY + lineOffset, _width, 3, tocolor(255, 255, 255, 255))
				dxDrawImage(offsetX + _width * item.g, offsetY + selectorOffset, 16, 16, "img/dxlib/selector.png", 0, 0, 0, tocolor(255, 255, 255, 255))
				offsetY = offsetY + item.rowHeight
				-- B
				dxDrawRectangle(offsetX + 8, offsetY + lineOffset, _width, 3, tocolor(255, 255, 255, 255))
				dxDrawImage(offsetX + _width * item.b, offsetY + selectorOffset, 16, 16, "img/dxlib/selector.png", 0, 0, 0, tocolor(255, 255, 255, 255))
				offsetY = offsetY + item.rowHeight
				-- A
				dxDrawRectangle(offsetX + 8, offsetY + lineOffset, _width, 3, tocolor(0, 0, 0, 255))
				dxDrawRectangle(offsetX + 8, offsetY + lineOffset, _width, 3, tocolor(255 * item.r, 255 * item.g, 255 * item.b, 255 * item.a))
				dxDrawImage(offsetX + _width * item.a, offsetY + selectorOffset, 16, 16, "img/dxlib/selector.png", 0, 0, 0, tocolor(255, 255, 255, 255))
				offsetY = offsetY + item.rowHeight
				-- Display
				local r, g, b, a = math.floor(255 * item.r), math.floor(255 * item.g), math.floor(255 * item.b), math.floor(255 * item.a)
				dxDrawText("R: "..r..", G: "..g..", B: "..b..", A: "..a, x, offsetY, x + item.width, offsetY + item.rowHeight, tocolor(255, 255, 255, 155), item.fontScale, item.font, "center", "center", true)
			end
		end
	end
	dxSetBlendMode("blend")
	dxSetRenderTarget()
	return renderTarget
end

function dxlib.checkGridlistHover(container, gridlist, scrollOffset)
	local y = gridlist.y - scrollOffset
	if isCursorInRange(container.x + gridlist.x, container.y + y, gridlist.width - 6, gridlist.height) then
		local delta, endIndex, scroll = gridlist.delta, gridlist.endIndex, gridlist.scroll or 0
		if delta and endIndex then
			local offset = -scroll
			for i = delta, endIndex do
				local row = gridlist.rows[i]
				if row then
					if isCursorInRange(container.x + gridlist.x + row.x, container.y + y + row.y + offset, gridlist.blockWidth, gridlist.blockHeight) then
						if gridlist.hoveredRow == i then
							break
						end
						if not gridlist.selectedRow or gridlist.selectedRow ~= i then
							row.tick = getTickCount()
						end
						gridlist.hoveredRow = i
						break
					else
						if gridlist.hoveredRow == i then
							if not gridlist.selectedRow or gridlist.selectedRow ~= i then
								row.tick = getTickCount()
							end
							gridlist.hoveredRow = nil
						end
					end
				end
			end
		end
	elseif gridlist.hoveredRow then
		if not gridlist.selectedRow or gridlist.selectedRow ~= gridlist.hoveredRow then
			gridlist.rows[gridlist.hoveredRow].tick = getTickCount()
		end
		gridlist.hoveredRow = nil
	end
end

function dxlib.updateColorpicker(container, colorpicker, cX, cY, scrollOffset)
	if colorpicker.dragging then
		local x = container.x + colorpicker.x
		local distance = math_min(math_max(cX - x, 0), colorpicker.width)
		colorpicker[colorpicker.dragging] = distance/colorpicker.width
		if colorpicker.onUpdate then
			colorpicker.onUpdate(255 * colorpicker.r, 255 * colorpicker.g, 255 * colorpicker.b, colorpicker.a)
		end
	end
end

function dxlib.updateScrollbar(container, scrollbar, cX, cY)
	if scrollbar.dragging then
		local x = scrollbar.x
		local width = scrollbar.width - 16
		local offset = cX - (container.x + x)
		if offset < 0 then
			offset = 0
		elseif offset > width then
			offset = width
		end
		local progress = offset/width
		scrollbar.progress = progress
		if scrollbar.onUpdate then
			scrollbar.onUpdate(scrollbar.progress)
		end
	end
end

addEventHandler("onClientCursorMove", root,
function(_, _, cX, cY)
	if not dxlib.active or not dxlib.activeContainer then
		return
	end
	local container = dxlib.containers[dxlib.activeContainer]
	if container then
		if isCursorInRange(container.x, container.y, container.width, container.height) or getKeyState("mouse1") then
			local scrollOffset = container.scroll or 0
			-- Update gridlists
			if container.items["gridlist"] then
				for i, item in pairs(container.items["gridlist"]) do
					local y = item.y - scrollOffset
					if isCursorInRange(container.x + item.x, container.y + y, item.width, item.height) then
						if not item.hovered then
							item.hovered = true
						end
					else
						if item.hovered then
							item.hovered = false
						end
					end
					if item.dragging then
						local y = item.y - scrollOffset
						local height = item.height
						local offset = cY - (container.y + y)
						offset = offset - item.dragOffset
						if offset < 0 then
							offset = 0
						elseif offset > height - item.scrollbarSize then
							offset = height - item.scrollbarSize
						end
						local percantage = offset/(height - item.scrollbarSize)
						item.scrollToGo = item.maximumScroll * percantage
						item.scroll = item.scrollToGo
					elseif item.rows then
						dxlib.checkGridlistHover(container, item, scrollOffset)
					end
				end
			end
			-- Update buttons
			if container.items["button"] then
				for i, item in pairs(container.items["button"]) do
					local y = item.y - scrollOffset
					if isCursorInRange(container.x + item.x, container.y + y, item.width, item.height) then
						if not item.hovered then
							item.tick = getTickCount()
							item.hovered = true
						end
					else
						if item.hovered then
							item.tick = getTickCount()
							item.hovered = false
						end
					end
				end
			end
			-- Update inputs
			if container.items["input"] then
				for i, item in pairs(container.items["input"]) do
					local y = item.y - scrollOffset
					if isCursorInRange(container.x + item.x, container.y + y, item.width, item.height) then
						if not item.hovered then
							item.hovered = true
						end
					else
						if item.hovered then
							item.hovered = false
						end
					end
				end
			end
			-- Update selectors
			if container.items["selector"] then
				for i, item in pairs(container.items["selector"]) do
					local y = item.y - scrollOffset
					if isCursorInRange(container.x + item.x, container.y + y, item.width, item.height) then
						if not item.hovered then
							item.tick = getTickCount()
							item.hovered = true
						end
					else
						if item.hovered then
							item.tick = getTickCount()
							item.hovered = false
						end
					end
				end
			end
			-- Update colorpickers
			if container.items["colorpicker"] then
				for i, item in pairs(container.items["colorpicker"]) do
					if item.dragging then
						dxlib.updateColorpicker(container, item, cX, cY, scrollOffset)
					end
				end
			end
			-- Update scrollbars
			if container.items["scrollbar"] then
				for i, item in pairs(container.items["scrollbar"]) do
					if item.dragging then
						dxlib.updateScrollbar(container, item, cX, cY)
					end
				end
			end
		else
			if not getKeyState("mouse1") then
				dxlib.unhoverContainer(container)
			end
		end
	end
end)

addEventHandler("onClientClick", root,
function(button, state)
	if not dxlib.active or not dxlib.activeContainer then
		return
	end
	local container = dxlib.containers[dxlib.activeContainer]
	if container then
		local scrollOffset = container.scroll or 0
		local inputEnabled = true
		if button == "left" and state == "down" then
			-- Update gridlists
			if container.items["gridlist"] then
				for i, item in pairs(container.items["gridlist"]) do
					if item.rows and not item.dragging then
						local x, y = item.x, item.y - scrollOffset
						if isCursorInRange(container.x + x + item.width - 6, container.y + y, 15, item.height) and item.maximumScroll and item.maximumScroll > 0 and item.scrollbarSize then
							local percantage = (item.scroll or 0)/(item.maximumScroll)
							local scrollbarOffset = (item.height - item.scrollbarSize) * percantage
							local cX, cY = getCursorPosition()
							item.dragging = true
							item.dragOffset = cY - (container.y + y + scrollbarOffset)
						end
					end
				end
			end
			-- Update inputs
			if container.items["input"] then
				for i, item in pairs(container.items["input"]) do
					if item.hovered then
						if not item.selected then
							if not item.text or item.text == "" then
								item.tick = getTickCount()
							end
							item.selected = true
						end
					else
						if item.selected then
							if not item.text or item.text == "" then
								item.tick = getTickCount()
							end
							item.selected = false
						end
					end
					if item.selected then
						inputEnabled = false
					end
				end
			end
			-- Update colorpickers
			if container.items["colorpicker"] then
				for i, item in pairs(container.items["colorpicker"]) do
					if isCursorInRange(container.x + item.x, container.y + item.y - scrollOffset, item.width, item.height) then
						if isCursorInRange(container.x + item.x, container.y + item.y - scrollOffset, item.width, item.rowHeight) then
							item.dragging = "r"
						elseif isCursorInRange(container.x + item.x, container.y + item.y - scrollOffset + item.rowHeight, item.width, item.rowHeight) then
							item.dragging = "g"
						elseif isCursorInRange(container.x + item.x, container.y + item.y - scrollOffset + item.rowHeight * 2, item.width, item.rowHeight) then
							item.dragging = "b"
						elseif isCursorInRange(container.x + item.x, container.y + item.y - scrollOffset + item.rowHeight * 3, item.width, item.rowHeight) then
							item.dragging = "a"
						end
						local cX, cY = getCursorPosition()
						dxlib.updateColorpicker(container, item, cX, cY, scrollOffset)
					else
						item.dragging = false
					end
				end
			end
			-- Update scrollbars
			if container.items["scrollbar"] then
				for i, item in pairs(container.items["scrollbar"]) do
					local x, y = item.x, item.y - scrollOffset
					if isCursorInRange(container.x + x, container.y + y, item.width, item.height) then
						item.dragging = true
						local cX, cY = getCursorPosition()
						dxlib.updateScrollbar(container, item, cX, cY)
					else
						item.dragging = false
					end
				end
			end
			-- Update selectors
			if container.items["selector"] then
				for i, item in pairs(container.items["selector"]) do
					if item.hovered and item.values and #item.values > 1 then
						local x, y = item.x, item.y - scrollOffset
						local leftHovered = isCursorInRange(container.x + x, container.y + y, item.width/2, item.height)
						local rightHovered = isCursorInRange(container.x + x + item.width/2, container.y + y, item.width/2, item.height)
						if leftHovered then
							item.currentID = (item.currentID or 1) - 1
							if item.currentID < 1 then
								item.currentID = #item.values
							end
							if item.onSelect then
								item.onSelect(item.currentID)
							end
						elseif rightHovered then
							item.currentID = (item.currentID or 1) + 1
							if item.currentID > #item.values then
								item.currentID = 1
							end
							if item.onSelect then
								item.onSelect(item.currentID)
							end
						end
					end
				end
			end
			-- Update checkboxes
			if container.items["checkbox"] then
				for i, item in pairs(container.items["checkbox"]) do
					local x, y = item.x, item.y - scrollOffset
					if isCursorInRange(container.x + x, container.y + y, item.width, item.height) then
						item.tick = getTickCount()
						item.checked = not item.checked
						if item.onCheck then
							item.onCheck(item.checked)
						end
					end
				end
			end
			guiSetInputMode(inputEnabled and "allow_binds" or "no_binds")
		elseif button == "left" and state == "up" then
			-- Update gridlists
			if container.items["gridlist"] then
				for i, item in pairs(container.items["gridlist"]) do
					if item.hoveredRow and item.selectedRow ~= item.hoveredRow then
						if item.selectedRow and item.rows[item.selectedRow] then
							item.rows[item.selectedRow].tick = getTickCount()
						end
						if item.onSelect then
							local doSelect = item.onSelect(item.hoveredRow)
							if doSelect or not item.readOnly then
								item.tick = getTickCount()
								item.selectedRow = item.hoveredRow
							end
						elseif not item.readOnly then
							item.tick = getTickCount()
							item.selectedRow = item.hoveredRow
						end
					end
					item.dragging = false
					item.dragOffset = nil
				end
			end
			-- Update buttons
			if container.items["button"] then
				for i, item in pairs(container.items["button"]) do
					if item.hovered then
						if item.onClick then
							item.onClick()
						end
					end
				end
			end
			-- Update colorpickers
			if container.items["colorpicker"] then
				for i, item in pairs(container.items["colorpicker"]) do
					item.dragging = false
				end
			end
			-- Update scrollbars
			if container.items["scrollbar"] then
				for i, item in pairs(container.items["scrollbar"]) do
					item.dragging = false
				end
			end
		end
	end
end)

addEventHandler("onClientCharacter", root,
function(key)
	if not dxlib.active or not dxlib.activeContainer then
		return
	end
	local container = dxlib.containers[dxlib.activeContainer]
	if container then
		key = tostring(key)
		if container.items["input"] then
			for i, item in pairs(container.items["input"]) do
				if item.selected then
					local text = item.text or ""
					local maxLength = tonumber(item.maxLength or 0)
					local passwordInput = item.passwordInput
					if maxLength == 0 or #text + 1 <= maxLength then			
						item.text = text..key
						if passwordInput then
							item.passwordText = (item.passwordText or "").."*"
						end
						if item.onTextChange then
							item.onTextChange(item.text or "")
						end
					end
				end
			end
		end
	end
end)

function dxlib.backTrigger()
	if not dxlib.active or not dxlib.activeContainer then
		return
	end
	local container = dxlib.containers[dxlib.activeContainer]
	if container then
		if container.items["input"] then
			for i, item in pairs(container.items["input"]) do
				if item.selected then
					local text = item.text or ""
					local passwordInput = item.passwordInput
					if text ~= "" then
						item.text = string.sub(text, 1, string.len(text) - 1)
						if passwordInput then
							item.passwordText = ""
							for i = 1, string.len(text) do
								item.passwordText = (item.passwordText or "").."*"
							end
						end
						if item.text == "" then
							item.text = nil
							item.passwordText = nil
						end
						if item.onTextChange then
							item.onTextChange(item.text or "")
						end
					end
				end
			end
		end
	end
end

function dxlib.cancelBackTrigger()
	if dxlib.backTimer and isTimer(dxlib.backTimer) then
		killTimer(dxlib.backTimer)
	end
end

function dxlib.scroll(side)
	if not dxlib.active or not dxlib.activeContainer then
		return
	end
	local globalScrolled = false
	local container = dxlib.containers[dxlib.activeContainer]
	if container then
		if side == "up" then
			local scrolled = false
			if container.items["gridlist"] then
				for i, item in pairs(container.items["gridlist"]) do
					local maximumScroll = item.maximumScroll or 0
					if item.hovered and maximumScroll > 0 then
						item.scrollTick = getTickCount()
						item.scrollToGo = math_max((item.scrollToGo or 0) - (item.blockHeight + item.padding) * 2, 0)
						scrolled = true
						globalScrolled = true
					end
				end
			end
			if not scrolled and container.maximumScroll and isCursorInRange(container.x, container.y, container.width, container.height) then
				if container.scrollable then
					if container.lastScrollTick and getTickCount() - container.lastScrollTick < 200 then
						return true
					end
					container.scrollTick = getTickCount()
					container.scrollToGo = math_max((container.scrollToGo or 0) - container.height, 0)
					container.lastScrollTick = getTickCount()
					globalScrolled = true
				else
					container.scrollTick = getTickCount()
					container.scrollToGo = math_max((container.scrollToGo or 0) - 100, 0)
					globalScrolled = true
				end
			end
		elseif side == "down" then
			local scrolled = false
			if container.items["gridlist"] then
				for i, item in pairs(container.items["gridlist"]) do
					local maximumScroll = item.maximumScroll or 0
					if item.hovered and maximumScroll > 0 then
						local height = item.height
						local blockHeight = item.blockHeight
						item.scrollTick = getTickCount()
						item.scrollToGo = math_min((item.scrollToGo or 0) + (item.blockHeight + item.padding) * 2, maximumScroll)
						scrolled = true
						globalScrolled = true
					end
				end
			end
			if not scrolled and container.maximumScroll and isCursorInRange(container.x, container.y, container.width, container.height) then
				if container.scrollable then
					if container.lastScrollTick and getTickCount() - container.lastScrollTick < 200 then
						return true
					end
					container.scrollTick = getTickCount()
					container.scrollToGo = math_min((container.scrollToGo or 0) + container.height, container.maximumScroll)
					container.lastScrollTick = getTickCount()
					globalScrolled = true
				else
					container.scrollTick = getTickCount()
					container.scrollToGo = math_min((container.scrollToGo or 0) + 100, container.maximumScroll)
					globalScrolled = true
				end
			end
		end
	end
	return globalScrolled
end

addEventHandler("onClientKey", root,
function(button, press)
	if not dxlib.active or not dxlib.activeContainer then
		return
	end
	local container = dxlib.containers[dxlib.activeContainer]
	if container then
		if button == "backspace" then
			if press then
				dxlib.backTrigger()
				dxlib.cancelBackTrigger()
				dxlib.backTimer = setTimer(function()
					if getKeyState("backspace") then
						dxlib.backTimer = setTimer(dxlib.backTrigger, 50, 0)
					end
				end, 250, 1)
			else
				dxlib.cancelBackTrigger()
			end
		elseif button == "mouse_wheel_up" then
			dxlib.scroll("up")
		elseif button == "mouse_wheel_down" then
			dxlib.scroll("down")
		elseif button == "tab" and press then
			guiSetInputMode("allow_binds")
			if container.items["input"] then
				local selectedInputID = nil
				for i, item in pairs(container.items["input"]) do
					if item.selected then
						if not item.text or item.text == "" then
							item.tick = getTickCount()
						end
						item.selected = false
						selectedInputID = i
						break
					end
				end
				if selectedInputID then
					for i, item in pairs(container.items["input"]) do
						if i > selectedInputID then
							if not item.selected then
								if not item.text or item.text == "" then
									item.tick = getTickCount()
								end
								item.selected = true
							end
							break
						end
					end
				else
					local item = container.items["input"][1]
					if item then
						if not item.text or item.text == "" then
							item.tick = getTickCount()
						end
						item.selected = true
						guiSetInputMode("no_binds")
					end
				end
			end
		end
	end
end)

function dxDrawCurvedRectangle(x, y, width, height, color, postGUI, texture)
	if type(x) ~= "number" or type(y) ~= "number" or type(width) ~= "number" or type(height) ~= "number" then
		return
	end
	local texture = texture or "img/dxlib/edge-button.png"
	local color = color or tocolor(25, 132, 109, 255)
	local postGUI = type(postGUI) == "boolean" and postGUI or false
	local edgeSize = height/2
	width = width - height
	dxDrawImageSection(x, y, edgeSize, edgeSize, 0, 0, 33, 33, texture, 0, 0, 0, color, postGUI)
	dxDrawImageSection(x, y + edgeSize, edgeSize, edgeSize, 0, 33, 33, 33, texture, 0, 0, 0, color, postGUI)
	dxDrawImageSection(x + width + edgeSize, y, edgeSize, edgeSize, 43, 0, 33, 33, texture, 0, 0, 0, color, postGUI)
	dxDrawImageSection(x + width + edgeSize, y + edgeSize, edgeSize, edgeSize, 43, 33, 33, 33, texture, 0, 0, 0, color, postGUI)
	if width > 0 then
		dxDrawImageSection(x + edgeSize, y, width, height, 33, 0, 10, 66, texture, 0, 0, 0, color, postGUI)
	end
end

function dxDrawCurvedBorder(x, y, width, height, color, postGUI, texture)
	if type(x) ~= "number" or type(y) ~= "number" or type(width) ~= "number" or type(height) ~= "number" then
		return
	end
	local texture = texture or "img/dxlib/border-button.png"
	local color = color or tocolor(25, 132, 109, 255)
	local postGUI = type(postGUI) == "boolean" and postGUI or false
	local edgeSize = height/2
	local lineWidth = math_max(width - height, 0)
	dxDrawImageSection(x + edgeSize, y, lineWidth, height, 90, 1, 10, 50, texture, 0, 0, 0, color, postGUI)
	dxDrawImageSection(x, y, edgeSize, height, 1, 1, 25, 50, texture, 0, 0, 0, color, postGUI)
	dxDrawImageSection(x + width - edgeSize, y, edgeSize, height, 26, 1, 25, 50, texture, 0, 0, 0, color, postGUI)
end

function dxDrawBorder(x, y, width, height, size, color)
	if type(size) ~= "number" then
		size = 1
	end
	if not color then
		color = tocolor(255, 255, 255, 255)
	end
	dxDrawRectangle(x, y + size, size, height - size * 2, color, false)
	dxDrawRectangle(x + width - size, y + size, size, height - size * 2, color, false)
	dxDrawRectangle(x, y, width, size, color, false)
	dxDrawRectangle(x, y + height - size, width, size, color, false)
end

function string.shrinkToSize(text, scale, font, size)
	local textWidth = dxGetTextWidth(text, scale, font)
	local iter = 0
	while textWidth >= size do
		text = string.sub(text, 0, -2)
		iter = iter + 1
		textWidth = dxGetTextWidth(text, scale, font)
	end
	local wasShrinked = iter > 0
	if wasShrinked then
		text = string.sub(text, 0, -2)
		text = text..".."
	end
	return text, wasShrinked
end

function isCursorInRange(x, y, width, height)
	if not isCursorShowing() then
		return
	end
	local cX, cY = getCursorPosition()
	if cX >= x and cX <= x + width and cY >= y and cY <= y + height then
		return cX, cY
	end
	return
end

function isCursorInCircleRange(x, y, radius)
	if not isCursorShowing() then
		return
	end
	local cX, cY = getCursorPosition()
	x, y = x + radius, y + radius
	return (x - cX) ^ 2 + (y - cY) ^ 2 <= radius ^ 2
end

_getCursorPosition = getCursorPosition
function getCursorPosition()
	if not isCursorShowing() then
		return
	end
	local cX, cY = _getCursorPosition()
	return screenWidth * cX, screenHeight * cY, cX, cY
end

-- Global functions
function dxlib.setItemData(item, data, value)
	if type(item) ~= "table" or not item.type or not data then
		return
	end
	item[data] = value
	dxlib.initItem(item)
	if item.type == "gridlist" then
		local saved = {}
		if item.rows then
			for i, v in pairs(item.rows) do
				table.insert(saved, v.text)
			end
		end
		dxlib.setGridlistContent(item, saved)
	end
end

function dxlib.setItemVisible(container, item, visible)
	if type(container) ~= "table" or not container.items or type(item) ~= "table" or not item.type then
		return
	end
	local visible = visible and true or false
	local i = nil
	if not container.items[item.type] then
		return
	end
	for k, v in pairs(container.items[item.type]) do
		if v == item then
			i = k
			break
		end
	end
	if visible and i then
		return
	elseif visible and not i then
		item.hovered = nil
		item.hoveredRow = nil
		item.dragging = nil
		table.insert(container.items[item.type], item)
	elseif not visible and i then
		container.items[item.type][i] = nil
	end
end

function dxlib.setGridlistContent(gridlist, content)
	if type(gridlist) == "table" and type(content) == "table" then
		gridlist.rows = {}
		gridlist.selectedRow = nil
		local multicolumn = gridlist.columns > 1
		local column, x, y = 1, gridlist.padding, gridlist.padding
		for i, v in pairs(content) do
			local row = {}
			row.text = tostring(v)
			row.x, row.y = x, y
			if multicolumn then
				column = column + 1
				if column > gridlist.columns then
					column = 1
					x = gridlist.padding
					y = y + gridlist.blockHeight + gridlist.padding
				else
					x = x + gridlist.blockWidth + gridlist.padding
				end
			else
				y = y + gridlist.blockHeight + gridlist.padding
			end
			table.insert(gridlist.rows, row)
		end
		if multicolumn and column > 1 then
			y = y + gridlist.blockHeight + gridlist.padding
		end
		gridlist.maximumScroll = math_max(y - gridlist.height, 0)
		if gridlist.scrollToGo and gridlist.scrollToGo > gridlist.maximumScroll then
			gridlist.scrollTick = getTickCount()
			gridlist.scrollToGo = gridlist.maximumScroll
		end
		gridlist.scrollbarSize = math_max(gridlist.height * (gridlist.height/(gridlist.height + gridlist.maximumScroll)), gridlist.height * 0.1)
		if gridlist.selectedRow and not gridlist.rows[gridlist.selectedRow] then
			gridlist.tick = getTickCount()
			gridlist.selectedRow = nil
		end
	end
end

function dxlib.getGridlistSelectedRow(gridlist)
	if type(gridlist) == "table" then
		if gridlist.rows and gridlist.selectedRow then
			return gridlist.rows[gridlist.selectedRow] or nil, gridlist.selectedRow
		end
	end
end

function dxlib.setImagePath(image, path)
	if type(path) == "string" and fileExists(path) then
		image.path = path
	end
end

function dxlib.getColorpickerRGB(colorpicker, mix)
	if type(colorpicker) == "table" then
		local r, g, b, a = colorpicker.r or 1, colorpicker.g or 1, colorpicker.b or 1, colorpicker.a or 1
		if mix then
			return 255 * r * a, 255 * g * a, 255 * b * a, a
		else
			return 255 * r, 255 * g, 255 * b, a
		end
	end
end

function dxlib.getScrollbarProgress(scrollbar)
	if type(scrollbar) == "table" then
		return scrollbar.progress or 0
	end
end