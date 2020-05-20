-- 'Clan Registration' tab
local settings = {id = 2.2, title = "Clan Registration"}
local content = nil
local items = {
	["rectangle_header"] = {type = "rectangle", x = 0, y = 0, width = panel.width, height = panel.height * 0.2, color = tocolor(25, 25, 25, 245)},
	["button_goback"] = {type = "button", text = "Return", x = 5, y = 5, width = 100, height = 35},
	["gridlist_information"] = {type = "gridlist", x = panel.width * 0.5 + 5, y = panel.height * 0.2, width = panel.width * 0.5 - 5, height = panel.height * 0.8 - 50, readOnly = true, customBlockHeight = panel.fontHeight * 3, blockColor = {0, 0, 0, 0}},
	["input_clanname"] = {type = "input", placeholder = "How will your clan be called?", x = 0, y = panel.height * 0.2 - panel.fontHeight * 2 - 5, width = panel.width, height = panel.fontHeight * 2, font = dxlib.getFont("Roboto-Medium", 16), maxLength = 36, horizontalAlign = "center", backgroundColor = {0, 0, 0, 0}},
	["input_clancolor"] = {type = "input", placeholder = "Color code (hex)", x = 0, y = panel.height * 0.2 + 10, width = panel.width * 0.5 - 25, height = 40, maxLength = 7, backgroundColor = {0, 0, 0, 0}},
	["rectangle_seperator"] = {type = "rectangle", x = 10, y = panel.height * 0.2 + 55, width = panel.width * 0.5 - 20, height = 1, color = tocolor(255, 255, 255, 55)},
	["input_description"] = {type = "input", placeholder = "Short description", x = 0, y = panel.height * 0.2 + 60, width = panel.width * 0.5 - 5, height = 40, maxLength = 75, backgroundColor = {0, 0, 0, 0}},
	["custom_colorpreview"] = {type = "custom", x = panel.width * 0.5 - 25, y = panel.height * 0.2 + 20, width = 20, height = 20},
	["button_create"] = {type = "button", text = "Create", x = panel.width * 0.375, y = panel.height - 45, width = panel.width * 0.25, height = 35}
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
-- Infos
local information = {
	"Registration costs $250K for donators and $500K for regular users",
	"You can rename your clan for $10K",
	"You can re-colorize your clan for $10K",
	"You can invite, promote, demote and kick players anytime"
}

-- Calculations
local function precacheStuff()
	content.circleSize = math.floor(items["gridlist_information"].blockHeight * 0.65)
	content.circleOffset = (items["gridlist_information"].blockHeight - content.circleSize)/2
	content.iconSize = content.circleSize * 0.4
	content.iconOffset = (content.circleSize - content.iconSize)/2
end

-- Initialization
local function initTab()
	-- Tab registration
	content = panel.initTab(settings.id, settings, items)
	precacheStuff()
	dxlib.setGridlistContent(items["gridlist_information"], information)
	-- Customization
	items["custom_colorpreview"].renderingFunction = function(x, y, item)
		local color = content.previewColor or {255, 255, 255}
		dxDrawImage(x, y, item.width, item.height, "img/circle.png", 0, 0, 0, tocolor(color[1], color[2], color[3], 255))
	end
	items["gridlist_information"].customBlockRendering = function(x, y, row, item, i)
		dxDrawImage(x + 10, y + content.circleOffset, content.circleSize, content.circleSize, "img/circle.png", 0, 0, 0, tocolor(25, 132, 109, 105))
		dxDrawImageSection(x + 10 + content.iconOffset, y + content.circleOffset + content.iconOffset, content.iconSize, content.iconSize, 1, 1, 46, 46, "img/info.png", 0, 0, 0, tocolor(255, 255, 255, 255))
		dxDrawText(row.text, x + content.circleSize + 20, y, x + item.blockWidth, y + item.blockHeight, tocolor(255, 255, 255, 255), item.fontScale, item.font, "left", "center", true, true)
	end
	-- Functions
	-- 'return'
	items["button_goback"].onClick = function()
		panel.switch(math.floor(settings.id))
	end
	-- 'input'
	items["input_clancolor"].onTextChange = function(text)
		local r, g, b = hexToRGB(text)
		content.previewColor = {r or 255, g or 255, b or 255}
	end
	-- 'create'
	items["button_create"].onClick = function()
		if content.lastAttemptTick and getTickCount() - content.lastAttemptTick < 2000 then
			return triggerEvent("notification:create", localPlayer, "Clan", "You can't make too many attempts in a row, please wait")
		end
		local name = items["input_clanname"].text or ""
		local color = content.previewColor or {255, 255, 255}
		color = string.format("#%.2X%.2X%.2X", unpack(color))
		local description = items["input_description"].text or ""
		if #name:gsub(" ", "") < 3 then
			return triggerEvent("notification:create", localPlayer, "Clan", "Clan name should contain minimum 3 letters")
		end
		if not color then
			return triggerEvent("notification:create", localPlayer, "Clan", "Failed to convert color, please retry")
		end
		if #description:gsub(" ", "") < 8 then
			return triggerEvent("notification:create", localPlayer, "Clan", "Your description is too short")
		end
		content.clanName = name
		triggerServerEvent("Clan:onClanCreate", localPlayer, name, color, {description = description})
		triggerEvent("notification:create", localPlayer, "Clan", "Please wait while your clan is being registered...")
		content.lastAttemptTick = getTickCount()
	end
end
addEventHandler("onClientResourceStart", resourceRoot, initTab)

-- Catch creation of clan
addEvent("Clans:onClanCreate", true)
addEventHandler("Clans:onClanCreate", localPlayer,
function(errorCode, messageCode)
	if errorCode == 0 then
		panel.switch(math.floor(settings.id))
		triggerEvent("notification:create", localPlayer, "Clan", "Your clan "..content.clanName.." has been successfully created. You can access the ACP from 'Clans' tab")
	else
		if messageCode == 1 then
			triggerEvent("notification:create", localPlayer, "Clan", "You don't have enough money to create a clan")
		elseif messageCode == 2 then
			triggerEvent("notification:create", localPlayer, "Clan", "A clan with this name is already registered")
		end
	end
end)