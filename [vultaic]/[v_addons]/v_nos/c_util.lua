local DEBUG = true
local rootElement = getRootElement()
local resName = getResourceName(getThisResource())

---- FPS 

FPSMax = 1
FPSAvg = 1
FPSCalc = 0
FPSTime = getTickCount() + 1000
AVGTbl = {}
val = 1

function CalcFps( )
	if (getTickCount() < FPSTime) then
		FPSCalc = FPSCalc + 1
	else
		if (FPSCalc > FPSMax) then
			FPSMax = FPSCalc
		end
		if val == 101 then val = 1 end
		AVGTbl[val] = FPSCalc
		FPSAvg = 0
		for k,v in pairs(AVGTbl) do
			FPSAvg = FPSAvg + v
		end
		FPSAvg = math.floor(FPSAvg / #AVGTbl)
		FPSCalc = 0
		FPSTime = getTickCount() + 1000
		val = val + 1
	end
end


function GetCurrentFps()
	return FPSCalc
end


function GetAverageFps()
	return FPSAvg
end


--
-- DEBUG
--
function alert(message, channel)
	if not DEBUG then return end

	message = resName..": "..tostring(message)

	if channel == "console" then
		outputConsole(message)
		return
	end
	
	if channel == "chat" then
		outputChatBox(message)
		return
	end
	
	outputDebugString(message)
end
