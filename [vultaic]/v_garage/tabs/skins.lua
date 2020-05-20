-- 'Skin' tab
local settings = {id = 10, title = "Skins"}
local content = nil
local items = {
	["button_apply"] = {type = "button", text = "Save", x = selector.width * 0.35, y = selector.height - 40, width = selector.width * 0.3, height = 35, backgroundColor = tocolor(25, 155, 255, 55), hoverColor = {25, 155, 255, 255}},
	["gridlist_skins"] = {type = "gridlist", x = 0, y = 0, width = selector.width, height = selector.height - 45},
}
local skins = {
	[0] = "CJ",
	[1] = "Truth",
	[2] = "Maccer",
	[7] = "Casual Jeanjacket",
	[9] =  "Business Lady",
	[10] = "Old Fat Lady",
	[11] = "Card Dealer",
	[12] = "Classy Gold Hooker",
	[13] = "Homegirl",
	[14] = "Floral Shirt",
	[15] = "Plaid Baldy",
	[16] = "Earmuff Worker",
	[17] = "Black suit",
	[18] = "Black Beachguy",
	[19] = "Beach Gangsta",
	[20] = "Fresh Prince",
	[21] = "Striped Gangsta",
	[22] = "Orange Sportsman",
	[23] = "Skater Kid",
	[24] = "LS Coach",
	[25] = "Varsity Jacket",
	[26] = "Hiker",
	[27] = "Construction 1",
	[28] = "Black Dealer",
	[29] = "White Dealer",
	[30] = "Religious Essey",
	[31] = "Fat Cowgirl",
	[32] = "Eyepatch",
	[33] = "Bounty Hunter"
}

-- Initialization
local function initTab()
	-- Tab registration
	content = selector.initTab(settings.id, settings, items)
	local names = {}
	modelFromID = {}
	local k = 1
	for model, name in pairs(skins) do
		table.insert(names, name)
		modelFromID[k] = model
		k = k + 1
	end
	dxlib.setGridlistContent(items["gridlist_skins"], names)
	-- Functions
	-- 'apply'
	items["button_apply"].onClick = function()
		if not content.madeChanges then
			return triggerEvent("notification:create", localPlayer, "Tuning", "You did not make any changes yet")
		end
		if content.lastApplyTick and getTickCount() - content.lastApplyTick < 5000 then
			return triggerEvent("notification:create", localPlayer, "Tuning", "Please wait some while before saving your skin again")
		end
		local skin = getElementModel(garage.ped)
		triggerServerEvent("updateSkins", localPlayer, skin)
		content.lastApplyTick = getTickCount()
		content.madeChanges = nil
	end
	items["gridlist_skins"].onSelect = function(i)
		previewSkin(modelFromID[i])
		content.madeChanges = true
	end
end
addEventHandler("onClientResourceStart", resourceRoot, initTab)

function previewSkin(model)
	setElementModel(garage.ped, tonumber(model))
	triggerEvent("shellPed", localPlayer, garage.ped)
end

-- Get skin
function getSkin()
	local skin = getElementData(localPlayer, "custom_skin")
	if skin then
		previewSkin(skin)
	end
	content.madeChanges = nil
end
addEvent("garage:onInit", true)
addEventHandler("garage:onInit", localPlayer, getSkin)