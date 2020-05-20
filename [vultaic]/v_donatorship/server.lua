addEventHandler("onPlayerJoin", root,
function()
	setElementData(source, "donator", false)
end)

addEventHandler("onPlayerLogin", root,
function()
	checkDonatorShip(source)
end)

function checkDonatorShip(player)
	if isElement(player) then
		if not getElementData(player, "donator") then
			local donator = true--isPlayerDonator(player)
			if donator then
				setElementData(player, "donator", true)
			end
		end
	end
end

function onPlayerLogin(data)
	local donator = true--data.donator and true or false
	print(getPlayerName(source).." has logged in, DONATOR: "..tostring(donator))
	if donator then
		setElementData(source, "donator", true)
		outputChatBox("[Donator] #FFFFFFYour donator status is #00FF00active", source, 25, 132, 109, true)
	end
end
addEvent("login:onPlayerLogin", true)
addEventHandler("login:onPlayerLogin", root, onPlayerLogin)

function checkPlayerReward()
	--print("Checking reward for "..getPlayerName(source))
	local userdata = getElementData(source, "userdata") or {}
	local donated = tonumber(userdata.active_donation) or 0
	--print("Active donations for "..getPlayerName(source)..": "..donated)	
	if donated > 0 then
		local reward = donated * 25000
		exports.v_mysql:givePlayerStats(source, "money", reward)
		outputChatBox("[Donator] #FFFFFFYou have been rewarded with #19846D$"..reward.."#FFFFFF, thanks for your support!", source, 25, 132, 109, true)
		DLog.player(source, string.gsub(getPlayerName(source), "#%x%x%x%x%x%x", "").." has been awarded $"..reward.." for donating.")
	end
end
addEvent("mysql:onPlayerLogin", true)
addEventHandler("mysql:onPlayerLogin", root, checkPlayerReward)

function isPlayerDonator(player)
	if isElement(player) then
		if getElementData(player, "donator") then
			return true
		else
			local admin_level = getElementData(player, "admin_level") or 1
			if admin_level > 2 then
				return true
			else
				return false
			end
		end
		return false
	end
	return false
end

addCommandHandler("donator",
function(player, command, ...)
	local donator = isPlayerDonator(player)
	if donator then
		outputChatBox("You are a donator", player, 0, 255, 0)
	else
		outputChatBox("You are not a donator", player, 255, 0, 0)
	end
end)