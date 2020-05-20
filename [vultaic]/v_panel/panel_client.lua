panel = {}
panel.width, panel.height = math.floor(1200 * relativeScale), math.floor(720 * math.min(math.max(screenHeight/900, 0.5), 1))
panel.width, panel.height = panel.width - (panel.width % 10), panel.height - (panel.height % 10)
panel.x, panel.y = (screenWidth - panel.width)/2, (screenHeight - panel.height)/2
panel.fontScale = 1
panel.font = dxlib.getFont("RobotoCondensed-Regular", 13)
panel.fontHeight = dxGetFontHeight(panel.fontScale, panel.font)
panel.sliderPadding = 2
panel.sliderHeight = panel.fontHeight + 10
panel.sliderOffset = panel.y - panel.sliderHeight - panel.sliderPadding
panel.interpolator = "Linear"
panel.tabs = {}
panel.sliderItems = {}
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

function panel.initTab(id, settings, items)
	if not id or (id and panel.tabs[id]) then
		return
	end
	local settings = settings or {}
	local data = {}
	for i, v in pairs(settings) do
		data[i] = v
	end
	local subContainer = id - math.floor(id) > 0
	data.x = panel.x
	data.y = panel.y
	data.width = panel.width
	data.height = panel.height
	data.title = data.title or "Tab #"..#panel.tabs
	local container = dxlib.createContainer(data)
	if container then
		for i, item in pairs(items) do
			dxlib.registerItem(container.id, item)
		end
		panel.tabs[id] = container
		if not subContainer then
			local sliderItemsOffset = panel.sliderItemsOffset or 0
			local item = {id = id, title = container.title}
			item.width = dxGetTextWidth(container.title:gsub("#%x%x%x%x%x%x", ""), panel.fontScale, panel.font) + 20
			item.offset = sliderItemsOffset
			panel.sliderItems[id] = item
			panel.sliderItemsOffset = sliderItemsOffset + item.width + panel.sliderPadding
		end
		return panel.tabs[id]
	end
end

addEventHandler("onClientResourceStart", resourceRoot,
function()
	panel.replaceShader = dxCreateShader("fx/txReplace.fx")
	panel.renderTarget_current = dxCreateRenderTarget(panel.width, panel.height, true)
	panel.renderTarget_previous = dxCreateRenderTarget(panel.width, panel.height, true)
end)

function panel.toggle()
	if panel.visible then
		panel.hide()
	else
		panel.show()
	end
end

function panel.switch(id)
	local savedID = panel.currentTabID
	if id then
		if panel.currentTabID and panel.currentTabID == id then
			return
		end
		if panel.tabs[id] then
			panel.currentTabID = id
		end
	end
	if not panel.tabs[panel.currentTabID] then
		return
	end
	panel.currentTab = panel.tabs[panel.currentTabID]
	panel.currentTab.tick = getTickCount()
	panel.previousTabID = savedID
	dxlib.setActiveContainer(panel.currentTab.id)
	panel.previousTab = panel.tabs[savedID] or nil
	if panel.previousTab then
		panel.previousTab.tick = getTickCount()
	end
end
addEvent("panel:switch", true)
addEventHandler("panel:switch", localPlayer, panel.switch)

function panel.show()
	panel.tick = getTickCount()
	panel.visible = true
	panel.currentTabID = panel.currentTabID or 1
	panel.currentTab = panel.tabs[panel.currentTabID] or nil
	panel.currentTab.tick = getTickCount()
	dxlib.activate()
	dxlib.setActiveContainer(panel.currentTab.id)
	removeEventHandler("onClientRender", root, panel.render)
	addEventHandler("onClientRender", root, panel.render, true, "low-2")
	showCursor(true)
	showChat(false)
	setElementData(localPlayer, "panel.visible", panel.visible, false)
	triggerEvent("panel:onVisibilityChanged", localPlayer, panel.visible)
	triggerEvent("blur:enable", localPlayer)
end
addEvent("panel:show", true)
addEventHandler("panel:show", localPlayer, panel.show)

function panel.hide()
	panel.tick = getTickCount()
	panel.visible = false
	dxlib.deactivate()
	showCursor(false)
	showChat(true)
	setElementData(localPlayer, "panel.visible", panel.visible, false)
	triggerEvent("panel:onVisibilityChanged", localPlayer, panel.visible)
	triggerEvent("blur:disable", localPlayer)
end
addEvent("panel:hide", true)
addEventHandler("panel:hide", localPlayer, panel.hide)
addEvent("core:onClientLeaveArena", true)
addEventHandler("core:onClientLeaveArena", localPlayer, panel.hide, true, "high+4")
addEventHandler("onClientResourceStop", resourceRoot, panel.hide)

function panel.render()
	local currentTick = getTickCount()
	local tick = panel.tick or 0
	panel.progress = interpolateBetween(panel.progress or 0, 0, 0, panel.visible and 1 or 0, 0, 0, math_min(250, currentTick - tick)/250, panel.interpolator)
	if not panel.visible and panel.progress == 0 then
		removeEventHandler("onClientRender", root, panel.render)
		return
	end
	for i, tab in pairs(panel.tabs) do
		local tick = tab.tick or 0
		local current = panel.currentTab.id == tab.id
		local from, to = current and 0 or 1, current and 1 or 0
		tab.progress = interpolateBetween(from, 0, 0, to, 0, 0, math_min(250, currentTick - tick)/250, panel.interpolator)
	end
	-- Slider
	local offset = math.floor(panel.sliderOffset - 20 * (1 - panel.progress))
	for i, item in pairs(panel.sliderItems) do
		local tab = panel.tabs[i]
		local x, y = panel.x + item.offset, offset
		local progress = math_max(tab.progress, 0.35) * panel.progress
		local alpha = 255 * progress
		dxDrawRectangle(x, y, item.width, panel.sliderHeight, tocolor(25, 25, 25, 245 * panel.progress), false)
		dxDrawRectangle(x, y, item.width, panel.sliderHeight, tocolor(25, 132, 109, 205 * panel.tabs[i].progress * panel.progress), false)
		dxDrawText(item.title, x, y, x + item.width, y + panel.sliderHeight, tocolor(255, 255, 255, 255 * panel.progress), panel.fontScale, panel.font, "center", "center", true)
	end
	if panel.previousTab and panel.previousTab.progress > 0 then
		local progress = panel.previousTab.progress * panel.progress
		local renderTarget = dxlib.renderContainer(panel.previousTab.id, panel.renderTarget_previous)
		dxSetShaderValue(panel.replaceShader, "tex", renderTarget)
		dxSetShaderTransform(panel.replaceShader, 0, 8 * progress, 0)
		dxDrawImage(panel.x, panel.y, panel.width, panel.height, renderTarget, 0, 0, 0, tocolor(255, 255, 255, 255 * progress), false)
	end
	local progress = panel.currentTab.progress * panel.progress
	local renderTarget = dxlib.renderContainer(panel.currentTab.id, panel.renderTarget_current)
	dxSetShaderValue(panel.replaceShader, "tex", renderTarget)
	dxSetShaderTransform(panel.replaceShader, 0, 8 * (1 - progress), 0)
	dxDrawImage(panel.x, panel.y, panel.width, panel.height, panel.replaceShader, 0, 0, 0, tocolor(255, 255, 255, 255 * progress), false)
end

addEventHandler("onClientKey", root,
function(button, press)
	local arena = getElementParent(localPlayer)
	local gamemode = isElement(arena) and getElementData(arena, "gamemode") or nil
	if isClientInLobby() or not gamemode or getElementData(localPlayer, "scoreboard.visible") or getElementData(localPlayer, "selector.visible") then
		return
	end
	if button == "F7" and press then
		panel.toggle()
	end
end)

addEventHandler("onClientCursorMove", root,
function()
	if not panel.visible then
		return
	end
	local hoveredItem = nil
	for i, item in pairs(panel.sliderItems) do
		local x, y = panel.x + item.offset, panel.sliderOffset
		if isCursorInRange(x, y, item.width, panel.sliderHeight) then
			hoveredItem = item
			break
		end
	end
	if panel.hoveredItem and panel.hoveredItem == hoveredItem then
		return
	end
	panel.hoveredItem = hoveredItem
end)

addEventHandler("onClientClick", root,
function(button, state)
	if not panel.visible or not panel.hoveredItem then
		return
	end
	if button == "left" and state == "up" then
		panel.switch(panel.hoveredItem.id)
	end
end)