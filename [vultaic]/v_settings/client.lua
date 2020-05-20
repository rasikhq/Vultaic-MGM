local variableClass = {}
local defaultClass = "misc"

-- Save all
function saveAll()
	for class, data in pairs(variableClass) do
		local path = "settings_"..class
		if fileExists(path) then
			fileDelete(path)
		end
		local file = fileCreate(path)
		if file then
			fileWrite(file, toJSON(data))
			fileClose(file)
		end
	end
	--print("Saved all client variables")
end
addEventHandler("onClientResourceStop", resourceRoot, saveAll)

-- Set variable
function setClientVariable(variable, value, class)
	if variable and value then
		variable = tostring(variable)
		value = tostring(value)
		class = tostring(class or defaultClass)
		if not variableClass[class] then
			loadVariableClass(class)
		end
		variableClass[class][variable] = value
		local data = {}
		data[variable] = value
		local path = "settings_"..class
		if fileExists(path) then
			fileDelete(path)
		end
		local file = fileCreate(path)
		if file then
			fileWrite(file, toJSON(data))
			fileClose(file)
		end
		triggerEvent("settings:onSettingChange", localPlayer, variable, value, class)
		triggerServerEvent("settings:syncPlayerSettings", localPlayer, data)
		--print("Updated client variable '"..variable.."' as '"..value.."' from '"..class.."' class")
	end
end

-- Get variable
function getClientVariable(variable, class)
	if variable then
		variable = tostring(variable)
		class = tostring(class or defaultClass)
		if not variableClass[class] then
			loadVariableClass(class)
		end
		return variableClass[class][variable] or nil
	end
end

function loadVariableClass(class)
	if class then
		local path = "settings_"..class
		if fileExists(path) then
			local file = fileOpen(path)
			if file then
				local content = fileRead(file, fileGetSize(file))
				if content then
					content = fromJSON(content)
					variableClass[class] = type(content) == "table" and content or {}
					local data = {}
					for i, v in pairs(content) do
						data[i] = v
					end
					triggerServerEvent("settings:syncPlayerSettings", localPlayer, data)
				end
				fileClose(file)
			else
				variableClass[class] = {}
			end
		else
			variableClass[class] = {}
		end
		--print("Loaded client variable class '"..class.."' into memory")
	end
end