local screenWidth, screenHeight = guiGetScreenSize()
local relativeScale, relativeFontScale = math.min(math.max(screenWidth/1600, 0.9), 1), math.min(math.max(screenWidth/1600, 0.85), 1)
local toptimes = {}
toptimes.fontScale = 1
toptimes.font = dxCreateFont(":v_locale/fonts/Roboto-Regular.ttf", math.floor(10 * relativeFontScale))
toptimes.fontHeight = dxGetFontHeight(toptimes.fontScale, toptimes.font)
toptimes.rowsToShow = 8
toptimes.offset = 5
toptimes.padding = 10
toptimes.interpolator = "Linear"
toptimes.width = math.floor(450 * relativeScale)
toptimes.contentWidth = toptimes.width - toptimes.padding * 2
toptimes.titleHeight = toptimes.fontHeight
toptimes.rowHeight = toptimes.fontHeight
toptimes.height = (toptimes.rowHeight + toptimes.padding) * (toptimes.rowsToShow + 1) + toptimes.titleHeight + toptimes.padding * 2
toptimes.x = screenWidth - toptimes.width - toptimes.offset
toptimes.y = (screenHeight - toptimes.height)/2
toptimes.iconSize = toptimes.rowHeight * 0.8
toptimes.iconOffset = (toptimes.rowHeight - toptimes.iconSize)/2
toptimes.flagWidth, toptimes.flagHeight = toptimes.fontHeight * 0.65 * 1.45, toptimes.fontHeight * 0.65
toptimes.flagOffset = (toptimes.rowHeight - toptimes.flagHeight)/2
toptimes.textures = {}
toptimes.columnWidth = {
	0.075,
	0.525,
	0.15,
	0.2,
	0.05
}
for i, v in pairs(toptimes.columnWidth) do
	toptimes.columnWidth[i] = toptimes.contentWidth * v
end
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

function toptimes.show(auto)
	if toptimes.hideTimer and isTimer(toptimes.hideTimer) then
		killTimer(toptimes.hideTimer)
	end
	if not toptimes.rows then
		return
	end
	toptimes.hideTimer = auto and setTimer(toptimes.hide, 5000, 1) or nil
	if toptimes.visible then
		return
	end
	toptimes.tick = getTickCount()
	toptimes.visible = true
	toptimes.rows = toptimes.rows and toptimes.rows or {}
	removeEventHandler("onClientRender", root, toptimes.render)
	addEventHandler("onClientRender", root, toptimes.render)
end

function toptimes.hide()
	if not toptimes.visible then
		return
	end
	toptimes.tick = getTickCount()
	toptimes.visible = false
end

function toptimes.reset()
	removeEventHandler("onClientRender", root, toptimes.render)
	toptimes.visible = false
	toptimes.progress = 0
	toptimes.rows = nil
end
addEvent("toptimes:reset", true)
addEventHandler("toptimes:reset", localPlayer, toptimes.reset)
addEvent("core:onClientLeaveArena", true)
addEventHandler("core:onClientLeaveArena", localPlayer, toptimes.reset)

function toptimes.toggle()
	if getElementData(localPlayer, "panel.visible") or getElementData(localPlayer, "scoreboard.visible") then
		return
	end
	if toptimes.visible then
		toptimes.hide()
	else
		toptimes.show()
	end
end
bindKey("F5", "down", toptimes.toggle)

addEvent("panel:onVisibilityChanged", true)
addEventHandler("panel:onVisibilityChanged", localPlayer,
function()
	if toptimes.visible then
		toptimes.hide()
	end
end)

addEvent("toptimes:onClientReceiveToptimes", true)
addEventHandler("toptimes:onClientReceiveToptimes", resourceRoot,
function(data, forceDisplay)
	if type(data) ~= "table" then
		return
	end
	local id = getElementData(localPlayer, "LoggedIn") and tonumber(getElementData(localPlayer, "account_id")) or getPlayerSerial(localPlayer)
	toptimes.title = string.shrinkToSize(data.mapNameReal or "N/A", toptimes.fontScale, toptimes.font, toptimes.contentWidth)
	toptimes.rows = {}
	for i = 1, toptimes.rowsToShow do
		local toptime = data.toptimes[i]
		if toptime then
			toptimes.rows[i] = {
				rank = i,
				username = toptime.username,
				nickname = toptime.nickname,
				timeString = msToTimeString(toptime.time),
				dateString = toptime.dateRecorded,
				country = toptime.country,
				personal = tonumber(toptime.id) == id
			}
		end
	end
	local personalToptime = nil
	if #data.toptimes > toptimes.rowsToShow then
		for i = toptimes.rowsToShow, #data.toptimes do
			if data.toptimes[i].id and tonumber(data.toptimes[i].id) == id then
				personalToptime = data.toptimes[i]
				personalToptime.rank = i
				break
			end
		end
	end
	if personalToptime and personalToptime.rank > 8 then
		toptimes.personalToptime = {
			rank = personalToptime.rank,
			nickname = personalToptime.nickname,
			timeString = msToTimeString(personalToptime.time),
			dateString = personalToptime.dateRecorded,
			country = personalToptime.country
		}
	else
		toptimes.personalToptime = nil
	end
	if forceDisplay then
		toptimes.show(true)
	end
end)

function toptimes.render()
	local currentTick = getTickCount()
	local toptimesTick = toptimes.tick or 0
	toptimes.progress = interpolateBetween(toptimes.progress or 0, 0, 0, toptimes.visible and 1 or 0, 0, 0, math_min(500, currentTick - toptimesTick)/500, toptimes.interpolator)
	if not toptimes.visible and toptimes.progress == 0 then
		removeEventHandler("onClientRender", root, toptimes.render)
		return
	end
	local realWidth = (toptimes.width + toptimes.offset) * 0.25
	local x, y = math.floor(toptimes.x + realWidth - realWidth * toptimes.progress), toptimes.y
	dxDrawRectangle(x, y, toptimes.width, toptimes.height, tocolor(10, 10, 10, 185 * toptimes.progress), false)
	local offsetX, offsetY = toptimes.padding, toptimes.padding
	dxDrawText(toptimes.title or "none", x + toptimes.padding, y + offsetY, x + toptimes.contentWidth + toptimes.padding, y + offsetY + toptimes.titleHeight, tocolor(25, 132, 109, 255 * toptimes.progress), toptimes.fontScale, toptimes.font, "left", "top", true)
	offsetY = offsetY + toptimes.titleHeight + toptimes.padding
	local width = toptimes.columnWidth[1]
	dxDrawImageSection(x + offsetX, y + offsetY + toptimes.iconOffset, toptimes.iconSize, toptimes.iconSize, 1, 1, 30, 30, "img/rank.png", 0, 0, 0, tocolor(25, 132, 109, 255 * toptimes.progress), false)
	offsetX = offsetX + width
	width = toptimes.columnWidth[2]
	dxDrawImageSection(x + offsetX, y + offsetY + toptimes.iconOffset, toptimes.iconSize, toptimes.iconSize, 1, 1, 30, 30, "img/nickname.png", 0, 0, 0, tocolor(25, 132, 109, 255 * toptimes.progress), false)
	offsetX = offsetX + width
	width = toptimes.columnWidth[3]
	dxDrawImageSection(x + offsetX, y + offsetY + toptimes.iconOffset, toptimes.iconSize, toptimes.iconSize, 1, 1, 30, 30, "img/time.png", 0, 0, 0, tocolor(25, 132, 109, 255 * toptimes.progress), false)
	offsetX = offsetX + width
	width = toptimes.columnWidth[4]
	dxDrawImageSection(x + offsetX, y + offsetY + toptimes.iconOffset, toptimes.iconSize, toptimes.iconSize, 1, 1, 30, 30, "img/date.png", 0, 0, 0, tocolor(25, 132, 109, 255 * toptimes.progress), false)
	offsetX = offsetX + width
	width = toptimes.columnWidth[5]
	dxDrawImageSection(x + offsetX, y + offsetY + toptimes.iconOffset, toptimes.iconSize, toptimes.iconSize, 1, 1, 30, 30, "img/country.png", 0, 0, 0, tocolor(25, 132, 109, 255 * toptimes.progress), false)
	offsetX = offsetX + width
	offsetY = offsetY + toptimes.rowHeight + toptimes.padding
	for i = 1, toptimes.rowsToShow do
		offsetY = toptimes.drawRow(i, x, y, offsetY)
	end
	if toptimes.personalToptime then
		y = y + toptimes.height
		dxDrawRectangle(x, y, toptimes.width, toptimes.rowHeight + toptimes.padding, tocolor(5, 5, 5, 205 * toptimes.progress), false)
		toptimes.drawRow(toptimes.personalToptime, x, toptimes.y + toptimes.padding * 0.5, offsetY, 25, 132, 109)
	end
end

bindKey("tab", "both",
function()
	if not toptimes.visible or not toptimes.rows then
		return
	end
	toptimes.hide()
end)

function toptimes.drawRow(row, x, y, startOffsetY, r, g, b)
	local data = type(row) == "table" and row or toptimes.rows[row] or {}
	local rank = type(row) == "table" and row.rank or row
	local offsetX, offsetY = toptimes.padding, startOffsetY
	width = toptimes.columnWidth[1]
	if data.personal then
		dxDrawRectangle(x, y + offsetY, 2, toptimes.rowHeight, tocolor(25, 132, 109, 255 * toptimes.progress), false)
		dxDrawText(rank, x + offsetX, y + offsetY, x + offsetX + width, y + offsetY + toptimes.rowHeight, tocolor(25, 132, 109, 255 * toptimes.progress), toptimes.fontScale, toptimes.font, "left", "center", true)
	else
		dxDrawText(rank, x + offsetX, y + offsetY, x + offsetX + width, y + offsetY + toptimes.rowHeight, tocolor(r or 255, g or 255, b or 255, 255 * toptimes.progress), toptimes.fontScale, toptimes.font, "left", "center", true)
	end
	offsetX = offsetX + width
	width = toptimes.columnWidth[2]
	dxDrawText(data.nickname or "Empty", x + offsetX, y + offsetY, width, y + offsetY + toptimes.rowHeight, tocolor(255, 255, 255, 255 * toptimes.progress), toptimes.fontScale, toptimes.font, "left", "center", false, false, false, true)
	offsetX = offsetX + width
	width = toptimes.columnWidth[3]
	dxDrawText(data.timeString or "-", x + offsetX, y + offsetY, x + offsetX + width, y + offsetY + toptimes.rowHeight, tocolor(255, 255, 255, 255 * toptimes.progress), toptimes.fontScale, toptimes.font, "left", "center", true)
	offsetX = offsetX + width
	width = toptimes.columnWidth[4]
	dxDrawText(data.dateString or "-", x + offsetX, y + offsetY, x + offsetX + width, y + offsetY + toptimes.rowHeight, tocolor(255, 255, 255, 255 * toptimes.progress), toptimes.fontScale, toptimes.font, "left", "center", true)
	local path = data.country and ":admin/client/images/flags/"..(data.country:lower())..".png" or nil
	if path and fileExists(path) then
		offsetX = offsetX + width
		dxDrawImage(x + offsetX, y + offsetY + toptimes.flagOffset, toptimes.flagWidth, toptimes.flagHeight, path, 0, 0, 0, tocolor(255, 255, 255, 255 * toptimes.progress), false)
	end
	return offsetY + toptimes.rowHeight + toptimes.padding
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