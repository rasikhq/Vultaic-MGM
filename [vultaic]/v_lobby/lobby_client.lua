local screenWidth, screenHeight = guiGetScreenSize()
local relativeScale, relativeFontScale = math.min(math.max(screenWidth/1600, 0.5), 1), math.min(math.max(screenWidth/1600, 0.85), 1)
local lobby = {}
lobby.fontScale = 1
lobby.font = dxCreateFont(":v_locale/fonts/RobotoCondensed-Regular.ttf", math.floor(13 * relativeFontScale))
lobby.infoFont = dxCreateFont(":v_locale/fonts/RobotoCondensed-Regular.ttf", math.floor(22 * relativeFontScale))
lobby.fontHeight = dxGetFontHeight(lobby.fontScale, lobby.font)
lobby.interpolator = "Linear"
lobby.columns = 4
lobby.imageWidth, lobby.imageHeight = math.floor(250 * relativeScale), math.floor(250 * relativeScale)
lobby.imageRatio = lobby.imageHeight/lobby.imageWidth
lobby.padding = 5
lobby.subArenasToShow = math.ceil(lobby.imageHeight/(lobby.fontHeight + 14))
lobby.subArenaHeight = lobby.imageHeight/lobby.subArenasToShow
lobby.avatarSize = math.floor(lobby.fontHeight * 2.5)
lobby.leave = {size = 100 * relativeFontScale}
lobby.leave.x = screenWidth/2 - lobby.leave.size/2
lobby.leave.y = screenHeight - lobby.leave.size * 2
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
-- Arenas to be displayed
local arenas = {
	{
		imagePath = "img/dm.png",
		rows = {{id = "dm"}, {id = "os"}, {id = "hdm"}}
	},
	{
		imagePath = "img/dd.png",
		rows = {{id = "dd"}, {id = "fdd"}}
	},
	{
		imagePath = "img/race.png",
		rows = {{id = "race"}, {id = "srace"}}
	},
	{
		imagePath = "img/shooter.png",
		rows = {{id = "shooter"}, {id = "shooterjump"}}
	},
	{
		imagePath = "img/hunter.png",
		rows = {{id = "hunter"}, {id = "hunter nolimit"}}
	},
	{
		imagePath = "img/training.png",
		rows = {{id = "dm training"}, {id = "race training"}},
		new = true
	},
	{
		imagePath = "img/tdm.png",
		rows = {{id = "tdm"}},
		new = true
	},
	{
		imagePath = "img/garage.png",
		rows = {{id = "garage"}},
		new = true
	}
}

-- Cache
function lobby.cacheArenasData()
	for i, arena in pairs(arenas) do
		local totalOnline = 0
		if arena.rows then
			local offset = lobby.imageHeight - lobby.subArenaHeight
			for i, row in pairs(arena.rows) do
				if row.id then
					row.element = getElementByID(row.id) or nil
					if isElement(row.element) then
						row.title = string.shrinkToSize(getElementData(row.element, "name"), lobby.fontScale, lobby.font, lobby.imageWidth * 0.7 - 10)
						row.locked = getElementData(row.element, "locked") and true or false
						row.offset = offset
						row.invisible = false
						offset = offset - lobby.subArenaHeight
						totalOnline = totalOnline + 1
					else
						row.element = nil
						row.invisible = true
					end
				end
			end
		end
		arena.activeRows = totalOnline
		arena.closed = totalOnline == 0
	end
end
addEvent("core:syncArenasData", true)
addEventHandler("core:syncArenasData", root, lobby.cacheArenasData)

addEventHandler("onClientResourceStart", resourceRoot,
function()
	local rows = math.ceil(#arenas/lobby.columns)
	local columns = #arenas >= lobby.columns and lobby.columns or #arenas
	local totalWidth = columns * lobby.imageWidth + (columns - 1) * lobby.padding
	local totalHeight = rows * lobby.imageHeight + (rows - 1) * lobby.padding
	local centerLeft, centerTop = (screenWidth - totalWidth)/2, (screenHeight - totalHeight)/2
	local offsetX, offsetY = centerLeft, centerTop
	for i, arena in pairs(arenas) do
		if arena.imagePath and fileExists(arena.imagePath) then
			arena.image = dxCreateTexture(arena.imagePath)
			arena.imageWidth, arena.imageHeight = dxGetMaterialSize(arena.image)
		end
		arena.x = offsetX
		arena.y = offsetY
		if i % lobby.columns == 0 then
			offsetX = centerLeft
			offsetY = offsetY + lobby.imageHeight + lobby.padding
		else
			offsetX = offsetX + lobby.imageWidth + lobby.padding
		end
		if arena.rows then
			arena.rows = table.reverse(arena.rows)
		end
	end
	lobby.replaceShader = dxCreateShader("fx/txReplace.fx")
	lobby.renderTarget = dxCreateRenderTarget(screenWidth, screenHeight, true)
	progressMask = dxCreateTexture("img/progress-ring.png")
	lobby.circleShader = dxCreateShader("fx/circle.fx")
	dxSetShaderValue(lobby.circleShader, "tex_Source", progressMask)
	setElementData(localPlayer, "lobby.visible", false, false)
	lobby.check()
end)

-- Startup check
function lobby.check()
	local arena = getElementData(localPlayer, "arena") or "lobby"
	if getElementData(localPlayer, "login.skipped") and arena == "lobby" then
		lobby.show()
	end
end
addEventHandler("onClientResourceStart", resourceRoot, lobby.check)
addEvent("login:onSkip", true)
addEventHandler("login:onSkip", root, lobby.check)

function updateTime()
	setTime(5, 30)
	setWeather(17)
	setMinuteDuration(60000000)
end
addEvent("lobby:updateTime", true)
addEventHandler("lobby:updateTime", localPlayer, updateTime)

function lobby.show()
	lobby.cacheArenasData()
	lobby.tick = getTickCount()
	lobby.visible = true
	removeEventHandler("onClientRender", root, lobby.render)
	addEventHandler("onClientRender", root, lobby.render, true, "low-4")
	lobby.targetArena = nil
	setElementData(localPlayer, "lobby.visible", true, false)
	showCursor(true)
	showChat(false)
	updateTime()
	triggerEvent("blur:enable", localPlayer, "lobby")
end
addEvent("lobby:show", true)
addEventHandler("lobby:show", localPlayer, lobby.show)
addEvent("core:onClientLeaveArena", true)
addEventHandler("core:onClientLeaveArena", localPlayer, lobby.show, true, "low-5")

function lobby.hide(targetArena)
	lobby.tick = getTickCount()
	lobby.visible = false
	showCursor(false)
	lobby.targetArena = targetArena
	setElementData(localPlayer, "lobby.visible", false, false)
	if cameraMatrixTimer and isTimer(cameraMatrixTimer) then
		killTimer(cameraMatrixTimer)
	end
	showCursor(false)
	showChat(true)
	lobby.disableBlur = true
end
addEvent("lobby:hide", true)
addEventHandler("lobby:hide", localPlayer, lobby.hide)
addEvent("core:onClientJoinArena", true)
addEventHandler("core:onClientJoinArena", localPlayer, lobby.hide)

addEvent("mapmanager:onMapLoad", true)
addEventHandler("mapmanager:onMapLoad", localPlayer,
function()
	if lobby.disableBlur then
		triggerEvent("blur:disable", localPlayer, "lobby")
		lobby.disableBlur = nil
	end
end)

-- Rendering
function lobby.render()
	local currentTick = getTickCount()
	local tick = lobby.tick or 0
	lobby.progress = interpolateBetween(lobby.progress or 0, 0, 0, lobby.visible and 1 or 0, 0, 0, math_min(1000, currentTick - tick)/1000, lobby.interpolator)
	if not lobby.visible and lobby.progress == 0 then
		if lobby.targetArena then
			triggerServerEvent("core:onPlayerRequestJoinArena", localPlayer, lobby.targetArena.id)
		end
		removeEventHandler("onClientRender", root, lobby.render)
		return
	end
	local playersCount = #getElementsByType("player")
	dxDrawText(playersCount, 0, 0, screenWidth, screenHeight * 0.9, tocolor(255, 255, 255, 155 * lobby.progress), lobby.fontScale, lobby.infoFont, "center", "bottom", true)
	dxDrawText((playersCount == 1 and "PLAYER" or "PLAYERS").." ONLINE", 0, 0, screenWidth, screenHeight * 0.9 + lobby.fontHeight + 5, tocolor(255, 255, 255, 155 * lobby.progress), lobby.fontScale, lobby.font, "center", "bottom", true)
	dxSetRenderTarget(lobby.renderTarget, true)
	dxSetBlendMode("modulate_add")
	for i, arena in pairs(arenas) do
		local tick = arena.tick or 0
		arena.hover = interpolateBetween(arena.hover or 0, 0, 0, lobby.hoveredArena == arena and 1 or 0, 0, 0, math_min(500, currentTick - tick)/500, lobby.interpolator)
		dxDrawRectangle(arena.x, arena.y, lobby.imageWidth, lobby.imageHeight, tocolor(10, 10, 10, 185))		
		if arena.closed then
			dxDrawText("Closed", arena.x, arena.y, arena.x + lobby.imageWidth, arena.y + lobby.imageHeight, tocolor(255, 255, 255, 205), lobby.fontScale, lobby.font, "center", "center", true)
		else
			if arena.image then
				local usize, vsize = arena.imageWidth, arena.imageWidth * lobby.imageRatio
				local u, v = arena.imageWidth - usize, arena.imageHeight - vsize
				dxDrawImageSection(arena.x, arena.y, lobby.imageWidth, lobby.imageHeight, u, v, usize, vsize, arena.image, 0, 0, 0, tocolor(255, 255, 255, 255))
			end
			dxDrawRectangle(arena.x, arena.y, lobby.imageWidth, lobby.imageHeight, tocolor(10, 10, 10, 85 * arena.hover))
			if arena.rows then
				for i = 1, lobby.subArenasToShow do
					local row = arena.rows[i]
					if row and not row.invisible then
						local tick = row.tick or 0
						row.hover = interpolateBetween(row.hover or 0, 0, 0, arena.hoveredRow == row and 1 or 0, 0, 0, math_min(500, currentTick - tick)/500, lobby.interpolator)
						local playerCount, maximumPlayerCount, closed = 0, 0, true
						if isElement(row.element) then
							playerCount = #getElementChildren(row.element, "player")
							maximumPlayerCount = getElementData(row.element, "maximumPlayers") or 0
							closed = false
						end
						dxDrawRectangle(arena.x, arena.y + row.offset, lobby.imageWidth, lobby.subArenaHeight, tocolor(10, 10, 10, 185))
						dxDrawRectangle(arena.x, arena.y + row.offset, lobby.imageWidth, lobby.subArenaHeight, tocolor(205, 205, 205, 15 * row.hover))
						dxDrawText(row.title or "Closed", arena.x + 5, arena.y + row.offset, arena.x + lobby.imageWidth, arena.y + row.offset + lobby.subArenaHeight, tocolor(255, 255, 255, 255), lobby.fontScale, lobby.font, "left", "center", true)
						dxDrawText(row.locked and "Locked" or playerCount..""..(maximumPlayerCount > 0 and "/"..maximumPlayerCount or ""), arena.x, arena.y + row.offset, arena.x + lobby.imageWidth - 5, arena.y + row.offset + lobby.subArenaHeight, tocolor(255, 255, 255, 105), lobby.fontScale, lobby.font, "right", "center", true)
						if i > 1 and i < lobby.subArenasToShow then
							dxDrawRectangle(arena.x, arena.y + row.offset + lobby.subArenaHeight - 1, lobby.imageWidth, 1, tocolor(10, 10, 10, 185))
						end
					end
				end
			end
			if arena.new then
				dxDrawImage(arena.x, arena.y, lobby.imageWidth, lobby.imageHeight, "img/new.png", 0, 0, 0, tocolor(255, 255, 255, 255))
			end
			dxDrawBorder(arena.x, arena.y, lobby.imageWidth, lobby.imageHeight, 2, tocolor(20, 20, 20, 245))
		end
	end
	dxSetBlendMode("blend")
	dxSetRenderTarget()
	local _, _, cX, cY = getCursorPosition()
	cX, cY = tonumber(cX or 0.5), tonumber(cY or 0.5)
	dxSetShaderValue(lobby.replaceShader, "tex", lobby.renderTarget)
	dxSetShaderTransform(lobby.replaceShader, -2 + 4 * cX, -2 + 4 *  cY, 0)
	dxDrawImage(0, 0, screenWidth, screenHeight, lobby.replaceShader, 0, 0, 0, tocolor(255, 255, 255, 255 * lobby.progress), false)
end

addEventHandler("onClientCursorMove", root,
function(_, _, cX, cY)
	if not lobby.visible then
		return
	end
	local hoveredArena = nil
	for i, arena in pairs(arenas) do
		if isCursorInRange(arena.x, arena.y, lobby.imageWidth, lobby.imageHeight) then
			hoveredArena = arena
			break
		end
	end
	if lobby.hoveredArena ~= hoveredArena then
		if lobby.hoveredArena then
			lobby.hoveredArena.tick = getTickCount()
			if lobby.hoveredArena.hoveredRow then
				lobby.hoveredArena.hoveredRow.tick = getTickCount()
				lobby.hoveredArena.hoveredRow = nil
			end
		end
		lobby.hoveredArena = hoveredArena
		if lobby.hoveredArena then
			lobby.hoveredArena.tick = getTickCount()
		end
	end
	local arena = lobby.hoveredArena
	if arena and arena.rows then
		local hoveredRow = nil
		for i = 1, lobby.subArenasToShow do
			local row = arena.rows[i]
			if row and not row.invisible and isCursorInRange(arena.x, arena.y + row.offset, lobby.imageWidth, lobby.subArenaHeight) then
				hoveredRow = row
				break
			end
		end
		hoveredRow = hoveredRow or (arena.activeRows == 1 and arena.rows[#arena.rows]) or nil
		if arena.hoveredRow ~= hoveredRow then
			if arena.hoveredRow then
				arena.hoveredRow.tick = getTickCount()
			end
			arena.hoveredRow = hoveredRow
			if arena.hoveredRow then
				arena.hoveredRow.tick = getTickCount()
			end
		end
	end
end)

addEventHandler("onClientClick", root,
function(button, state)
	if not lobby.visible then
		return
	end
	if button == "left" and state == "up" then
		if lobby.hoveredArena then
			local targetArena = lobby.hoveredArena.hoveredRow and lobby.hoveredArena.hoveredRow or lobby.hoveredArena
			if not isElement(targetArena.element) then
				return
			end
			if targetArena.locked and not getElementData(localPlayer, "member") then
				return triggerEvent("notification:create", localPlayer, "Arena", "This arena is locked")
			end
			lobby.hide(targetArena)
		end
	end
end)

-- Hold 'F1' to leave
function lobby.leave.render()
	local currentTick = getTickCount()
	local visible = not lobby.visible and getKeyState("F1") and true or false
	local tick = lobby.leave.tick or 0
	lobby.leave.progress = interpolateBetween(lobby.leave.progress or 0, 0, 0, visible and 1 or 0, 0, 0, math_min(2000, currentTick - tick)/2000, lobby.interpolator)
	local fadeDelay = 1000
	local fadeFactor = math_min(fadeDelay, currentTick - tick)/fadeDelay
	dxSetShaderValue(lobby.circleShader, "progress", 1 - lobby.leave.progress)
	dxDrawImageSection(lobby.leave.x, lobby.leave.y, lobby.leave.size, lobby.leave.size, 1, 1, 130, 130, "img/progress-circle.png", 0, 0, 0, tocolor(10, 10, 10, 185 * lobby.leave.progress), false)
	dxDrawImage(lobby.leave.x, lobby.leave.y, lobby.leave.size, lobby.leave.size, lobby.circleShader, 0, 0, 0, tocolor(25, 132, 109, 255 * lobby.leave.progress), false)
	if fadeFactor < 1 then
		local fadeScale = 20 * fadeFactor * lobby.leave.progress
		dxDrawImage(lobby.leave.x - fadeScale/2, lobby.leave.y - fadeScale/2, lobby.leave.size + fadeScale, lobby.leave.size + fadeScale, lobby.circleShader, 0, 0, 0, tocolor(25, 132, 109, 255 * (1 - fadeFactor) * lobby.leave.progress), false)
	end
	dxDrawText("LEAVING", lobby.leave.x, lobby.leave.y, lobby.leave.x + lobby.leave.size, lobby.leave.y + lobby.leave.size, tocolor(255, 255, 255, 255 * lobby.leave.progress), lobby.fontScale, lobby.font, "center", "center", true)
	if not visible and lobby.leave.progress  == 0 then
		removeEventHandler("onClientRender", root, lobby.leave.render)
		return
	elseif visible and lobby.leave.progress == 1 then
		triggerServerEvent("core:onPlayerRequestLeaveArena", localPlayer)
	end
end

bindKey("F1", "down",
function()
	if not lobby.visible then
		lobby.leave.tick = getTickCount()
		removeEventHandler("onClientRender", root, lobby.leave.render)
		addEventHandler("onClientRender", root, lobby.leave.render, true, "low-2")
	end
end)

bindKey("F1", "up",
function()
	if not lobby.visible then
		lobby.leave.tick = getTickCount()
	end
end)

-- Useful functions
function dxDrawClientAvatar(x, y, size, alpha)
	if not lobby.maskShader then
		lobby.maskShader = dxCreateShader("fx/mask.fx")
	end
	if not lobby.maskTexture then
		lobby.maskTexture = dxCreateTexture("img/circle.png")
		dxSetShaderValue(lobby.maskShader, "maskTexture", lobby.maskTexture)
	end
	if not lobby.defaultAvatar then
		lobby.defaultAvatar = dxCreateTexture("img/default-avatar.png")
	end
	local texture = getElementData(localPlayer, "avatarTexture")
	dxSetShaderValue(lobby.maskShader, "imageTexture", isElement(texture) and texture or lobby.defaultAvatar)
	return dxDrawImage(x, y, size, size, lobby.maskShader, 0, 0, 0, tocolor(255, 255, 255, tonumber(alpha or 255)), false)
end
 
function dxDrawBorder(x, y, width, height, size, color)
	if type(size) ~= "number" then
		size = 1
	end
	if not color then
		color = tocolor(255, 255, 255, 255)
	end
	dxDrawRectangle(x, y + size, size, height - size * 2, color, false)
	dxDrawRectangle(x + width - size, y + size, size, height - size * 2, color, false)
	dxDrawRectangle(x, y, width, size, color, false)
	dxDrawRectangle(x, y + height - size, width, size, color, false)
end

function isCursorInRange(x, y, width, height)
	if not isCursorShowing() then
		return
	end
	local cX, cY = getCursorPosition()
	if cX >= x and cX <= x + width and cY >= y and cY <= y + height then
		return cX, cY
	end
	return
end

_getCursorPosition = getCursorPosition
function getCursorPosition()
	if not isCursorShowing() then
		return
	end
	local cX, cY = _getCursorPosition()
	return screenWidth * cX, screenHeight * cY, cX, cY
end

function string.shrinkToSize(text, scale, font, size)
	local textWidth = dxGetTextWidth(text, scale, font)
	local iter = 0
	while textWidth >= size do
		text = string.sub(text, 0, -2)
		iter = iter + 1
		textWidth = dxGetTextWidth(text, scale, font)
	end
	local wasShrinked = iter > 0
	if wasShrinked then
		text = string.sub(text, 0, -2)
		text = text..".."
	end
	return text, wasShrinked
end

function table.reverse(_table)
	local newTable = {}
	for i, v in pairs(_table) do
		table.insert(newTable, 1, v)
	end
	return newTable
end