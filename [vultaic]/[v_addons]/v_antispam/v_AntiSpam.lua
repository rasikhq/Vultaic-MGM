--[[
	Vultaic::Addon::AntiSpam
--]]
local commandSpam = {}
local gameplayCommands = {
	Previous = true,
	Next = true
}
function preventCommandSpam(cmd)
	if gameplayCommands[cmd] then
		return
	end
	if(not commandSpam[source]) then
		commandSpam[source] = {warn = 1, tick = getTickCount()}
	end
	local lastTick = commandSpam[source].tick
	local warns = commandSpam[source].warn
	local now = getTickCount()
	if(now - lastTick < 1000) then
		commandSpam[source].warn = warns+1
	else
		commandSpam[source].tick = now
		commandSpam[source].warn = 1
	end
	if commandSpam[source].warn > 3 then
		commandSpam[source].tick = now
		cancelEvent()
		outputChatBox("ERROR :: #ffffffPlease refrain from spamming!", source, 255, 0, 0, true)
	end
end
addEventHandler("onPlayerCommand", root, preventCommandSpam)