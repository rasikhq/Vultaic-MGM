spawnChanger = {}
spawnChanger.spawns = nil
spawnChanger.currentSpawn = nil
addEventHandler("onClientArenaStateChanging", resourceRoot,
function(currentState, newState, data)
	if newState == "spawningPlayers" then
		spawnChanger:toggle(true)
	else
		spawnChanger:toggle(false)
	end
end)
function onMapLoad_Spawnchanger()
	if arena.state ~= "running" and arena.state ~= "changingMap" and spawnChanger.Enabled then
		spawnChanger:loadSpawns()
	end
end
addEventHandler("onClientJoinArena", resourceRoot,
function(data)
	addEventHandler("mapmanager:onMapLoad", localPlayer, onMapLoad_Spawnchanger)
	if arena.state ~= "running" and arena.state ~= "changingMap" then
		spawnChanger:toggle(true)
	end
end)
addEventHandler("onClientLeaveArena", resourceRoot,
function(data)
	removeEventHandler("mapmanager:onMapLoad", localPlayer, onMapLoad_Spawnchanger)
	spawnChanger:clear()
end)
--
function spawnChanger:toggle(tog)
	--outputDebugString("Toggling spawnchanger: "..tostring(tog), 0, 100, 200, 50)
	if tog == nil then
		return
	elseif spawnChanger.Enabled == tog then
		return
	end
	spawnChanger.Enabled = tog
	if tog then
		bindKey("mouse_wheel_down", "down", spawnChanger.requestSpawn)
		bindKey("mouse_wheel_up", "down", spawnChanger.requestSpawn)
		-- Arrow keys as well
		addEventHandler("onClientKey", root, spawnChanger.requestSpawnExtra)
		spawnChanger:loadSpawns()
	else
		unbindKey("mouse_wheel_down", "down", spawnChanger.requestSpawn)
		unbindKey("mouse_wheel_up", "down", spawnChanger.requestSpawn)
		removeEventHandler("onClientKey", root, spawnChanger.requestSpawnExtra)
		spawnChanger.spawns = nil
	end
end
function spawnChanger:loadSpawns()
	spawnChanger.spawns = getElementsByType("mapmanager:spawnpoint")
	if #spawnChanger.spawns == 0 then
		return
	end
	local spawns = {}
	local baseSpawn = spawnChanger.spawns[1]
	table.insert(spawns, {
		getElementData(baseSpawn, "posX"),
		getElementData(baseSpawn, "posY"),
		getElementData(baseSpawn, "posZ"),
		getElementData(baseSpawn, "rotX"),
		getElementData(baseSpawn, "rotY"),
		getElementData(baseSpawn, "rotZ"),
	})
	for i = 2, #spawnChanger.spawns do
	
		local _spawnData = {getElementData(spawnChanger.spawns[i], "posX"), getElementData(spawnChanger.spawns[i], "posY"), getElementData(spawnChanger.spawns[i], "posZ"), getElementData(spawnChanger.spawns[i], "rotX"), getElementData(spawnChanger.spawns[i], "rotY"), getElementData(spawnChanger.spawns[i], "rotZ")}
		for j = 1, #spawns do
			local spawnData_spawns = spawns[j]
			if spawnData_spawns then
				local x, y, z = spawnData_spawns[1], spawnData_spawns[2], spawnData_spawns[3]
				local distance = getDistanceBetweenPoints3D(x, y, z, _spawnData[1], _spawnData[2], _spawnData[3])
				if distance > 1 then
					table.insert(spawns, {_spawnData[1], _spawnData[2], _spawnData[3], _spawnData[4], _spawnData[5], _spawnData[6]})
					break
				end
			end
		end
	end
	spawnChanger.spawns = spawns
end
function spawnChanger.requestSpawn(key, state)
	if guiGetInputMode() ~= "allow_binds" or isCursorShowing() or getElementData(localPlayer, "scoreboard.visible") then
		return
	end
	if key == "mouse_wheel_down" then
		spawnChanger:GetSpawn(true)
	else
		spawnChanger:GetSpawn(false)
	end
end
function spawnChanger.requestSpawnExtra(button, press)
	if guiGetInputMode() ~= "allow_binds" or isCursorShowing() or getElementData(localPlayer, "scoreboard.visible") or not press or button ~= "arrow_r" and button ~= "arrow_l" then
		return
	end
	spawnChanger:GetSpawn((button == "arrow_r" and true or false))
end
function spawnChanger:GetSpawn(direction)
	--outputDebugString("Getting next spawnpoint in the direction: "..tostring(direction), 0, 100, 200, 50)
	if not spawnChanger.spawns or #spawnChanger.spawns <= 1 then
		return
	end
	local vehicle = arena.vehicle or getPedOccupiedVehicle(localPlayer)
	if not vehicle then return end
	spawnChanger.currentSpawn = spawnChanger.currentSpawn or 1
	if direction then
		spawnChanger.currentSpawn = spawnChanger.currentSpawn+1
		if spawnChanger.currentSpawn > #spawnChanger.spawns then
			spawnChanger.currentSpawn = 1
		end
		local spawnData = spawnChanger.spawns[spawnChanger.currentSpawn]
		if spawnData and type(spawnData) == "table" then
			local x, y, z, rotX, rotY, rotZ = spawnData[1], spawnData[2], spawnData[3], spawnData[4], spawnData[5], spawnData[6]
			setElementPosition(vehicle, x, y, z)
			setElementRotation(vehicle, rotX, rotY, rotZ)
		end
	else
		spawnChanger.currentSpawn = spawnChanger.currentSpawn-1
		if spawnChanger.currentSpawn < 1 then
			spawnChanger.currentSpawn = #spawnChanger.spawns
		end
		local spawnData = spawnChanger.spawns[spawnChanger.currentSpawn]
		if spawnData and type(spawnData) == "table" then
			local x, y, z, rotX, rotY, rotZ = spawnData[1], spawnData[2], spawnData[3], spawnData[4], spawnData[5], spawnData[6]
			setElementPosition(vehicle, x, y, z)
			setElementRotation(vehicle, rotX, rotY, rotZ)
		end
	end
	setCameraTarget(localPlayer)
end
function spawnChanger:clear()
	spawnChanger:toggle(false)
	spawnChanger.spawns = nil
	spawnChanger.currentSpawn = nil
end