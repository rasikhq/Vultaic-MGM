local DEVELOPMENT_MODE = true
local DB_NAME = (getServerPort() ~= 22003 and DEVELOPMENT_MODE) and "v_accounts_dev" or "v_accounts"

g_Connection = nil
--[[
	IMPORTANT NOTE:
		The order of indexes of this table should now never be changed, if [0] becomes "toptimes" for example,
		the players who unlocked $1M achievement will have toptimes one unlocked instead of money.
		
		New achievements always go at the end of the table.
]]--
g_Achievements = {
	{"money", "Money? I got that!", 1000000, "Get 1 million in cash", 0},
	{"toptimes", "Remember the name!", 1000, "Get 1K toptimes", 25000},
	{"dm_points", "Deathmatch Rookie!", 10000, "Get 10K points in Deathmatch arena", 50000},
	{"dm_points", "King of Deathmatch!", 100000, "Get 100K points in Deathmatch arena", 75000},
	{"os_points", "Old, but gold!", 10000, "Get 10K points in Oldschool arena", 50000},
	{"os_points", "King of Oldschool!", 100000, "Get 100K points in Oldschool arena", 75000},
	{"dd_points", "They know me for my destruction!", 10000, "Get 10K points in DD arena", 50000},
	{"dd_points", "King of Destruction Derby!", 100000, "Get 100K points in DD arena", 75000},
	{"race_points", "Step up to my wheels!", 10000, "Get 10K points in Race arena", 50000},
	{"race_points", "King of Race!", 100000, "Get 100K points in Race arena", 75000},
	{"shooter_points", "Shoot or get shot!", 10000, "Get 10K points in Shooter arena", 50000},
	{"shooter_points", "King of Shooter!", 100000, "Get 100K points in Shooter arena", 75000},
	{"hunter_points", "Don't flame, get Aim!", 10000, "Get 10K points in Hunter arena", 50000},
	{"hunter_points", "King of Hunter!", 100000, "Get 100K points in Hunter arena", 75000},
}
g_PlayerAchievements = {}
function onScriptLoad()
	g_Connection, error = dbConnect("mysql", "dbname="..DB_NAME..";host=127.0.0.1;port=3306", "root", "M1RAg3_Zz@ST3R")
	if g_Connection then
		dbExec(g_Connection, "CREATE TABLE IF NOT EXISTS v_achievements (`account_id` INT NOT NULL, `achievement_id` INT NOT NULL)")
		for _, player in ipairs(getElementsByType("player")) do
			if getElementData(player, "LoggedIn") then
				CAchievement:new(player)
			end
		end
		outputDebugString("Achievements MySQL: Connected")
	else
		outputDebugString("Achievements MySQL: Failed to connect")
	end
end
addEventHandler("onResourceStart", resourceRoot, onScriptLoad)

function onPlayerLogin(userdata)
	CAchievement:new(source)
end
addEvent("mysql:onPlayerLogin", true)
addEventHandler("mysql:onPlayerLogin", root, onPlayerLogin)

function onPlayerStatsUpdate(key, newValue)
	CAchievement:onPlayerStatsUpdate(source, key, newValue)
end
addEvent("CAccount:onPlayerStatsUpdate", true)
addEventHandler("CAccount:onPlayerStatsUpdate", root, onPlayerStatsUpdate)

function onPlayerRequestList()
	triggerClientEvent(client, "Achievements:onPlayerReceiveList", client, g_Achievements, g_PlayerAchievements[client])
end
addEvent("Achievements:onPlayerRequestList", true)
addEventHandler("Achievements:onPlayerRequestList", resourceRoot, onPlayerRequestList)