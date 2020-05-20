local DEVELOPMENT_MODE = true
local DB_NAME = (getServerPort() ~= 22003 and DEVELOPMENT_MODE) and "v_accounts_dev" or "v_accounts"
--[[ Global Variables ]]--
g_Connection = nil
g_Userdata = {}

--[[ Events Callbacks ]]--
function onScriptLoad()
	local v_login = getResourceFromName("v_login")
	if getResourceState(v_login) == "running" then
		restartResource(v_login)
	else
		startResource(v_login)
	end
	startResource(getResourceFromName("v_awards"))
	valid_awards = exports.v_awards:getAwards()
	g_Connection, error = dbConnect("mysql", "dbname="..DB_NAME..";host=127.0.0.1;port=3306", "root", "M1RAg3_Zz@ST3R")
	if g_Connection then
		resetGlobalLoginStatus()
		outputDebugString("MySQL: Connected")
	else
		outputDebugString("MySQL: Failed to connect")
	end
end
addEventHandler("onResourceStart", resourceRoot, onScriptLoad)

function onScriptUnload()
	for _, p in pairs(getElementsByType("player")) do
		CAccount.destructor(p)
	end
	destroyElement(g_Connection)
	stopResource(getResourceFromName("v_login"))
	outputDebugString("MySQL: Disconnected")
end
addEventHandler("onResourceStop", resourceRoot, onScriptUnload)

addEvent("login:onPlayerLogin", true)
addEventHandler("login:onPlayerLogin", root, function(userdata)
	CAccount:new(source, userdata)
end)

addEvent("mysql:onRequestPlayerStats", true)
addEventHandler("mysql:onRequestPlayerStats", root, function(player)
	local userdata = getElementData(player, "LoggedIn") and g_Userdata[player] or false
	-- Update playtime
	if getElementData(player, "arena") ~= "lobby" then
		local joinTick = getPlayerStats(player, "PlayTimeTick") or getTickCount()
		local playTime = getTickCount()-joinTick
		local current_playtime = getPlayerStats(player, "playtime") or 0
		setPlayerStats(player, "playtime", current_playtime+playTime)
		setPlayerStats(player, "PlayTimeTick", getTickCount(), true)
	end
	--
	triggerClientEvent(client, "mysql:onReceivePlayerStats", client, player, userdata)
end)

function resetGlobalLoginStatus()
	for _, p in pairs(getElementsByType("player")) do
		setElementData(p, "account_id", nil)
		setElementData(p, "username", nil)
		setElementData(p, "LoggedIn", false)
	end
end

-- Statistics
addEvent("core:onPlayerJoinArena", true)
addEventHandler("core:onPlayerJoinArena", root, function(arena)
	setPlayerStats(source, "PlayTimeTick", getTickCount(), true)
end)

addEvent("core:onPlayerLeaveArena", true)
addEventHandler("core:onPlayerLeaveArena", root, function(arena)
	local joinTick = getPlayerStats(source, "PlayTimeTick") or getTickCount()
	local playTime = getTickCount()-joinTick
	local current_playtime = getPlayerStats(source, "playtime") or 0
	setPlayerStats(source, "playtime", current_playtime+playTime)
end)

-- Exported functions
function getMySQLConnectionPointer()
	return class_Accounts.connection or false
end

function setPlayerStats(...)
	CAccount:setPlayerStats(...)
end

function getPlayerStats(...)
	return CAccount:getPlayerStats(...)
end

function takePlayerStats(...)
	CAccount:takePlayerStats(...)
end

function givePlayerStats(...)
	CAccount:givePlayerStats(...)
end

function setPlayerTuningStats(...)
	CAccount:setPlayerTuningStats(...)
end

function getPlayerTuningStats(...)
	return CAccount:getPlayerTuningStats(...)
end

function givePlayerAward(...)
	return CAccount:givePlayerAward(...)
end