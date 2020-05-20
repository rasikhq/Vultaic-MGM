CAchievement = {}
function CAchievement:new(player)
	outputDebugString("CAchievement:new >> "..string.gsub(getPlayerName(player), "#%x%x%xx%x%x", ""), 0, 255, 180, 0)
	dbQuery(CAchievement.constructor, {player}, g_Connection, "SELECT * FROM v_achievements WHERE `account_id` = ?", getElementData(player, "account_id"))
end

function CAchievement.constructor(query, player)
	local result = dbPoll(query, 0)
	if not result then
		return outputDebugString("[Achievements] constructor failure")
	end
	g_PlayerAchievements[player] = {}
	for _, row in pairs(result) do
		local achievement_id = row.achievement_id
		g_PlayerAchievements[player][achievement_id] = true
	end
	exports.v_mysql:setPlayerStats(player, "achievements", #result, true)
	triggerEvent("Achievements:onPlayerInit", player)
	triggerClientEvent(player, "Achievements:onPlayerReceiveList", player, g_Achievements, g_PlayerAchievements[player])
end

function CAchievement.destructor(player)
	player = isElement(player) and player or source
	if not getElementData(player, "LoggedIn") then
		return
	end
	if g_PlayerAchievements[player] then
		g_PlayerAchievements[player] = nil
	end
end

local function tableFind(tbl, key)
	local findings = {}
	local first_result = false
	for i = 1, #tbl do
		if tbl[i][1] == key then
			if first_result == false then
				first_result = true
			end
			table.insert(findings, i)
		end
	end
	return (first_result == true and findings or false)
end
function CAchievement:onPlayerStatsUpdate(player, key, newValue)
	local achievement_ids = tableFind(g_Achievements, key)
	if achievement_ids then
		for index, achievement_id in pairs(achievement_ids) do
			if type(newValue) ~= "number" then
				outputDebugString("Found achievement id for a non-numeric value >> "..key.." >> "..newValue, 1)
			end
			local player_achievement_data = g_PlayerAchievements[player]
			if(not player_achievement_data) then
				outputDebugString("CAchievement:onPlayerStatsUpdate >> Achievement data not present for "..getPlayerName(player).." (key: "..key..")", 0, 255, 180, 0)
				return
			end
			local achievement_data = g_Achievements[achievement_id]
			if newValue >= achievement_data[3] and player_achievement_data[achievement_id] == nil then
				player_achievement_data[achievement_id] = true
				exports.v_mysql:givePlayerStats(player, "money", achievement_data[5])
				CAchievement:UpdateAchievements(player, achievement_id)
			end
		end
	end
end

function CAchievement:UpdateAchievements(player, achievement_id)
	local account_id = getElementData(player, "account_id")
	dbExec(g_Connection, "INSERT INTO v_achievements (`account_id`, `achievement_id`) VALUES (?, ?)", account_id, achievement_id)
	triggerClientEvent(player, "Achievements:onPlayerUnlockAchievement", player, achievement_id)
	exports.v_mysql:setPlayerStats(player, "achievements", (exports.v_mysql:getPlayerStats(player, "achievements") or 0)+1, true)
	--outputDebugString("CAchievement:UpdateAchievements >> "..string.gsub(getPlayerName(player), "#%x%x%xx%x%x", ""), 0, 255, 180, 0)
end