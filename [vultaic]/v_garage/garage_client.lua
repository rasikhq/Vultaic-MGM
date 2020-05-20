local screenWidth, screenHeight = guiGetScreenSize()
local relativeScale = math.min(screenWidth/640, 1)
garage = {}
garage.vehiclePosition = {3030, -1930, 55.54, 0, 0, 180}
garage.pedPosition = {3035, -1925, 55.54, 135}
selector = {}
selector.width, selector.height = math.floor(200 * math.min((screenWidth/640), 1.75)), math.floor(math.min(500 * relativeScale, screenHeight - 20))
selector.width, selector.height = selector.width - (selector.width % 10), selector.height - (selector.height % 10)
selector.x, selector.y = 5, 5
selector.size = math.floor(360 * relativeScale)
selector.iconSize = math.floor(48 * relativeScale)
selector.radius = selector.size * 0.5
selector.menuX, selector.menuY = screenWidth/2, screenHeight/2
selector.fontScale = 1
selector.font = dxlib.getFont("RobotoCondensed-Regular", 14)
selector.fontBig = dxlib.getFont("RobotoCondensed-Regular", 22)
selector.fontHeight = dxGetFontHeight(selector.fontScale, selector.font)
selector.interpolator = "Linear"
selector.tabs = {}
garage.upgrades = {
	{title = "Colors", event = "purchaseColors", path = "img/colors.png", data = "colors_bought", description = "Would you like to change colors of your vehicle? Or perhaps you're looking for a way to change the color of your headlights. Colors upgrade is just for that!"},
	{title = "Tints", event = "purchaseTints", path = "img/colors.png", data = "tints_bought", description = "Customize your vehicle's window colors and their appearance by purchasing tints upgrade!"},
	{title = "Wheels", event = "purchaseWheels", path = "img/wheels.png", data = "wheels_bought", description = "Show off your rims and unique tires by purchasing our wheels pack!"},
	{title = "Body parts", event = "purchaseBodyparts", path = "img/bodyparts.png", data = "bodyparts_bought", description = "If you wish to customize the looks of your Infernus body parts, this upgrade is just what you need!"},
	{title = "Stickers", event = "purchaseStickers", path = "img/stickers.png", data = "stickers_bought", description = "In order to browse our stickers catalog and stick them onto your vehicle, you must purchase them first!"},
	{title = "Lights", event = "purchaseLights", path = "img/lights.png", data = "lights_bought", description = "Pimp your ride by selecting your favorite lights from our lights catalog. Make sure to purchase it first!"},
	{title = "Overlays", event = "purchaseOverlays", path = "img/overlays.png", data = "overlays_bought", description = "Exclusive for Donators upgrade that synchronizes the outer part of your vehicle with music and makes it go live."},
	{title = "Neons", event = "purchaseNeons", path = "img/neons.png", price = 50000, data = "neons_bought", description = "Exclusive for Donators upgrade that displays a neon light or an image of your choice underneath your vehicle."},
	{title = "Rocket color", event = "purchaseRocketColor", path = "img/weaponvisuals.png", data = "rocketcolor_bought", description = "Lets you choose your own rocket color."},
	{title = "Skins", event = "purchaseSkins", path = "img/skin.png", data = "skins_bought", description = "Lets you select a player skin from GTA: San Andreas."}
}
local angle = 0
local average = 360/#garage.upgrades
for i, upgrade in pairs(garage.upgrades) do
	upgrade.tab = i
	upgrade.angle = angle
	angle = angle + average
end
local tabControls = {
	["main"] = {
		controls = {
			{key = "rmb", text = "return"},
			{key = "lmb", text = "rotate camera"},
			{key = "mouse wheel", text = "zoom in/out"}
		}
	},
	["stickers"] = {
		controls = {
			{key = "arw up", text = "move forwards"},
			{key = "arw down", text = "move backwards"},
			{key = "arw left", text = "move left"},
			{key = "arw right", text = "move right"},
			{key = "lctrl + scroll", text = "resize"},
			{key = "lalt + scroll", text = "rotate"},
		}
	}
}
for i, controlsClass in pairs(tabControls) do
	for k, control in pairs(controlsClass.controls) do
		control.key = control.key:upper()
		control.text = control.text:upper()
		control.keyWidth = dxGetTextWidth(control.key, selector.fontScale, selector.font) + 10
		control.textWidth = dxGetTextWidth(control.text, selector.fontScale, selector.font) + 10
	end
end
local currentControls = {}
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

addEvent("garage:onClientJoinGarage", true)
addEventHandler("garage:onClientJoinGarage", resourceRoot,
function()
	garage.enter()
end)

addEvent("garage:onClientLeaveGarage", true)
addEventHandler("garage:onClientLeaveGarage", resourceRoot,
function()
	if not garage.entered then
		return
	end
	garage.entered = false
	garage.deinit()
	unbindKey("enter", "down", selector.purchaseUpgrade)
	unbindKey("mouse2", "down", selector.switchToIndex)
	setElementData(localPlayer, "garage.entered", garage.entered)
	reloadElementData()
	triggerEvent("blur:disable", localPlayer, "garage")
end)

function garage.enter()
	if garage.entered then
		return
	end
	garage.entered = true
	setElementData(localPlayer, "garage.entered", garage.entered)
	local stored = garage.getUpgrades()
	if stored then
		garage._enter()
	end
end

function garage._enter(ready)
	garage.init()
	fadeCamera(false, 0.2)
	garage.initTimer = setTimer(function()
		if getElementData(localPlayer, "client.mapLoaded") and isElement(garage.vehicle) and isElementFrozen(garage.vehicle) then
			camera.activate(garage.vehicle)
			garage.timer = setTimer(function()	
				camera.deactivate()
				fadeCamera(true, 1)
				garage.timer = setTimer(function() 
					triggerEvent("garage:onInit", localPlayer, garage.vehicle) 
					selector.show()
					triggerEvent("blur:enable", localPlayer, "garage")
					if ready then
						playSound("sfx/ready.wav", false)
						triggerEvent("notification:create", localPlayer, "Garage", "Ready to use!")
					end
				end, 500, 1)
			end, 1000, 1)
			killTimer(garage.initTimer)
		end
	end, 250, 0)
end

function garage.init()
	if garage.timer and isTimer(garage.timer) then
		killTimer(garage.timer)
	end
	setTime(5, 40)
	setWeather(18)
	setElementFrozen(localPlayer, true)
	garage.vehicle = createVehicle(411, unpack(garage.vehiclePosition))	
	setElementData(garage.vehicle, "garage.vehicle", true)
	setElementData(localPlayer, "garage.vehicle", garage.vehicle, false)
	setElementDimension(garage.vehicle, getElementDimension(localPlayer))
	setElementFrozen(garage.vehicle, true)
	local x, y, z = unpack(garage.vehiclePosition)
	garage.ped = createPed(0, unpack(garage.pedPosition))
	setElementDimension(garage.ped, getElementDimension(localPlayer))
	setElementFrozen(garage.ped, true)
end

function garage.deinit()
	if garage.initTimer and isTimer(garage.initTimer) then
		killTimer(garage.initTimer)
	end
	camera.deactivate()
	dxlib.deactivate()
	selector.hide()
	selector.currentTabID = nil
	selector.currentTab = nil
	if selector.message then
		selector.message.visible = false
	end
	showCursor(false)
	if garage.timer and isTimer(garage.timer) then
		killTimer(garage.timer)
	end
	local elements = {garage.vehicle, garage.ped}
	for i, v in pairs(elements) do
		if isElement(v) then
			destroyElement(v)
		end
	end
	triggerEvent("garage:onDeInit", localPlayer, garage.vehicle)
	triggerEvent("garage:onTabSwitch", localPlayer, selector.currentTabID)
	triggerEvent("blur:disable", localPlayer, "garage")
end

function garage.getUpgrades()
	if not garage.upgradePrices then
		triggerEvent("notification:create", localPlayer, "Garage", "Getting some details from the server, please wait...")
		triggerServerEvent("getTuningUpgrades", localPlayer)
	else
		return true
	end
end

addEvent("onClientReceiveTuningUpgrades", true)
addEventHandler("onClientReceiveTuningUpgrades", localPlayer,
function(upgradePrices, exclusiveUpgrades)
	garage.upgradePrices = upgradePrices
	garage.exclusiveUpgrades = exclusiveUpgrades
	garage._enter(true)
	print("Received tuning upgrades from server")
end)

function selector.show()
	if selector.visible then
		return
	end
	selector.tick = getTickCount()
	selector.visible = true
	showCursor(true)
	showChat(false)
	if not selector.renderTarget_current then
		selector.renderTarget_current = dxCreateRenderTarget(selector.width, selector.height, true)
	end
	if not selector.renderTarget_previous then
		selector.renderTarget_previous = dxCreateRenderTarget(selector.width, selector.height, true)
	end
	selector.tick = getTickCount()
	if selector.currentTabID then
		selector.currentTab = selector.tabs[selector.currentTabID] or nil
		selector.currentTab.tick = getTickCount()
	end
	removeEventHandler("onClientRender", root, selector.render)
	addEventHandler("onClientRender", root, selector.render, true, "low-2")
end

function selector.hide()
	if not selector.visible then
		return
	end
	selector.tick = getTickCount()
	selector.visible = false
end

function selector.initTab(id, settings, items)
	if id and selector.tabs[id] then
		return
	end
	local settings = settings or {}
	local data = {}
	for i, v in pairs(settings) do
		data[i] = v
	end
	data.x = selector.x
	data.y = selector.y
	data.width = selector.width
	data.height = selector.height
	data.title = data.title or "Tab #"..#selector.tabs
	local container = dxlib.createContainer(data)
	if container then
		for i, item in pairs(items) do
			dxlib.registerItem(container.id, item)
		end
		selector.tabs[id] = container
		return selector.tabs[id]
	end
end

function selector.switch(id)
	local savedID = selector.currentTabID
	if id then
		if selector.currentTabID and selector.currentTabID == id then
			return
		end
		if selector.tabs[id] then
			selector.currentTabID = id
		end
	end
	selector.currentTab = selector.tabs[selector.currentTabID]
	selector.currentTab.tick = getTickCount()
	selector.previousTabID = savedID
	dxlib.setActiveContainer(selector.currentTab.id)
	selector.previousTab = selector.tabs[savedID] or nil
	if selector.previousTab then
		selector.previousTab.tick = getTickCount()
	end
	triggerEvent("garage:onTabSwitch", localPlayer, selector.currentTabID)
end

function selector.switchToIndex()
	dxlib.deactivate()
	camera.deactivate()
	selector.show()
	local savedID = selector.currentTabID
	selector.currentTabID = nil
	selector.currentTab = nil
	selector.previousTabID = savedID
	selector.previousTab = selector.tabs[savedID] or nil
	if selector.previousTab then
		selector.previousTab.tick = getTickCount()
	end
	if selector.message and selector.message.visible then
		selector.message.tick = getTickCount()
		selector.message.visible = false
		unbindKey("enter", "down", selector.purchaseUpgrade)
	end
	unbindKey("mouse2", "down", selector.switchToIndex)
	triggerEvent("garage:onTabSwitch", localPlayer, selector.currentTabID)
	triggerEvent("blur:enable", localPlayer, "garage")
end

function selector.purchaseUpgrade()
	if selector.message and selector.message.visible and selector.message.event then
		triggerServerEvent(selector.message.event, localPlayer)
	end
end

function selector.updateControls(upgrade)
	currentControls = {}
	table.insert(currentControls, tabControls["main"])
	local current = upgrade and upgrade.title:lower()
	if tabControls[current] then
		table.insert(currentControls, tabControls[current])
	end
	local offset = screenHeight - selector.fontHeight - 5
	for i, controlsClass in pairs(currentControls) do
		controlsClass.offset = offset
		offset = offset - selector.fontHeight - 5
	end
end

function selector.render()
	local currentTick = getTickCount()
	local tick = selector.tick or 0
	selector.progress = interpolateBetween(selector.progress or 0, 0, 0, selector.visible and 1 or 0, 0, 0, math_min(300, currentTick - tick)/300, selector.interpolator)
	if not garage.entered and selector.progress == 0 then
		removeEventHandler("onClientRender", root, selector.render)
		return
	end
	for i, tab in pairs(selector.tabs) do
		local tick = tab.tick or 0
		tab.progress = interpolateBetween(tab.progress or 0, 0, 0, selector.currentTab and selector.currentTab.id == tab.id and 1 or 0, 0, 0, math_min(300, currentTick - tick)/300, selector.interpolator)
	end
	if selector.previousTab and selector.previousTab.progress > 0 then
		local progress = selector.previousTab.progress
		local renderTarget = dxlib.renderContainer(selector.previousTab.id, selector.renderTarget_previous)
		dxDrawImage(selector.previousTab.x - 20 * (1 - progress), selector.previousTab.y, selector.previousTab.width, selector.previousTab.height, renderTarget, 0, 0, 0, tocolor(255, 255, 255, 255 * progress), false)
	end
	if selector.currentTab then
		local progress = selector.currentTab.progress
		local renderTarget = dxlib.renderContainer(selector.currentTab.id, selector.renderTarget_current)
		dxDrawImage(selector.currentTab.x - 20 * (1 - progress), selector.currentTab.y, selector.currentTab.width, selector.currentTab.height, renderTarget, 0, 0, 0, tocolor(255, 255, 255, 255 * progress), false)
		for i, controlsClass in pairs(currentControls) do
			local offset = 5
			for k, control in pairs(controlsClass.controls) do
				dxDrawRectangle(offset, controlsClass.offset, control.keyWidth, selector.fontHeight, tocolor(25, 25, 25, 245 * progress), false)
				dxDrawText(control.key, offset, controlsClass.offset, offset + control.keyWidth, controlsClass.offset + selector.fontHeight, tocolor(255, 255, 255, 255 * progress), selector.fontScale, selector.font, "center", "center", true)
				offset = offset + control.keyWidth
				dxDrawText(control.text, offset, controlsClass.offset, offset + control.textWidth, controlsClass.offset + selector.fontHeight, tocolor(255, 255, 255, 155 * progress), selector.fontScale, selector.font, "center", "center", true)
				offset = offset + control.textWidth + 10
			end
		end
	end
	if selector.progress > 0 then
		for i, upgrade in pairs(garage.upgrades) do
			local x, y = getPointFromDistanceRotation(0, 0, selector.radius, upgrade.angle)
			x, y = selector.menuX + x - selector.iconSize/2, selector.menuY + y - selector.iconSize/2
			if isCursorInRange(x, y, selector.iconSize, selector.iconSize + selector.fontHeight + 5) then
				if not upgrade.hovered then
					upgrade.tick = getTickCount()
					upgrade.hovered = true
				end
			elseif upgrade.hovered then
				upgrade.tick = getTickCount()
				upgrade.hovered = false
			end
			local tick = upgrade.tick or 0
			upgrade.progress = interpolateBetween(upgrade.progress or 0, 0, 0, upgrade.hovered and 1 or 0, 0, 0, math_min(300, currentTick - tick)/300, selector.interpolator)
			local alpha = (155 + 100 * upgrade.progress) * selector.progress
			dxDrawImage(x, y, selector.iconSize, selector.iconSize, upgrade.path, 0, 0, 0, tocolor(255, 255, 255, alpha), false)
			y = y + selector.iconSize + 5
			dxDrawText(upgrade.title, x, y, x + selector.iconSize, y + selector.iconSize, tocolor(255, 255, 255, alpha), selector.fontScale, selector.font, "center", "top", false, false, false, true)
		end
	end
	if selector.message then
		local tick = selector.message.tick or 0
		selector.message.progress = interpolateBetween(selector.message.progress or 0, 0, 0, selector.message.visible and 1 or 0, 0, 0, math_min(150, currentTick - tick)/150, selector.interpolator)
		if not selector.message.visible and selector.message.progress == 0 then
			selector.message = nil
			return
		end
		local price = math.floor(selector.message.price * selector.message.progress)
		local animation = -10 * (1 - selector.message.progress)
		local x, width = screenWidth * 0.125, screenWidth * 0.75
		dxDrawRectangle(x, screenHeight * 0.3 + animation, width, 1, tocolor(255, 255, 255, 25 * selector.message.progress), true)
		dxDrawRectangle(x ,screenHeight * 0.7 + animation, width, 1, tocolor(255, 255, 255, 25 * selector.message.progress), true)
		do
			local x, width = screenWidth * 0.125, screenWidth * 0.875
			dxDrawText(selector.message.title, x, 0, width, screenHeight * 0.3 - 5 + animation, tocolor(25, 132, 109, 255 * selector.message.progress), selector.fontScale, selector.fontBig, "left", "bottom", true, false, true)
			dxDrawText("$"..price, x, 0, width, screenHeight * 0.3 - 5 + animation, tocolor(25, 132, 109, 255 * selector.message.progress), selector.fontScale, selector.fontBig, "right", "bottom", true, false, true)
			dxDrawText(selector.message.message, x, screenHeight * 0.3 + 15 + animation, width, screenHeight, tocolor(255, 255, 255, 255 * selector.message.progress), selector.fontScale, selector.font, "left", "top", true, true, false, true)			
			dxDrawText("RMB - RETURN", x, screenHeight * 0.7 + 5 + animation, width, screenHeight, tocolor(255, 255, 255, 55 * selector.message.progress), selector.fontScale, selector.font, "left", "top", false, false, true, true)
			dxDrawText("ENTER - PURCHASE", x, screenHeight * 0.7 + 5 + animation, width, screenHeight, tocolor(255, 255, 255, 55 * selector.message.progress), selector.fontScale, selector.font, "right", "top", false, false, true, true)
			if selector.message.exclusive then
				dxDrawText("This upgrade is exclusive for donators", x, 0, width, screenHeight * 0.7 - 5 + animation, tocolor(55, 255, 55, 255 * selector.message.progress), selector.fontScale, selector.font, "right", "bottom", false, false, true, true)
			end
		end
	end
end

addEventHandler("onClientClick", root,
function(button, state)
	if not selector.visible then
		return
	end
	if button == "left" and state == "up" then
		local _upgrade = nil
		for i, upgrade in pairs(garage.upgrades) do
			if upgrade.hovered then
				_upgrade = upgrade
				break
			end
		end
		if _upgrade then
			local data = getElementData(localPlayer, _upgrade.data)
			if data == "expired" then
				return triggerEvent("notification:create", localPlayer, "Donatorship", "Please extend your donatorship to use ".._upgrade.title)
			end
			if not data then
				local price = garage.upgradePrices and garage.upgradePrices[_upgrade.title] and garage.upgradePrices[_upgrade.title] or nil
				price = tonumber(price) or nil
				if not price then
					return triggerEvent("notification:create", localPlayer, "Garage", "Failed to get prices from the server, please try again later")
				end
				local exclusive = garage.exclusiveUpgrades and garage.exclusiveUpgrades[_upgrade.title] and true or false
				selector.message = {
					tick = getTickCount(),
					visible = true,
					icon = _upgrade.path,
					title = _upgrade.title,
					event = _upgrade.event,
					price = price,
					exclusive = exclusive,
					message = _upgrade.description or "no description"
				}
				selector.hide()
				bindKey("mouse2", "down", selector.switchToIndex)
				bindKey("enter", "down", selector.purchaseUpgrade)
				triggerEvent("blur:enable", localPlayer, "garage")
				return
			end
			selector.hide()
			if selector.tabs[_upgrade.tab] then
				selector.switch(_upgrade.tab)
				dxlib.activate()
			end
			camera.activate(_upgrade.title == "Skins" and garage.ped or garage.vehicle)
			bindKey("mouse2", "down", selector.switchToIndex)
			selector.updateControls(_upgrade)
			triggerEvent("blur:disable", localPlayer, "garage")
		end
	end
end)

local dataToCatch = {}
for i, _upgrade in pairs(garage.upgrades) do
	dataToCatch[_upgrade.data] = true
end

addEventHandler("onClientElementDataChange", localPlayer,
function(dataName)
	if dataToCatch[dataName] and selector.message and selector.message.visible then
		selector.switchToIndex()
	end
end)

local elementData = {}
_setElementData = setElementData
function setElementData(element, key, value)
	if element == localPlayer then
		elementData[key] = getElementData(localPlayer, key)
		return _setElementData(localPlayer, key, value, false)
	else
		return _setElementData(element, key, value, false)
	end
end

function resetElementData(key)
	if elementData[key] then
		elementData[key] = nil
	end
end

function reloadElementData()
	for key, value in pairs(elementData) do
		setElementData(localPlayer, key, value, false)
	end
end