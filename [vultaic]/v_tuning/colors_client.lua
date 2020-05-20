local projectileMarkers = {}

addEventHandler("onClientResourceStart", resourceRoot,
function()
	enableRocketLines = not (exports.v_settings:getClientVariable("enable_rocketlines") == "Off")
end)

addEvent("settings:onSettingChange", true)
addEventHandler("settings:onSettingChange", localPlayer,
function(variable, value)
	if variable == "enable_rocketlines" then
		enableRocketLines = value == "On"
	end
end)

addEventHandler("onClientProjectileCreation", root,
function(creator)
	if getElementType(creator) == "vehicle" then
		local occupant = getVehicleOccupant(creator)
		if occupant then
			local rocketColor = getElementData(occupant, "rocketcolor")
			if rocketColor then
				local x, y, z = getElementPosition(source)
				local r, g, b, a = hexToRGB(rocketColor.color or "#FFFFFFFF")
				if a and a > 0 then
					local marker = createMarker(x, y, z, "corona", 2, r, g, b, a)
					if marker then
						setElementDimension(marker, getElementDimension(localPlayer))
						table.insert(projectileMarkers, {source, marker, creator})
						if #projectileMarkers == 1 then
							addEventHandler("onClientPreRender", root, renderRockets)
						end
					end
				end
			end
		end
	end
end)

function renderRockets()
	if #projectileMarkers == 0 then
		return removeEventHandler("onClientPreRender", root, renderRockets)
	end
	for i, v in pairs(projectileMarkers) do
		if isElement(v[1]) and isElement(v[2]) then
			local projX, projY, projZ = getElementPosition(v[1])
			setElementPosition(v[2], projX, projY, projZ)
			if enableRocketLines and isElement(v[3]) then
				local vehX, vehY, vehZ = getElementPosition(v[3])
				local r, g, b, a = getMarkerColor(v[2])
				dxDrawLine3D(vehX, vehY, vehZ, projX, projY, projZ, tocolor(r, g, b, a), 1)
			end
		else
			if isElement(v[2]) then
				destroyElement(v[2])
			end
			table.remove(projectileMarkers, i)
			break
		end
	end
end