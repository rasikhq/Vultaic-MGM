addEvent("settings:syncPlayerSettings", true)
addEventHandler("settings:syncPlayerSettings", root,
function(data)
	if type(data) == "table" then
		for i, v in pairs(data) do
			setElementData(source, i, v, false)
		end
	end
end)