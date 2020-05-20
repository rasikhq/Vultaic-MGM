function msToTimeString(ms)
	if not ms then
		return ""
	end
	local centiseconds = tostring(math.floor(math.fmod(ms, 1000)/10))
	if #centiseconds == 1 then
		centiseconds = "0"..centiseconds
	end
	local s = math.floor(ms/1000)
	local seconds = tostring(math.fmod(s, 60))
	if #seconds == 1 then
		seconds = "0"..seconds
	end
	local minutes = math.floor(s/60)
	return tostring((minutes < 10 and "0"..minutes or minutes))..":"..seconds..":"..centiseconds	
end