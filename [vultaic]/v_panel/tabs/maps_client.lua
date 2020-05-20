-- 'Maps' tab
local settings = {id = 3, title = "Maps"}
local content = nil
local items = {
	["input_search"] = {type = "input", placeholder = "Search for a map...", x = 0, y = 0, width = panel.width, height = panel.fontHeight * 2, maxLength = 20},
	["gridlist_maps"] = {type = "gridlist", x = 0, y = panel.fontHeight * 2, width = panel.width, height = panel.height - panel.fontHeight * 2 - 50, customBlockHeight = panel.fontHeight * 3, columns = 2},
	["button_buymap"] = {type = "button", text = "Buy for $5K", hoverText = "$2.5K for donators", x = panel.width * 0.375, y = panel.height - 45, width = panel.width * 0.25, height = 35}
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
	content.rankSize = 10
end

local function initTab()
	-- Tab registration
	content = panel.initTab(settings.id, settings, items)
	precacheStuff()
	-- Customization
	items["gridlist_maps"].customBlockRendering = function(x, y, row, item, i)
		local map = content.mapFromID[i]
		local locked = map and content.lockedMaps[map] and true or false
		if locked then
			dxDrawRectangle(x, y, item.blockWidth, item.blockHeight, tocolor(255, 0, 0, 25))
		end
		dxDrawText(row.text, x + 10, y, x + item.blockWidth - 10, y + item.blockHeight, tocolor(255, 255, 255, 255), item.fontScale, item.font, "left", "center", true)
	end
	-- Functions
	-- 'search'
	items["input_search"].onTextChange = function(text)
		applyMapFilter(text)
	end
	-- 'buy map'
	items["button_buymap"].onClick = function()
		local row, id = dxlib.getGridlistSelectedRow(items["gridlist_maps"])
		if id and content.mapFromID[id] then
			triggerServerEvent("panel:onPlayerRequestBuyMap", localPlayer, content.mapFromID[id])
		end
	end
	content.maps, content.mapFromID, content.lockedMaps = {}, {}, {}
	if getElementData(localPlayer, "arena") ~= nil and getElementData(localPlayer, "arena") ~= "lobby" then
		triggerServerEvent("panel:onPlayerRequestMaps", localPlayer)
	end
end
addEventHandler("onClientResourceStart", resourceRoot, initTab)

-- Updates on panel's state changed
addEvent("panel:onVisibilityChanged", true)
addEventHandler("panel:onVisibilityChanged", localPlayer,
function(state)
	if state then
		local parent = getElementParent(localPlayer)
		if parent and getElementData(parent, "gamemode") == "race" and not content.requestedMaps then
			triggerServerEvent("panel:onPlayerRequestMaps", localPlayer)
			content.requestedMaps = true
		end
	end
end)

addEvent("core:onClientLeaveArena", true)
addEventHandler("core:onClientLeaveArena", localPlayer,
function()
	content.maps, content.mapFromID, content.lockedMaps = {}, {}, {}
	dxlib.setGridlistContent(items["gridlist_maps"], {})
	content.requestedMaps = nil
end)

-- Receive and store maps
addEvent("panel:onClientReceiveMaps", true)
addEventHandler("panel:onClientReceiveMaps", resourceRoot,
function(maps, lockData)
	local maps = fromJSON(maps)
	if type(maps) ~= "table" then
		return
	end
	content.maps, content.mapFromID = maps, {}
	local i = 1
	local data = {}
	for resourceName, mapName in pairs(maps) do
		table.insert(data, mapName)
		content.mapFromID[i] = resourceName
		i = i + 1
	end
	cacheLockedMaps(lockData)
	dxlib.setGridlistContent(items["gridlist_maps"], data)
end)

-- Search filter
function applyMapFilter(filter)
	if filter == "" then
		content.mapFromID = {}
		local i = 1
		local data = {}
		for resourceName, mapName in pairs(content.maps) do
			table.insert(data, mapName)
			content.mapFromID[i] = resourceName
			i = i + 1
		end
		dxlib.setGridlistContent(items["gridlist_maps"], data)
		return
	end
	if type(content.maps) == "table" then
		local filter = filter:gsub("#%x%x%x%x%x%x", ""):lower()
		content.mapFromID = {}
		local i = 1
		local data = {}
		for resourceName, mapName in pairs(content.maps) do
			if mapName:gsub("#%x%x%x%x%x%x", ""):lower():find(filter, 1, true) then
				table.insert(data, mapName)
				content.mapFromID[i] = resourceName
				i = i + 1
			end
		end
		dxlib.setGridlistContent(items["gridlist_maps"], data)
	end
end

-- Lock cache
function cacheLockedMaps(data)
	if type(data) == "table" then
		content.lockedMaps = {}
		for i, v in pairs(data) do
			content.lockedMaps[i] = true
		end
	end
end

addEvent("panel:onClientReceiveLockTable", true)
addEventHandler("panel:onClientReceiveLockTable", resourceRoot,
function(data)
	cacheLockedMaps(data)
end)