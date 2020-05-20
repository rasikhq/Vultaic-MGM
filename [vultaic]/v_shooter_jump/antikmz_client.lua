local antiKMZ = {}
local KMZ = {}
addEvent("onClientJoinArena", true)
addEvent("onClientLeaveArena", true)

function antiKMZ.setEnabled(state)
	antiKMZ.enabled = state and true or false
	KMZ = {}
	removeEventHandler("onClientProjectileCreation", root, antiKMZ.handleProjectileCreation)
	removeEventHandler("onClientVehicleDamage", root, antiKMZ.handleDamage)
	if antiKMZ.enabled then
		addEventHandler("onClientProjectileCreation", root, antiKMZ.handleProjectileCreation)
		addEventHandler("onClientVehicleDamage", root, antiKMZ.handleDamage)
		outputChatBox("[Anti-KMZ] #FFFFFFAnti-KMZ has been turned on", 255, 0, 0, true)
	end
end

addEventHandler("onClientJoinArena", resourceRoot,
function(data)
	antiKMZ.setEnabled(true)
end)

addEventHandler("onClientLeaveArena", resourceRoot,
function()
	antiKMZ.setEnabled(false)
end)

function antiKMZ.handleProjectileCreation(creator)
	if getElementType(creator) == "vehicle" then
		local occupant = getVehicleOccupant(creator)
		if isElement(occupant) then
			local x, y, z = getElementPosition(localPlayer)
			local x2, y2, z2 = getElementPosition(occupant)
			local distance = getDistanceBetweenPoints3D(x, y, z, x2, y2, z2)
			if distance < 10 then
				KMZ[occupant] = true
				KMZ[localPlayer] = true
				if occupant ~= localPlayer then
					setElementPosition(source, 0, 0, 0)
					destroyElement(source)
				end
			end
		end
	end
end

function antiKMZ.handleDamage(attacker, weapon, loss, x, y, z, tire)
	if (source == localPlayer or source == arena.vehicle) and isElement(attacker) and KMZ[attacker]	then
		cancelEvent()
		KMZ[attacker] = nil
		return
	end
end