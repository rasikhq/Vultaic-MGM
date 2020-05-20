local models = {1025, 1073, 1074, 1075, 1076, 1077, 1078, 1079, 1080, 1081, 1082, 1083, 1084, 1085, 1096, 1097, 1098}
addEvent("custom:onClientVehicleStreamIn", true)
addEvent("custom:onClientPlayerVehicleEnter", true)
addEvent("custom:onClientVehicleModelChange", true)

addEventHandler("onClientResourceStart", resourceRoot,
function()
	local k, dffs = 1, {}
	local metaFile = xmlLoadFile("meta.xml")
	if metaFile then
		for i, node in pairs (xmlNodeGetChildren(metaFile)) do
			local info = xmlNodeGetAttributes(node)
			if xmlNodeGetName(node) == "file" and info["wheel"] then
				dffs[k] = fileExists(info["src"]) and engineLoadDFF(info["src"]) or nil
				k = k + 1
			end
		end
		xmlUnloadFile(metaFile)
	end
	engineImportTXD(engineLoadTXD("model/wheels.txd"), 1082)
	for i = 1, #models do
		local dff = dffs[i]
		if dff then
			engineReplaceModel(dff, models[i])
		end
	end
end)

function getWheels()
	return models
end