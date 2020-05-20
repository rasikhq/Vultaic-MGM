--[[
	Vultaic::Addon::Maptest
--]]
local settings = {
	allow_deletes = {
		race = true,
	},
}
function onMapAccepted(mapName)
	if getPlayerCount() < 100 then
		outputChatBox("#19846dMap Testing :: #ffffffThe map #19846d"..mapName.."#ffffff has been #00ff00accepted#ffffff!", root, 255, 255, 255, true)
		exports.core:refreshMaps()
	end
end