arena = {
	waterCheckTimer = Timer:create(),
	-- Gameplay
	clientMap = nil,
	startTick = nil,
	allowToptime = true,
}
local waterCraftIDS = {
	[539] = true,
	[460] = true,
	[417] = true,
	[447] = true,
	[472] = true,
	[473] = true,
	[493] = true,
	[595] = true,
	[484] = true,
	[430] = true,
	[453] = true,
	[452] = true,
	[446] = true,
	[454] = true
}
enterKey = next(getBoundKeys("enter_exit"))
-- Main events
addEvent("onClientJoinArena", true)
addEvent("onClientLeaveArena", true)
addEvent("onClientPlayerJoinArena", true)
addEvent("onClientPlayerLeaveArena", true)
addEvent("onClientArenaSpawn", true)
addEvent("onClientArenaWasted", true)
addEvent("checkpoints:onClientFinish", true)
addEvent("mapmanager:onMapLoad", true)
addEvent("racepickups:onClientPickupRacepickup", true)
-- Custom training events
addEvent("training:onClientMapSet", true)
addEvent("training:onClientMapRemove", true)
addEvent("training:onPlayerStart", true)

--[[ Functions::Main ]]--

addEventHandler("onClientJoinArena", resourceRoot,
function(data)
	-- Update synced data
	for i, v in pairs(data) do
		arena[i] = v
	end
	-- Gameplay functions
	setBlurLevel(0)
	setPedCanBeKnockedOffBike(localPlayer, false)
	-- Handlers
	addCommandHandler("suicide", requestKill)
	addCommandHandler("kill", requestKill)
	addEventHandler("mapmanager:onMapLoad", localPlayer, requestToptimes)
	addEventHandler("checkpoints:onClientFinish", root, handleRaceFinish)
	addEventHandler("onClientKey", root, handleKeyPress)
	-- Binds
	bindKey(enterKey, "down", "suicide")
	--bindKey("b", "down", "manualspectate")
	-- UI stuff
	selector.show()
	selector.displayMaps(data.maps)
	setElementData(localPlayer, "checkpointsEnabled", true, false)
	triggerEvent("blur:enable", localPlayer, "training")
	arena.clientDriving = nil
end)

addEventHandler("onClientLeaveArena", resourceRoot,
function()
	-- Reset gameplay functions
	setPedCanBeKnockedOffBike(localPlayer, true)
	if(arena.waterCheckTimer:isActive()) then
		arena.waterCheckTimer:killTimer()
	end
	-- Handlers
	removeCommandHandler("suicide", requestKill)
	removeCommandHandler("kill", requestKill)
	removeEventHandler("mapmanager:onMapLoad", localPlayer, requestToptimes)
	removeEventHandler("checkpoints:onClientFinish", root, handleRaceFinish)
	-- Binds
	unbindKey(enterKey, "down", "suicide")
	--unbindKey("b", "down", "manualspectate")
	-- UI stuff
	selector.applyMapFilter("")
	selector.hide()
	removeEventHandler("onClientKey", root, handleKeyPress)
	triggerEvent("radar:setVisible", localPlayer, false)
	triggerEvent("racehud:hide", localPlayer)
	setElementData(localPlayer, "checkpointsEnabled", false, false)
	triggerEvent("blur:disable", localPlayer, "training")
	arena.clientDriving = nil
end)

function handleKeyPress(key, press)
	if key == "F1" and press and arena.clientDriving and not selector.visible then
		removeClientMap()
	end
end

--[[ Functions::Core ]]--

addEventHandler("onClientArenaSpawn", resourceRoot,
function(vehicle)
	arena.vehicle = vehicle
	respawnPlayer()
	arena.clientDriving = true
end)

addEventHandler("onClientArenaWasted", resourceRoot,
function()
	arena.allowToptime = true
	setGameSpeed(1)
	setGravity(0.008)
end)

function handleRaceFinish()
	setElementHealth(localPlayer, 0)
	triggerEvent("checkpoints:reset", localPlayer)
	if not arena.allowToptime then
		return outputChatBox("#19846d[Toptime] #ffffffWell done! Now try finishing the map without any warps.", 255, 255, 255, true)
	end
	local timePassed = getTickCount() - arena.startTick
	if timePassed then
		triggerServerEvent("training:onPlayerRequestAddToptime", resourceRoot, timePassed)
	end
end

function requestToptimes()
	triggerServerEvent("toptimes:onPlayerRequestToptimes", localPlayer, arena.clientMap.resourceName)
end

--[[ Functions::Misc ]]--

function respawnPlayer()
	local cameraTarget = getCameraTarget()
	fadeCamera(true)
	setCameraTarget(localPlayer)
	arena.waterCheckTimer:setTimer(checkWater, 1000, 0)
	removeVehicleNitro()
	toggleAllControls(true)
	-- Gameplay
	triggerEvent("checkpoints:reset", localPlayer)
	arena.allowToptime = true
	--
	triggerEvent("updateVehicleWeapons", localPlayer)
	triggerEvent("blur:disable", localPlayer, "training")
	triggerEvent("onClientTimeIsUpDisplayRequest", localPlayer)
end

function removeVehicleNitro()
	if isElement(arena.vehicle) then
		removeVehicleUpgrade(arena.vehicle, 1010)
	end
end

function requestKill()
	setCameraMatrix(getCameraMatrix())
	triggerServerEvent("onRequestKillPlayer", localPlayer)
end

addEventHandler("training:onClientMapSet", resourceRoot, function(data)
	arena.clientMap = data
	arena.allowToptime = true
	-- UI stuff
	selector.hide()
	showChat(true)
	triggerEvent("racehud:show", localPlayer)
	triggerEvent("radar:setVisible", localPlayer, true)
	triggerEvent("onClientArenaMapStarting", localPlayer, {mapName = data.mapName})
end)

addEventHandler("training:onClientMapRemove", resourceRoot, function()
	arena.clientMap = nil
	arena.allowToptime = false
	triggerEvent("toptimes:reset", localPlayer)
	showChat(false)
end)

addEventHandler("training:onPlayerStart", resourceRoot, function()
	arena.startTick = getTickCount()
	triggerEvent("onClientTimeIsUpDisplayRequest", localPlayer)
end)

function removeClientMap()
	if lastRemoveTick and getTickCount() - lastRemoveTick < 5000 then
		return triggerEvent("notification:create", localPlayer, "Warning", "Please wait some time before unloading the map again")
	end
	selector.show()
	showChat(false)
	triggerEvent("blur:enable", localPlayer, "training")
	lastRemoveTick = getTickCount()
end

function checkWater()
	if isElement(arena.vehicle) then
		if not waterCraftIDS[getElementModel(arena.vehicle)] then
			local x, y, z = getElementPosition(localPlayer)
			local waterZ = getWaterLevel(x, y, z)
			if waterZ and z < waterZ - 0.5 and not isPlayerDead(localPlayer) then
				setElementHealth(localPlayer, 0)
				triggerServerEvent("onRequestKillPlayer", localPlayer)
			end
		end
	end
end

--[[ Functions::Exports ]]--