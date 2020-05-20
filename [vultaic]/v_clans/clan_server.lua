local DEVELOPMENT_MODE = true
local DB_NAME = (getServerPort() ~= 22003 and DEVELOPMENT_MODE) and "v_accounts_dev" or "v_accounts"
--[[ Global Variables ]]--
Clans = {}
g_Connection = nil

local _outputDebugString = outputDebugString
local function outputDebugString(text) return _outputDebugString(text, 0, 42, 51, 43) end
setPlayerStats = function(player, key, val, isTemporary) return exports.v_mysql:setPlayerStats(player, key, val, isTemporary) end

--[[ Events Callbacks ]]--
--[[ -- Global clans management ]]--
function onScriptLoad()
	g_Connection, error = dbConnect("mysql", "dbname="..DB_NAME..";host=127.0.0.1;port=3306", "root", "M1RAg3_Zz@ST3R")
	if g_Connection then
		Clans.initiate()
		outputDebugString("Clans: Connected")
	else
		outputDebugString("Clans: Failed to connect")
	end
end
addEventHandler("onResourceStart", resourceRoot, onScriptLoad)

function onScriptUnload()
	for _, player in ipairs(getElementsByType("player")) do
		if getElementData(player, "LoggedIn") then
			local ClanID = getElementData(player, "Clan")
			if isClanRegistered(ClanID) then
				Clans[ClanID]:destructor_member(player)
			end
		end
	end
	destroyElement(g_Connection)
	outputDebugString("Clans: Disconnected")
end
addEventHandler("onResourceStop", resourceRoot, onScriptUnload)

addEvent("mysql:onPlayerLogin", true)
addEventHandler("mysql:onPlayerLogin", root, function(userdata)
	local ClanID = getElementData(source, "Clan")
	if isClanRegistered(ClanID) then
		if Clans[ClanID]:isClanMember(source) then
			Clans[ClanID]:constructor_member(source)
		else
			setElementData(source, "Clan", 0)
		end
	end
end)

addEvent("mysql:onPlayerLogout", true)
addEventHandler("mysql:onPlayerLogout", root, function()
	local ClanID = getElementData(source, "Clan")
	if isClanRegistered(ClanID) then
		Clans[ClanID]:destructor_member(source)
	end
end)

--[[
addEvent("core:onPlayerLeaveArena", true)
addEventHandler("core:onPlayerLeaveArena", root, function(arena)
	if getElementData(source, "LoggedIn") then
		local ClanID = getElementData(source, "Clan")
		if isClanRegistered(ClanID) then
			Clans[ClanID]:constructor_member(source)
		end
	end
end)
]]

addEventHandler("onPlayerQuit", root, function()
	if getElementData(source, "LoggedIn") then
		local ClanID = getElementData(source, "Clan")
		if isClanRegistered(ClanID) then
			Clans[ClanID]:destructor_member(source)
		end
	end
end)

function Clans.initiate()
	dbQuery(Clans.constructorInitiate, g_Connection, "SELECT * FROM v_clans")
end

function Clans.constructorInitiate(query)
	local result = dbPoll(query, 0)
	if not result then
		return outputDebugString("[Clans] constructor failure - no results")
	end
	for rowID, rowData in pairs(result) do
		local ClanID = tonumber(rowData["ClanID"])
		local ClanName = tostring(rowData["ClanName"])
		local ClanColor = tostring(rowData["ClanColor"])
		local ClanMembers = fromJSON(rowData["ClanMembers"])
		local ClanLeaders = fromJSON(rowData["ClanLeaders"])
		local data = fromJSON(rowData["data"])
		Clans[ClanID] = CClan:new(ClanID, ClanName, ClanColor, ClanMembers, ClanLeaders, data)
		if Clans[ClanID] ~= nil then
			outputDebugString("Loaded clan data for: "..ClanName)
		else
			_outputDebugString("Failed to load clan data for: "..ClanName, 0, 255, 0, 0)
		end
	end
	for _, player in ipairs(getElementsByType("player")) do
		if getElementData(player, "LoggedIn") then
			local ClanID = getElementData(player, "Clan")
			if isClanRegistered(ClanID) then
				Clans[ClanID]:constructor_member(player)
			end
		end
	end
	
end

--[[ -- Individual clan management ]]--
function Clans.registerClan(leader, ClanName, ClanColor, data)
	if not isElement(leader) then
		return outputDebugString("Clans: Expected player element at argument 1 got "..type(leader))
	elseif not getElementData(leader, "LoggedIn") then
		return outputDebugString("Clans: Player requesting to create clan while not logged-in")
	end
	local account_id, account_username = getElementData(leader, "account_id"), getElementData(leader, "username")
	local donator = exports.v_donatorship:isPlayerDonator(leader)
	local cost = donator and 250000 or 500000
	if isClanRegistered(getElementData(leader, "Clan")) then
		triggerClientEvent(leader, "notification:create", leader, "Error", "You already have a clan")
		return false
	elseif getElementData(leader, "money") < cost then
		triggerClientEvent(leader, "notification:create", leader, "Clan", "You don't have enough money")
		return false
	elseif not isClanNameAvailable(ClanName) then
		triggerClientEvent(leader, "notification:create", leader, "Clan", "Clan name is not available")
		return false
	end
	local ClanID = getFreeClanID()
	if isClanRegistered(ClanID) then
		outputDebugString("Clans: Generated invalid free clan ID - "..ClanID)
		return false
	end
	local ClanMembers = {}
	local ClanLeaders = {}
	ClanMembers[tostring(account_id)] = account_username
	ClanLeaders[tostring(account_id)] = account_username
	if not data["Founder"] or not data["Founder"][account_id] then
		data["Founder"] = {}
		data["Founder"][tostring(account_id)] = account_username
	end
	Clans[ClanID] = CClan:new(ClanID, ClanName, ClanColor, ClanMembers, ClanLeaders, data, leader)
	if isClanRegistered(ClanID) then
		dbExec(g_Connection, "INSERT INTO v_clans (ClanID, ClanName, ClanColor, ClanMembers, ClanLeaders, data) VALUES (?, ?, ?, ?, ?, ?)",
		ClanID, ClanName, ClanColor, toJSON(Clans[ClanID]:getData("ClanMembers")), toJSON(Clans[ClanID]:getData("ClanLeaders")), toJSON(Clans[ClanID]:getData("data")))
		setElementData(leader, "ClanInvite", nil)
		setElementData(leader, "Clan", ClanID)
		exports.v_mysql:takePlayerStats(leader, "money", cost)
		DLog.player(leader, string.gsub(getPlayerName(leader), "#%x%x%x%x%x%x", "").." has registered a clan ["..ClanID.."] "..ClanName)
		return true
	else
		outputDebugString("Clans: Failed to create clan")
	end
	return false
end

function Clans.destroyClan(leader)
	if not isElement(leader) then
		return outputDebugString("Clans: Expected player element at argument 1 got "..type(leader))
	elseif not getElementData(leader, "LoggedIn") then
		return outputDebugString("Clans: Player requesting to create clan while not logged-in")
	end
	local ClanID = getElementData(leader, "Clan")
	if isClanRegistered(ClanID) then
		Clans[ClanID]:destroy(leader)
		DLog.player(leader, string.gsub(getPlayerName(leader), "#%x%x%x%x%x%x", "").." has destroyed his clan ["..ClanID.."]")
		return true
	else
		outputDebugString("Clans: Trying to destroy an unregistered clan")
	end
	return false
end

function Clans.addMember(ClanID, player)
	if isClanRegistered(ClanID) then
		Clans[ClanID]:addMember(player)
		triggerClientEvent(root, "Clans:onPlayerReceiveClanUpdate", resourceRoot, Clans[ClanID])
	end
end

function Clans.removeMember(ClanID, player)
	if isClanRegistered(ClanID) then
		Clans[ClanID]:removeMember(player)
		triggerClientEvent(root, "Clans:onPlayerReceiveClanUpdate", resourceRoot, Clans[ClanID])
	end
end

function Clans.addLeader(ClanID, player)
	if isClanRegistered(ClanID) then
		Clans[ClanID]:addLeader(player)
		triggerClientEvent(root, "Clans:onPlayerReceiveClanUpdate", resourceRoot, Clans[ClanID])
	end
end

function Clans.removeLeader(ClanID, player)
	if isClanRegistered(ClanID) then
		Clans[ClanID]:removeLeader(player)
		triggerClientEvent(root, "Clans:onPlayerReceiveClanUpdate", resourceRoot, Clans[ClanID])
	end
end

function Clans.kickMember(ClanID, leader, member)
	if isClanRegistered(ClanID) then
		member = isElement(member) and member or member.accountID
		outputDebugString("Clans: kickMember >> "..getPlayerName(leader).." >> "..tostring(member))
		Clans[ClanID]:removeMember(member, leader)
	end
end

--[[ -- Callbacks - Information exchange and update ]]--
addEvent("Clans:onPlayerRequestClans", true)
addEventHandler("Clans:onPlayerRequestClans", resourceRoot, function()
	triggerClientEvent(client, "Clans:onClientReceiveClans", client, getClans())
end)

addEvent("Clan:onClanCreate", true)
addEventHandler("Clan:onClanCreate", root, function(ClanName, ClanColor, data)
	outputDebugString("Clan:onClanCreate >> "..getPlayerName(client).." | ("..tostring(ClanName)..", "..tostring(ClanColor)..", "..tostring(data)..")")
	local clan_registered = Clans.registerClan(client, ClanName, ClanColor, data)
	if clan_registered then
		triggerClientEvent(root, "Clans:onPlayerReceiveClanUpdate", resourceRoot, Clans[getElementData(client, "Clan")])
		triggerClientEvent(client, "Clans:onClanCreate", client, 0)
	else
		triggerClientEvent(client, "Clans:onClanCreate", client, -1)
	end
end)

addEvent("Clan:onClanDestroy", true)
addEventHandler("Clan:onClanDestroy", root, function()
	local ClanID = getElementData(client, "Clan")
	if isClanRegistered(ClanID) then
		local clan_destroyed = Clans.destroyClan(client)
		if clan_destroyed then
			triggerClientEvent(root, "Clans:onPlayerReceiveClans", resourceRoot, getClans())
		end
	end
end)

addEvent("Clan:onPlayerLeaveClan", true)
addEventHandler("Clan:onPlayerLeaveClan", root, function()
	local ClanID = getElementData(client, "Clan")
	if isClanRegistered(ClanID) then
		Clans[ClanID]:removeMember(client)
		if isClanRegistered(ClanID) then
			triggerClientEvent(root, "Clans:onPlayerReceiveClanUpdate", resourceRoot, Clans[ClanID])
		else
			triggerClientEvent(root, "Clans:onPlayerReceiveClans", resourceRoot, getClans())
		end
	end
end)

addEvent("Clan:onPlayerKick", true)
addEventHandler("Clan:onPlayerKick", root, function(player)
	local ClanID = getElementData(client, "Clan")
	if isClanRegistered(ClanID) then
		Clans.kickMember(ClanID, client, player)
		triggerClientEvent(root, "Clans:onPlayerReceiveClanUpdate", resourceRoot, Clans[ClanID])
	end
end)

addEvent("Clan:onPlayerUpdateRole", true)
addEventHandler("Clan:onPlayerUpdateRole", root, function(player, role)
	local ClanID = getElementData(client, "Clan")
	if isClanRegistered(ClanID) then
		player = isElement(player) and player or player.accountID
		if Clans[ClanID]:isFounder(client) then
			if client == player then
				return
			elseif role == "member" and not Clans[ClanID]:isClanLeader(player) then
				return triggerClientEvent(client, "notification:create", client, "Clan", "Cannot complete request")
			elseif role == "leader" and Clans[ClanID]:isClanLeader(player) then
				return triggerClientEvent(client, "notification:create", client, "Clan", "Cannot complete request")
			end
		elseif Clans[ClanID]:isClanLeader(client) then
			if client == player then
				return
			elseif (role == "member" and Clans[ClanID]:isFounder(player)) or (role == "member" and Clans[ClanID]:isClanLeader(player)) or (role == "leader" and Clans[ClanID]:isClanLeader(player)) then
				return triggerClientEvent(client, "notification:create", client, "Clan", "Cannot complete request")
			end
		else
			return triggerClientEvent(client, "notification:create", client, "Clan", "Permission denied")
		end
		local role_updated = Clans[ClanID]:setRole(player, role)
		outputDebugString("Clans: role_updated: "..tostring(role_updated))
		if role_updated then
			outputDebugString("Clans: ["..tostring(ClanID).."] Role updated for: "..tostring(player).." new role: "..tostring(role))
			triggerClientEvent(root, "Clans:onPlayerReceiveClanUpdate", resourceRoot, Clans[ClanID])
		end
	else
		outputDebugString("Clan:onPlayerUpdateRole >> Clan is not registered")
	end
end)

addEvent("Clan:onClanUpdateConfig", true)
addEventHandler("Clan:onClanUpdateConfig", root, function(ClanID, Config)
	if isClanRegistered(ClanID) and ClanID == getElementData(client, "Clan") then
		local oldClanData = {
			ClanName = Clans[ClanID]:getData("ClanName"),
			ClanColor = Clans[ClanID]:getData("ClanColor"),
			description = Clans[ClanID]:getData("data")["description"]
		}
		local cost_multiplier = 0
		local update_clanName, update_clanColor, update_clan_description = false, false, false
		if Config.ClanName and Config.ClanName ~= oldClanData.ClanName then
			if not isClanNameAvailable(Config.ClanName) then
				return triggerClientEvent(client, "notification:create", client, "Clan", "The clan name specified is not available")
			end
			cost_multiplier = cost_multiplier+1
			update_clanName = true
		end
		if Config.ClanColor and Config.ClanColor ~= oldClanData.ClanColor then
			cost_multiplier = cost_multiplier+1
			update_clanColor = true
		end
		if Config.description and Config.description ~= oldClanData.description then
			cost_multiplier = cost_multiplier+1
			update_clan_description = true
		end
		--local donator = exports.v_donatorship:isPlayerDonator(client)
		local cost = 50000*cost_multiplier
		if cost == 0 then
			return triggerClientEvent(client, "notification:create", client, "Clan", "Nothing was changed to update")
		elseif getElementData(client, "money") < cost then
			return triggerClientEvent(client, "notification:create", client, "Clan", "Not enough money! ("..(donator and "$25K" or "$50k").." per field)")
		end
		--
		if update_clanName then
			Clans[ClanID]:setData("ClanName", Config.ClanName, true)
		end
		if update_clanColor then
			Clans[ClanID]:setData("ClanColor", Config.ClanColor, true)
		end
		if update_clan_description then
			Clans[ClanID]:setData("description", Config.description, true)
		end
		--
		exports.v_mysql:takePlayerStats(client, "money", cost)
		if update_clanColor or update_clanName then
			local team = getTeamFromName(oldClanData.ClanName)
			if isElement(team) then
				if update_clanColor then
					local r, g, b = hexToRGB(Config.ClanColor)
					setTeamColor(team, r, g, b)
				end
				if update_clanName then
					setTeamName(team, Config.ClanName)
				end
			end
		end
		triggerClientEvent(root, "Clans:onPlayerReceiveClanUpdate", resourceRoot, Clans[ClanID])
		triggerClientEvent(client, "notification:create", client, "Clan", "Clan configuration updated (Cost $"..cost..")")
		DLog.player(client, string.gsub(getPlayerName(client), "#%x%x%x%x%x%x", "").." has updated his clan configuration ($"..cost..")")
	end
end)
--[[ Invitations ]]--
addEvent("Clan:onPlayerInvite", true)
addEventHandler("Clan:onPlayerInvite", root, function(player)
	local ClanID = getElementData(client, "Clan")
	if isClanRegistered(ClanID) then
		Clans.invitePlayer(client, ClanID, player)
	end
end)

addEvent("Clan:onPlayerTakeInvitationAction", true)
addEventHandler("Clan:onPlayerTakeInvitationAction", root, function(ClanID, action)
	Clans.inviteAction(client, ClanID, action)
end)
--[[ -- Invite functions ]]--
function Clans.invitePlayer(inviter, ClanID, player)
	local _ClanID = getElementData(player, "Clan")
	if isClanRegistered(_ClanID) then
		return triggerClientEvent(inviter, "notification:create", inviter, "Clan", getPlayerName(player).."#ffffff is already in a clan")
	elseif Clans[ClanID]:getClanMembersCount() >= 30 then
		return triggerClientEvent(inviter, "notification:create", inviter, "Clan", "Your clan has reached max member count (30)")
	end
	local player_invite = getElementData(player, "ClanInvite")
	if not player_invite  then
		player_invite = {}
	end
	if player_invite[ClanID] ~= nil then
		return triggerClientEvent(inviter, "notification:create", inviter, "Clan", getPlayerName(player).."#ffffff is already invited to the clan")
	end
	player_invite[ClanID] = true
	setElementData(player, "ClanInvite", player_invite)
	triggerClientEvent(inviter, "notification:create", inviter, "Clan", getPlayerName(player).."#ffffff has been invited to the clan")
	triggerClientEvent(player, "notification:create", player, "Clan", getPlayerName(inviter).."#ffffff invited you to "..Clans[ClanID]:getData("ClanName"))
	triggerClientEvent(player, "Clan:onClientInvitationUpdate", player, player_invite)
end

function Clans.inviteAction(player, ClanID, action)
	local player_invite = getElementData(player, "ClanInvite")
	if type(player_invite) ~= "table" then
		return false
	elseif player_invite[ClanID] == nil then
		return false
	elseif not isClanRegistered(ClanID) then
		player_invite[clanID] = nil
		setElementData(player, "ClanInvite", player_invite)
		triggerClientEvent(player, "Clan:onClientInvitationUpdate", player, player_invite)
		return triggerClientEvent(player, "notification:create", player, "Error", "Invitation expired")
	end
	if action == "accept" then
		Clans[ClanID]:addMember(player)
		setElementData(player, "ClanInvite", nil)
		triggerClientEvent(root, "Clans:onPlayerReceiveClanUpdate", resourceRoot, Clans[ClanID])
	elseif action == "decline" then
		player_invite[ClanID] = nil
		setElementData(player, "ClanInvite", player_invite)
		triggerClientEvent(player, "notification:create", player, "Clan", "Invitation from "..Clans[ClanID]:getData("ClanName").." has been declined")
	end
end

--[[ Functions ]]--
function isClanRegistered(ClanID)
	if not tonumber(ClanID) then
		return false
	end
	if Clans[ClanID] ~= nil then
		return true
	else
		return false
	end
end

function isClanNameAvailable(ClanName)
	local lClanName = ClanName:lower()
	for ClanID, ClanData in pairs(Clans) do
		if type(ClanData) == "table" and ClanData:getData("ClanName"):lower() == lClanName then
			return false
		end
	end
	return true
end

function isPlayerClanMember(player, ClanID)
	if isClanRegistered(ClanID) then
		return Clans[ClanID]:isClanMember(player)
	end
end

function isPlayerClanLeader(player, ClanID)
	if isClanRegistered(ClanID) then
		return Clans[ClanID]:isClanLeader(player)
	end
end

function isPlayerClanFounder(player, ClanID)
	if isClanRegistered(ClanID) then
		return Clans[ClanID]:isFounder(player)
	end
end

function getFreeClanID()
	local i = 1
	while Clans[i] ~= nil do
		i = i+1
	end
	return i
end

function getClans()
	local _Clans = {}
	for ClanID, ClanData in pairs(Clans) do
		if type(ClanData) == "table" then
			_Clans[ClanID] = ClanData
		end
	end
	return _Clans
end

--[[ Exports ]]--
function getClan(ClanID)
	if not tonumber(ClanID) then
		return false
	end
	if isClanRegistered(tonumber(ClanID)) then
		return Clans[tonumber(ClanID)]
	end
end

function createClanwarRequest(clanID, settings)
	if isClanRegistered(clanID) and isClanRegistered(settings.clan) then
		Clans[clanID]:createClanwarRequest(settings)
		return true
	end
end

--[[ Utils ]]--

function getPlayerFromAccountID(accountID)
	local getElementData = getElementData
	for _, player in pairs(getElementsByType("player")) do
		local p_account_id = getElementData(player, "account_id")
		if p_account_id == accountID then
			return player
		end
	end
	return false
end

function hexToRGB(hex)
    if hex then
        hex = hex:gsub("#", "")
        return tonumber("0x"..hex:sub(1, 2)), tonumber("0x"..hex:sub(3, 4)), tonumber("0x"..hex:sub(5, 6)), tonumber("0x"..hex:sub(7, 8))
    end
    return 255, 255, 255, 255
end