local _G = _G
local _sandbox = {}
local _data = {}
_data.eventHandlers = {}
_data.elementData = {}
_data.boundKeys = {}
_data.commandHandlers = {}
_data.fileHandlers = {}
_data.xmlHandlers = {}
_data.LODDistance = {}
_data.objectsCreated = {}
_data.staticObjects = {}
_data.replacedModels = {}
_data.elements = {}
_data.shaders = {}
_data.soundHandlers = {}
_data.soundsEnabled = true
_data.shadersEnabled = true
local _mapDirectory = ":mapmanager/"
local _cacheDirectory = CACHE_DIRECTORY
local _activeMapDirectory = ""
local _activeStreamDirectory = ""
local _thisResource = getThisResource()
local _thisResourceName = getResourceName(_thisResource)
local _staticModels = {
	[411] = true,
	[1025] = true,
	[1073] = true,
	[1074] = true,
	[1075] = true,
	[1076] = true,
	[1077] = true,
	[1078] = true,
	[1079] = true,
	[1080] = true,
	[1081] = true,
	[1082] = true,
	[1083] = true,
	[1084] = true,
	[1085] = true,
	[1096] = true,
	[1097] = true,
	[1098] = true
}
local _skyboxModels = {
	[15057] = true,
}
local _forbiddenKeys = {
	f1 = true,
	f2 = true,
	f3 = true,
	f4 = true,
	f5 = true,
	f6 = true,
	f7 = true,
	f8 = true,
	f9 = true,
	f10 = true,
	f11 = true,
	f12 = true,
	t = true,
	m = true,
	n = true,
	g = true,
	l = true,
	lctrl = true,
	rctrl = true,
	lshift = true,
	rshift = true,
	space = true,
	lalt = true,
	ralt = true
}
local _forbiddenKeys_noOverwrite = {
	f1 = true,
	f2 = true,
	f3 = true,
	f4 = true,
	f5 = true,
	f6 = true,
	f7 = true,
	f8 = true,
	f9 = true,
	f10 = true,
	f11 = true,
	f12 = true,
	t = true,
	m = true,
	n = true,
	g = true,
	l = true,
}
local _forbiddenWorldTextures = {
	vehiclelights128 = true,
	vehiclelightson128 = true
}
local _upgrades = {
	[1008] = true,
	[1009] = true,
	[1010] = true,
	[1087] = true
}
local unpack = unpack
local tostring = tostring
local tonumber = tonumber
local tableInsert = table.insert
local tableRemove = table.remove

function _loadScripts(scripts, directory, streamDirectory)
	if type(scripts) ~= "table" then
		return outputDebugString("Sandbox can not run non-table scripts", 1)
	end
	directory = directory and directory.."/" or ""
	_activeMapDirectory = _mapDirectory..directory
	_activeStreamDirectory = streamDirectory and streamDirectory.."/" or ""
	if _activeMapDirectory == _mapDirectory then
		return outputDebugString("Sandbox can not run in global folder", 1)
	end
	local startTick = getTickCount()
	local scriptsLoaded = 0
	for i = 1, #scripts do
		scriptsLoaded = _environment_load(scripts[i]) and scriptsLoaded + 1 or scriptsLoaded
	end
	_environment_ready()
	triggerEvent("scriptloader:onScriptsLoaded", localPlayer)
	outputDebugString("Sandbox has loaded "..scriptsLoaded.." scripts in "..getTickCount() - startTick.." ms", 0, 55, 155, 255)
end
addEvent("sandbox:load", true)
addEventHandler("sandbox:load", localPlayer, _loadScripts)

function _unloadScripts()
	local startTick = getTickCount()
	_environment_reset()
	_game_reset()
	outputDebugString("Sandbox has been cleaned up for "..getTickCount() - startTick.." ms", 0, 55, 155, 255)
end
addEvent("sandbox:unload", true)
addEventHandler("sandbox:unload", localPlayer, _unloadScripts)

local _replace = {
	-- Allowed
	["playSFX3D"] = true,
	["createBlip"] = true,
	["createBlipAttachedTo"] = true,
	["createColCircle"] = true,
	["createColCuboid"] = true,
	["createColRectangle"] = true,
	["createColSphere"] = true,
	["createColTube"] = true,
	["createColPolygon"] = true,
	["createFire"] = true,
	["createEffect"] = true,
	["createElement"] = true,
	["createLight"] = true,
	["createPed"] = true,
	["createPickup"] = true,
	["createRadarArea"] = true,
	["createSearchLight"] = true,
	["createVehicle"] = true,
	["createWater"] = true,
	["createWeapon"] = true,
	["setElementVelocity"] = true,
	["getPedOccupiedVehicle"] = true,
	-- Forbidden
	["loadstring"] = false,
	["load"] = false,
	["setfenv"] = false,
	["getfenv"] = false,
	["debug"] = false,
	["pcall"] = false,
	["call"] = false,
	["rawget"] = false,
	["rawset"] = false,
	["triggerServerEvent"] = false,
	["triggerLatentServerEvent"] = false,
	["collectgarbage"] = false,
	["setMinuteDuration"] = false,
	["getPlayerSerial"] = false,
	["getPlayerFromName"] = false,
	["setFPSLimit"] = false,
	["setVehicleColor"] = false,
	["setSoundVolume"] = false,
	["setSoundPaused"] = false,
	["setCloudsEnabled"] = false,
	["setBlurLevel"] = false,
	["engineSetAsynchronousLoading"] = false,
	["showPlayerHudComponent"] = false,
	["showPlayerHudComponentVisible"] = false,
	["setCameraClip"] = false,
	["setCameraFieldOfView"] = false,
	["setDevelopmentMode"] = false,
	["setBlipColor"] = false,
	["dxSetTestMode"] = false,
	["showChat"] = false,
	["setPedCanBeKnockedOffBike"] = false,
	["setPedTargetingMarkerEnabled"] = false,
	["setPedWalkingStyle"] = false,
	["setPlayerNametagText"] = false,
	["addDebugHook"] = false,
	["fetchRemote"] = false,
	["setDebugViewActive"] = false,
	["outputChatBox"] = false,
	["setVehicleHeadLightColor"] = false,
	["setVehicleLightState"] = false,
	["setVehicleOverrideLights"] = false,
	["setVehiclePaintjob"] = false,
	["createSWATRope"] = false,
	["setRadioChannel"] = false,
	["engineSetModelLODDistance"] = false,
	-- Complete replacements
	["addEventHandler"] = function(...)
		local args = {...}
		if not args[3] then
			return
		end
		local eventName = args[1]
		if eventName == "onClientResourceStart" then
			args[1] = "onClientFakeResourceStart"
			args[2] = resourceRoot
		elseif eventName == "onClientResourceStop" then
			args[1] = "onClientFakeResourceStop"
			args[2] = resourceRoot
		elseif eventName == "onClientRender" or eventName == "onClientPreRender" or eventName == "onClientHUDRender" then
			args[4] = true
			args[5] = "high+99999"
		elseif eventName == "onClientPlayerRadioSwitch" then
			return
		end
		if not isElement(args[2]) then
			return
		end
		tableInsert(_data.eventHandlers, args)
		removeEventHandler(unpack(args))
		return addEventHandler(unpack(args))
	end,
	["removeEventHandler"] = function(...)
		local args = {...}
		if not args[3] then
			return
		end
		return removeEventHandler(unpack(args))
	end,
	["playSound"] = function(...)
		local args = {...}
		local isWebURL = args[1]:find("^http(.*)://")
		--args[1] = isWebURL and args[1] or _cacheDirectory.._activeStreamDirectory..args[1]
		args[1] = _cacheDirectory.._activeStreamDirectory..args[1]
		args[3] = false
		local handler = playSound(unpack(args))
		if handler then
			setElementData(handler, "sound_type", "map_music")
			table.insert(_data.soundHandlers, handler)
			triggerEvent("sandbox:onSoundStart", handler)
		end
		return handler
	end,
	["playSound3D"] = function(...)
		local args = {...}
		local isWebURL = args[1]:find("^http(.*)://")
		--args[1] = isWebURL and args[1] or _cacheDirectory.._activeStreamDirectory..args[1]
		args[1] = _cacheDirectory.._activeStreamDirectory..args[1]
		args[6] = false
		local handler = playSound3D(unpack(args))
		if handler then
			setElementDimension(handler, getElementDimension(localPlayer))
			setElementData(handler, "sound_type", "map_music")
			setElementDimension(handler, getElementDimension(localPlayer))
			table.insert(_data.soundHandlers, handler)
			triggerEvent("sandbox:onSoundStart", handler)
		end
		return handler
	end,
	["createMarker"] = function(...)
		local args = {...}
		local x, y, z, marker_type, size, r, g, b, a = unpack(args)
		local handler = createMarker(x, y, z, marker_type, size, r, g, b, a)
		if handler then
			setElementDimension(handler, getElementDimension(localPlayer))
		end
		return handler
	end,
	["dxDrawImage"] = function(...)
		local args = {...}
		if type(args[5]) == "string" then
			args[5] = _activeMapDirectory..args[5]
		end
		if (type(args[5]) == "string" and not fileExists(args[5])) and not isElement(args[5]) then
			return
		end
		return dxDrawImage(unpack(args))
	end,
	["dxDrawImageSection"] = function(...)
		local args = {...}
		if type(args[9]) == "string" then
			args[9] = _activeMapDirectory..args[9]
		end
		if (type(args[5]) == "string" and not fileExists(args[9])) and not isElement(args[9]) then
			return
		end
		return dxDrawImageSection(unpack(args))
	end,
	["dxDrawMaterialLine3D"] = function(...)
		local args = {...}
		if not isElement(args[7]) then
			return
		end
		return dxDrawMaterialLine3D(unpack(args))
	end,
	["dxCreateFont"] = function(...)
		local args = {...}
		if type(args[1]) == "string" then
			args[1] = _activeMapDirectory..args[1]
		end
		if not fileExists(args[1]) then
			return "default-bold"
		end
		local handler = dxCreateFont(args[1], tonumber(args[2]) or 9)
		return handler
	end,
	["dxCreateTexture"] = function(...)
		local args = {...}
		if type(args[1]) == "string" then
			args[1] = _activeMapDirectory..args[1]
		end
		if not fileExists(args[1]) then
			return
		end
		local handler = dxCreateTexture(unpack(args))
		return handler
	end,
	["dxGetTexturePixels"] = function(...)
		local args = {...}
		if not isElement(args[1]) or not isElement(args[2]) then
			return
		end
		return dxGetTexturePixels(unpack(args))
	end,
	["dxCreateShader"] = function(...)
		local args = {...}
		args[1] = _activeMapDirectory..args[1]
		args[2] = -1
		if not fileExists(args[1]) then
			return false
		end
		local handler, tecnique = dxCreateShader(unpack(args))
		return handler, tecnique
	end,
	["dxSetShaderValue"] = function(...)
		local args = {...}
		if not isElement(args[1]) or not args[3] then
			return
		end
		local valueType = type(args[3])
		if valueType == "string" then
			return
		end
		return dxSetShaderValue(unpack(args))
	end,
	["destroyElement"] = function(element)
		if element == root or element == localPlayer or element == resourceRoot or not isElement(element) then
			return
		end
		return destroyElement(element)
	end,
	["getElementData"] = function(element, key)
		local info = _data.elementData[element]
		return info and info[key] or getElementData(element, key)
	end,
	["getElementDimension"] = function(...)
		local args = {...}
		return getElementDimension(unpack(args)) - getElementDimension(localPlayer)
	end,
	["setElementData"] = function(element, key, value, ...)
		if not isElement(element) then
			return
		end
		if not _data.elementData[element] then
			_data.elementData[element] = {}
		end
		_data.elementData[element][key] = value
		return true
	end,
	["setElementDimension"] = function(...)
		local args = {...}
		if args[1] == localPlayer then
			return
		end
		args[2] = args[2] + getElementDimension(localPlayer)
		return setElementDimension(unpack(args))
	end,
	["setElementModel"] = function(...)
		local args = {...}
		if getElementType(args[1]) == "player" or not isElement(args[1]) or not args[2] then
			return
		end
		triggerServerEvent("sandbox:syncFunction", localPlayer, "setElementModel", unpack(args))
		return setElementModel(...)
	end,
	["setElementAlpha"] = function(...)
		return setElementAlpha(...)
	end,
	["engineImportTXD"] = function(...)
		local args = {...}
		if not args[1] or _staticModels[args[2]] then
			return
		end
		local model = args[2]
		tableInsert(_data.replacedModels, args)
		return engineImportTXD(...)
	end,
	["engineLoadCOL"] = function(...)
		local args = {...}
		args[1] = _activeMapDirectory..args[1]
		if not fileExists(args[1]) then
			return false
		end
		local handler = engineLoadCOL(unpack(args))
		if handler then
			tableInsert(_data.elements, handler)
		end
		return handler
	end,
	["engineLoadDFF"] = function(...)
		local args = {...}
		args[1] = _activeMapDirectory..args[1]
		if not fileExists(args[1]) then
			return false
		end
		local handler = engineLoadDFF(unpack(args))
		if handler then
			tableInsert(_data.elements, handler)
		end
		return handler
	end,
	["engineLoadTXD"] = function(...)
		local args = {...}
		args[1] = _activeMapDirectory..args[1]
		if not fileExists(args[1]) then
			return false
		end
		local handler = engineLoadTXD(unpack(args))
		if handler then
			tableInsert(_data.elements, handler)
		end
		return handler
	end,
	["engineReplaceCOL"] = function(...)
		local args = {...}
		if _staticModels[args[2]] then
			return
		end
		local model = args[2]
		tableInsert(_data.replacedModels, args)
		return engineReplaceCOL(...)
	end,
	["engineReplaceModel"] = function(...)
		local args = {...}
		if not isElement(args[1]) then
			return false
		end
		if _staticModels[args[2]] then
			return
		end
		local model = args[2]
		tableInsert(_data.replacedModels, args)
		return engineReplaceModel(...)
	end,
	["engineApplyShaderToWorldTexture"] = function(...)
		local args = {...}
		if args[2] and _forbiddenWorldTextures[args[2]] then
			return false
		end
		table.insert(_data.shaders, args)
		if _data.shadersEnabled then
			return engineApplyShaderToWorldTexture(...)
		else
			return true
		end
	end,
	["engineRemoveShaderFromWorldTexture"] = function(...)
		if not _data.shadersEnabled then
			return engineRemoveShaderFromWorldTexture(...)
		else
			return true
		end
	end,
	["fileCopy"] = function(...)
		local args = {...}
		args[1] = _activeMapDirectory..args[1]
		args[2] = _activeMapDirectory..args[2]
		return fileCopy(unpack(args))
	end,
	["fileCreate"] = function(...)
		local args = {...}
		args[1] = _activeMapDirectory..args[1]
		local handler = fileCreate(unpack(args))
		tableInsert(_data.fileHandlers, handler)
		return handler
	end,
	["fileDelete"] = function(...)
		local args = {...}
		args[1] = _activeMapDirectory..args[1]
		return fileDelete(unpack(args))
	end,
	["fileExists"] = function(...)
		local args = {...}
		args[1] = _activeMapDirectory..args[1]
		return fileExists(unpack(args))
	end,
	["fileOpen"] = function(...)
		local args = {...}
		args[1] = _activeMapDirectory..args[1]
		local handler = fileOpen(unpack(args))
		tableInsert(_data.fileHandlers, handler)
		return handler
	end,
	["fileRename"] = function(...)
		local args = {...}
		args[1] = _activeMapDirectory..args[1]
		args[2] = _activeMapDirectory..args[2]
		return fileRename(unpack(args))
	end,
	["guiCreateFont"] = function(...)
		local args = {...}
		args[1] = _activeMapDirectory..args[1]
		local handler = guiCreateFont(unpack(args))
		return handler
	end,
	["bindKey"] = function(...)
		local args = {...}
		args[1] = string.lower(args[1])
		if _forbiddenKeys[args[1]] and getElementData(localPlayer, "scriptloader_keys_forbidden") then
			return
		elseif _forbiddenKeys_noOverwrite[args[1]] then
			return
		end
		tableInsert(_data.boundKeys, args)
		return bindKey(unpack(args))
	end,
	["unbindKey"] = function(...)
		local args = {...}
		args[1] = string.lower(args[1])
		for i, v in pairs(_data.boundKeys) do
			if v[1] == args[1] and v[2] == args[2] and v[3] == args[3] then
				return unbindKey(unpack(args))
			end
		end
		return false
	end,
	["addCommandHandler"] = function(...)
		local args = {...}
		tableInsert(_data.commandHandlers, {args[1], args[2]})
		return addCommandHandler(unpack(args))
	end,
	["createObject"] = function(...)
		local args = {...}
		local handler = createObject(unpack(args))
		if not handler then
			return
		end
		if _skyboxModels[args[1]] then
			tableInsert(_data.staticObjects, handler)
			if not _data.shadersEnabled then
				setElementDimension(handler, getElementDimension(localPlayer) + 1)
			else
				setElementDimension(handler, getElementDimension(localPlayer))
			end
		else
			setElementDimension(handler, getElementDimension(localPlayer))
		end
		tableInsert(_data.objectsCreated, handler)
		return handler
	end,
	["setObjectScale"] = function(...)
		return setObjectScale(...)
	end,
	["getResourceConfig"] = function(...)
		local args = {...}
		args[1] = _activeMapDirectory..args[1]
		return getResourceConfig(unpack(args))
	end,
	["addVehicleUpgrade"] = function(...)
		local args = {...}
		if not isElement(args[1]) or not _upgrades[args[2]] then
			return
		end
		triggerServerEvent("sandbox:syncFunction", localPlayer, "addVehicleUpgrade", unpack(args))
		return addVehicleUpgrade(...)
	end,
	["removeVehicleUpgrade"] = function(...)
		local args = {...}
		if not _upgrades[args[2]] then
			return
		end
		return removeVehicleUpgrade(...)
	end,
	["xmlCreateFile"] = function(...)
		local args = {...}
		args[1] = _activeMapDirectory..args[1]
		local handler = xmlCreateFile(unpack(args))
		tableInsert(_data.xmlHandlers, handler)
		return handler
	end,
	["xmlLoadFile"] = function(...)
		local args = {...}
		args[1] = _activeMapDirectory..args[1]
		if not fileExists(args[1]) then
			return false
		end
		local handler = xmlLoadFile(unpack(args))
		tableInsert(_data.xmlHandlers, handler)
		return handler
	end,
	["xmlCopyFile"] = function(...)
		local args = {...}
		args[2] = _activeMapDirectory..args[2]
		return xmlCopyFile(unpack(args))
	end,
	["showCursor"] = function(...)
		local args = {...}
		_data.isCursorModified = args[1] or args[2]
		return showCursor(...)
	end,
	["getElementsByType"] = function(...)
		local args = {...}
		local info, info_new = getElementsByType(...), {}
		local dimension = getElementDimension(localPlayer)
		for i = 1, #info do
			local v = info[i]
			if getElementDimension(v) == dimension then
				tableInsert(info_new, v)
			end
		end
		return info_new
	end,
	["getElementVelocity"] = function(element)
		if isElement(element) then
			return getElementVelocity(element)
		else
			return 0, 0, 0
		end
	end,
	["createProjectile"] = function(...)
		local args = {...}
		local vehicle = getPedOccupiedVehicle(localPlayer)
		if args[1] == localPlayer or (isElement(vehicle) and args[1] == vehicle) then
			return
		end
		return createProjectile(...)
	end,
	["getCameraTarget"] = function()
		local cameraTarget = getCameraTarget()
		return isElement(cameraTarget) and cameraTarget or (getPedOccupiedVehicle(localPlayer) or localPlayer)
	end,
}

function _game_reset()
	setRadioChannel(0)
	setCameraShakeLevel(0)
	setCameraInterior(0)
	setCursorAlpha(255)
	setElementAlpha(localPlayer, 255)
	dxSetBlendMode("blend")
	guiSetInputEnabled(false)
	toggleAllControls(true)
	resetSkyGradient()
	resetWaterColor()
	setWaveHeight(0)
	resetWaterLevel()
	setGameSpeed(1)
	setGravity(0.008)
	setCloudsEnabled(false)
	forcePlayerMap(false)
	setOcclusionsEnabled(true)
	setWaterDrawnLast(true)
	resetRainLevel()
	resetSunSize()
	resetNearClipDistance()
	resetVehiclesLODDistance()
	resetSunColor()
	resetFarClipDistance()
	resetWindVelocity()
	resetMoonSize()
	resetFogDistance()
	resetHeatHaze()
	restoreAllWorldModels()
	setWorldSpecialPropertyEnabled("hovercars", false)
	setWorldSpecialPropertyEnabled("aircars", false)
	setWorldSpecialPropertyEnabled("extrabunny", false)
	setWorldSpecialPropertyEnabled("extrajump", false)
	setWorldSpecialPropertyEnabled("randomfoliage", true)
	setWorldSpecialPropertyEnabled("snipermoon", false)
	setWorldSpecialPropertyEnabled("extraairresistance", true)
end

function _data_reset()
	_environment_unready()
	if next(_data) ~= nil then
		local pairs = pairs
		for i, v in pairs(_data.eventHandlers) do
			removeEventHandler(unpack(v))
		end
		for i, v in pairs(getTimers()) do
			killTimer(v)
		end
		for i, v in pairs(_data.boundKeys) do
			unbindKey(unpack(v))
		end
		for i, v in pairs(_data.commandHandlers) do
			removeCommandHandler(unpack(v))
		end
		for i, v in pairs(_data.fileHandlers) do
			fileClose(v)
		end
		for i, v in pairs(_data.xmlHandlers) do
			if isElement(v) then
				xmlUnloadFile(v)
			end
		end
		for i, v in pairs(_data.LODDistance) do
			engineSetModelLODDistance(i, v)
		end
		for i, v in pairs(_data.objectsCreated) do
			if isElement(v) then
				destroyElement(v)
			end
		end
		for i, v in pairs(_data.replacedModels) do
			engineRestoreModel(v[2])
		end
		for i, v in pairs(_data.elements) do
			if isElement(v) then
				destroyElement(v)
			end
		end
		if _data.isCursorModified then
			showCursor(false, false)
		end
	end
	destroyElement(resourceRoot)
	local savedShadersState = _data.shadersEnabled
	_data = {}
	_data.eventHandlers = {}
	_data.elementData = {}
	_data.boundKeys = {}
	_data.commandHandlers = {}
	_data.fileHandlers = {}
	_data.xmlHandlers = {}
	_data.LODDistance = {}
	_data.objectsCreated = {}
	_data.staticObjects = {}
	_data.replacedModels = {}
	_data.elements = {}
	_data.soundHandlers = {}
	_data.shaders = {}
	_data.shadersEnabled = savedShadersState
	triggerEvent("sandbox:onDataReset", localPlayer)
end
addEventHandler("onClientResourceStop", resourceRoot, _data_reset)

function _environment_reset()
	local startTick = getTickCount()
	_data_reset()
	_sandbox = {}
	local env = {}
	env.__index = function(t, k)
		local r = rawget(_G, "_getglobalenv")(k)
		return r or rawget(t, k)
	end
	env.__newindex = function(t, k, v)
		local r = rawget(_G, "_setglobalenv")(k, v)
		return r or rawset(t, k, v)
	end
	setmetatable(_sandbox, env)
	local string_sub = string.gsub
	local type = type
	for k, v in pairs(_G) do
		if type(v) ~= "variable" and string_sub(k, 1, 1) ~= "_" then
			local v = v
			_sandbox[k] = v
		end
	end
	local function stub()
		return
	end
	for k, v in pairs(_replace) do
		if v == true then
			local v = _G[k]
			_sandbox[k] = function(...)
				local e = v(...)
				if not e then
					return
				end
				if isElement(e) then
					setElementDimension(e, getElementDimension(localPlayer))
				end
				return e
			end
		elseif type(v) == "function" then
			local v = v
			_sandbox[k] = v
		elseif v == false then
			_sandbox[k] = stub
		end
	end
	_sandbox["_G"] = _sandbox
	outputDebugString("Sandbox has been reset for "..getTickCount() - startTick.." ms", 0, 55, 155, 255)
end

function _getglobalenv(key, value)
	if key == "localPlayer" then
		return localPlayer
	elseif key == "source" then
		return source
	elseif key == "this" then
		return this
	elseif key == "eventName" then
		return eventName
	elseif key == "resource" then
		return resource
	elseif key == "resourceRoot" then
		return resourceRoot
	elseif key == "guiRoot" then
		return guiRoot
	elseif key == "root" then
		return root
	end
end

function _setglobalenv(key, value)
	if key == "source" then
		source = value
		return true
	elseif key == "this" then
		this = value
		return true
	elseif key == "eventName" then
		eventName = value
		return true
	elseif key == "resource" then
		resource = value
		return true
	elseif key == "resourceRoot" then
		resourceRoot = value
		return true
	elseif key == "guiRoot" then
		guiRoot = value
		return true
	elseif key == "localPlayer" then
		localPlayer = value
		return true
	elseif key == "root" then
		root = value
		return true
	end
end

function _environment_load(_string)
	local chunk, error = loadstring(_string)
	if chunk then
		setfenv(chunk, _sandbox)
		chunk = load(chunk)
		_, error = pcall(chunk)
		error = error and outputDebugString("Sandbox script error: "..tostring(error), 0, 55, 155, 255)
		return not error
	else
		outputDebugString("Sanbox script error: "..tostring(error), 0, 55, 155, 255)
		return false
	end
end

addEvent("onClientFakeResourceStart", true)
function _environment_ready()
	if _sandbox.currentStateIsReady then
		return
	end
	_sandbox.currentStateIsReady = true
	triggerEvent("onClientFakeResourceStart", resourceRoot)
	outputDebugString("_environment_ready triggered", 0, 55, 155, 255)
end

addEvent("onClientFakeResourceStop", true)
function _environment_unready()
	if not _sandbox.currentStateIsReady then
		return
	end
	_sandbox.currentStateIsReady = nil
	triggerEvent("onClientFakeResourceStop", resourceRoot)
	outputDebugString("_environment_unready triggered", 0, 55, 155, 255)
end

function _toggle_shaders(noToggle)
	if not getElementData(localPlayer, "arena") or getElementData(localPlayer, "arena") == "lobby" then
		return
	end
	_data.shadersEnabled = not _data.shadersEnabled
	local dimension = getElementDimension(localPlayer)
	if _data.shadersEnabled then
		for i, object in pairs(_data.staticObjects) do
			setElementDimension(object, dimension)
		end
	else
		dimension = dimension + 1
		for i, object in pairs(_data.staticObjects) do
			setElementDimension(object, dimension)
		end
	end
	if _data.shadersEnabled and isElement(_data.replaceShader) then
		engineRemoveShaderFromWorldTexture(_data.replaceShader, "*")
	end
	for i, shader in pairs(_data.shaders) do
		if isElement(shader[1]) then
			if not _data.shadersEnabled then
				engineRemoveShaderFromWorldTexture(shader[1], shader[2])
			else
				engineApplyShaderToWorldTexture(unpack(shader))
			end
		end
	end
	triggerEvent("notification:create", localPlayer, "Shaders", "Map shaders are now "..(_data.shadersEnabled and "enabled" or "disabled"))
end
bindKey("N", "down", _toggle_shaders)

addEventHandler("onClientResourceStart", resourceRoot, function()
	triggerServerEvent("scriptloader:onClientResourceStart", resourceRoot)
end)

addEvent("scriptloader:setCacheDirectory", true)
addEventHandler("scriptloader:setCacheDirectory", resourceRoot, function(port)
	_cacheDirectory = port == 22003 and "http://164.132.114.156:8080/mainresourcecache" or _cacheDirectory
end)