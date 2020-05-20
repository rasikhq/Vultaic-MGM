DLog = {
	path = "[LOGS]/"
}

function DLog.getRealTime()
	local time = getRealTime()
	local hours = time.hour
	local minutes = time.minute
	local seconds = time.second

    local monthday = time.monthday
	local month = time.month
	local year = time.year

    local formattedTime = string.format("[%02d-%02d-%04d %02d:%02d:%02d]", monthday, month + 1, 1900 + year, hours, minutes, seconds)
	return formattedTime
end

function DLog.verifyFile(fileName)
	if not fileName:find(".txt") then
		fileName = fileName..".txt"
	end
	local file = fileExists(DLog.path..fileName)
	if not file then
		file = fileCreate(DLog.path..fileName)
	else
		file = fileOpen(DLog.path..fileName)
		fileSetPos(file, fileGetSize(file))
		fileWrite(file, "\n")
		fileFlush(file)
	end
	fileClose(file)
end

function DLog.writeFile(fileName, data)
	local file = fileOpen(DLog.path..fileName..".txt")
	fileSetPos(file, fileGetSize(file))
	fileWrite(file, data)
	fileFlush(file)
	fileClose(file)
end

function DLog.player(player, str)
	if not isElement(player) then
		return
	end
	local fileName = getPlayerSerial(player)
	str = tostring(str)
	--
	DLog.verifyFile(fileName)
	DLog.writeFile(fileName, DLog.getRealTime().." "..str)
end