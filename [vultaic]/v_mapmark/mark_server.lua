local settings = {
	allow_marks = {
		dm = true,
		os = true,
		hdm = true
	},
	
	delete_disabled = {
		tdm = true,
		garage = true,
	}
}

local COMMAND_PERMISSION = exports.v_admin:getCommandLevels()

local function dbg(t)
	print(tostring(t) .. " ["..type(t).."]")
end

function mark(player, command, prefix)
	local pArena = getElementParent(player)
	if isElement(pArena) and settings.allow_marks[getElementData(pArena, "id")] then
		local player_level = getElementData(player, "admin_level") or 1
		local has_tag = exports.v_admin:getPlayerTag(player, "mapmanager")
		if player_level < COMMAND_PERMISSION[command] and not has_tag then
			outputChatBox("Access denied.", player, 255, 255, 255, true)
			return
		end
		local resource_name = getElementData(pArena, "mapResourceName")
		if not resource_name then
			outputChatBox("There is no map loaded for you to mark.", player, 255, 255, 255, true)
			return
		end
		if not prefix then
			return outputChatBox("Invalid syntax! /mark [Prefix - dm/os/hdm]", player, 255, 255, 255, true)
		end
		prefix = string.lower(tostring(prefix))
		if not settings.allow_marks[prefix] then
			return outputChatBox("Invalid prefix.", player, 255, 255, 255, true)
		end
		local resource = getResourceFromName(resource_name)
		if not resource then
			return outputChatBox("Failed to locate resource from arena element", player, 255, 255, 255, true)
		end
		local map_name = getResourceInfo(resource, "name")
		local current_prefix = string.sub(map_name, 1, string.find(map_name, "]"))
		if not current_prefix then
			return outputChatBox("Could not detect a prefix in map name.", player, 255, 255, 255, true)
		end
		if current_prefix:lower() == ("["..prefix.."]") then
			return outputChatBox("The is already marked as "..current_prefix, player, 255, 255, 255, true)
		end
		--
		local current_prefix_unlabeled = string.sub(current_prefix, 2, string.find(map_name, "]")-1)
		local new_prefix = prefix:upper()
		local new_prefix_labeled = "["..new_prefix.."]"
		--
		local new_map_name = string.gsub(map_name, "%[DM%]", "")
		new_map_name = string.gsub(new_map_name, "%[OS%]", "")
		new_map_name = string.gsub(new_map_name, "%[HDM%]", "")
		--
		local new_resource_name = string.gsub(resource_name, "%[DM%]", "")
		new_resource_name = string.gsub(new_resource_name, "%[OS%]", "")
		new_resource_name = string.gsub(new_resource_name, "%[HDM%]", "")
		--
		new_map_name = new_prefix_labeled..new_map_name
		new_resource_name = new_prefix_labeled..new_resource_name
		dbg(new_map_name)
		dbg(new_resource_name)
		setResourceInfo(resource, "name", new_map_name)
		--if renameResource(resource, new_resource_name, "[maps]/["..(prefix:upper()).."]") then
		if renameResource(resource, new_resource_name, getResourceOrganizationalPath(resource)) then
			outputChatBox("#19846d[Info] #ffffffCurrent map has been marked #19846d"..new_prefix_labeled.." #ffffffby #19846d"..getPlayerName(player), pArena, 255, 255, 255, true)
			exports.core:refreshMaps(getElementData(pArena, "id"))
			exports.core:refreshMaps((getElementByID(prefix) or prefix))
			exports.core:refreshMaps(getElementByID("dm training"))
		end
	end
end
addCommandHandler("mark", mark)

function delete_map(player, command, ...)
	local pArena = getElementParent(player)
	if isElement(pArena) and settings.delete_disabled[getElementData(pArena, "id")] == nil then
		local player_level = getElementData(player, "admin_level") or 1
		local has_tag = exports.v_admin:getPlayerTag(player, "mapmanager")
		if player_level < COMMAND_PERMISSION[command] and not has_tag then
			outputChatBox("Access denied.", player, 255, 255, 255, true)
			return
		end
		local currentMap = getElementData(pArena, "mapResourceName")
		if not currentMap then
			outputChatBox("There is no map to be deleted.", player, 255, 255, 255, true)
			return
		end
		local resource = getResourceFromName(currentMap)
		if not resource then
			return outputChatBox("Failed to locate resource from arena element", player, 255, 255, 255, true)
		end
		local reason = table.concat({...}, " ") or ""
		if reason ~= "" then reason = " ("..reason..")" end
		if deleteResource(getResourceName(resource)) then
			executeCommandHandler("random", player)
			executeCommandHandler("refreshmaps", player)
			outputChatBox("#19846d[Info] #ffffffCurrent map has been deleted #ffffffby #19846d"..getPlayerName(player)..reason, pArena, 255, 255, 255, true)
		else
			return outputChatBox("Failed to delete map", player, 255, 255, 255, true)
		end
	end
end
addCommandHandler("deletemap", delete_map)