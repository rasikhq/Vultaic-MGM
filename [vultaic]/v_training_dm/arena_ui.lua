selector = {}
selector.width, selector.height = math.floor(1200 * relativeScale), math.floor(720 * math.min(math.max(screenHeight/900, 0.5), 1))
selector.width, selector.height = selector.width - (selector.width % 10), selector.height - (selector.height % 10)
selector.x, selector.y = (screenWidth - selector.width)/2, (screenHeight - selector.height)/2
selector.fontScale = 1
selector.font = dxlib.getFont("Roboto-Regular", 13)
selector.fontHeight = dxGetFontHeight(selector.fontScale, selector.font)
selector.interpolator = "Linear"
local container = nil
local mapFromID = {}
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
local items = {
	["rectangle_header"] = {type = "rectangle", x = 0, y = 0, width = selector.width, height = selector.fontHeight * 2, color = tocolor(25, 25, 25, 245)},
	["label_title"] = {type = "label", text = "Select a map to train", x = selector.width * 0.0 + 15, y = 0, width = selector.width * 0.9 - 20, height = selector.fontHeight * 2, font = dxlib.getFont("Roboto-Regular", 13)},
	["input_search"] = {type = "input", placeholder = "or search", x = selector.width * 0.75 - 5, y = 5, width = selector.width * 0.25, height = selector.fontHeight * 2 - 10, horizontalAlign = "right"},
	["gridlist_maps"] = {type = "gridlist", x = 0, y = selector.fontHeight * 2, width = selector.width, height = selector.height - selector.fontHeight * 2 - 45, columns = 2, customBlockHeight = selector.fontHeight * 3},
	["button_train"] = {type = "button", text = "Train selected map", x = selector.width * 0.8 - 5, y = selector.height - 40, width = selector.width * 0.2, height = 35},
	["button_resume"] = {type = "button", text = "Resume", x = selector.width * 0.7 - 10, y = selector.height - 40, width = selector.width * 0.1, height = 35, backgroundColor = tocolor(255, 25, 0, 55), hoverColor = {255, 25, 0, 255}}
}
setElementData(localPlayer, "selector.visible", selector.visible, false)

addEventHandler("onClientResourceStart", resourceRoot,
function()
	container = dxlib.createContainer({title = "selector", x = selector.x, y = selector.y, width = selector.width, height = selector.height})
	if container then
		for i, item in pairs(items) do
			dxlib.registerItem(container.id, item)
		end
	end
	selector.replaceShader = dxCreateShader("fx/txReplace.fx")
	selector.renderTarget = dxCreateRenderTarget(selector.width, selector.height, true)
	items["input_search"].onTextChange = function(text)
		selector.applyMapFilter(text)
	end
	items["button_train"].onClick = function()
		local _, id = dxlib.getGridlistSelectedRow(items["gridlist_maps"])
		local map = mapFromID[id]
		if map then
			triggerServerEvent("training:onClientRequestTrainMap", resourceRoot, map)
		end
	end
	items["button_resume"].onClick = function()
		if arena.clientDriving then
			selector.hide()
			showChat(true)
			triggerEvent("blur:disable", localPlayer, "training")
		end
	end
end)

function selector.show()
	if selector.visible then
		return
	end
	selector.tick = getTickCount()
	selector.visible = true
	dxlib.activate()
	dxlib.setActiveContainer(container.id)
	showCursor(true)
	showChat(false)
	removeEventHandler("onClientRender", root, selector.render)
	addEventHandler("onClientRender", root, selector.render, true, "low-2")
	guiSetInputMode("allow_binds")
	setElementData(localPlayer, "selector.visible", selector.visible, false)
	triggerEvent("lobby:updateTime", localPlayer)
end

function selector.hide()
	if not selector.visible then
		return
	end
	selector.tick = getTickCount()
	selector.visible = false
	dxlib.deactivate()
	showCursor(false)
	guiSetInputMode("allow_binds")
	setElementData(localPlayer, "selector.visible", selector.visible, false)
end

function selector.displayMaps(data)
	if type(data) == "table" then
		mapFromID = {}
		local maps = {}
		local i = 1
		for resourceName, mapName in pairs(data) do
			mapFromID[i] = resourceName
			table.insert(maps, mapName)
			i = i + 1
		end
		dxlib.setGridlistContent(items["gridlist_maps"], maps)
	end
end

function selector.applyMapFilter(filter)
	if filter == "" then
		mapFromID = {}
		local i = 1
		local data = {}
		for resourceName, mapName in pairs(arena.maps) do
			table.insert(data, mapName)
			mapFromID[i] = resourceName
			i = i + 1
		end
		dxlib.setGridlistContent(items["gridlist_maps"], data)
		return
	end
	if type(arena.maps) == "table" then
		local filter = filter:gsub("#%x%x%x%x%x%x", ""):lower()
		mapFromID = {}
		local i = 1
		local data = {}
		for resourceName, mapName in pairs(arena.maps) do
			if mapName:gsub("#%x%x%x%x%x%x", ""):lower():find(filter, 1, true) then
				table.insert(data, mapName)
				mapFromID[i] = resourceName
				i = i + 1
			end
		end
		dxlib.setGridlistContent(items["gridlist_maps"], data)
	end
end

function selector.render()
	local currentTick = getTickCount()
	local tick = selector.tick or 0
	selector.progress = interpolateBetween(selector.progress or 0, 0, 0, selector.visible and 1 or 0, 0, 0, math_min(1000, currentTick - tick)/1000, selector.interpolator)
	if not selector.visible and selector.progress == 0 then
		removeEventHandler("onClientRender", root, selector.render)
		return
	end
	local renderTarget = dxlib.renderContainer(container.id, selector.renderTarget)
	dxSetShaderValue(selector.replaceShader, "tex", renderTarget)
	dxSetShaderTransform(selector.replaceShader, 0, -10 * (1 - selector.progress), 0)
	dxDrawImage(selector.x, selector.y, selector.width, selector.height, selector.replaceShader, 0, 0, 0, tocolor(255, 255, 255, 255 * selector.progress), false)
end