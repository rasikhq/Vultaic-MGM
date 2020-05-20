core = {}
core.spectate = {startTimer = Timer:create(), tickTimer = Timer:create()}
core.movePlayerAway = {readyTimer = Timer:create()}

addEventHandler("onClientResourceStart", resourceRoot,
function()
	triggerEvent("unloadMap", localPlayer)
	fadeCamera(true)
	setCameraClip(false, false)
	showPlayerHudComponent("all", false)
	showPlayerHudComponent("crosshair", true)
	triggerEvent("core:onClientResourceStart", localPlayer)
end)

addEventHandler("onClientResourceStop", resourceRoot,
function()
	core.spectate.stop()
end)

addEvent("core:handleClientJoinArena", true)
addEventHandler("core:handleClientJoinArena", resourceRoot,
function(data)
	core.arenaData = {}
	-- Update synced data
	for i, v in pairs(data) do
		core.arenaData[i] = v
	end
	fadeCamera(true)
	-- Update dimension
	setElementDimension(localPlayer, core.arenaData.dimension)
	core.updateAllDimensions()
	-- Addons
	setGhostmodeEnabled(core.arenaData.ghostmodeEnabled)
	triggerEvent("core:onClientJoinArena", localPlayer, core.arenaData)
	-- Others
	triggerEvent("notification:create", localPlayer, "Quick Guide", "Hold 'F1' to leave arena")
end)

addEvent("core:handleClientLeaveArena", true)
addEventHandler("core:handleClientLeaveArena", resourceRoot,
function()
	-- Clean data
	core.arenaData = nil
	-- Update dimension
	setElementDimension(localPlayer, 0)
	-- Addons
	core.spectate.stop()
	setGhostmodeEnabled(false)
	triggerEvent("core:onClientLeaveArena", localPlayer)
	-- Others
	setElementFrozen(localPlayer, true)
	showPlayerHudComponent("all", false)
	showPlayerHudComponent("crosshair", true)
end)

-- Fixes
function core.updateAllDimensions()
	local dimension = core.arenaData and core.arenaData.dimension or getElementDimension(localPlayer)
	local parent = getElementParent(localPlayer)
	for i, player in pairs(getElementChildren(parent, "player")) do
		setElementDimension(player, dimension)
	end
end

-- Useful functions
function isClientInLobby()
	return getElementData(localPlayer, "arena") == nil or getElementData(localPlayer, "arena") == "lobby" and true or false
end

function getClientArena()
	return core.arenaData.element or getElementParent(localPlayer)
end

function getPlayerArena(player)
	return getElementParent(player)
end

function getClientArenaData()
	return core.arenaData or {}
end

function getClientArenaPlayers()
	local parent = getElementParent(localPlayer)
	local players = parent and getElementChildren(parent, "player") or {}
	return players
end

function getClientArenaVehicles()
	local vehicles = {} 
	local parent = getElementParent(localPlayer)
	if parent then
		for i, player in pairs(getElementChildren(parent, "player")) do
			local vehicle = getPedOccupiedVehicle(player)
			if isElement(vehicle) then
				table.insert(vehicles, vehicle)
			end
		end
	end
	return vehicles
end

function isPlayerDead(player)
	return not getElementHealth(player) or getElementHealth(player) < 1e-45 or getElementHealth(player) <= 0 or isPedDead(player)
end

-- Ghostmode
local ghostmodeEnabled = false

function setGhostmodeEnabled(enabled)
	ghostmodeEnabled = enabled and true or false
	updateElementCollisions()
end

function updateElementCollisions(element)
	if isElement(element) then
		local collidable = ghostmodeEnabled == false
		for _, other in pairs(getClientArenaVehicles()) do
			setElementCollidableWith(element, other, collidable)
		end
	else
		local collidable = ghostmodeEnabled == false
		for _, element in pairs(getClientArenaVehicles()) do
			for _, other in pairs(getClientArenaVehicles()) do
				setElementCollidableWith(element, other, collidable)
			end
		end
	end
end

-- Spectating
function core.spectate.start(isManual)
	if core.spectate.active then
		core.spectate.stop()
	end
	core.spectate.active = true
	core.spectate.targets = core.spectate.getTargets()
	core.spectate.target = nil
	if isElement(core.vehicle) then
		core.spectate.savedData = {
			model = getElementModel(core.vehicle),
			position = {getElementPosition(core.vehicle)},
			rotation = {getElementRotation(core.vehicle)},
			velocity = {getElementVelocity(core.vehicle)},
			turnVelocity = {getVehicleTurnVelocity(core.vehicle)},
			health = math.max(getElementHealth(core.vehicle), 0)
		}
	end
	core.spectate.currentIndex = 1
	if isManual then
		core.spectate._start()
	else
		core.spectate.startTimer:setTimer(core.spectate._start, 500, 1)
	end
	setCameraMatrix(getCameraMatrix())
	fadeCamera(true)
	core.spectate.tickTimer:setTimer(core.spectate.tick, 1000, 0)
end
addEvent("spectate:start", true)
addEventHandler("spectate:start", resourceRoot, core.spectate.start)
startSpectating = core.spectate.start

addEventHandler("onClientKey", root,
function(button, press)
	if core.spectate.active and press then
		if button == "arrow_l" then
			core.spectate.previous()
		elseif button == "arrow_r" then
			core.spectate.next()
		end
	end
end)

function core.spectate.getTargets()
	local targets = {}
	for i, player in pairs(getClientArenaPlayers()) do
		if player ~= localPlayer and getElementData(player, "state") == "alive" then
			table.insert(targets, player)
		end
	end
	return targets
end

function core.spectate.isValidTarget(player)
	return isElement(player) and tableFind(core.spectate.targets, player) and true or false
end

function core.spectate._start(target)
	if target then
		if not core.spectate.isValidTarget(target) then
			core.spectate.setTarget(false)
		end
		return
	end
	core.movePlayerAway.start()
	core.spectate.setTarget(core.spectate.targets[core.spectate.currentIndex])
end

function core.spectate.stop(isManual)
	if not core.spectate.active then
		return
	end
	core.spectate.active = false
	core.spectate.manual = false
	core.spectate.targets = {}
	core.spectate.target = nil
	core.spectate.startTimer:killTimer()
	core.spectate.tickTimer:killTimer()
	core.movePlayerAway.readyTimer:killTimer()
	if isManual then
		core.movePlayerAway.stop()
	else
		setCameraTarget(localPlayer)
	end
end
addEvent("spectate:stop", true)
addEventHandler("spectate:stop", resourceRoot, core.spectate.stop)
stopSpectating = core.spectate.stop

function core.spectate.forcedStop()
	core.spectate.active = false
	core.spectate.manual = false
	core.spectate.targets = {}
	core.spectate.startTimer:killTimer()
	core.spectate.tickTimer:killTimer()
	setCameraMatrix(getCameraMatrix())
end
forcedStopSpectating = core.spectate.forcedStop

function core.spectate.setTarget(target)
	core.spectate.target = target
	if isElement(target) then
		if target == localPlayer or target == core.spectate.getTarget() then
			return
		end
		setCameraTarget(target)
	else
		local x, y, z = getCameraMatrix()
		x = x - (x % 32)
		y = y - (y % 32)
		z = getGroundPosition(x, y, 5000) or 40
		setCameraTarget(localPlayer)
		setCameraMatrix(x, y, z + 10, x, y + 50, z + 60)
	end
end

function core.spectate.getTarget()
	local target = getCameraTarget()
	if isElement(target) and getElementType(target) == "vehicle" then
		target = getVehicleOccupant(target)
	end
	return target
end

function core.spectate.previous()
	if not core.spectate.active or core.spectate.startTimer:isActive() then
		return
	end
	core.spectate.currentIndex = core.spectate.currentIndex - 1
	if core.spectate.currentIndex < 1 then
		core.spectate.currentIndex = #core.spectate.targets
	end
	core.spectate.setTarget(core.spectate.targets[core.spectate.currentIndex])
end

function core.spectate.next()
	if not core.spectate.active or core.spectate.startTimer:isActive() then
		return
	end
	core.spectate.currentIndex = core.spectate.currentIndex + 1
	if core.spectate.currentIndex > #core.spectate.targets then
		core.spectate.currentIndex = 1
	end
	core.spectate.setTarget(core.spectate.targets[core.spectate.currentIndex])
end

function core.spectate.tick()
	if not core.spectate.active or core.spectate.startTimer:isActive() then
		return
	end
	local target = core.spectate.target
	if target and core.spectate.isValidTarget(target) and core.spectate.getTarget() ~= target then
		setCameraTarget(target)
	elseif (not target or not core.spectate.isValidTarget(target)) and #core.spectate.targets > 0 then
		core.spectate.target = nil
		spectate.next()
	end
end

-- movePlayerAway: hero function to hide dead peds
function core.movePlayerAway.start()
	local cameraTarget = core.spectate.getTarget()
	if not isPedInVehicle(localPlayer) then
		setElementPosition(localPlayer, 0, 0, -10)
		setElementFrozen(localPlayer, true)
	end
	if isElement(core.vehicle) then
		setElementVelocity(core.vehicle, 0, 0, 0)
		setVehicleTurnVelocity(core.vehicle, 0, 0, 0)
		setElementPosition(core.vehicle, 0, 0, -15)
		setElementRotation(core.vehicle, 0, 0, 0)
		setElementFrozen(core.vehicle, true)
		fixVehicle(core.vehicle)
		setElementCollisionsEnabled(core.vehicle, false)
		setVehicleDamageProof(core.vehicle, true)
	end
	setElementHealth(localPlayer, 100)
	if isElement(cameraTarget) and core.spectate.getTarget() ~= cameraTarget then
		setCameraTarget(cameraTarget)
	end
end

function core.movePlayerAway.stop()
	if isElement(core.vehicle) and core.spectate.savedData then
		setElementModel(core.vehicle, core.spectate.savedData.model)
		setElementPosition(core.vehicle, unpack(core.spectate.savedData.position))
		setElementRotation(core.vehicle, unpack(core.spectate.savedData.rotation))
		setElementHealth(core.vehicle, core.spectate.savedData.health)
		setCameraTarget(localPlayer)
		core.movePlayerAway.readyTimer:setTimer(function()
			local cameraTarget = core.spectate.getTarget()
			if cameraTarget == localPlayer and isPedInVehicle(localPlayer) then
				if isElement(core.vehicle) and core.spectate.savedData then
					setElementCollisionsEnabled(core.vehicle, true)
					setElementFrozen(core.vehicle, false)
					setElementVelocity(core.vehicle, unpack(core.spectate.savedData.velocity))
					setVehicleTurnVelocity(core.vehicle, unpack(core.spectate.savedData.turnVelocity))
				end
				core.spectate.savedData = nil
				triggerServerEvent("spectate:unfreeze", localPlayer)
				core.movePlayerAway.readyTimer:killTimer()
			end
		end, 500, 0)
	end
end

-- Replacements
_setCameraTarget = setCameraTarget
setCameraTarget = function(target)
	if isElement(target) then
		setElementDimension(target, getElementDimension(localPlayer))
		_setCameraTarget(target)
		setElementData(localPlayer, "spectatedTarget", target, false)
		triggerEvent("core:onClientCameraTargetChange", localPlayer, target)
	end
end

-- Handlers
addEventHandler("onClientElementStreamIn", root,
function()
	if getElementType(source) == "player" or getElementType(source) == "vehicle" then
		updateElementCollisions(source)
	end
end)

addEventHandler("onClientPlayerVehicleEnter", root,
function(vehicle)
	if source == localPlayer then
		core.vehicle = vehicle
	end
end)

addEventHandler("onClientElementDataChange", root,
function(dataName)
	if getElementType(source) ~= "player" or source == localPlayer or not core.spectate.active then
		return
	end
	if dataName == "arena" and getPlayerArena(source) ~= getClientArena() then -- Player leaves arena
		tableRemove(core.spectate.targets, source)
		if source == core.spectate.target then
			core.spectate.target = nil
			setCameraMatrix(getCameraMatrix())
			core.spectate.next()
		end
	elseif dataName == "state" and getPlayerArena(source) == getClientArena() then -- When player's state changes
		local state = getElementData(source, "state")
		if state == "alive" then
			tableInsert(core.spectate.targets, source)
			if not core.spectate.target or not core.spectate.getTarget() then
				setCameraMatrix(getCameraMatrix())
				for i, player in pairs(core.spectate.targets) do
					if player == source then
						core.spectate.currentIndex = i
						break
					end
				end
				core.spectate.target = source
				setCameraTarget(source)
			end
		elseif getPlayerArena(source) == getClientArena() then
			tableRemove(core.spectate.targets, source)
			if source == core.spectate.target then
				core.spectate.target = nil
				setCameraMatrix(getCameraMatrix())
				core.spectate.next()
			end
		end
	end
end)

-- Commented to avoid bug abusement
addCommandHandler("join",
function(command, arena)
	if type(arena) == "string" then
		triggerServerEvent("core:onPlayerRequestJoinArena", localPlayer, arena)
	end
end)

addCommandHandler("leave",
function(command)
	triggerServerEvent("core:onPlayerRequestLeaveArena", localPlayer)
end)