-- 'Achievements' tab
local settings = {id = 4, title = "Achievements"}
local content = nil
local guestText = [[You are not logged in.
Please register at www.vultaic.com
]]
local items = {
	["custom_progress"] = {type = "custom", x = 0, y = 0, width = panel.width, height = panel.height * 0.1, font = dxlib.getFont("RobotoCondensed-Regular", 16)},
	["gridlist_achievements"] = {type = "gridlist", x = 0, y = panel.height * 0.1, width = panel.width, height = panel.height * 0.9, customBlockHeight = panel.fontHeight * 4.5, columns = (screenWidth < 1000 and 1 or 2), font = dxlib.getFont("Roboto-Regular", 11), readOnly = true},
	["label_guest"] = {type = "label", text = guestText, x = 0, y = 0, width = panel.width, height = panel.height, font = dxlib.getFont("RobotoCondensed-Regular", 18), horizontalAlign = "center", verticalAlign = "center"}
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

-- Calculations
local function precacheStuff()
	content.imageSize = math.floor(items["gridlist_achievements"].blockHeight * 0.45)
	content.imageOffset = (items["gridlist_achievements"].blockHeight - content.imageSize)/2
end

-- Initialization
local function initTab()
	-- Tab registration
	content = panel.initTab(settings.id, settings, items)
	precacheStuff()
	-- Customization
	items["custom_progress"].renderingFunction = function(x, y, item)
		if not content.notLogged then
			local width = item.width * content.achievementsProgress * content.progress
			dxDrawRectangle(x, y, item.width, item.height, tocolor(255, 255, 255, 5))
			dxDrawRectangle(x, y, width, item.height, tocolor(25, 132, 109, 255))
			dxDrawText(content.progressText, x, y, x + item.width, y + item.height, tocolor(255, 255, 255, 255 * content.progress), item.fontScale, item.font, "center", "center", true)
		end
	end
	items["gridlist_achievements"].customBlockRendering = function(x, y, row, item, i)
		local progress = content.data[i].progress
		progress = progress and math.floor(progress * 100)/100 or 0
		local offset = x + 10
		local image = "img/uncompleted.png"
		local r, g, b = 255, 25, 0
		if content.data[i].completed then
			image = "img/completed.png"
			r, g, b = 25, 132, 109
		end
		if progress and progress > 0 then
			local r, g, b = 255, 255, 255
			if content.data[i].completed then
				r, g, b = 25, 132, 109
			end
			dxDrawRectangle(x, y + item.blockHeight - 4, item.blockWidth * progress, 4, tocolor(r, g, b, 255))
		end
		dxDrawImageSection(offset, y + content.imageOffset, content.imageSize, content.imageSize, 1, 1, 46, 46, image, 0, 0, 0, tocolor(r, g, b, 255))
		offset = offset + content.imageSize + 10
		dxDrawText(row.text, offset, y, x + item.blockWidth, y + item.blockHeight * 0.5 - 2.5, tocolor(255, 255, 255, 255), item.fontScale, dxlib.getFont("RobotoCondensed-Regular", 14), "left", "bottom", true)
		dxDrawText(tostring(content.data[i].description or "no description"), offset, y + item.blockHeight * 0.5 + 2.5, x + item.blockWidth - 5, y + item.blockHeight, tocolor(255, 255, 255, 155), item.fontScale, item.font, "left", "top", true)
		if not content.data[i].completed then
			dxDrawText("completed "..tostring(progress * 100).."%", x, y, x + item.blockWidth - 10, y + item.blockHeight - 10, tocolor(255, 255, 255, 155), item.fontScale, dxlib.getFont("Roboto-Regular", 10), "right", "bottom", true)
		end
	end
	updateAchievements()
end
addEventHandler("onClientResourceStart", resourceRoot, initTab)

-- Catch updates
function updateAchievements()
	local achievements = getElementData(localPlayer, "LoggedIn") and exports.v_achievements:getPlayerAchievements() or nil
	local data = {}
	if type(achievements) == "table" then
		content.unlocked, content.total = 0, #achievements
		content.data = {}
		for i, achievement in pairs(achievements) do
			local progress = nil
			local dataName = achievement.elementData
			local goal = tonumber(achievement.goal)
			if dataName and goal then
				local value = tonumber(getElementData(localPlayer, dataName) or exports.v_mysql:getPlayerStats_data(dataName))
				if value then
					progress = math.max(math.min(value/goal, 1), 0)
				end
			end
			table.insert(data, achievement.name)
			content.data[i] = {description = achievement.description, completed = achievement.completed, progress = progress}
			if achievement.completed then
				content.unlocked = content.unlocked + 1
			end
		end
		content.notLogged = nil
		content.achievementsProgress = content.unlocked/content.total
		content.progressText = "Unlocked "..content.unlocked.." "..(content.unlocked == 1 and "achievement" or "achievements").." of "..content.total
		dxlib.setGridlistContent(items["gridlist_achievements"], data)
		dxlib.setItemVisible(content, items["custom_progress"], true)
		dxlib.setItemVisible(content, items["gridlist_achievements"], true)
		dxlib.setItemVisible(content, items["label_guest"], false)
	else
		content.notLogged = true
		content.achievementsProgress = 0
		dxlib.setItemVisible(content, items["custom_progress"], false)
		dxlib.setItemVisible(content, items["gridlist_achievements"], false)
		dxlib.setItemVisible(content, items["label_guest"], true)
	end
end
addEvent("Achievements:onClientUnlockAchievement", true)
addEventHandler("Achievements:onClientUnlockAchievement", localPlayer, updateAchievements)