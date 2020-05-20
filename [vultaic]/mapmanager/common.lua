function filePut(path, content)
	if type(path) == "string" and type(content) == "string" then
		if fileExists(path) then
			fileDelete(path)
		end
		local file = fileCreate(path)
		if file then
			fileWrite(file, content)
			fileClose(file)
		end
	end
end

function hexToRGB(hex)
	if hex then
		hex = hex:gsub("#", "")
		return tonumber("0x"..hex:sub(1, 2)), tonumber("0x"..hex:sub(3, 4)), tonumber("0x"..hex:sub(5, 6)), tonumber("0x"..hex:sub(7, 8))
	end
	return 255, 255, 255, 255
end

-- Modulo with more useful sign handling
function rem(a, b)
	local result = a - b * math.floor(a/b)
	if result >= b then
		result = result - b
	end
	return result
end

-- Vector3D
Vector3D = {
	new = function(self, _x, _y, _z)
		local newVector = {x = _x or 0.0, y = _y or 0.0, z = _z or 0.0}
		return setmetatable(newVector, {__index = Vector3D})
	end,
	Copy = function(self)
		return Vector3D:new(self.x, self.y, self.z)
	end,
	Normalize = function(self)
		local mod = self:Length()
		self.x = self.x/mod
		self.y = self.y/mod
		self.z = self.z/mod
	end,
	Dot = function(self, V)
		return self.x * V.x + self.y * V.y + self.z * V.z
	end,
	Length = function(self)
		return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
	end,
	AddV = function(self, V)
		return Vector3D:new(self.x + V.x, self.y + V.y, self.z + V.z)
	end,
	SubV = function(self, V)
		return Vector3D:new(self.x - V.x, self.y - V.y, self.z - V.z)
	end,
	CrossV = function(self, V)
		return Vector3D:new(self.y * V.z - self.z * V.y,
							self.z * V.x - self.x * V.z,
							self.x * V.y - self.y * V.z)
	end,
	Mul = function(self, n)
		return Vector3D:new(self.x * n, self.y * n, self.z * n)
	end,
	Div = function(self, n)
		return Vector3D:new(self.x/n, self.y/n, self.z/n)
	end,
}

_getCameraTarget = getCameraTarget
function getCameraTarget()
	local target = _getCameraTarget()
	if isElement(target) and getElementType(target) == "vehicle" then
		target = getVehicleOccupant(target)
	end
	return target
end