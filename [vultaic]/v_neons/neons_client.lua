local shaders, textures = {}, {}
addEvent("custom:onClientVehicleStreamIn", true)
addEvent("custom:onClientVehicleStreamOut", true)
addEvent("custom:onClientPlayerVehicleEnter", true)

-- Toggle
function toggleFeature(state)
	featureEnabled = state
	--print("Toggled neons: "..tostring(featureEnabled))
	removeEventHandler("custom:onClientVehicleStreamIn", root, updateVehicleNeon)
	removeEventHandler("custom:onClientVehicleStreamOut", root, destroyVehicleNeon)
	removeEventHandler("custom:onClientPlayerVehicleEnter", root, updateVehicleNeon)
	removeEventHandler("onClientElementDataChange", root, updateVehicleNeon)
	removeEventHandler("onClientPreRender", root, renderNeons)
	if featureEnabled then
		for i, vehicle in pairs(getElementsByType("vehicle")) do
			if isElementStreamedIn(vehicle) then
				updateVehicleNeon(vehicle, getVehicleOccupant(vehicle))
			end
		end
		addEventHandler("custom:onClientVehicleStreamIn", root, updateVehicleNeon)
		addEventHandler("custom:onClientVehicleStreamOut", root, destroyVehicleNeon)
		addEventHandler("custom:onClientPlayerVehicleEnter", root, updateVehicleNeon)
		addEventHandler("onClientElementDataChange", root, updateVehicleNeon)
		addEventHandler("onClientPreRender", root, renderNeons)
	else
		clearAllNeons()
	end
end

function initNeons()
	textures = {}
	pack = {}
	local metaFile = xmlLoadFile("meta.xml")
	if metaFile then
		for i, node in pairs (xmlNodeGetChildren(metaFile)) do
			local info = xmlNodeGetAttributes(node)
			if xmlNodeGetName(node) == "file" and info["neon"] then
				textures[info["src"]] = true
				table.insert(pack, info["src"])
			end
		end
		xmlUnloadFile(metaFile)
	end
	triggerEvent("neons:onTexturesUpdate", localPlayer, textures)
	local state = not (exports.v_settings:getClientVariable("disable_neons") == "Off")
	toggleFeature(state)
end
addEventHandler("onClientResourceStart", resourceRoot, initNeons)

addEventHandler("onClientRestore", root,
function()
	for player, data in pairs(shaders) do
		createNeonTexture(data.texture, player, unpack(data.rgb))
	end
end)

addEvent("settings:onSettingChange", true)
addEventHandler("settings:onSettingChange", localPlayer,
function(variable, value)
	if variable == "disable_neons" then
		initNeons()
	end
end)

function updateVehicleNeon(vehicle, player)
	if isElement(player) and isElement(vehicle) then
		destroyVehicleNeon(player)
		local neon = getElementData(player, "neon")
		if not neon or type(neon) ~= "table" then
			return
		end
		local _type = tonumber(neon.neon_type) or nil
		if not _type or _type == 0 then
			return
		end
		local texture = neon.neon_texture
		if not texture or not textures[texture] then
			return
		end
		local path = "fx/type".._type..".fx"
		if not fileExists(path) then
			return
		end
		if not shaders[player] or not isElement(shaders[player].shader) then
			destroyVehicleNeon(player)
			local shader = createNeonShader(path)
			if shader then
				shaders[player] = {shader = shader}
				local hex = neon.neon_color or "#FFFFFF"
				local r, g, b = hexToRGB(hex)
				local rate = tonumber(neon.neon_rate or 1)
				shaders[player].rgb = {r, g, b}
				dxSetShaderValue(shader, "rgb", r/255, g/255, b/255)
				dxSetShaderValue(shader, "rate", rate)
				if _type == 4 or _type == 5 or _type == 6 then
					if textures[texture] then
						shaders[player].texture = texture
						createNeonTexture(texture, player, r, g, b)
						if not shaders[player].renderTarget then
							destroyVehicleNeon(player)
						end
					end
				end
				--print("Applied neon for "..getPlayerName(player))
			end
		end
	end
end

function createNeonShader(path)
	local shader = dxCreateShader(path, 0, 50, true, "world,object")
	if not isElement(shader) then
		return false
	end
	engineApplyShaderToWorldTexture(shader, "*")
	local removeTable = {
		"", "*spoiler*", "*particle*", "*light*",
		"vehicle*", "?emap*", "?hite*",
		"*92*", "*wheel*", "*interior*",
		"*handle*", "*body*", "*decal*",
		"*8bit*", "*logos*", "*badge*",
		"*plate*", "*sign*",
		"*headlight*",
		"*shad*",
		"coronastar",
		"tx*",
		"lod*",
		"cj_w_grad",
		"*cloud*",
		"*smoke*",
		"sphere_cj",
		"particle*",
		"*water*", "coral",
		"shpere", "*inferno*", "*fire*", "*cypress*", "list",
		"*brtb*", "*tree*", "*leave*", "*spark*", "*eff*", "*branch", "*ash*", "*fire*", "*rocket*", "*hud*",
		"bark2", "bchamae", "*sfx*", "*wires*", "*agave*", "*plant*", "neon", "*log*",
		"sjmshopbk",
		"*sand*", "*radar*",
		"*skybox*",
		"metalox64", "metal1_128",
		"nitro", "repair", "carchange",
		"bullethitsmoke",
		"toll_sfw1", "toll_sfw3", "trespasign1_256", "steel64", "beachwalkway", "ws_greymeta", "telepole2128", "ah_barpanelm",
		"plasticdrum1_128", "planks01", "unnamed", "aascaff128"
	}
	for i, v in ipairs(removeTable) do
		engineRemoveShaderFromWorldTexture(shader, v)
	end
	return shader
end

function createNeonTexture(texture, player, r, g, b)
	local path = textures[texture] and texture or nil
	if not path or not fileExists(path) or not shaders[player] or not isElement(shaders[player].shader) then
		return
	end
	local renderTarget = dxCreateRenderTarget(512, 512, true)
	if not isElement(renderTarget) then
		return
	end
	local r, g, b = r or 255, g or 255, b or 255
	dxSetRenderTarget(renderTarget, true)
	dxDrawImage(0, 512, 512, -512, path, 0, 0, 0, tocolor(r, g, b, 255))
	dxSetRenderTarget()
	dxSetShaderValue(shaders[player].shader, "tex", renderTarget)
	shaders[player].renderTarget = renderTarget
	return renderTarget
end

function handleDataChange(dataName)
	if dataName == "neon" and getElementType(source) == "player" and isElementStreamedIn(source) then
		updateVehicleNeon(getPedOccupiedVehicle(source), source)
	end
end
addEventHandler("onClientElementDataChange", root, handleDataChange)

function destroyVehicleNeon(player)
	local data = shaders[player]
	if isElement(player) and data then
		if data.shader then
			destroyElement(data.shader)
		end
		if data.renderTarget then
			destroyElement(data.renderTarget)
		end
		shaders[player] = nil
		--print("Destroyed neons for "..getPlayerName(player))
	end
end
addEvent("neons:destroyVehicleNeon", true)
addEventHandler("neons:destroyVehicleNeon", resourceRoot, destroyVehicleNeon)

function clearAllNeons()
	for player in pairs(shaders) do
		destroyVehicleNeon(player)
	end
	shaders = {}
	--print("Cleared all neons")
end
addEvent("core:onClientLeaveArena", true)
addEventHandler("core:onClientLeaveArena", localPlayer, clearAllNeons)

function renderNeons()
	for player, data in pairs(shaders) do
		while true do
			local vehicle = getPedOccupiedVehicle(player)
			if not isElement(vehicle) or getElementType(vehicle) ~= "vehicle" then
				destroyVehicleNeon(player)
				break
			end
			local vehicleType = getVehicleType(vehicle)
			if vehicleType ~= "Automobile" then
				destroyVehicleNeon(player)
				break
			end
			local streamed = isElementStreamedIn(vehicle)
			if not streamed then
				destroyVehicleNeon(player)
				break
			end
			if not data.shader or not isElement(data.shader) then
				destroyVehicleNeon(player)
				break
			end
			local boundingBox = {getElementBoundingBox(vehicle)}
			local size = math.max(math.abs(math.min(unpack(boundingBox))), math.max(unpack(boundingBox))) * 2
			dxSetShaderValue(data.shader, "scale", size)
			local minz = boundingBox[3]
			local px, py, pz = getPositionFromElementOffset(vehicle, 0, 0, minz * 0.5)
			dxSetShaderValue(data.shader, "pos", px, py, pz)
			local mx, my, mz = getPositionFromElementOffset(vehicle, 0, 0, -1)
			dxSetShaderValue(data.shader, "mt", mx - px, my - py, mz - pz)
			local rx, ry, rz = getElementRotation(vehicle, "ZYX")
			rx, ry, rz = -math.rad(rx), -math.rad(ry), -math.rad(rz)
			dxSetShaderValue(data.shader, "rt", ry, rx, rz)
			break
		end
	end
end

function getPositionFromElementOffset(element, offX, offY, offZ)
	local m = getElementMatrix(element)
	local x = offX * m[1][1] + offY * m[2][1] + offZ * m[3][1] + m[4][1]
	local y = offX * m[1][2] + offY * m[2][2] + offZ * m[3][2] + m[4][2]
	local z = offX * m[1][3] + offY * m[2][3] + offZ * m[3][3] + m[4][3]
	return x, y, z
end

_getVehicleOccupant = getVehicleOccupant
function getVehicleOccupant(vehicle)
	if isElement(vehicle) and getElementType(vehicle) == "vehicle" then
		if getElementData(vehicle, "garage.vehicle") then
			return localPlayer
		end
		return _getVehicleOccupant(vehicle)
	end
end

_getPedOccupiedVehicle = getPedOccupiedVehicle
function getPedOccupiedVehicle(player)
	if isElement(player) then
		if player == localPlayer then
			local garageVehicle = getElementData(localPlayer, "garage.vehicle")
			return isElement(garageVehicle) and garageVehicle or _getPedOccupiedVehicle(localPlayer)
		else
			return _getPedOccupiedVehicle(player)
		end
	end
end

function hexToRGB(hex)
	hex = hex:gsub("#", "") 
	return tonumber("0x"..hex:sub(1, 2)) or 255, tonumber("0x"..hex:sub(3, 4)) or 255, tonumber("0x"..hex:sub(5, 6)) or 255
end

function getNeonTextures()
	return pack
end