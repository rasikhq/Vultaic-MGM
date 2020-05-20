--[[
	Vultaic::Addon::DecoHider
--]]
local fileName = "objects.xml"
local fileRoot = "objects"
local ObjectsList = {}
ObjectsList.List = {}

function ObjectsList.add(model)
	model = tonumber(model)
	if not model then return end
	ObjectsList.List[model] = model
end

function ObjectsList.del(model)
	model = tonumber(model)
	if not model then return end
	ObjectsList.List[model] = nil
end

function ObjectsList.sendToClient(element)
	if not element then
		return
	end
	triggerClientEvent(element, "onClientReceiveObjectsList", resourceRoot, ObjectsList.List)
end

addEvent("onClientRequestObjectList", true)
addEventHandler("onClientRequestObjectList", resourceRoot, function()
	ObjectsList.sendToClient(client)
end)

addEventHandler("onResourceStart", resourceRoot,
function()
	local _xml = XML.load(fileName)
	if(not _xml) then
		_xml = XML(fileName, fileRoot)
		if not _xml  then
			return
		end
	end
	local _xmlChildren = _xml:getChildren()
	for _, node in pairs(_xmlChildren) do
		local objectModel = node:getValue()
		ObjectsList.add(objectModel)
	end
	_xml:saveFile()
	_xml:unload()
end)

addCommandHandler("addobject", 
function(source, _, objectModel)
	if not(hasObjectPermissionTo(source, "function.kickPlayer", false)) then
		return
	end
	local _xml = XML.load(fileName)
	if (not _xml) then
		return
	end
	local _xmlChildren = _xml:getChildren()
	local foundRecord = false
	for _, node in pairs(_xmlChildren) do
		if (node:getValue() == objectModel) then
			foundRecord = true
			break
		end
	end
	if foundRecord then
		return outputChatBox("#19846dDecoHider :: #ffffffRecord for object model #19846d"..objectModel.."#ffffff already exists", source, 255, 255, 255, true)
	end
	local _xmlChild = _xml:createChild(fileRoot)
	_xmlChild:setValue(objectModel)
	_xml:saveFile()
	_xml:unload()
	ObjectsList.add(objectModel)
	ObjectsList.sendToClient(root)
	outputChatBox("#19846dDecoHider :: #ffffffAdded object model #19846d"..objectModel.."#ffffff to the list", source, 255, 255, 255, true)
end)

addCommandHandler("delobject",
function(source, _, objectModel)
	if not (hasObjectPermissionTo(source, "function.kickPlayer", false)) then
		return
	end
	local _xml = XML.load(fileName)
	if (not _xml) then
		return
	end
	local _xmlChildren = _xml:getChildren()
	local foundRecord = false
	for _, node in pairs(_xmlChildren) do
		if (node:getValue() == objectModel) then
			node:destroy()
			foundRecord = true
			break
		end
	end
	_xml:saveFile()
	_xml:unload()
	if foundRecord then
		ObjectsList.del(objectModel)
		ObjectsList.sendToClient(root)
		outputChatBox("#19846dDecoHider :: #ffffffRemoved object model #19846d"..objectModel.."#ffffff to the list", source, 255, 255, 255, true)
	else
		outputChatBox("#19846dDecoHider :: #ffffffRecord for object model #19846d"..objectModel.."#ffffff does not exist", source, 255, 255, 255, true)
	end
end)