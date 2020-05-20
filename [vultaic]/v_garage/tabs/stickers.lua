-- 'Stickers' tab
local settings = {id = 5, title = "Stickers"}
local content = nil
stickerCategories = {}
local items = {
	["button_apply"] = {type = "button", text = "Save", x = selector.width * 0.35, y = selector.height - 40, width = selector.width * 0.3, height = 35, backgroundColor = tocolor(25, 155, 255, 55), hoverColor = {25, 155, 255, 255}},
	["selector_slot"] = {type = "selector", x = 10, y = 5, width = selector.width * 0.6 - 25, height = 40},
	["button_manage_slot"] = {type = "button", text = "Create slot", x = selector.width * 0.6 - 5, y = 10, width = selector.width * 0.4, height = 30, backgroundColor = tocolor(105, 105, 105, 55), hoverColor = {105, 105, 105, 255}},
	["image_sticker"] = {type = "image", x = 10, y = 45, width = selector.width - 20, height = 90},
	["label_sticker"] = {type = "label", x = 10, y = 45, width = selector.width - 20, height = 90, horizontalAlign = "center", verticalAlign = "center"},
	["button_choose_sticker"] = {type = "button", text = "...", x = selector.width * 0.4, y = 140, width = selector.width * 0.2, height = 25},	
	["label_info"] = {type = "label", text = "", x = 10, y = 50, width = selector.width - 20, height = selector.height - 100, horizontalAlign = "center", verticalAlign = "center"},
	["label_position"] = {type = "label", text = "POSITION", x = 10, y = 170, width = selector.width * 0.5 - 15, height = 30},
	["label_position_x"] = {type = "label", text = "X:", x = 10, y = 200, width = selector.width * 0.5 - 15, height = 30},
	["input_position_x"] = {type = "input", text = "0", x = selector.width * 0.2 + 5, y = 200, width = selector.width * 0.3 - 15, height = 30, maxLength = 9},
	["label_position_y"] = {type = "label", text = "Y:", x = 10, y = 235, width = selector.width * 0.5 - 15, height = 30},
	["input_position_y"] = {type = "input", text = "0", x = selector.width * 0.2 + 5, y = 235, width = selector.width * 0.3 - 15, height = 30, maxLength = 9},
	["label_rotation"] = {type = "label", text = "Rot:", x = 10, y = 270, width = selector.width * 0.5 - 15, height = 30},
	["input_rotation"] = {type = "input", text = "0", x = selector.width * 0.2 + 5, y = 270, width = selector.width * 0.3 - 15, height = 30, maxLength = 4},	
	["label_size"] = {type = "label", text = "SIZE", x = selector.width * 0.5 + 5, y = 170, width = selector.width * 0.5 - 15, height = 30},
	["label_size_x"] = {type = "label", text = "X:", x = selector.width * 0.5 + 5, y = 200, width = selector.width * 0.5 - 15, height = 30},
	["input_size_x"] = {type = "input", text = "1", x = selector.width * 0.7 + 5, y = 200, width = selector.width * 0.3 - 15, height = 30, maxLength = 9},
	["label_size_y"] = {type = "label", text = "Y:", x = selector.width * 0.5 + 5, y = 235, width = selector.width * 0.5 - 15, height = 30},
	["input_size_y"] = {type = "input", text = "1", x = selector.width * 0.7 + 5, y = 235, width = selector.width * 0.3 - 15, height = 30, maxLength = 9},
	["label_color"] = {type = "label", text = "Color:", x = selector.width * 0.5 + 5, y = 270, width = selector.width * 0.5 - 15, height = 30},
	["input_color"] = {type = "input", text = "#FFFFFFFF", x = selector.width * 0.7 + 5, y = 270, width = selector.width * 0.3 - 15, height = 30, maxLength = 9},
	["label_priority"] = {type = "label", text = "Priority:", x = 10, y = 305, width = selector.width * 0.5 - 10, height = 30},
	["input_priority"] = {type = "input", text = "0", x = selector.width * 0.2 + 5, y = 305, width = selector.width * 0.3 - 15, height = 30, maxLength = 2},
	["label_scale"] = {type = "label", text = "Scale:", x = selector.width * 0.5 + 5, y = 305, width = selector.width * 0.5 - 10, height = 30},
	["input_scale"] = {type = "input", text = "0", x = selector.width * 0.7 + 5, y = 305, width = selector.width * 0.3 - 15, height = 30, maxLength = 1},
	["colorpicker"] = {type = "colorpicker", x = 10, y = 340, width = selector.width - 20, height = selector.height - 405}
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
			return triggerEvent("notification:create", localPlayer, "Tuning", "Please wait some while before saving your stickers again")
		end
		local data = {}
		for i, slot in pairs(content.slots) do
			for k, v in pairs(slot) do
				slot[k] = tostring(v)
			end
			data["slot_"..i] = slot
		end
		for i = 1, 32 do
			resetElementData("paint_slot_"..i)
		end
		triggerServerEvent("updateStickers", localPlayer, data)
		content.lastApplyTick = getTickCount()
		content.madeChanges = nil
	end
	items["button_choose_sticker"].onClick = function()
		selector.switch(tonumber(settings.id..".1"))
	end
	items["selector_slot"].onSelect = function(i)
		content.selectedSlotID = tonumber(i)
		checkSlot()
	end
	items["button_manage_slot"].onClick = function()
		if content.slotAction == "add" then
			local i = tonumber(items["selector_slot"].currentID or 1)
			if i then
				createSlot(i)
			end
		elseif content.slotAction == "clear" then
			clearSlot(content.selectedSlotID)
		end
	end
	items["label_info"].text = "Empty slot"
	items["input_position_x"].onTextChange = function(text)
		local value = tonumber(text) or nil
		if value then
			updateSelectedSlot(2, value)
		end
	end
	items["input_position_y"].onTextChange = function(text)
		local value = tonumber(text) or nil
		if value then
			updateSelectedSlot(3, value)
		end
	end
	items["input_size_x"].onTextChange = function(text)
		local value = tonumber(text) or nil
		if value then
			updateSelectedSlot(4, value)
		end
	end
	items["input_size_y"].onTextChange = function(text)
		local value = tonumber(text) or nil
		if value then
			updateSelectedSlot(5, value)
		end
	end
	items["input_rotation"].onTextChange = function(text)
		local value = tonumber(text) or nil
		if value then
			updateSelectedSlot(6, value)
		end
	end
	items["input_color"].onTextChange = function(text)
		local r, g, b, a = hexToRGB(text)
		r, g, b, a = (r or 255)/255, (g or 255)/255, (b or 255)/255, (a or 255)/255
		items["colorpicker"].r, items["colorpicker"].g, items["colorpicker"].b, items["colorpicker"].a = r, g, b, a
		updateSelectedSlot(7, rgbToHex(dxlib.getColorpickerRGB(items["colorpicker"], true)))
	end
	items["colorpicker"].onUpdate = function(r, g, b, a)
		local hex = rgbToHex(r * a, g * a, b * a)
		items["input_color"].text = hex
		updateSelectedSlot(7, hex)
	end
	items["input_priority"].onTextChange = function(text)
		local value = tonumber(text) or nil
		if value then
			updateSelectedSlot(8, value)
		end
	end
	items["input_scale"].onTextChange = function(text)
		local value = tonumber(text) or nil
		if value then
			updateSelectedSlot(9, value)
		end
	end
	content.slots = {}
	updateFields()
	content.slotAction = "add"
	content.selectedSlotID = 1
end
addEventHandler("onClientResourceStart", resourceRoot, initTab)

-- Get images
function getStickers(data)
	local categories = type(data) == "table" and data or exports.v_paint:getStickers()
	if not categories then
		return
	end
	stickerCategories = {}
	local k = 1
	for category, data in pairs(categories) do
		stickerCategories[k] = {title = tostring(category), stickers = {}}
		for i, v in pairs(data) do
			table.insert(stickerCategories[k].stickers, v)
		end
		k = k + 1
	end
	cacheStickerCategories()
end
addEvent("paints:onUpdateStickers", true)
addEventHandler("paints:onUpdateStickers", localPlayer, function() getStickers(stickers) end)

function cacheSlots()
	local slots = tonumber(getElementData(localPlayer, "paint_slots"))
	items["selector_slot"].values = {}
	content.slots = {}
	if slots then
		for i = 1, slots do
			local slot = getElementData(localPlayer, "paint_slot_"..i)
			if slot then
				slot = fromJSON(slot)
				if type(slot) == "table" then
					content.slots[i] = slot
				end
			end
			table.insert(items["selector_slot"].values, tostring("Slot #"..i))
		end
	end
	if not content.selectedSlot then
		content.selectedSlotID = 1
		content.selectedSlot = content.slots[1]
		updateFields()
	end
end

addEventHandler("onClientElementDataChange", localPlayer,
function(dataName)
	if dataName == "paint_slots" then
		cacheSlots()
	end
end)

function checkSlot(id)
	local id = tonumber(content.selectedSlotID)
	if not id then
		return
	end
	if not content.slots[id] then
		items["button_manage_slot"].text = "Create"
		content.slotAction = "add"
	else
		content.selectedSlot = content.slots[id]
		items["button_manage_slot"].text = "Clear"
		content.slotAction = "clear"
	end
	updateFields()
end

function updateFields()
	dxlib.setItemVisible(content, items["label_info"], not (content.slotAction == "clear"))
	local _items = {"button_choose_sticker", "label_position", "label_position_x", "label_position_y", "input_position_x", "input_position_y", "label_size", "label_size_x", "label_size_y", "input_size_x", "input_size_y", "label_rotation", "label_color", "input_color", "input_rotation", "image_sticker", "label_sticker", "colorpicker", "label_priority", "input_priority", "label_scale", "input_scale"}
	for i, item in pairs(_items) do
		dxlib.setItemVisible(content, items[item], content.slotAction == "clear")
	end
	local slot = content.selectedSlotID and content.slots[content.selectedSlotID] or nil
	if slot then
		local isText = string.sub(slot[1], 1, 3) == "tx."
		if isText then
			items["label_sticker"].text = "Text:\n"..string.sub(slot[1], 4, string.len(slot[1]))
			dxlib.setItemVisible(content, items["image_sticker"], false)
			dxlib.setItemVisible(content, items["label_sticker"], true)
		else
			dxlib.setImagePath(items["image_sticker"], slot[1] and ":v_paint/img/"..slot[1] or nil)
			dxlib.setItemVisible(content, items["image_sticker"], true)
			dxlib.setItemVisible(content, items["label_sticker"], false)
		end
		items["input_position_x"].text = tostring(slot[2])
		items["input_position_y"].text = tostring(slot[3])
		items["input_size_x"].text = tostring(slot[4])
		items["input_size_y"].text = tostring(slot[5])
		items["input_rotation"].text = tostring(slot[6])
		items["input_color"].text = tostring(slot[7] or "#FFFFFFFF")
		items["input_priority"].text = tostring(slot[8] or 0)
		items["input_scale"].text = tostring(slot[9] or 1)
		local r, g, b, a = hexToRGB(slot[7])
		r, g, b, a = (r or 255)/255, (g or 255)/255, (b or 255)/255, (a or 255)/255
		items["colorpicker"].r, items["colorpicker"].g, items["colorpicker"].b, items["colorpicker"].a = r, g, b, a
	end
end

function createSlot(id)
	if content.slots[id] then
		return
	end
	local default = {"rectangle.png", 0.25, 0.25, 0.5, 0.5, 0, "#FFFFFFFF", 0, 1}
	local data = content.selectedSlot and table.copy(content.selectedSlot) or default
	for i = 1, #default do
		if not data[i] then
			data[i] = default[i]
		end
	end
	content.slots[id] = data
	setElementData(localPlayer, "paint_slot_"..id, toJSON(data))
	checkSlot(id)
	content.madeChanges = true
end

function clearSlot(id)
	if not content.slots[id] then
		return
	end
	content.slots[id] = nil
	if id == content.selectedSlotID then
		content.selectedSlot = nil
	end
	setElementData(localPlayer, "paint_slot_"..id, nil)
	checkSlot(id)
	content.madeChanges = true
end

function updateSelectedSlot(key, value, update)
	local id = tonumber(content.selectedSlotID)
	local slot = id and content.slots[id] or nil
	if slot then
		slot[key] = value
		setElementData(localPlayer, "paint_slot_"..id, toJSON(slot))
		content.madeChanges = true
		if key == 1 then
			local isText = string.sub(slot[1], 1, 3) == "tx."
			if isText then
				items["label_sticker"].text = "Text:\n"..string.sub(slot[1], 4, string.len(slot[1]))
				dxlib.setItemVisible(content, items["image_sticker"], false)
				dxlib.setItemVisible(content, items["label_sticker"], true)
			else
				dxlib.setImagePath(items["image_sticker"], slot[1] and ":v_paint/img/"..slot[1] or nil)
				dxlib.setItemVisible(content, items["image_sticker"], true)
				dxlib.setItemVisible(content, items["label_sticker"], false)
			end
		end
		if update then
			updateFields()
		end
	end
end

local controls = {
	-- Movement
	moveSticker_forwards = "arrow_u",
	moveSticker_backwards = "arrow_d",
	moveSticker_left = "arrow_l",
	moveSticker_right = "arrow_r",
	moveSticker_slow = "lalt",
	moveSticker_fast = "lshift",
	-- Resize if lctrl is not pressed
	resizeSticker_inc = "mouse_wheel_up",
	resizeSticker_dec = "mouse_wheel_down",
	resizeSticker_activate = "lctrl",
	-- Rotate if lctrl is pressed
	rotateSticker_inc = "mouse_wheel_up",
	rotateSticker_dec = "mouse_wheel_down",
	rotateSticker_activate = "lalt"
}
local controlSpeed = {
	moveSticker_slow = 0.001,
	moveSticker_normal = 0.01,
	moveSticker_fast = 0.025,
	resizeSticker = 0.005,
	rotateSticker = 2
}

function renderControls()
	local slot = content.selectedSlotID and content.slots[content.selectedSlotID] or nil
	if selector.currentTabID ~= settings.id or not slot then
		return
	end	
	local rotation = math.fmod(camera.angleH + garage.vehiclePosition[6], 360)
	local move_slow = getKeyState(controls.moveSticker_slow)
	local move_fast = getKeyState(controls.moveSticker_fast)
	local move_speed = move_slow and controlSpeed.moveSticker_slow or (move_fast and controlSpeed.moveSticker_fast or controlSpeed.moveSticker_normal)
	do
		local move_rotation_x = math.cos(math.rad(rotation))
		local move_rotation_y = math.sin(math.rad(rotation))
		move_rotation_x = math.round(move_rotation_x * 10)/10
		move_rotation_y = math.round(move_rotation_y * 10)/10
		local angleX = math.cos(math.rad(rotation))
		local angleY = math.sin(math.rad(rotation))
		if getKeyState(controls.moveSticker_forwards) then -- Forwards
			local x, y = slot[2], slot[3]
			x = x + move_speed * move_rotation_x
			y = y + move_speed * move_rotation_y
			updateSelectedSlot(2, x, true)
			updateSelectedSlot(3, y, true)
		elseif getKeyState(controls.moveSticker_backwards) then -- Backwards
			local x, y = slot[2], slot[3]
			x = x - move_speed * move_rotation_x
			y = y - move_speed * move_rotation_y
			updateSelectedSlot(2, x, true)
			updateSelectedSlot(3, y, true)
		end
	end
	do
		local move_rotation_x = math.cos(math.rad(rotation + 90))
		local move_rotation_y = math.sin(math.rad(rotation + 90))
		move_rotation_x = math.round(move_rotation_x * 10)/10
		move_rotation_y = math.round(move_rotation_y * 10)/10
		local angleX = math.cos(math.rad(rotation))
		local angleY = math.sin(math.rad(rotation))
		if getKeyState(controls.moveSticker_left) then -- Forwards
			local x, y = slot[2], slot[3]
			x = x - move_speed * move_rotation_x
			y = y - move_speed * move_rotation_y
			updateSelectedSlot(2, x, true)
			updateSelectedSlot(3, y, true)
		elseif getKeyState(controls.moveSticker_right) then -- Backwards
			local x, y = slot[2], slot[3]
			x = x + move_speed * move_rotation_x
			y = y + move_speed * move_rotation_y
			updateSelectedSlot(2, x, true)
			updateSelectedSlot(3, y, true)
		end
	end
end

addEvent("garage:onInit", true)
addEventHandler("garage:onInit", localPlayer,
function()
	getStickers()
	cacheSlots()
	checkSlot(content.selectedSlotID)
end)

addEvent("garage:onTabSwitch", true)
addEventHandler("garage:onTabSwitch", localPlayer,
function(tab)
	removeEventHandler("onClientPreRender", root, renderControls)
	if tab == settings.id then
		addEventHandler("onClientPreRender", root, renderControls)
	end
end)

addEventHandler("onClientKey", root,
function(key, press)
	if selector.currentTabID ~= settings.id then
		return
	end
	local slot = content.selectedSlotID and content.slots[content.selectedSlotID] or nil
	if not slot then
		return
	end	
	if key == controls.resizeSticker_activate or key == controls.rotateSticker_activate then
		if press then
			camera.deactivate()
		else
			camera.activate(garage.vehicle)
		end
	end
	if getKeyState(controls.resizeSticker_activate) then
		if key == controls.resizeSticker_inc then
			local x, y = slot[2], slot[3]
			local width, height = slot[4], slot[5]
			local ratio = math.max(height/width, 0)
			local diffX, diffY = width, height
			width = width + controlSpeed.resizeSticker
			height = width * ratio
			width, height = tonumber(width) or 0, tonumber(height) or 0
			diffX, diffY = width - diffX, height - diffY
			diffX, diffY = tonumber(diffX or 0), tonumber(diffY or 0)
			x, y = tonumber(x - diffX/2) or 0, tonumber(y - diffY/2) or 0
			updateSelectedSlot(2, x, true)
			updateSelectedSlot(3, y, true)
			updateSelectedSlot(4, width, true)
			updateSelectedSlot(5, height, true)
		elseif key == controls.resizeSticker_dec then
			local x, y = slot[2], slot[3]
			local width, height = slot[4], slot[5]
			local ratio = math.max(height/width, 0)
			local diffX, diffY = width, height
			width = width - controlSpeed.resizeSticker
			height = width * ratio
			width, height = tonumber(width) or 0, tonumber(height) or 0
			diffX, diffY = width - diffX, height - diffY
			diffX, diffY = tonumber(diffX or 0), tonumber(diffY or 0)
			x, y = tonumber(x - diffX/2) or 0, tonumber(y - diffY/2) or 0
			updateSelectedSlot(2, x, true)
			updateSelectedSlot(3, y, true)
			updateSelectedSlot(4, width, true)
			updateSelectedSlot(5, height, true)
		end
	elseif getKeyState(controls.rotateSticker_activate) then
		if key == controls.resizeSticker_inc then
			local rotation = slot[6]
			rotation = math.fmod(rotation + controlSpeed.rotateSticker, 360)
			updateSelectedSlot(6, rotation, true)
		elseif key == controls.resizeSticker_dec then
			local rotation = slot[6]
			rotation = math.fmod(rotation - controlSpeed.rotateSticker, 360)
			if rotation < 0 then
				rotation = 360 + rotation
			end
			updateSelectedSlot(6, rotation, true)
		end
	end
end)