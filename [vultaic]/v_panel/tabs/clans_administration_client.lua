-- 'Clan Administration' tab
local settings = {id = 2.3, title = "Clan Administration"}
local content = nil
local items = {
	["button_goback"] = {type = "button", text = "Return", x = 5, y = 5, width = 100, height = 35},
	["button_destroyclan"] = {type = "button", text = "Destroy", x = panel.width - 105, y = 5, width = 100, height = 35},
	["custom_infoblock"] = {type = "custom", x = panel.width * 0.1, y = panel.height * 0.15, width = panel.width * 0.8, height = panel.height * 0.2}, 
	["label_clanname"] = {type = "label", text = "Rename your clan ($50K)", x = panel.width * 0.1, y = panel.height * 0.3, width = panel.width * 0.2, height = 40, verticalAlign = "center"},
	["input_clanname"] = {type = "input", text = "How will be your clan called?", x = panel.width * 0.3, y = panel.height * 0.3, width = panel.width * 0.6, height = 40, maxLength = 36, backgroundColor = {0, 0, 0, 0}},
	["rectangle_clannameseperator"] = {type = "rectangle", x = panel.width * 0.1, y = panel.height * 0.3 + 39, width = panel.width * 0.8, height = 1, color = tocolor(255, 255, 255, 55)},
	["label_clancolor"] = {type = "label", text = "Re-colorize ($50K)", x = panel.width * 0.1, y = panel.height * 0.3 + 45, width = panel.width * 0.2, height = 40, verticalAlign = "center"},
	["input_clancolor"] = {type = "input", text = "#FFFFFF", x = panel.width * 0.3, y = panel.height * 0.3 + 45, width = panel.width * 0.6, height = 40, maxLength = 7, backgroundColor = {0, 0, 0, 0}},
	["rectangle_clancolorseperator"] = {type = "rectangle", x = panel.width * 0.1, y = panel.height * 0.3 + 84, width = panel.width * 0.8, height = 1, color = tocolor(255, 255, 255, 55)},
	["label_clandescription"] = {type = "label", text = "Change the description ($50K)", x = panel.width * 0.1, y = panel.height * 0.3 + 90, width = panel.width * 0.2, height = 40, verticalAlign = "center"},
	["input_clandescription"] = {type = "input", text = "#FFFFFF", x = panel.width * 0.3, y = panel.height * 0.3 + 90, width = panel.width * 0.6, height = 40, maxLength = 75, backgroundColor = {0, 0, 0, 0}},
	["button_update"] = {type = "button", text = "Update", x = panel.width * 0.5 - 100, y = panel.height - 40, width = 200, height = 35},
	["custom_colorpreview"] = {type = "custom", x = panel.width * 0.1 - 35, y = panel.height * 0.3 + 55, width = 20, height = 20}
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
-- Info text
local infoText = [[
	Welcome to your clan admin control panel, in this panel you can reconfigure your clan's important settings such as its name, color and update its description. Enter new configuration in the field which is required to be updated, and hit the update button to update.

	Important: Destroying the clan cannot be cancelled later. So please think twice before doing it.
]]

-- Initialization
local function initTab()
	-- Tab registration
	content = panel.initTab(settings.id, settings, items)
	-- Customization
	items["custom_infoblock"].renderingFunction = function(x, y, item)
		dxDrawText(infoText, x, y, x + item.width, y + item.height, tocolor(255, 255, 255, 255), item.fontScale, item.font, "center", "top", true, true)
	end
	items["custom_colorpreview"].renderingFunction = function(x, y, item)
		local color = content.previewColor or {255, 255, 255}
		dxDrawImage(x, y, item.width, item.height, "img/circle.png", 0, 0, 0, tocolor(color[1], color[2], color[3], 255))
	end
	-- Functions
	-- 'return'
	items["button_goback"].onClick = function()
		panel.switch(2.1)
	end
	-- 'input'
	items["input_clancolor"].onTextChange = function(text)
		local r, g, b = hexToRGB(text)
		if r and g and b then
			content.previewColor = {r, g, b}
		else
			content.previewColor = nil
		end
		updateConfiguration()
	end
	items["input_clanname"].onTextChange = function()
		updateConfiguration()
	end
	items["input_clandescription"].onTextChange = function()
		updateConfiguration()
	end
	-- 'update'
	items["button_update"].onClick = function()
		if content.lastAttemptTick and getTickCount() - content.lastAttemptTick < 2000 then
			return triggerEvent("notification:create", "Clan", "You can't make too many attempts in a row, please wait")
		end
		if not content.configuration then
			return triggerEvent("notification:create", localPlayer, "Clan", "You didn't change anything")
		end
		if content.configuration.ClanName and #content.configuration.ClanName:gsub(" ", "") < 3 then
			return triggerEvent("notification:create", localPlayer, "Clan", "Clan name should contain minimum 3 letters")
		end
		if content.configuration.description and #content.configuration.description:gsub(" ", "") < 8 then
			return triggerEvent("notification:create", localPlayer, "Clan", "Your description is too short")
		end
		triggerServerEvent("Clan:onClanUpdateConfig", localPlayer, content.clan.id, content.configuration)
		content.lastAttemptTick = getTickCount()
	end
	-- 'destroy'
	items["button_destroyclan"].onClick = function()
		triggerServerEvent("Clan:onClanDestroy", localPlayer, content.clan.id)
	end
end
addEventHandler("onClientResourceStart", resourceRoot, initTab)

-- Update cache
function updateAdministrationCache(clan)
	if clan then
		content.clan = clan
	else
		return
	end
	items["input_clanname"].text = content.clan.name
	items["input_clancolor"].text = content.clan.colorHex
	items["input_clandescription"].text = content.clan.data.description
end

-- Config
function updateConfiguration()
	local name = items["input_clanname"].text
	local color = content.previewColor
	local description = items["input_clandescription"].text
	if name or color or description then
		if not content.configuration then
			content.configuration = {}
		end
		if name and name ~= "" then
			content.configuration.ClanName = name
		else
			content.configuration.ClanName = nil
		end
		if color then
			local hex = string.format("#%.2X%.2X%.2X", unpack(color))
			content.configuration.ClanColor = hex
		else
			content.configuration.ClanColor = nil
		end
		if description and description ~= "" then
			content.configuration.description = description
		else
			content.configuration.description = nil
		end
	else
		content.configuration = nil
	end
end