function table.copy(tab, recursive)
    local ret = {}
    for key, value in pairs(tab) do
        if (type(value) == "table") and recursive then
        	ret[key] = table.copy(value)
        else
        	ret[key] = value
        end
    end
    return ret
end

function hexToRGB(hex)
	hex = (hex or "#FFFFFFFF"):gsub("#", "")
	return tonumber("0x"..hex:sub(1, 2) or 255), tonumber("0x"..hex:sub(3, 4) or 255), tonumber("0x"..hex:sub(5, 6) or 255), tonumber("0x"..hex:sub(7, 8) or 255)
end

function rgbToHex(r, g, b, a)
	return string.format("#%.2X%.2X%.2X%.2X", r or 255, g or 255, b or 255, a or 255)
end

_setVehicleColor = setVehicleColor
function setVehicleColor(vehicle, r1, g1, b1, r2, g2, b2, r3, g3, b3, r4, g4, b4)
	if isElement(vehicle) then
		local _r1, _g1, _b1, _r2, _g2, _b2, _r3, _g3, _b3, _r4, _g4, _b4 = getVehicleColor(vehicle, true)
		_r1, _g1, _b1 = tonumber(r1) or _r1, tonumber(g1) or _g1, tonumber(b1) or _b1
		_r2, _g2, _b2 = tonumber(r2) or _r2, tonumber(g2) or _g2, tonumber(b2) or _b2
		_r3, _g3, _b3 = tonumber(r3) or _r3, tonumber(g3) or _g3, tonumber(b3) or _b3
		_r4, _g4, _b4 = tonumber(r4) or _r4, tonumber(g4) or _g4, tonumber(b4) or _b4
		return _setVehicleColor(vehicle, _r1, _g1, _b1, _r2, _g2, _b2, _r3, _g3, _b3, _r4, _g4, _b4)
	end
end

function findRotation(x1, y1, x2, y2) 
    local t = -math.deg(math.atan2(x2 - x1, y2 - y1))
    return t < 0 and t + 360 or t
end

function findRotation3D(x1, y1, z1, x2, y2, z2) 
	local rotx = math.atan2 (z2 - z1, getDistanceBetweenPoints2D (x2, y2, x1,y1))
	rotx = math.deg(rotx)
	local rotz = -math.deg(math.atan2(x2 - x1, y2 - y1))
	rotz = rotz < 0 and rotz + 360 or rotz
	return rotx, 0,rotz
end

function math.round(number, decimals, method)
    decimals = decimals or 0
    local factor = 10 ^ decimals
    if (method == "ceil" or method == "floor") then return math[method](number * factor) / factor
    else return tonumber(("%."..decimals.."f"):format(number)) end
end