CAccount = {}
CAccount.Elements = {
	account_id = -1,
	money = 0,
	dm_points = 0,
	os_points = 0,
	dd_points = 0,
	race_points = 0,
	shooter_points = 0,
	hunter_points = 0,
	tdm_points = 0,
	Clan = 0,
}
CAccount.DefaultData = {
	["awards"] = {}
}
function CAccount:new(player, userdata)
	dbQuery(CAccount.constructor, {player, userdata}, g_Connection, "SELECT * FROM vmtasa_accounts WHERE `account_id` = ? LIMIT 1", userdata.connect_id)
end

function CAccount.constructor(query, player, userdata)
	if not isElement(player) then return end
	local result = dbPoll(query, 0)
	if not result then
		return outputDebugString("[Accounts] constructor failure")
	end
	g_Userdata[player] = {}
	setElementData(player, "LoggedIn", true)
	if #result > 0 then
		for fieldName, fieldValue in pairs(result[1]) do
			if CAccount.Elements[fieldName] ~= nil then
				setElementData(player, fieldName, fieldValue)
				g_Userdata[player][fieldName] = fieldValue
			else
				g_Userdata[player][fieldName] = fromJSON(fieldValue) or {}
			end
		end
	end
	if #result == 0 then
		dbExec(g_Connection, "INSERT INTO vmtasa_accounts (`account_id`) VALUES (?)", userdata.connect_id)
		g_Userdata[player] = {
			account_id = userdata.connect_id,
		}
		for statsName, statsDefault in pairs(CAccount.Elements) do
			if g_Userdata[player][statsName] == nil and statsName ~= "account_id" then
				g_Userdata[player][statsName] = statsDefault
			end
		end
		g_Userdata[player]["data"] = {}
		g_Userdata[player]["tuning"] = {}
		for statsName, statsValue in pairs(g_Userdata[player]) do
			if CAccount.Elements[statsName] ~= nil then
				setElementData(player, statsName, statsValue)
			end
		end
		-- Display help
		outputChatBox("#19846d* #ffffffWelcome to #19846dVultaic#ffffff! Check out the '#19846dHelp#ffffff' tab on #19846dF7#ffffff to know all the important factors.", player, 255, 255, 255, true)
		--triggerClientEvent(player, "panel:show", player, 6)
	end
	for statsName, statsDefault in pairs(CAccount.DefaultData) do
		if g_Userdata[player]["data"][statsName] == nil then
			g_Userdata[player]["data"][statsName] = (type(statsDefault) == "table" and {} or statsDefault)
		end
	end
	g_Userdata[player]["temporary"] = {}
	setElementData(player, "username", userdata.username)
	triggerClientEvent(player, "mysql:onClientLogin", player, g_Userdata[player])
	triggerEvent("mysql:onPlayerLogin", player, g_Userdata[player], userdata)
end

function CAccount.destructor(player)
	player = isElement(player) and player or source
	if not getElementData(player, "LoggedIn") then
		return
	end
	triggerEvent("mysql:onPlayerLogout", player)
	local accountID = getElementData(player, "account_id")
	local userdata = g_Userdata[player]
	userdata.temporary = nil
	for statsName, statsValue in pairs(userdata) do
		if CAccount.Elements[statsName] ~= nil then
			userdata[statsName] = getElementData(player, statsName)
			setElementData(player, statsName, nil)
		end
	end
	local sQueryValue = ""
	--print("[MySQL DEBUG] Starting to save")
	for statsName, statsValue in pairs(userdata) do
		if CAccount.Elements[statsName] ~= nil then
			--print("		"..statsName.." : "..tostring(statsValue))
			sQueryValue = sQueryValue == "" and (sQueryValue.."`"..statsName.."` = "..statsValue) or (sQueryValue..", ".."`"..statsName.."` = "..statsValue)
		end
	end
	local clean_data = toJSON(userdata["data"])
	local clean_tuning = toJSON(userdata["tuning"])
	dbExec(g_Connection, 'UPDATE vmtasa_accounts SET '..sQueryValue..', `data` = ?, `tuning` = ? WHERE `account_id` = '..accountID, clean_data, clean_tuning)
	setElementData(player, "LoggedIn", false)
	g_Userdata[player] = nil
	print("[MySQL DEBUG] Saved "..getPlayerName(player).."'s data")
end
addEventHandler("onPlayerQuit", root, CAccount.destructor)

--[[ Metamethods ]]--
function CAccount:setPlayerStats(player, key, value, isTemporary)
	if not getElementData(player, "LoggedIn") then
		return
	end
	isTemporary = isTemporary or false
	local userdata = g_Userdata[player]
	if isTemporary then
		userdata.temporary[key] = value
		return true
	end
	if CAccount.Elements[key] ~= nil then
		setElementData(player, key, value)
	else
		if userdata[key] then
			userdata[key] = value
		else
			userdata["data"][key] = value
			-- JSON TEST
			local json_test = toJSON(userdata["data"])
			if not json_test or json_test == "" or json_test == "[ [ ] ]" then
				outputChatBox("AN ERROR HAS OCCURED. INFORM DEVELOPERS, ERROR CODE: #1 | ERROR KEY: "..key, player, 255, 0, 0, true)
				print("Error Code 1: "..tostring(key).." - "..tostring(value))
			end
		end
	end
	triggerEvent("CAccount:onPlayerStatsUpdate", player, key, value)
	triggerClientEvent(player, "CAccount:onClientStatsUpdate", player, key, value)
end

function CAccount:getPlayerStats(player, key)
	if not getElementData(player, "LoggedIn") then
		return
	end
	local userdata = g_Userdata[player]
	if userdata["temporary"][key] ~= nil then
		return userdata["temporary"][key]
	end
	if CAccount.Elements[key] ~= nil then
		return getElementData(player, key)
	else
		if userdata[key] then
			return userdata[key]
		elseif userdata["data"][key] then
			return userdata["data"][key]
		else
			return false
		end
	end
end

function CAccount:takePlayerStats(player, key, amount)
	if not getElementData(player, "LoggedIn") then
		return
	end
	local userdata = g_Userdata[player]
	local newValue = nil
	local userdata_updated = false
	if userdata["temporary"][key] ~= nil then
		newValue = math.max(0, userdata["temporary"][key]-amount)
		userdata["temporary"][key] = newValue
		return true
	end
	if CAccount.Elements[key] ~= nil then
		newValue = math.max(0, getElementData(player, key, value)-amount)
		setElementData(player, key, newValue)
		userdata_updated = true
	else
		if userdata[key] then
			newValue = math.max(0, userdata[key]-amount)
			userdata[key] = newValue
			userdata_updated = true
		elseif userdata["data"][key] and tonumber(userdata["data"][key]) then
			newValue = math.max(0, tonumber(userdata["data"][key])-amount)
			userdata["data"][key] = newValue
			userdata_updated = true
		else
			return outputDebugString("[Accounts] Invalid key to take amount")
		end
	end
	if userdata_updated then
		triggerEvent("CAccount:onPlayerStatsUpdate", player, key, newValue)
		triggerClientEvent(player, "CAccount:onClientStatsUpdate", player, key, newValue)
	end
end

function CAccount:givePlayerStats(player, key, amount, forceSet)
	if not getElementData(player, "LoggedIn") then
		return
	end
	--outputDebugString("[CACCOUNT]: "..getPlayerName(player).." >> "..tostring(key).." > "..tostring(amount))
	local userdata = g_Userdata[player]
	local newValue = nil
	local userdata_updated = false
	if userdata["temporary"][key] ~= nil then
		userdata["temporary"][key] = userdata["temporary"][key]+amount
		return true
	end
	if CAccount.Elements[key] ~= nil then
		setElementData(player, key, getElementData(player, key)+amount)
		newValue = getElementData(player, key)
		userdata_updated = true
	else
		if userdata[key] then
			userdata[key] = userdata[key]+amount
			newValue = userdata[key]
			userdata_updated = true
		elseif userdata["data"][key] and tonumber(userdata["data"][key]) then
			userdata["data"][key] = tonumber(userdata["data"][key])+amount
			newValue = userdata["data"][key]
			userdata_updated = true
		else
			if forceSet then
				userdata["data"][key] = amount
				newValue = amount
				userdata_updated = true
			else
				return outputDebugString("[Accounts] Invalid key to give amount")
			end
		end
	end
	if userdata_updated then
		triggerEvent("CAccount:onPlayerStatsUpdate", player, key, newValue)
		triggerClientEvent(player, "CAccount:onClientStatsUpdate", player, key, newValue)
	end
end

function CAccount:setPlayerTuningStats(player, key, value)
	if not getElementData(player, "LoggedIn") then
		return
	end
	--print("[TUNING DEBUG] Setting "..getPlayerName(player).."'s tuning key: "..tostring(key)..", to value: "..tostring(value))
	--iprint(value)
	g_Userdata[player]["tuning"][key] = value
	-- JSON TEST
	local json_test = toJSON(g_Userdata[player]["tuning"])
	if not json_test or json_test == "" or json_test == "[ [ ] ]" then
		outputChatBox("AN ERROR HAS OCCURED. INFORM DEVELOPERS, ERROR CODE: #2 | ERROR KEY: "..key, player, 255, 0, 0, true)
		print("Error Code 2: "..tostring(key).." - "..tostring(value))
	end
	--
	triggerEvent("CAccount:onPlayerStatsUpdate", player, key, value)
	triggerClientEvent(player, "CAccount:onClientStatsUpdate", player, key, value)
end

function CAccount:getPlayerTuningStats(player, key)
	if not getElementData(player, "LoggedIn") then
		return
	end
	--print("[TUNING DEBUG] Getting "..getPlayerName(player).."'s tuning key: "..tostring(key))
	local userdata = g_Userdata[player]
	if userdata["tuning"][key] then
		return userdata["tuning"][key]
	else
		return false
	end
end

-- [[ Metamethods::Awards ]] --
function CAccount:givePlayerAward(player, awardName)
	if not getElementData(player, "LoggedIn") then
		return
	end
	if not findAward(valid_awards, awardName) then
		return outputDebugString("Awarding player an invalid award")
	end
	local player_awards = getPlayerStats(player, "awards") or {}
	if player_awards[awardName] ~= nil then
		return outputDebugString("Player is already having the given award")
	end
	player_awards[awardName] = valid_awards[awardName]
	setPlayerStats(player, "awards", player_awards)
	outputChatBox("#19846dAward :: #ffffff"..getPlayerName(player).." #ffffffhas been awarded the badge #19846d"..player_awards[awardName].name, root, 255, 255, 255, true)
end

-- [[ Utils ]] --
function reloadAwards()
	restartResource(getResourceFromName("v_awards"))
	valid_awards = exports.v_awards:getAwards()
	print("* Refreshed awards")
end

function findAward(tbl, awardName)
	for awardKey, awardInfo in pairs(tbl) do
		if(awardKey == awardName) then
			return awardInfo
		end
	end
	return false
end