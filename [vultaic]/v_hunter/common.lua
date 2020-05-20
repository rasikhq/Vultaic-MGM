Countdown = {}
Countdown.__index = Countdown
Countdown.instances = {}

function Countdown:create(autoDestroy)
	local id = #Countdown.instances + 1
	Countdown.instances[id] = setmetatable(
		{
			id = id,
			timer = nil,
			autoDestroy = autoDestroy,
		},
		self
	)
	return Countdown.instances[id]
end

function Countdown:destroy()
	self:stop()
	Countdown.instances[self.id] = nil
	self.id = 0
end

function Countdown:isActive()
	return self.timer ~= nil
end

function Countdown:stop()
	if self.timer then
		killTimer(self.timer)
		self.timer = nil
	end
end

function Countdown:start(handledFunction, timesToExecute)
	self:stop()
	self.handledFunction = handledFunction
	self.count = timesToExecute
	self.doDestroy = false
	self.timer = setTimer(function() self:handleFunctionCall() end, 1000, timesToExecute)
end

function Countdown:handleFunctionCall()
	if self.count > 0 then
		self.count = self.count - 1
		if self.count == 0 then
			self.timer = nil
			self.doDestroy = self.autoDestroy
		end
	end
	self.handledFunction(self.count)
	if self.doDestroy then
		self:destroy()
	end
end

Timer = {}
Timer.__index = Timer
Timer.instances = {}

function Timer:create(autoDestroy)
	local id = #Timer.instances + 1
	Timer.instances[id] = setmetatable(
		{
			id = id,
			timer = nil,
			autoDestroy = autoDestroy,
		},
		self
	)
	return Timer.instances[id]
end

function Timer:destroy()
	self:killTimer()
	Timer.instances[self.id] = nil
	self.id = 0
end

function Timer:isActive()
	return self.timer ~= nil
end

function Timer:getDetails()
	if self.timer then
		return getTimerDetails(self.timer)
	end
	return nil
end

function Timer:killTimer()
	if self.timer then
		killTimer(self.timer)
		self.timer = nil
	end
end

function Timer:setTimer(handledFunction, timeInverval, timesToExecute, ...)
	self:killTimer()
	self.handledFunction = handledFunction
	self.count = timesToExecute
	self.doDestroy = false
	self.arguments = {...}
	if type(timeInverval) ~="number" or timeInverval < 50 then
		timeInverval = 50
	end
	self.timer = setTimer(function() self:handleFunctionCall() end, timeInverval, timesToExecute)
end

function Timer:handleFunctionCall()
	if self.count > 0 then
		self.count = self.count - 1
		if self.count == 0 then
			self.timer = nil
			self.doDestroy = self.autoDestroy
		end
	end
	self.handledFunction(unpack(self.arguments))
	if self.doDestroy then
		self:destroy()
	end
end

function tableFind(_table, value)
	for i, item in pairs(_table) do
		if item == value then
			return i
		end
	end
	return false
end

function tableInsert(_table, value)
	local id = tableFind(_table, value)
	if id then
		return
	end
	if type(_table) == "table" and value then
		table.insert(_table, value)
	end
end

function tableRemove(_table, value)
	if type(_table) == "table" and value then
		local id = tableFind(_table, value)
		if id then
			table.remove(_table, id)
		end
	end
end

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
	local minutes = tostring(math.floor(s/60))
	return minutes..":"..seconds..":"..centiseconds	
end

_fixVehicle = fixVehicle
function fixVehicle(vehicle)
	_fixVehicle(vehicle)
	for i = 0, 5 do
		setVehicleDoorOpenRatio(vehicle, i, 0, 0)
	end
end