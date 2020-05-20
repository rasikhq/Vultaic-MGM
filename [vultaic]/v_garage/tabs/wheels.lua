-- 'Wheels' tab
local settings = {id = 3, title = "Wheels"}
local content = nil
local wheels = {}
local items = {
	["button_apply"] = {type = "button", text = "Save", x = selector.width * 0.35, y = selector.height - 40, width = selector.width * 0.3, height = 35, backgroundColor = tocolor(25, 155, 255, 55), hoverColor = {25, 155, 255, 255}},
	["label_info"] = {type = "label", text = "Color", x = 10, y = 5, width = (selector.width - 20) * 0.5, height = 40},
	["input_hex"] = {type = "input", text = "#FFFFFFFF", x = selector.width * 0.5, y = 10, width = (selector.width - 20) * 0.5, height = 30, maxLength = 9},
	["colorpicker"] = {type = "colorpicker", x = 10, y = 55, width = selector.width - 20, height = 85},
	["gridlist_wheels"] = {type = "gridlist", x = 0, y = 160, width = selector.width, height = selector.height - 205}
}

-- Initialization
local function initTab()
	-- Tab registration
	content = selector.initTab(settings.id, settings, items)
	content.wheels = exports.v_wheels:getWheels()
	if type(content.wheels) ~= "table" then
		content.wheels = {}
	end
	local values = {}
	table.insert(values, 1, "Stock")
	for i = 2, #content.wheels do
		table.insert(values, tostring("Custom #"..(i - 1)))
	end
	dxlib.setGridlistContent(items["gridlist_wheels"], values)
	-- Functions
	-- 'apply'
	items["button_apply"].onClick = function()
		if not content.madeChanges then
			return triggerEvent("notification:create", localPlayer, "Tuning", "You did not make any changes yet")
		end
		if content.lastApplyTick and getTickCount() - content.lastApplyTick < 5000 then
			return triggerEvent("notification:create", localPlayer, "Tuning", "Please wait some while before saving your wheels again")
		end
		triggerServerEvent("updateWheels", localPlayer, wheels)
		content.lastApplyTick = getTickCount()
		resetElementData("wheels")
		content.madeChanges = nil
	end
	-- 'input'
	items["input_hex"].onTextChange = function(text)
		local r, g, b, a = hexToRGB(text)
		r, g, b, a = (r or 255)/255, (g or 255)/255, (b or 255)/255, (a or 255)/255
		wheels.wheels_color = rgbToHex(r * a, b * a, g * a)
		items["colorpicker"].r, items["colorpicker"].g, items["colorpicker"].b, items["colorpicker"].a = r, g, b, a
		updateWheelsColor()
	end
	items["colorpicker"].onUpdate = function(r, g, b, a)
		local hex = rgbToHex(r, g, b, 255 * a)
		items["input_hex"].text = hex
		wheels.wheels_color = hex
		updateWheelsColor()
	end
	items["gridlist_wheels"].onSelect = function(i)
		wheels.wheels_model = tonumber(content.wheels[i])
		updateWheels()
		return true
	end
end
addEventHandler("onClientResourceStart", resourceRoot, initTab)

-- Update wheels
function updateWheels(model)
	local wheel = model and model or wheels.wheels_model
	if wheel then
		addVehicleUpgrade(garage.vehicle, wheel)
	end
	content.madeChanges = true
end

function updateWheelsColor()
	local r, g, b = dxlib.getColorpickerRGB(items["colorpicker"], true)
	setVehicleColor(garage.vehicle, nil, nil, nil, nil, nil, nil, r, g, b)
	content.madeChanges = true
end

-- Cache wheels
function cacheWheels()
	wheels = getElementData(localPlayer, "wheels") or {}
	if type(wheels) ~= "table" then
		wheels = {}
	end
	local model = tonumber(wheels.wheels_model) or content.wheels[1]
	local color = wheels.wheels_color or "#FFFFFFFF"
	local r, g, b, a = hexToRGB(color)
	items["colorpicker"].r, items["colorpicker"].g, items["colorpicker"].b, items["colorpicker"].a = r/255, g/255, b/255, a/255
	items["input_hex"].text = color
	updateWheels(model)
	updateWheelsColor()
	content.madeChanges = nil
end
addEvent("garage:onInit", true)
addEventHandler("garage:onInit", localPlayer, cacheWheels)