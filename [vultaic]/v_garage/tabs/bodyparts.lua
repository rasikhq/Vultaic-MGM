-- 'Body Parts' tab
local settings = {id = 4, title = "Body Parts"}
local content = nil
local bodyparts = {}
local items = {
	["button_apply"] = {type = "button", text = "Save", x = selector.width * 0.35, y = selector.height - 40, width = selector.width * 0.3, height = 35, backgroundColor = tocolor(25, 155, 255, 55), hoverColor = {25, 155, 255, 255}},
	["label_bumper_front"] = {type = "label", text = "Front bumper", x = 10, y = 5, width = (selector.width - 20) * 0.4, height = 40},
	["selector_bumper_front"] = {type = "selector", values = {"Stock", "Custom #1", "Custom #2", "Custom #3", "Custom #4"}, x = selector.width * 0.4, y = 5, width = (selector.width - 20) * 0.6, height = 40},
	["label_bumper_rear"] = {type = "label", text = "Rear bumper", x = 10, y = 50, width = (selector.width - 20) * 0.4, height = 40},
	["selector_bumper_rear"] = {type = "selector", values = {"Stock", "Custom #1", "Custom #2", "Custom #3", "Custom #4"}, x = selector.width * 0.4, y = 50, width = (selector.width - 20) * 0.6, height = 40},
	["label_roof"] = {type = "label", text = "Roof", x = 10, y = 95, width = (selector.width - 20) * 0.4, height = 40},
	["selector_roof"] = {type = "selector", values = {"Stock", "Semi roadster", "Roadster"}, x = selector.width * 0.4, y = 95, width = (selector.width - 20) * 0.6, height = 40},
	["label_side_skirt"] = {type = "label", text = "Side skirts", x = 10, y = 140, width = (selector.width - 20) * 0.4, height = 40},
	["selector_side_skirt"] = {type = "selector", values = {"None", "Custom #1", "Custom #2"}, x = selector.width * 0.4, y = 140, width = (selector.width - 20) * 0.6, height = 40},
	["label_spoiler"] = {type = "label", text = "Spoiler", x = 10, y = 185, width = (selector.width - 20) * 0.4, height = 40},
	["selector_spoiler"] = {type = "selector", values = {"Stock", "None", "Custom #1", "Custom #2", "Custom #3", "Custom #4", "Custom #5", "Custom #6"}, x = selector.width * 0.4, y = 185, width = (selector.width - 20) * 0.6, height = 40},
	["label_podium"] = {type = "label", text = "Podium", x = 10, y = 230, width = (selector.width - 20) * 0.4, height = 40},
	["selector_podium"] = {type = "selector", values = {"Visible", "Invisible"}, x = selector.width * 0.4, y = 230, width = (selector.width - 20) * 0.6, height = 40},
	["label_cover_headlights"] = {type = "label", text = "Covers (front)", x = 10, y = 275, width = (selector.width - 20) * 0.4, height = 40},
	["selector_cover_headlights"] = {type = "selector", values = {"None", "Type #1", "Type #2", "Type #3"}, x = selector.width * 0.4, y = 275, width = (selector.width - 20) * 0.6, height = 40},
	["label_cover_taillights"] = {type = "label", text = "Covers (tail)", x = 10, y = 320, width = (selector.width - 20) * 0.4, height = 40},
	["selector_cover_taillights"] = {type = "selector", values = {"None", "Type #1", "Type #2", "Type #3"}, x = selector.width * 0.4, y = 320, width = (selector.width - 20) * 0.6, height = 40}
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
			return triggerEvent("notification:create", localPlayer, "Tuning", "Please wait some while before saving your body parts again")
		end
		triggerServerEvent("updateBodyparts", localPlayer, bodyparts)
		content.lastApplyTick = getTickCount()
		resetElementData("bodyparts")
		content.madeChanges = nil
	end
	-- 'updates'
	items["selector_bumper_front"].onSelect = function(id)
		bodyparts.bumper_front = tonumber(id - 1)
		setElementData(localPlayer, "bodyparts", bodyparts)
		content.madeChanges = true
	end
	items["selector_bumper_rear"].onSelect = function(id)
		bodyparts.bumper_rear = tonumber(id - 1)
		setElementData(localPlayer, "bodyparts", bodyparts)
		content.madeChanges = true
	end
	items["selector_roof"].onSelect = function(id)
		bodyparts.roof = tonumber(id - 1)
		setElementData(localPlayer, "bodyparts", bodyparts)
		content.madeChanges = true
	end
	items["selector_side_skirt"].onSelect = function(id)
		bodyparts.side_skirt = tonumber(id - 1)
		setElementData(localPlayer, "bodyparts", bodyparts)
		content.madeChanges = true
	end
	items["selector_spoiler"].onSelect = function(id)
		bodyparts.spoiler = id == 1 and 0 or (id == 2 and -1 or tonumber(id - 2))
		setElementData(localPlayer, "bodyparts", bodyparts)
		content.madeChanges = true
	end
	items["selector_podium"].onSelect = function(id)
		bodyparts.podium = id == 1 and 1 or 0
		setElementData(localPlayer, "bodyparts", bodyparts)
		content.madeChanges = true
	end
	items["selector_cover_headlights"].onSelect = function(id)
		bodyparts.cover_headlights = tonumber(id - 1)
		setElementData(localPlayer, "bodyparts", bodyparts)
		content.madeChanges = true
	end
	items["selector_cover_taillights"].onSelect = function(id)
		bodyparts.cover_taillights = tonumber(id - 1)
		setElementData(localPlayer, "bodyparts", bodyparts)
		content.madeChanges = true
	end
end
addEventHandler("onClientResourceStart", resourceRoot, initTab)

-- Cache body
function cacheVehicleBody()
	bodyparts = getElementData(localPlayer, "bodyparts")
	bodyparts = type(bodyparts) == "table" and bodyparts or {}
	if type(bodyparts) == "table" then
		items["selector_bumper_front"].currentID = tonumber(bodyparts.bumper_front or 0) + 1
		items["selector_bumper_rear"].currentID = tonumber(bodyparts.bumper_rear or 0) + 1
		items["selector_roof"].currentID = tonumber(bodyparts.roof or 0) + 1
		items["selector_side_skirt"].currentID = tonumber(bodyparts.side_skirt or 0) + 1
		local i = tonumber(bodyparts.spoiler or 0) 
		items["selector_spoiler"].currentID = i == 0 and 1 or (i == -1 and 2 or i + 2)
		items["selector_podium"].currentID = tonumber(bodyparts.podium or 1) == 1 and 1 or 2
		items["selector_cover_headlights"].currentID = tonumber(bodyparts.cover_headlights or 0) + 1
		items["selector_cover_taillights"].currentID = tonumber(bodyparts.cover_taillights or 0) + 1
	end
end
addEvent("garage:onInit", true)
addEventHandler("garage:onInit", localPlayer, cacheVehicleBody)