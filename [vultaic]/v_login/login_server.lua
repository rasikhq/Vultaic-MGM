local login = {}
login.apiURL = getServerPort() == 22003 and "https://forum.vultaic.com/mta_login_test.php" or "https://forum.vultaic.com/mta_login_dev.php"
login.isPlayerLoggedIn = {}
login.usedAccounts = {}
login.activeAttempts = {}

addEventHandler("onPlayerQuit", root,
function()
	local username = login.isPlayerLoggedIn[source] 
	if login.usedAccounts[username] then
		login.usedAccounts[username] = nil
	end
	if login.isPlayerLoggedIn[source] then
		login.isPlayerLoggedIn[source] = nil
	end
end)

function login.connectAPI(username, password, player)
	if not isElement(player) then
		return
	end
	local username, password = tostring(username), tostring(password)
	print("login.connectAPI: "..tostring(login.usedAccounts[username]))
	if login.isPlayerLoggedIn[player] then
		return triggerClientEvent(player, "notification:create", player, "Log in", "You are already logged in.")
	elseif login.activeAttempts[player] then
		return triggerClientEvent(player, "notification:create", player, "Log in", "Please wait some time before trying to logging again.")
	end
	if type(username) ~= "string" then
		return triggerClientEvent(player, "notification:create", player, "Log in", "Please enter your username.")
	end
	if #username <= 2 then
		return triggerClientEvent(player, "notification:create", player, "Log in", "Your username is too short.")
	end
	if login.usedAccounts[username] then
		return triggerClientEvent(player, "notification:create", player, "Log in", "This account is already being used.")
	end
	if type(password) ~= "string" then
		return triggerClientEvent(player, "notification:create", player, "Log in", "Please enter your password.")
	end
	if #password <= 2 then
		return triggerClientEvent(player, "notification:create", player, "Log in", "Your password is too short.")
	end
	local queueName = md5(username..password)
	local POST = toJSON({username = username, password = password})
	fetchRemote(login.apiURL, queueName, 1, 10000, login.APICallBack, POST, false, player, password)
	login.activeAttempts[player] = true
end

function login.APICallBack(responseData, errorNo, player, password)
	if errorNo == 0 then
		local response = fromJSON(responseData)
		if type(response) ~= "table" then
			return outputDebugString("Failed to convert JSON", 1)
		end
		if response.error == 0 then -- Login success
			response.password = password
			local assign = login.assingUserdata(player, response)
			if assign then
				triggerClientEvent(player, "notification:create", player, "Log in", "Successfully logged in as "..response.username)
			else
				triggerClientEvent(player, "notification:create", player, "Log in", "Failed to login as "..response.username)
			end
		else
			if response.message == 1 then -- Account is not found
				triggerClientEvent(player, "notification:create", player, "Log in", "An account with this name is not found")
			elseif response.message == 2 then -- Wrong password
				triggerClientEvent("notification:create", player, "Log in", "Wrong password")
			else
				outputDebugString("Unknown error while logging in player "..getPlayerName(player))
				triggerClientEvent(player, "notification:create", player, "Log in", "Failed to login")
			end
		end
	else
		outputDebugString("Failed to log player "..getPlayerName(player).." in, error no: "..errorNo, 0)
	end
	if login.activeAttempts[player] then
		login.activeAttempts[player] = nil
	end
end

function debugi(index, val)
	outputChatBox("[DEBUG] "..index..": "..tostring(val).." ["..type(val).."]")
end

function login.assingUserdata(player, data)
	if isElement(player) and type(data) == "table" then
		if not data.connect_id or not data.username then
			outputDebugString("Cannot assign userdata without an ID", 1)
			return false
		end
		if login.usedAccounts[data.username] then
			return false
		end
		setElementData(player, "userdata", data, false)
		triggerEvent("login:onPlayerLogin", player, data)
		triggerClientEvent(player, "login:onClientLogin", resourceRoot, data)
		login.isPlayerLoggedIn[player] = tostring(data.username)
		login.usedAccounts[tostring(data.username)] = player
		--
		--debugi("data.username", data.username)
		--debugi("login.usedAccounts index on "..data.username, login.usedAccounts[data.username])
		--
		return true
 	end
end

addEvent("login:onPlayerRequestLogin", true)
addEventHandler("login:onPlayerRequestLogin", root,
function(username, password)
	login.connectAPI(username, password, source)
end)

addEvent("login:onPlayerRequestPlayAsGuest", true)
addEventHandler("login:onPlayerRequestPlayAsGuest", root,
function()
	triggerEvent("login:onPlayerPlayAsGuest", source)
	triggerClientEvent(source, "login:onClientPlayAsGuest", resourceRoot)
end)

function getPlayerFromUsername(username)
	return username and login.usedAccounts[username] or nil
end