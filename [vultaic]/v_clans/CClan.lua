--[[ The Clan class ]]--
CClan = {}
CClan.__index = CClan
function CClan:new(...)
	local Clan = {...}
	if type(Clan[1]) ~= "number" then
		outputDebugString("Clans: Missing data 'ClanID' :: ["..tostring(type(Clan[1])).."] "..tostring(Clan[1]))
		return nil
	end
	if type(Clan[2]) ~= "string" then
		outputDebugString("Clans: Missing data 'ClanName' :: ["..tostring(type(Clan[2])).."] "..tostring(Clan[2]))
		return nil
	end
	if type(Clan[3]) ~= "string" then
		outputDebugString("Clans: Missing data 'ClanColor' :: ["..tostring(type(Clan[3])).."] "..tostring(Clan[3]))
		return nil
	end
	if type(Clan[4]) ~= "table" then
		outputDebugString("Clans: Missing data 'ClanMembers' :: ["..tostring(type(Clan[4])).."] "..tostring(Clan[4]))
		return nil
	end
	if type(Clan[5]) ~= "table" then
		outputDebugString("Clans: Missing data 'ClanLeaders' :: ["..tostring(type(Clan[5])).."] "..tostring(Clan[5]))
		return nil
	end
	if type(Clan[6]) ~= "table" then
		outputDebugString("Clans: Missing data 'data' :: ["..tostring(type(Clan[6])).."] "..tostring(Clan[6]))
		return nil
	end
	if not isClanNameAvailable(Clan[2]) and isElement(Clan[7]) then
		triggerClientEvent(Clan[7], "notification:create", Clan[7], "Clan", "Clan name is already in use")
		return nil
	end
	local self = setmetatable({}, CClan)
	self.ClanID		= Clan[1]
	self.ClanName	= Clan[2]
	self.ClanColor	= Clan[3]
	self.ClanMembers	= Clan[4]
	self.ClanLeaders	= Clan[5]
	self.data		= Clan[6]
	if isElement(Clan[7]) then
		self:constructor_member(Clan[7])
	end
	return self
end

function CClan:destroy(destroyer)
	local ClanID = self:getData("ClanID")
	local ClanMembers = self:getData("ClanMembers")
	local destroyerName = isElement(destroyer) and getPlayerName(destroyer) or "Admin"
	dbExec(g_Connection, "UPDATE vmtasa_accounts SET `Clan` = 0 WHERE `Clan` = ?", ClanID)
	dbExec(g_Connection, "DELETE FROM v_clans WHERE `ClanID` = ?", ClanID)
	for _account_id, _account_username in pairs(ClanMembers) do
		local player = getPlayerFromAccountID(tonumber(_account_id))
		if isElement(player) then
			setPlayerStats(player, "Clan", 0)
			self:destructor_member(player)
			triggerClientEvent(player, "notification:create", player, "Clan", "Your clan has been destroyed by "..destroyerName)
		end
	end
	triggerClientEvent(root, "Clans:onPlayerReceiveClanUpdate", resourceRoot, ClanID)
	Clans[ClanID] = nil
end

--[[ Clan member logging in/out management ]]--
function CClan:constructor_member(player)
	outputDebugString("CClan:constructor_member("..getPlayerName(player)..")")
	local ClanName = self:getData("ClanName")
	local team = getTeamFromName(ClanName)
	if isElement(team) then
		return setPlayerTeam(player, team)
	else
		local r, g, b = hexToRGB(self:getData("ClanColor"))
		team = createTeam(ClanName, r, g, b)
		if team then
			setPlayerTeam(player, team)
		else
			outputDebugString("Clans: Failed to create team element for "..getPlayerName(player))
			return false
		end
	end
end

function CClan:destructor_member(player)
	outputDebugString("CClan:destructor_member("..getPlayerName(player)..")")
	local ClanName = self:getData("ClanName")
	local team = getTeamFromName(ClanName)
	if isElement(team) then
		setPlayerTeam(player, nil)
		triggerEvent("Clans:Destructor_Player", player)
		if #getPlayersInTeam(team) == 0 then
			destroyElement(team)
			return true
		end
	end
end

--[[ Clan management ]]--
function CClan:addMember(member)
	if self:isClanMember(member) then
		return false
	end
	local account_id = getElementData(member, "account_id")
	local ClanMembers = self:getData("ClanMembers")
	ClanMembers[tostring(account_id)] = getElementData(member, "username")
	setPlayerStats(member, "Clan", self:getData("ClanID"))
	setElementData(member, "ClanInvite", nil)
	self:constructor_member(member)
	dbExec(g_Connection, "UPDATE v_clans SET `ClanMembers` = ? WHERE `ClanID` = ?", toJSON(ClanMembers), self:getData("ClanID"))
	self:notify(getPlayerName(member).."#ffffff has joined the clan")
end

function CClan:removeMember(member, leader)
	if not self:isClanMember(member) then
		outputDebugString("CClan:removeMember: Invalid member argument, expected element or account id got: "..tostring(member).." ["..type(member).."]")
		return false
	end
	local ClanMembers = self:getData("ClanMembers")
	local memberName
	if isElement(member) then
		local account_id = getElementData(member, "account_id")
		if ClanMembers[tostring(account_id)] then
			memberName = getPlayerName(member)
			ClanMembers[tostring(account_id)] = nil
			if self:getData("ClanID") == getElementData(member, "Clan") then
				setPlayerStats(member, "Clan", 0)
				self:destructor_member(member)
			end
		end
	else
		if ClanMembers[tostring(member)] then
			memberName = ClanMembers[tostring(member)]
			ClanMembers[tostring(member)] = nil
			dbExec(g_Connection, "UPDATE vmtasa_accounts SET `Clan` = 0 WHERE `Clan` = ? AND `account_id` = ?", self:getData("ClanID"), tonumber(member))
		end
	end
	if not isElement(leader) then
		self:notify(memberName.."#ffffff has left the clan")
	else
		self:notify(getPlayerName(leader).."#ffffff has kicked "..memberName.."#ffffff from the clan")
	end
	dbExec(g_Connection, "UPDATE v_clans SET `ClanMembers` = ? WHERE `ClanID` = ?", toJSON(ClanMembers), self:getData("ClanID"))
	if self:isClanLeader(member) then
		self:removeLeader(member)
	end
end

function CClan:addLeader(member)
	if self:isClanLeader(member) then
		return false
	end
	local ClanLeaders = self:getData("ClanLeaders")
	local account_id, account_username
	if isElement(member) then
		account_id = getElementData(member, "account_id")
		account_username = getElementData(member, "username")
		ClanLeaders[tostring(account_id)] = account_username
	else
		account_id = tostring(member)
		account_username = self:getData("ClanMembers")[account_id]
		ClanLeaders[account_id] = account_username
	end
	dbExec(g_Connection, "UPDATE v_clans SET `ClanLeaders` = ? WHERE `ClanID` = ?", toJSON(ClanLeaders), self:getData("ClanID"))
	self:notify((isElement(member) and getPlayerName(member) or account_username).."#ffffff is now leading the clan")
end

function CClan:removeLeader(member) --[[ TO DO: Check if any other leaders exist/not removing himself etc. ]]--
	if not self:isClanLeader(member) then
		return false
	end
	local ClanLeaders = self:getData("ClanLeaders")
	local memberName, account_id
	if isElement(member) then
		account_id = getElementData(member, "account_id")
		if ClanLeaders[tostring(account_id)] then
			memberName = getPlayerName(member)
			ClanLeaders[tostring(account_id)] = nil
		end
	else
		if ClanLeaders[tostring(member)] then
			account_id = tostring(member)
			memberName = ClanLeaders[account_id]
			ClanLeaders[tostring(account_id)] = nil
		end
	end
	dbExec(g_Connection, "UPDATE v_clans SET `ClanLeaders` = ? WHERE `ClanID` = ?", toJSON(ClanLeaders), self:getData("ClanID"))
	self:notify(memberName.."#ffffff is no longer leading the clan")
	--[[ Destroy clan if no other members/leaders left, Making the new leader if there are no leaders left ]]--
	local leader_account_id, leader_account_username
	if self:isFounder(member) then
		for _account_id, _account_username in pairs((self:getClanLeadersCount() == 0 and self:getData("ClanMembers") or self:getData("ClanLeaders"))) do
			if _account_id ~= account_id then
				leader_account_id = _account_id
				leader_account_username = _account_username
				break
			end
		end
	else
		return true
	end
	if not leader_account_id then --[[ If no other member to promote to leader, remove the clan ]]--
		self:destroy(member)
	else
		self:addLeader(leader_account_id) --[[ If there is a new leader to be made, promote ]]--
		if self:isFounder(member) then
			self:setNewFounder(leader_account_id, leader_account_username)
		end
	end
end

function CClan:setRole(member, role)
	if self:getRole(member):lower() == role then
		outputDebugString("Clans: Trying to set same role")
		return false
	end
	if role == "leader" and not self:isClanLeader(member) then
		self:addLeader(member)
		return true
	elseif role == "member" and self:isClanLeader(member) then
		self:removeLeader(member)
		return true
	end
	return false
end

--[[ Clanwars ]]--
function CClan:createClanwarRequest(settings)
	dbExec(g_Connection, "INSERT INTO v_clanwars (requester_clanid, challenged_clanid, settings) VALUES (?, ?, ?)",
	self:getData("ClanID"), settings.clan, toJSON(settings))
	self:setData("clanwar_requests", requests)
	self:notify("Clanwar request sent!")
	--
	Clans[settings.clan]:notify("Received a clanwar request!")
end

--[[ Metamethods ]]--
function CClan:setData(key, value, save)
	local column_index = key
	local column_value = value
	if self[key] ~= nil then
		self[key] = value
	else
		self["data"][key] = value
		column_index = "data"
		column_value = toJSON(self["data"])
	end
	if save then
		dbExec(g_Connection, "UPDATE v_clans SET `??` = ? WHERE `ClanID` = ?", column_index, column_value, self:getData("ClanID"))
	end
end

function CClan:getData(key)
	return self[key] or nil
end

function CClan:isFounder(leader)
	local account_id = isElement(leader) and tostring(getElementData(leader, "account_id")) or tostring(leader)
	return self:getData("data")["Founder"][tostring(account_id)] and true or false
end

function CClan:setNewFounder(account_id, account_username)
	if not self:isClanLeader(account_id) then
		return outputDebugString("Clans: Trying to set a non-leader member as founder")
	end
	local data = self:getData("data")
	data["Founder"] = {}
	data["Founder"][tostring(account_id)] = account_username
	dbExec(g_Connection, "UPDATE v_clans SET `data` = ? WHERE `ClanID` = ?", toJSON(data), self:getData("ClanID"))
	triggerClientEvent(root, "Clans:onPlayerReceiveClanUpdate", resourceRoot, Clans[self:getData("ClanID")])
	self:notify(account_username.."#ffffff is the new founder of the clan")
end

function CClan:isClanMember(member)
	local ClanMembers = self:getData("ClanMembers")
	if isElement(member) then
		local account_id = tostring(getElementData(member, "account_id"))
		return ClanMembers[tostring(account_id)] and true or false
	else
		return ClanMembers[tostring(member)] and true or false
	end
end

function CClan:isClanLeader(member)
	local ClanLeaders = self:getData("ClanLeaders")
	if isElement(member) then
		local account_id = tostring(getElementData(member, "account_id"))
		return ClanLeaders[tostring(account_id)] and true or false
	else
		return ClanLeaders[tostring(member)] and true or false
	end
end

function CClan:getClanMembersCount()
	local ClanMembers = self:getData("ClanMembers")
	local i = 0
	for a_i, a_u in pairs(ClanMembers) do
		i = i+1
	end
	return i
end

function CClan:getClanLeadersCount()
	local ClanLeaders = self:getData("ClanLeaders")
	local i = 0
	for a_i, a_u in pairs(ClanLeaders) do
		i = i+1
	end
	return i
end

function CClan:getRole(player)
	if self:isFounder(player) then
		return "Founder"
	elseif self:isClanLeader(player) then
		return "Leader"
	elseif self:isClanMember(player) then
		return "Member"
	else
		return false
	end
end

function CClan:notify(message)
	for account_id, account_username in pairs(self:getData("ClanMembers")) do
		local player = exports.v_login:getPlayerFromUsername(account_username)
		if isElement(player) then
			triggerClientEvent(player, "notification:create", player, "Clan", message)
		end
	end
end