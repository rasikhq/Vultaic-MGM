camera = {}
camera.angleH, camera.angleV = 0, 0
camera.distanceToGo = 6
local savedAngles = {}

function camera.activate(element)
	camera.deactivate()
	if camera.lastElement then
		savedAngles[camera.lastElement] = {camera.angleH, camera.angleV, camera.distanceToGo}
		if camera.lastElement ~= element then
			camera.distance = 4
		end
	end
	if isElement(element) then
		camera.distanceTick = getTickCount()
		camera.active = true
		camera.position = {getElementPosition(element)}
		if savedAngles[element] then
			camera.angleH, camera.angleV = savedAngles[element][1], savedAngles[element][2]
			camera.distanceToGo = savedAngles[element][3]
		end
		addEventHandler("onClientPreRender", root, camera.update)
	end
	camera.lastElement = element
end

function camera.deactivate()
	camera.active = false
	camera.moving = false
	camera.position = nil
	for element in pairs(savedAngles) do
		if not isElement(element) then
			savedAngles[element] = nil
		end
	end
	removeEventHandler("onClientPreRender", root, camera.update)
end

function camera.setDistance(addt)
	if camera.distanceTick and getTickCount() - camera.distanceTick < 250 then
		return
	end
	camera.distanceTick = getTickCount()
	camera.distanceToGo = camera.distanceToGo + addt
	if camera.distanceToGo < 4 then
		camera.distanceToGo = 4
	elseif camera.distanceToGo > 15 then
		camera.distanceToGo = 15	
	end
end

function camera.update()
	local currentTick = getTickCount()
	local tick = camera.distanceTick or 0
	camera.distance = interpolateBetween(camera.distance or 0, 0, 0, camera.distanceToGo, 0, 0, math.min(500, currentTick - tick)/500, "Linear")
	local x, y = getPointFromDistanceRotation(0, 0, camera.distance, camera.angleH)
	local z = getPointFromDistanceRotation(0, 0, camera.distance, camera.angleV)
	z = math.max(z, 0)
	local posX, posY, posZ = unpack(camera.position)
	setCameraMatrix(posX + x, posY + y, posZ + z, posX, posY, posZ)
end

addEventHandler("onClientClick", root,
function(button, state, absoluteX, absoluteY, worldX, worldY, worldZ, clickedElement)
	if not camera.active then
		return
	end
	if state == "down" and isUIHovering() then
		return
	end
	if button == "left" then
		if state == "down" then
			local _, _, cX, cY = getCursorPosition()
			camera.mouseX, camera.mouseY = cX, cY
			camera.moving = true
		else
			camera.moving = false
		end
	end
end)

addEventHandler("onClientCursorMove", root,
function()
	if not camera.active or not camera.moving then
		return
	end
	local _, _, cX, cY = getCursorPosition()
	local diffX, diffY = cX - camera.mouseX, cY - camera.mouseY
	camera.mouseX = cX
	camera.mouseY = cY
	camera.angleH = camera.angleH + diffX * 360
	camera.angleV = camera.angleV + diffY * 180
end)

addEventHandler("onClientKey", root,
function(key, press)
	if not camera.active or isUIHovering() then
		return
	end
	if press then
		if key == "mouse_wheel_up" then
			camera.setDistance(-2)
		elseif key == "mouse_wheel_down" then
			camera.setDistance(2)
		end
	end
end)

function isUIHovering()
	local container = dxlib.containers[dxlib.activeContainer]
	return container and container.hovered or false
end

function getPointFromDistanceRotation(x, y, distance, angle)
	local a = math.rad(90 - angle)
	local dx = math.cos(a) * distance
	local dy = math.sin(a) * distance
	return x + dx, y + dy
end