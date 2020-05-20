login = {}
login.width, login.height = math.floor(360 * relativeScale), math.floor(520 * math.min(math.max(screenHeight/900, 0.8), 1))
login.width, login.height = login.width - (login.width % 10), login.height - (login.height % 10)
login.x, login.y = (screenWidth - login.width)/2, (screenHeight - login.height)/2
login.fontScale = 1
login.font = dxlib.getFont("Roboto-Regular", 13)
login.fontHeight = dxGetFontHeight(login.fontScale, login.font)
login.interpolator = "Linear"
local container = nil
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
	["rectangle_header"] = {type = "rectangle", x = 0, y = 0, width = login.width, height = login.fontHeight * 2, color = tocolor(20, 20, 20, 245)},
	["label_title"] = {type = "label", text = "Welcome, please log into your account", x = 0, y = 0, width = login.width, height = login.fontHeight * 2, font = dxlib.getFont("RobotoCondensed-Regular", 14), horizontalAlign = "center"},
	["custom_avatar"] = {type = "custom", x = 0, y = login.fontHeight * 2 + 10, width = login.width, height = login.height/2 - (login.fontHeight + login.fontHeight * 2) - 20, font = dxlib.getFont("RobotoCondensed-Regular", 16), horizontalAlign = "center"},
	["input_username"] = {type = "input", placeholder = "Username", x = 0, y = login.height/2 - login.fontHeight - 1, width = login.width, height = login.fontHeight * 2, maxLength = 20, horizontalAlign = "center"},
	["input_password"] = {type = "input", placeholder = "Password", passwordInput = true, x = 0, y = login.height/2 + login.fontHeight + 1, width = login.width, height = login.fontHeight * 2, maxLength = 25, horizontalAlign = "center"},
	["button_login"] = {type = "button", text = "Log in", x = login.width * 0.5 + 2.5, y = login.height - 45, width = login.width * 0.3, height = 35},
	["button_guest"] = {type = "button", text = "Guest", x = login.width * 0.2 - 2.5, y = login.height - 45, width = login.width * 0.3, height = 35, backgroundColor = tocolor(25, 155, 255, 55), hoverColor = {25, 155, 255, 255}},
	["selector_savedetails"] = {type = "selector", values = {"Remember", "Do not remember"}, x = 30, y = login.height/2 + login.fontHeight + 45, width = login.width - 60, height = 40},
}

setElementData(localPlayer, "login.skipped", false, false)
addEventHandler("onClientResourceStart", resourceRoot,
function()
	container = dxlib.createContainer({title = "Login", x = login.x, y = login.y, width = login.width, height = login.height})
	if container then
		for i, item in pairs(items) do
			dxlib.registerItem(container.id, item)
		end
	end
	login.replaceShader = dxCreateShader("fx/txReplace.fx")
	login.renderTarget = dxCreateRenderTarget(login.width, login.height, true)
	login.avatarSize = math.floor(items["custom_avatar"].height * 0.45)
	login.avatarOffsetX, login.avatarOffsetY = (items["custom_avatar"].width - login.avatarSize)/2, (items["custom_avatar"].height - login.avatarSize)/2
	items["custom_avatar"].renderingFunction = function(x, y, item)
		local distance = 20 * (1 - login.avatarProgress)
		dxDrawClientAvatar(localPlayer, x + login.avatarOffsetX, y + login.avatarOffsetY - distance, login.avatarSize, 255 * login.avatarProgress)
	end
	items["input_username"].onTextChange = function(text)
		if login.avatarRefreshTimer and isTimer(login.avatarRefreshTimer) then
			killTimer(login.avatarRefreshTimer)
		end
		--if #text > 2 then
			--login.avatarRefreshTimer = setTimer(function()
				--triggerServerEvent("login:getAvatar", localPlayer, text)
			--end, 100, 1)
		--end
	end
	items["button_login"].onClick = function()
		local username, password = items["input_username"].text, items["input_password"].text
		if not username then
			return triggerEvent("notification:create", localPlayer, "Log in", "Please enter your username")
		elseif not password then
			return triggerEvent("notification:create", localPlayer, "Log in", "Please enter your password")
		end
		triggerServerEvent("login:onPlayerRequestLogin", localPlayer, username, password)
	end
	items["button_guest"].onClick = function()
		triggerServerEvent("login:onPlayerRequestPlayAsGuest", localPlayer)
	end
	setTimer(login.check, 500, 1)
end)

function login.show()
	if login.visible then
		return
	end
	login.tick = getTickCount()
	login.visible = true
	dxlib.activate()
	dxlib.setActiveContainer(container.id)
	showCursor(true)
	showChat(false)
	loadDetails()
	removeEventHandler("onClientRender", root, login.render)
	addEventHandler("onClientRender", root, login.render, true, "low-2")
	guiSetInputMode("allow_binds")
	setElementData(localPlayer, "login.visible", login.visible, false)
	triggerEvent("lobby:updateTime", localPlayer)
	triggerEvent("blur:enable", localPlayer, "login")
end

function login.hide()
	if not login.visible then
		return
	end
	login.tick = getTickCount()
	login.visible = false
	dxlib.deactivate()
	showCursor(false)
	guiSetInputMode("allow_binds")
	setElementData(localPlayer, "login.visible", login.visible, false)
	triggerEvent("blur:disable", localPlayer, "login")
end

function login.render()
	local currentTick = getTickCount()
	local tick = login.tick or 0
	login.progress = interpolateBetween(login.progress or 0, 0, 0, login.visible and 1 or 0, 0, 0, math_min(1000, currentTick - tick)/1000, login.interpolator)
	login.avatarProgress = interpolateBetween(0, 0, 0, 1, 0, 0, math_min(500, currentTick - (login.avatarRefreshTick or 0))/500, login.interpolator)
	if not login.visible and login.progress == 0 then
		if login.triggerSkipEvent then
			if isElement(clientPreviewAvatar) then
				destroyElement(clientPreviewAvatar)
			end
			setElementData(localPlayer, "previewAvatarTexture", nil, false)
			triggerEvent("login:onSkip", localPlayer)
			login.triggerSkipEvent = nil
		end
		removeEventHandler("onClientRender", root, login.render)
		return
	end
	local renderTarget = dxlib.renderContainer(container.id, login.renderTarget)
	local _, _, cX, cY = getCursorPosition()
	cX, cY = tonumber(cX or 0.5), tonumber(cY or 0.5)	
	dxSetShaderValue(login.replaceShader, "tex", renderTarget)
	dxSetShaderTransform(login.replaceShader, -2 + 4 * cX, -2 + 4 *  cY, 0)
	dxDrawImage(login.x, login.y, login.width, login.height, login.replaceShader, 0, 0, 0, tocolor(255, 255, 255, 255 * login.progress), false)
end

addEventHandler("onClientElementDataChange", root,
function(dataName)
	if source == localPlayer and dataName == "previewAvatarTexture" then
		login.avatarRefreshTick = getTickCount()
	end
end)

function login.check()
	local arena = getElementData(localPlayer, "arena") or "lobby"
	if getElementData(localPlayer, "login.skipped") then
		return
	end
	login.show()
end

addEvent("login:onClientLogin", true)
addEventHandler("login:onClientLogin", resourceRoot,
function()
	if login.visible then
		login.hide()
		local save = tonumber(items["selector_savedetails"].currentID or 1)
		if save == 1 then
			saveDetails(items["input_username"].text, items["input_password"].text)
		elseif save == 2 then
			resetDetails()
		end
		setElementData(localPlayer, "login.skipped", true, false)
		login.triggerSkipEvent = true
		local arena = getElementData(localPlayer, "arena")
		if arena and arena ~= "lobby" then
			triggerEvent("blur:disable", localPlayer, "login")
			showChat(true)
		end
	end
end)

addEvent("login:onClientPlayAsGuest", true)
addEventHandler("login:onClientPlayAsGuest", resourceRoot,
function()
	login.hide()
	setElementData(localPlayer, "login.skipped", true, false)
	login.triggerSkipEvent = true
	triggerEvent("notification:create", localPlayer, "Log in", "Playing as guest")
	local arena = getElementData(localPlayer, "arena")
	if arena and arena ~= "lobby" then
		triggerEvent("blur:disable", localPlayer, "login")
		showChat(true)
	end
end)

function loadDetails()
	local path = "details"
	local file = fileExists(path) and fileOpen(path) or nil
	local details = nil
	if file then
		details = fromJSON(fileRead(file, fileGetSize(file)))
		fileClose(file)
	end
	if type(details) == "table" then
		local username, password = details.username, details.password
		if username and password then
			items["input_username"].text = tostring(username)
			items["input_password"].text = tostring(password)
		end
		createClientAvatar(username)
	end
end

function saveDetails(username, password)
	if username and password then
		resetDetails()
		local path = "details"
		local file = fileCreate(path)
		if file then
			fileWrite(file, toJSON({username = username, password = password}))
			fileClose(file)
		end
	end
end

function resetDetails()
	local path = "details"
	if fileExists(path) then
		fileDelete(path)
	end
end

function createClientAvatar(username)
	local path = "avatarcache/avatar_"..username
	if fileExists(path) then
		clientPreviewAvatar = dxCreateTexture(path)
		setElementData(localPlayer, "previewAvatarTexture", clientPreviewAvatar, false)
	end
end

function dxDrawClientAvatar(player, x, y, size, alpha)
	if not isElement(player) then
		return
	end
	if not login.maskShader then
		login.maskShader = dxCreateShader("fx/mask.fx")
	end
	if not login.maskTexture then
		login.maskTexture = dxCreateTexture("img/circle.png")
		dxSetShaderValue(login.maskShader, "maskTexture", login.maskTexture)
	end
	if not login.defaultAvatar then
		login.defaultAvatar = dxCreateTexture("img/default-avatar.png")
	end
	local texture = getElementData(localPlayer, "previewAvatarTexture")
	dxSetShaderValue(login.maskShader, "imageTexture", isElement(texture) and texture or login.defaultAvatar)
	return dxDrawImage(x, y, size, size, login.maskShader, 0, 0, 0, tocolor(255, 255, 255, tonumber(alpha or 255)), false)
end