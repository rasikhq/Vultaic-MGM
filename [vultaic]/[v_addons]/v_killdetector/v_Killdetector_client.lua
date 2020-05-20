--[[
	Vultaic::Addon::Killdetector
--]]
local _DEBUG = true
local function Debug(str)
	if not _DEBUG then return end
	outputDebugString("[Kill detector] "..tostring(str), 0, 255, 255, 0)
end
local projectileOnly = {
	["shooter"] = true,
	["shooterjump"] = true,
	["hunter"] = true
}
local killer = false
local timer_ResetCollider = nil
addEventHandler("onClientPlayerWasted", localPlayer, function(_killer, weapon, bodypart)
	_killer = isElement(_killer) and _killer or killer
	if(isElement(_killer) and getElementType(_killer) == "vehicle") then
		_killer = getVehicleOccupant(_killer)
	end
	if(_killer and isElement(_killer) and getElementType(_killer) == "player") then
		triggerServerEvent("onPlayerKill", resourceRoot, _killer)
		triggerEvent("onClientPlayerKill", resourceRoot, _killer, localPlayer, weapon, bodypart)
		killer = false;
		if isTimer(timer_ResetCollider) then
			killTimer(timer_ResetCollider)
		end
	end
end)
addEventHandler("onClientVehicleEnter", root, function(player, seat)
	if(player == localPlayer and killer) then
		killer = false;
	end
end)
addEventHandler("onClientVehicleDamage", root, function(attacker, weaponID, loss)
	if(attacker and isElement(attacker) and getElementType(attacker) == "vehicle") then
		attacker = getVehicleOccupant(attacker)
	end
	if(not isElement(attacker)) then 
		return
	elseif(getElementType(attacker) ~= "player") then 
		return
	end
	Debug("Attacker: "..getPlayerName(attacker).." || Loss: "..loss)
	local vehicle = getPedOccupiedVehicle(localPlayer)
	if(source == vehicle and attacker ~= localPlayer) then
		if weaponID == 51 then
			killer = attacker
			return true
		end
		if projectileOnly[getElementData(localPlayer, "arena")] and weaponID ~= 51 then
			return
		end
		local health = (getElementHealth(vehicle) - loss)
		if(not killer and health <= 249) then
			killer = attacker;
		elseif(not killer) then
			killer = attacker
			if isTimer(timer_ResetCollider) then
				killTimer(timer_ResetCollider)
			end
			timer_ResetCollider = setTimer(function()
				killer = false
			end, 1000*10, 1)
		end
	end
end)