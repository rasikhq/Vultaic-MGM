local getPlayerStats = function(...) return exports.v_mysql:getPlayerStats(...) end
local setPlayerStats = function(...) exports.v_mysql:setPlayerStats(...) end
addEvent("Achievements:onPlayerInit", true)
addEventHandler("Achievements:onPlayerInit", root, function()
	local currentTime = getRealTime()
	if type(getPlayerStats(source, "daily_login")) ~= "table" then
		local m_currentTime = {}
		for k, v in pairs(currentTime) do
			m_currentTime[k] = v
		end
		m_currentTime.yearday = m_currentTime.yearday == 0 and 365 or m_currentTime.yearday-1
		setPlayerStats(source, "daily_login", m_currentTime)
		setPlayerStats(source, "daily_login_streak", 0)
	end
	local daily_login = getPlayerStats(source, "daily_login")
	local daily_login_streak = getPlayerStats(source, "daily_login_streak")
	local next_day = isNextDay(currentTime.yearday, daily_login.yearday)
	if next_day == true then
		setPlayerStats(source, "daily_login", currentTime)
		if daily_login_streak < 5 then
			daily_login_streak = daily_login_streak+1
			setPlayerStats(source, "daily_login_streak", daily_login_streak)
		end
		local reward = 5000*daily_login_streak
		local priority = "Bonus"
		if(exports.v_mysql:getPlayerStats(source, "money") >= 200000) then
			reward = 5000
			priority = "Reduced"
		end
		exports.v_mysql:givePlayerStats(source, "money", reward)
		triggerClientEvent(source, "notification:create", source, "Daily Login", "Award - $"..reward.. " [Streak: "..daily_login_streak.."/5] - "..priority)
	elseif next_day == false then
		setPlayerStats(source, "daily_login", currentTime)
		setPlayerStats(source, "daily_login_streak", 0)
		daily_login_streak = 0
		triggerClientEvent(source, "notification:create", source, "Daily Login", "You missed it! [Streak: "..daily_login_streak.."/5]")
	elseif next_day == nil then
		triggerClientEvent(source, "notification:create", source, "Daily Login", "Current Streak: "..daily_login_streak.."/5")
	end
end)

function getAwards()
	return {
		["beta_tester"] = {name = "Vultaic BETA Tester", description = "Vultaic BETA TESTER service award"},
		["ls_1"] = {name = "LSE: Sole Survivor", description = "Won Vultaic Last Survivor Event"},
		["ls_2"] = {name = "LSE: Runner Up", description = "Second place in Vultaic Last Survivor Event"},
		["ls_3"] = {name = "LSE: Fighter", description = "Third place in Vultaic Last Survivor Event"}
	}
end

local function getPlayerFromPartialName(name)
    local name = name and name:gsub("#%x%x%x%x%x%x", ""):lower() or nil
    if name then
        for _, player in ipairs(getElementsByType("player")) do
            local name_ = getPlayerName(player):gsub("#%x%x%x%x%x%x", ""):lower()
            if name_:find(name, 1, true) then
                return player
            end
        end
    end
end

local function getPlayerFromID(id)
	id = tonumber(id)
	if type(id) ~= "number" then
		return nil
	end
	for _, player in ipairs(getElementsByType("player")) do
		if getElementData(player, "id") == id then
			return player
		end
	end
	return nil
end

function cmd_givecash(player, cmd, plr, amount)
	if not hasObjectPermissionTo(player, "command.stopall" ) then
		return outputChatBox("Access denied", player, 255, 255, 255)
	end
	plr = getPlayerFromID(plr) or getPlayerFromPartialName(plr)
	if not isElement(plr) and getElementType(plr) ~= "player" then
		return outputChatBox("Invalid player", player)
	end
	if not tonumber(amount) then
		return outputChatBox("Invalid amount", player)
	end
	exports.v_mysql:givePlayerStats(plr, "money", amount)
	outputChatBox("#19846d[REWARD] #ffffffYou have been rewarded #19846d$"..amount.."#ffffff!", plr, 255, 255, 255, true)
	outputChatBox(getPlayerName(plr).."#ffffff has been awarded with $"..amount, player, 255, 255, 255, true)
end
addCommandHandler("givecash", cmd_givecash)

function cmd_rewardall(player, cmd, amount)
	if not hasObjectPermissionTo(player, "command.stopall" ) then
		return outputChatBox("Access denied", player, 255, 255, 255)
	end
	if not tonumber(amount) then
		return outputChatBox("Invalid amount", player)
	end
	for _, _player in ipairs(getElementsByType("player")) do
		exports.v_mysql:givePlayerStats(_player, "money", amount)
		outputChatBox("#19846d[REWARD] #ffffffYou have been rewarded #19846d$"..amount.."#ffffff!", _player, 255, 255, 255, true)
	end
	outputChatBox("Everyone #ffffff has been awarded with $"..amount, player, 255, 255, 255, true)
end
addCommandHandler("rewardall", cmd_rewardall)

function cmd_loginStreak(player, cmd, ...)
	local daily_login_streak = getPlayerStats(player, "daily_login_streak")
	if daily_login_streak then
		triggerClientEvent(player, "notification:create", player, "Daily Login", "Current Streak: "..daily_login_streak.."/5. Visit daily to increase it.")
	end
end
addCommandHandler("ls", cmd_loginStreak)

function isNextDay(day1, day2)
	if day1 == day2 then
		return nil
	end
	if day1 == day2+1 then
		return true
	end
	if day1 == 0 and day2 == 365 then
		return true
	end
	return false
end