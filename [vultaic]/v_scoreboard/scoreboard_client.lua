local _G = _G
local screenWidth, screenHeight = guiGetScreenSize()
local relativeScale, relativeFontScale = math.min(math.max(screenWidth/1600, 0.65), 1), math.min(math.max(screenWidth/1600, 0.85), 1)
local scoreboard = {}
scoreboard.width, scoreboard.height = math.floor(980 * relativeScale), math.floor(screenHeight - 20)
scoreboard.width, scoreboard.height = scoreboard.width - (scoreboard.width % 10), scoreboard.height - (scoreboard.height % 10)
scoreboard.x, scoreboard.y = (screenWidth - scoreboard.width)/2, (screenHeight - scoreboard.height)/2
scoreboard.fontScale = 1
scoreboard.font = dxCreateFont(":v_locale/fonts/Roboto-Regular.ttf", math.floor(10 * relativeFontScale))
scoreboard.fontHeight = dxGetFontHeight(scoreboard.fontScale, scoreboard.font)
scoreboard.headerHeight = math.floor(scoreboard.fontHeight * 2.5)
scoreboard.padding = 10
scoreboard.contentWidth, scoreboard.contentHeight = scoreboard.width - 5, scoreboard.height - scoreboard.headerHeight - scoreboard.padding
scoreboard.rowsToShow = math.ceil(scoreboard.height/(scoreboard.fontHeight * 2)) - 1
scoreboard.rowHeight = scoreboard.contentHeight/scoreboard.rowsToShow
scoreboard.flagWidth, scoreboard.flagHeight = scoreboard.fontHeight * 0.6 * 1.45, scoreboard.fontHeight * 0.6
scoreboard.flagOffset = (scoreboard.rowHeight - scoreboard.flagHeight)/2
scoreboard.logoSize = scoreboard.headerHeight * 0.65
scoreboard.logoOffset = (scoreboard.headerHeight - scoreboard.logoSize)/2
scoreboard.iconSize = scoreboard.fontHeight * 0.75
scoreboard.iconOffset = (scoreboard.rowHeight - scoreboard.iconSize)/2
scoreboard.heartSize = scoreboard.rowHeight * 0.3
scoreboard.heartOffsetX, scoreboard.heartOffsetY = (scoreboard.iconSize - scoreboard.heartSize)/2, (scoreboard.rowHeight - scoreboard.heartSize)/2
scoreboard.interpolator = "Linear"
scoreboard.showEmptyArenas = false
local serverName, playersCount, maximumPlayers = "", 0, 0
local colorForState = {
	["waiting"] = tocolor(255, 255, 0, 255),
	["alive"] = tocolor(25, 132, 109, 255),
	["dead"] = tocolor(50, 50, 50, 255),
	["spectating"] = tocolor(255, 255, 255, 255),
	["training"] = tocolor(255, 255, 255, 255)
}
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
--
local adminlevel_to_data = {[2] = tocolor(255, 255, 255, 255), [3] = tocolor(25, 132, 109, 255), [4] = tocolor(210, 0, 0, 255)}
-- Arenas to be shown
local arenas = {
	["lobby"] = {
		columns = {
			{"id", "ID", 0.05},
			{"nickname", "Nickname", 0.5},
			{"fps", "FPS", 0.1},
			{"ping", "Ping", 0.1},
			{"countryName", "Country", 0.25, "Unknown"}
		}
	},
	["garage"] = {
		columns = {
			{"id", "ID", 0.05},
			{"nickname", "Nickname", 0.5},
			{"fps", "FPS", 0.1},
			{"ping", "Ping", 0.1},
			{"countryName", "Country", 0.25, "Unknown"}
		}
	},
	["dm"] = {
		columns = {
			{"id", "ID", 0.05},
			{"nickname", "Nickname", 0.25},
			{"state", "State", 0.05},
			{"money", "Money", 0.1, "Guest"},
			{"dm_points", "Points", 0.1, "Guest"},
			{"fps", "FPS", 0.1},
			{"ping", "Ping", 0.1},
			{"countryName", "Country", 0.25, "Unknown"}
		}
	},
	["os"] = {
		columns = {
			{"id", "ID", 0.05},
			{"nickname", "Nickname", 0.25},
			{"state", "State", 0.05},
			{"money", "Money", 0.1, "Guest"},
			{"os_points", "Points", 0.1, "Guest"},
			{"fps", "FPS", 0.1},
			{"ping", "Ping", 0.1},
			{"countryName", "Country", 0.25, "Unknown"}
		}
	},
	["hdm"] = {
		columns = {
			{"id", "ID", 0.05},
			{"nickname", "Nickname", 0.25},
			{"state", "State", 0.05},
			{"money", "Money", 0.1, "Guest"},
			{"dm_points", "Points", 0.1, "Guest"},
			{"fps", "FPS", 0.1},
			{"ping", "Ping", 0.1},
			{"countryName", "Country", 0.25, "Unknown"}
		}
	},
	["dd"] = {
		columns = {
			{"id", "ID", 0.05},
			{"nickname", "Nickname", 0.25},
			{"state", "State", 0.05},
			{"money", "Money", 0.1, "Guest"},
			{"dd_points", "Points", 0.1, "Guest"},
			{"fps", "FPS", 0.1},
			{"ping", "Ping", 0.1},
			{"countryName", "Country", 0.25, "Unknown"}
		}
	},
	["fdd"] = {
		columns = {
			{"id", "ID", 0.05},
			{"nickname", "Nickname", 0.25},
			{"state", "State", 0.05},
			{"money", "Money", 0.1, "Guest"},
			{"dd_points", "Points", 0.1, "Guest"},
			{"fps", "FPS", 0.1},
			{"ping", "Ping", 0.1},
			{"countryName", "Country", 0.25, "Unknown"}
		}
	},
	["race"] = {
		columns = {
			{"id", "ID", 0.05},
			{"nickname", "Nickname", 0.25},
			{"checkpoint", "CP", 0.05},
			{"money", "Money", 0.1, "Guest"},
			{"race_points", "Points", 0.1, "Guest"},
			{"fps", "FPS", 0.1},
			{"ping", "Ping", 0.1},
			{"countryName", "Country", 0.25, "Unknown"}
		}
	},
	["shooter"] = {
		columns = {
			{"id", "ID", 0.05},
			{"nickname", "Nickname", 0.25},
			{"state", "State", 0.05},
			{"money", "Money", 0.1, "Guest"},
			{"shooter_points", "Points", 0.1, "Guest"},
			{"fps", "FPS", 0.1},
			{"ping", "Ping", 0.1},
			{"countryName", "Country", 0.25, "Unknown"}
		}
	},
	["shooterjump"] = {
		columns = {
			{"id", "ID", 0.05},
			{"nickname", "Nickname", 0.25},
			{"state", "State", 0.05},
			{"money", "Money", 0.1, "Guest"},
			{"shooter_points", "Points", 0.1, "Guest"},
			{"fps", "FPS", 0.1},
			{"ping", "Ping", 0.1},
			{"countryName", "Country", 0.25, "Unknown"}
		}
	},
	["hunter"] = {
		columns = {
			{"id", "ID", 0.05},
			{"nickname", "Nickname", 0.25},
			{"state", "State", 0.05},
			{"money", "Money", 0.1, "Guest"},
			{"hunter_points", "Points", 0.1, "Guest"},
			{"fps", "FPS", 0.1},
			{"ping", "Ping", 0.1},
			{"countryName", "Country", 0.25, "Unknown"}
		}
	},
	["hunter nolimit"] = {
		columns = {
			{"id", "ID", 0.05},
			{"nickname", "Nickname", 0.25},
			{"state", "State", 0.05},
			{"money", "Money", 0.1, "Guest"},
			{"hunter_points", "Points", 0.1, "Guest"},
			{"fps", "FPS", 0.1},
			{"ping", "Ping", 0.1},
			{"countryName", "Country", 0.25, "Unknown"}
		}
	},
	["dm training"] = {
		columns = {
			{"id", "ID", 0.05},
			{"nickname", "Nickname", 0.5},
			{"fps", "FPS", 0.1},
			{"ping", "Ping", 0.1},
			{"countryName", "Country", 0.25, "Unknown"}
		}
	},
	["race training"] = {
		columns = {
			{"id", "ID", 0.05},
			{"nickname", "Nickname", 0.5},
			{"fps", "FPS", 0.1},
			{"ping", "Ping", 0.1},
			{"countryName", "Country", 0.25, "Unknown"}
		}
	},
	["tdm"] = {
		columns = {
			{"id", "ID", 0.05},
			{"nickname", "Nickname", 0.5},
			{"fps", "FPS", 0.1},
			{"ping", "Ping", 0.1},
			{"countryName", "Country", 0.25, "Unknown"}
		}
	}
}
local arenasOrdered = {"dm", "os", "hdm", "dd", "fdd", "race", "shooter", "shooterjump", "hunter", "hunter nolimit", "dm training", "race training", "tdm", "garage", "lobby"}
for i, arena in pairs(arenas) do
	for i, column in pairs(arena.columns) do
		column.width = scoreboard.width * (tonumber(column[3]) or 0)
	end
end

addEventHandler("onClientResourceStart", resourceRoot,
function()
	local syncElement = getElementByID("scoreboard.syncElement")
	serverName = syncElement and getElementData(syncElement, "serverName") or 0
	maximumPlayers = syncElement and getElementData(syncElement, "maximumPlayers") or 0
	scoreboard.renderTarget = dxCreateRenderTarget(scoreboard.width, scoreboard.height, true)
	scoreboard.contentRenderTarget = dxCreateRenderTarget(scoreboard.contentWidth, scoreboard.contentHeight, true)
	scoreboard.update()
	setElementData(localPlayer, "scoreboard.visible", scoreboard.visible, false)
end)

function scoreboard.show()
	local arena = getElementData(localPlayer, "arena")
	if scoreboard.visible or getElementData(localPlayer, "login.visible") or getElementData(localPlayer, "lobby.visible") or getElementData(localPlayer, "panel.visible") or getElementData(localPlayer, "selector.visible") or not arena or arena == "lobby" then
		return
	end
	scoreboard.tick = getTickCount()
	scoreboard.visible = true
	scoreboard.refresh()
	removeEventHandler("onClientRender", root, scoreboard.render)
	addEventHandler("onClientRender", root, scoreboard.render, true, "low-3")
	scoreboard.refreshTimer = setTimer(scoreboard.refresh, 1000, 0)
	setElementData(localPlayer, "scoreboard.visible", scoreboard.visible, false)
	triggerEvent("blur:enable", localPlayer, "scoreboard", true)
end
bindKey("tab", "down", scoreboard.show)

function scoreboard.hide()
	if not scoreboard.visible then
		return
	end
	scoreboard.tick = getTickCount()
	scoreboard.visible = false
	if scoreboard.refreshTimer and isTimer(scoreboard.refreshTimer) then
		killTimer(scoreboard.refreshTimer)
	end
	setElementData(localPlayer, "scoreboard.visible", scoreboard.visible, false)
	triggerEvent("blur:disable", localPlayer, "scoreboard")
	showCursor(false)
	scoreboard.RMB = nil
	scoreboard.dragging = nil
	scoreboard.dragOffset = nil
end
bindKey("tab", "up", scoreboard.hide)

function scoreboard.refresh(exceptionPlayer)
	scoreboard.rows = {}
	local offset = 0
	local arenasOrderedNew = {}
	current, currentID = getElementData(localPlayer, "arena"), nil
	for i, id in pairs(arenasOrdered) do
		table.insert(arenasOrderedNew, id)
		if current and current == id then
			currentID = i
		end
	end
	if currentID then
		local id = arenasOrderedNew[currentID]
		table.remove(arenasOrderedNew, currentID)
		table.insert(arenasOrderedNew, 1, id)
		currentID = id
	end
	for i, id in pairs(arenasOrderedNew) do
		local arena = arenas[id]
		if arena and isElement(arena.element) and not (#getElementChildren(arena.element, "player") == 0 and not scoreboard.showEmptyArenas) then
			local playersCount = #getElementChildren(arena.element, "player")
			arena.id = id
			arena.playersCountText = playersCount.." "..(playersCount == 1 and "player" or "players")
			arena.map = getElementData(arena.element, "map")
			table.insert(scoreboard.rows, {"arena", arena, offset})
			offset = offset + scoreboard.rowHeight
			local id = getElementData(arena.element, "id")
			if arena.columns then
				table.insert(scoreboard.rows, {"column", arena.columns, offset})
				offset = offset + scoreboard.rowHeight
			end
			local players = getElementChildren(arena.element, "player")
			for i, player in pairs(players) do
				if not exceptionPlayer or player ~= exceptionPlayer then
					local team = getPlayerTeam(player)
					if not team then
						table.insert(scoreboard.rows, {"player", player, offset, arena.columns})
						offset = offset + scoreboard.rowHeight
						players[i] = nil
					end
				end
			end
			local teams = {}
			for i, player in pairs(players) do
				if not exceptionPlayer or player ~= exceptionPlayer then
					local team = getPlayerTeam(player)
					if team and not teams[team] then
						local playersInTeam = {}
						for i, v in pairs(getPlayersInTeam(team)) do
							if getElementParent(v) == arena.element then
								table.insert(playersInTeam, v)
							end
						end
						table.insert(scoreboard.rows, {"team", {name = getTeamName(team), color = {getTeamColor(team)}, players = playersInTeam}, offset})
						offset = offset + scoreboard.rowHeight
						for i, player in pairs(playersInTeam) do
							table.insert(scoreboard.rows, {"player", player, offset, arena.columns})
							offset = offset + scoreboard.rowHeight
						end
						teams[team] = true
					end
				end
			end
		end
	end
	scoreboard.maximumScroll = #scoreboard.rows * scoreboard.rowHeight
	local maximumScroll = math.max((scoreboard.maximumScroll or 0) - scoreboard.contentHeight, 0)
	scoreboard.maximumScrollReal = maximumScroll
	if scoreboard.scrollToGo and scoreboard.scrollToGo > maximumScroll then
		scoreboard.scrollTick = getTickCount()
		scoreboard.scrollToGo = maximumScroll
	end
	playersCount = #getElementsByType("player")
	scoreboard.scrollbarSize = math_max(scoreboard.contentHeight * (scoreboard.contentHeight/(scoreboard.contentHeight + maximumScroll)), scoreboard.contentHeight * 0.1)
end
addEventHandler("onClientPlayerQuit", root, function() scoreboard.refresh(source) end)

function scoreboard.update(data)
	for i, arena in pairs(arenas) do
		arena.element = getElementByID(i)
		if arena.element then
			arena.name = getElementData(arena.element, "name")
		end
	end
end
addEvent("core:syncArenasData", true)
addEventHandler("core:syncArenasData", root, scoreboard.update)
addEvent("core:onClientJoinArena", true)
addEventHandler("core:onClientJoinArena", localPlayer, scoreboard.update)

function scoreboard.reset()
	scoreboard.hide()
	scoreboard.scrollToGo = 0
	scoreboard.scroll = 0
end
addEvent("core:onClientLeaveArena", true)
addEventHandler("core:onClientLeaveArena", localPlayer, scoreboard.reset)

function scoreboard.doScroll(side)
	if side == "up" then
		local scrollToGo = scoreboard.scrollToGo or 0
		scoreboard.scrollTick = getTickCount()
		scoreboard.scrollToGo = math.max(scrollToGo - scoreboard.rowHeight * 2, 0)
	elseif side == "down" then
		local scrollToGo = scoreboard.scrollToGo or 0
		local maximumScroll = math.max((scoreboard.maximumScroll or 0) - scoreboard.contentHeight, 0)
		scoreboard.scrollTick = getTickCount()
		scoreboard.scrollToGo = math.min(scrollToGo + scoreboard.rowHeight * 2, maximumScroll)
	end
end

addEventHandler("onClientKey", root,
function(key, press)
	if not scoreboard.visible then
		return
	end
	if key == "mouse2" then
		scoreboard.RMB = press
		showCursor(scoreboard.RMB)
	elseif key == "mouse1" then
		if press and scoreboard.RMB and scoreboard.maximumScrollReal and scoreboard.scrollbarSize and isCursorInRange(scoreboard.x + scoreboard.contentWidth, scoreboard.y + scoreboard.headerHeight, 5, scoreboard.contentHeight) then
			local percantage = (scoreboard.scroll or 0)/(scoreboard.maximumScrollReal)
			local scrollbarOffset = (scoreboard.contentHeight - scoreboard.scrollbarSize) * percantage
			local cX, cY = getCursorPosition()
			scoreboard.dragging = true
			scoreboard.dragOffset = cY - (scoreboard.y + scoreboard.headerHeight + scrollbarOffset)
		else
			scoreboard.dragging = nil
			scoreboard.dragOffset = nil
		end
	elseif key == "mouse_wheel_up" then
		scoreboard.doScroll("up")
	elseif key == "mouse_wheel_down" then
		scoreboard.doScroll("down")
	end
end)

addEventHandler("onClientCursorMove", root,
function(_, _, cX, cY)
	if not scoreboard.visible then
		return
	end
	if scoreboard.dragging then
		local y = scoreboard.y + scoreboard.headerHeight
		local height = scoreboard.contentHeight
		local offset = cY - (scoreboard.y + y)
		offset = offset - scoreboard.dragOffset
		if offset < 0 then
			offset = 0
		elseif offset > height - scoreboard.scrollbarSize then
			offset = height - scoreboard.scrollbarSize
		end
		local percantage = offset/(height - scoreboard.scrollbarSize)
		scoreboard.scrollToGo = scoreboard.maximumScrollReal * percantage
		scoreboard.scroll = scoreboard.scrollToGo
	end
end)

function scoreboard.renderArenaRow(arena, offsetY)
	local title = arena.name or "N/A"
	local playersCount = arena.playersCountText
	local map = arena.map
	local width = dxGetTextWidth(title, scoreboard.fontScale, scoreboard.font)
	local size = scoreboard.rowHeight * 0.3
	local offset = (scoreboard.rowHeight - size)/2
	dxDrawRectangle(0, offsetY, scoreboard.width, scoreboard.rowHeight, tocolor(10, 10, 10, 205))
	if currentID and arena.id == currentID then
		dxDrawRectangle(0, offsetY, 2, scoreboard.rowHeight, tocolor(55, 155, 255, 255))
	end
	dxDrawText(title, scoreboard.padding, offsetY, scoreboard.width, offsetY + scoreboard.rowHeight, tocolor(255, 255, 255, 255), scoreboard.fontScale, scoreboard.font, "left", "center", false, false, false, true)
	dxDrawImageSection(width + scoreboard.padding * 1.5, offsetY + offset, size, size, 1, 1, 46, 46, "img/seperator.png", 0, 0, 0, tocolor(25, 132, 109, 255))
	width = width + size
	dxDrawText(playersCount, width + scoreboard.padding * 2, offsetY, scoreboard.width, offsetY + scoreboard.rowHeight, tocolor(255, 255, 255, 255), scoreboard.fontScale, scoreboard.font, "left", "center", false, false, false, true)
	if map then
		width = width + dxGetTextWidth(playersCount, scoreboard.fontScale, scoreboard.font) + scoreboard.padding
		dxDrawImageSection(width + scoreboard.padding * 1.5, offsetY + offset, size, size, 1, 1, 46, 46, "img/seperator.png", 0, 0, 0, tocolor(25, 132, 109, 255))
		width = width + size
		dxDrawText(map, width + scoreboard.padding * 2, offsetY, scoreboard.width, offsetY + scoreboard.rowHeight, tocolor(255, 255, 255, 255), scoreboard.fontScale, scoreboard.font, "left", "center", false, false, false, true)
	end
end

function scoreboard.renderColumns(columns, offsetY)
	local offsetX = 0
	dxDrawRectangle(0, offsetY, scoreboard.width, scoreboard.rowHeight, tocolor(10, 10, 10, 205))
	--dxDrawRectangle(0, offsetY, 2, scoreboard.rowHeight, tocolor(25, 132, 109, 255))
	for i, column in pairs(columns) do
		local path = "img/"..column[2]:lower()..".png"
		if fileExists(path) then
			dxDrawImageSection(offsetX + scoreboard.padding, offsetY + scoreboard.iconOffset, scoreboard.iconSize, scoreboard.iconSize, 1, 1, 46, 46, path, 0, 0, 0, tocolor(25, 132, 109, 255))
		else
			dxDrawText(column[2], offsetX + scoreboard.padding, offsetY, offsetX + column.width, offsetY + scoreboard.rowHeight, tocolor(25, 132, 109, 255), scoreboard.fontScale, scoreboard.font, "left", "center", true)
		end
		offsetX = offsetX + column.width
	end

end

function scoreboard.renderPlayerRow(player, columns, offsetY)
	local offsetX = 0
	local r, g, b = 255, 255, 255
	local team = getPlayerTeam(player)
	if team then
		r, g, b = getTeamColor(team)
	end
	local donator = getElementData(player, "donator")
	local sound = getElementData(player, "sound_mode") or nil
	local admin_level = getElementData(player, "admin_level") or 1
	if admin_level > 4 then
		admin_level = 4
	end
	local listener = sound and sound == "radio" or sound == "stream" and true or false
	if player == localPlayer then
		dxDrawRectangle(0, offsetY, scoreboard.width, scoreboard.rowHeight, tocolor(25, 132, 109, 45))
	end
	for i, column in pairs(columns) do
		local x = 0
		local logged = (not column[4] or getElementData(player, "LoggedIn")) and true or false
		local value = nil
		local colored = nil
		if column[1] == "nickname" then
			value = getPlayerName(player)
			colored = true
			if listener then
				dxDrawImageSection(offsetX + scoreboard.padding + x, offsetY + scoreboard.iconOffset, scoreboard.iconSize, scoreboard.iconSize, 1, 1, 30, 30, "img/stream.png", 0, 0, 0, tocolor(55, 155, 255, 255))
				x = x + scoreboard.iconSize + scoreboard.iconOffset
			end
			if donator then
				dxDrawImageSection(offsetX + scoreboard.padding + x, offsetY + scoreboard.iconOffset, scoreboard.iconSize, scoreboard.iconSize, 1, 1, 30, 30, "img/donator.png", 0, 0, 0, tocolor(55, 255, 55, 255))
				x = x + scoreboard.iconSize + scoreboard.iconOffset
			end
			if admin_level > 1 then
				dxDrawImageSection(offsetX + scoreboard.padding + x, offsetY + scoreboard.iconOffset, scoreboard.iconSize, scoreboard.iconSize, 1, 1, 30, 30, "img/[admin_img]/icon.png", 0, 0, 0, adminlevel_to_data[admin_level])
				x = x + scoreboard.iconSize + scoreboard.iconOffset
			end
		elseif column[1] == "ping" then
			value = tostring(getPlayerPing(player))
		elseif column[1] == "money" then
			value = logged and tonumber(getElementData(player, column[1]) or 0) or "Guest"
			if value and value ~= "Guest" then
				value = "$"..tostring(getElementData(player, column[1]))
			end
		else
			value = logged and tostring(getElementData(player, column[1]) or (column[4] or "-"))
		end
		if colored then
			dxDrawText(value or "-", offsetX + scoreboard.padding + x, offsetY, column.width, offsetY + scoreboard.rowHeight, tocolor(r, g, b, 255), scoreboard.fontScale, scoreboard.font, "left", "center", false, false, false, true)
		else
			if column[1] == "state" then
				local state = getElementData(player, "state")
				local color = tocolor(255, 255, 255, 255)
				if colorForState[state] then
					color = colorForState[state]
				end
				dxDrawImageSection(offsetX + scoreboard.padding + scoreboard.heartOffsetX, offsetY + scoreboard.heartOffsetY, scoreboard.heartSize, scoreboard.heartSize, 1, 1, 46, 46, "img/state.png", 0, 0, 0, color)
			elseif column[1] == "countryName" then
				local countryCode = getElementData(player, "countryCode")
				local path = countryCode and ":admin/client/images/flags/"..(countryCode:lower())..".png" or nil
				local offset = 0
				if path and fileExists(path) then
					dxDrawImage(offsetX + scoreboard.padding, offsetY + scoreboard.flagOffset, scoreboard.flagWidth, scoreboard.flagHeight, path, 0, 0, 0, tocolor(255, 255, 255, 255))
					offset = offset + scoreboard.flagOffset + 10
				end
				dxDrawText(value or "-", offsetX + offset + scoreboard.padding, offsetY, offsetX + offset + column.width, offsetY + scoreboard.rowHeight, tocolor(255, 255, 255, 255), scoreboard.fontScale, scoreboard.font, "left", "center", true)
			else
				dxDrawText(value or "-", offsetX + scoreboard.padding, offsetY, offsetX + column.width, offsetY + scoreboard.rowHeight, tocolor(255, 255, 255, 255), scoreboard.fontScale, scoreboard.font, "left", "center", true)
			end
		end
		offsetX = offsetX + column.width
	end
end

function scoreboard.renderTeamRow(team, columns, offsetY)
	local r, g, b = unpack(team.color)
	local playerCount = #team.players
	dxDrawRectangle(0, offsetY, scoreboard.width, scoreboard.rowHeight, tocolor(20, 20, 20, 205))
	dxDrawText(team.name, scoreboard.padding, offsetY, scoreboard.width * 0.75, offsetY + scoreboard.rowHeight, tocolor(r, g, b, 255), scoreboard.fontScale, scoreboard.font, "left", "center", false, false, false, true)
	dxDrawText(playerCount, 0, offsetY, scoreboard.width - scoreboard.padding, offsetY + scoreboard.rowHeight, tocolor(255, 255, 255, 255), scoreboard.fontScale, scoreboard.font, "right", "center", false, false, false, true)
end

function scoreboard.render()
	local currentTick = getTickCount()
	local scoreboardTick = scoreboard.tick or 0
	scoreboard.progress = interpolateBetween(scoreboard.progress or 0, 0, 0, scoreboard.visible and 1 or 0, 0, 0, math_min(500, currentTick - scoreboardTick)/500, scoreboard.interpolator)
	local scrollTick = scoreboard.scrollTick or 0
	scoreboard.scroll = interpolateBetween(scoreboard.scroll or 0, 0, 0, scoreboard.scrollToGo or 0, 0, 0, math_min(250, currentTick - scrollTick)/250, scoreboard.interpolator)
	if not scoreboard.visible and scoreboard.progress == 0 then
		removeEventHandler("onClientRender", root, scoreboard.render)
		return
	end
	local maximumScroll = scoreboard.maximumScroll or 0
	local minimumHeight = maximumScroll + (scoreboard.height - scoreboard.contentHeight)
	minimumHeight = minimumHeight - (minimumHeight % 10)
	local height = math_min(minimumHeight, scoreboard.height)
	local scroll = scoreboard.scroll or 0
	local delta, endIndex, maximumDelta = 1, 1, math_max(#scoreboard.rows - scoreboard.rowsToShow - 1, 0)
	if scroll and maximumScroll then
		maximumScroll = math_max((scoreboard.maximumScroll or 0) - scoreboard.contentHeight, 0)
		local percantage = scroll/(maximumScroll + scoreboard.contentHeight)
		delta = math_min(math_max(math_floor(#scoreboard.rows * percantage), 1), maximumDelta)
		endIndex = delta + scoreboard.rowsToShow + 1
	end
	dxSetRenderTarget(scoreboard.contentRenderTarget, true)
	dxSetBlendMode("modulate_add")
	for i = delta, endIndex do
		local row = scoreboard.rows[i]
		if row then
			local offsetY = row[3] - scroll
			if row[1] == "column" then
				scoreboard.renderColumns(row[2], offsetY)
				columns = row[2]
			elseif row[1] == "arena" then
				scoreboard.renderArenaRow(row[2], offsetY)
			elseif row[1] == "player" then
				scoreboard.renderPlayerRow(row[2], row[4], offsetY)
			elseif row[1] == "team" then
				scoreboard.renderTeamRow(row[2], columns, offsetY)
			end
		end
	end
	dxSetBlendMode("blend")
	dxSetRenderTarget()
	dxSetRenderTarget(scoreboard.renderTarget, true)
	dxDrawRectangle(0, 0, scoreboard.width, scoreboard.height, tocolor(10, 10, 10, 225))
	-- Header
	dxDrawRectangle(0, 0, scoreboard.width, scoreboard.headerHeight, tocolor(15, 15, 15, 255))
	dxDrawImageSection(scoreboard.logoOffset, scoreboard.logoOffset, scoreboard.logoSize, scoreboard.logoSize, 1, 1, 70, 70, "img/logo-mini.png", 0, 0, 0, tocolor(25, 132, 109, 255))
	dxDrawText(serverName, scoreboard.logoOffset + scoreboard.logoSize + scoreboard.padding, 0, scoreboard.logoOffset + scoreboard.logoSize + scoreboard.padding + scoreboard.width * 0.75, scoreboard.headerHeight, tocolor(255, 255, 255, 255), scoreboard.fontScale, scoreboard.font, "left", "center", true)
	dxDrawText(playersCount.."/"..maximumPlayers, scoreboard.width * 0.75, 0, scoreboard.width - scoreboard.padding, scoreboard.headerHeight, tocolor(255, 255, 255, 255), scoreboard.fontScale, scoreboard.font, "right", "center", true)
	offsetY = scoreboard.headerHeight
	dxSetBlendMode("add")
	dxDrawImage(0, offsetY, scoreboard.contentWidth, scoreboard.contentHeight, scoreboard.contentRenderTarget, 0, 0, 0, tocolor(255, 255, 255, 255))
	dxDrawRectangle(scoreboard.width - 5, offsetY, 5, scoreboard.contentHeight, tocolor(5, 5, 5, 105))
	if scoreboard.maximumScrollReal and scoreboard.maximumScrollReal > 0 and scoreboard.scrollbarSize then
		local percantage = (scoreboard.scroll or 0)/(scoreboard.maximumScrollReal)
		local scrollbarOffset = (scoreboard.contentHeight - scoreboard.scrollbarSize) * percantage
		dxDrawRectangle(scoreboard.width - 5, offsetY + scrollbarOffset, 10, scoreboard.scrollbarSize, tocolor(25, 132, 109, 255))
	end
	dxSetBlendMode("blend")
	dxSetRenderTarget()
	local offset = (scoreboard.height - height)/2
	dxDrawImageSection(scoreboard.x, scoreboard.y + offset, scoreboard.width, height, 0, 0, scoreboard.width, height, scoreboard.renderTarget, 0, 0, 0, tocolor(255, 255, 255, 255 * scoreboard.progress), true)
end

local get_fps_limit = getFPSLimit
local fps = {counter = 0, tick = getTickCount()}
addEventHandler("onClientRender", root,
function()
	fps.counter = fps.counter + 1
	if getTickCount() - fps.tick > 1000 and fps.lastCounter ~= fps.counter then
		fps.counter = math_min(fps.counter, get_fps_limit())
		if not lastSyncTick or getTickCount() - lastSyncTick > 3000 then
			setElementData(localPlayer, "fps", fps.counter, false)
			lastSyncTick = getTickCount()
		else
			setElementData(localPlayer, "fps", fps.counter, false)
		end
		fps.lastCounter = fps.counter
		fps.tick = getTickCount()
		fps.counter = 0
	end
end)

_getElementData = getElementData
function getElementData(element, dataName)
	if not isElement(element) or type(dataName) ~= "string" then
		return
	end
	if getElementType(element) == "player" and dataName == "money" then
		if not _getElementData(element, "LoggedIn") then
			return "Guest"
		end
	end
	return _getElementData(element, dataName)
end

addEventHandler("onClientMinimize", root,
function()
	setElementData(localPlayer, "minimized", true, false)
end)

addEventHandler("onClientRestore", root,
function()
	setElementData(localPlayer, "minimized", false, false)
end)

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