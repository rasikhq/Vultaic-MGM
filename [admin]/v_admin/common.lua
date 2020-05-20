local function replace(str, find, repl, whole)
	if whole then
		find = '%f[%a]'..find..'%f[%A]'
	end
	return (str:gsub(find,repl))
end

local function format_colors(str)
	str = replace(str, "c_w", "#ffffff")
	str = replace(str, "c_r", "#ff0000")
	str = replace(str, "c_g", "#00ff00")
	str = replace(str, "c_b", "#0000ff")
	str = replace(str, "c_y", "#ff0000")
	return str
end

function vmsg(msg, send_to)
	if not isElement(send_to or root) then
		return
	end
	msg = format_colors(msg)
	outputChatBox("* "..msg, send_to, 255, 255, 255, true)
end

function rgb2hex(r,g,b)
	
	local hex_table = {[10] = 'A',[11] = 'B',[12] = 'C',[13] = 'D',[14] = 'E',[15] = 'F'}
	
	local r1 = math.floor(r / 16)
	local r2 = r - (16 * r1)
	local g1 = math.floor(g / 16)
	local g2 = g - (16 * g1)
	local b1 = math.floor(b / 16)
	local b2 = b - (16 * b1)
	
	if r1 > 9 then r1 = hex_table[r1] end
	if r2 > 9 then r2 = hex_table[r2] end
	if g1 > 9 then g1 = hex_table[g1] end
	if g2 > 9 then g2 = hex_table[g2] end
	if b1 > 9 then b1 = hex_table[b1] end
	if b2 > 9 then b2 = hex_table[b2] end
	
	return "#" .. r1 .. r2 .. g1 .. g2 .. b1 .. b2

end

function outputChatBoxEx(msg, send_to, r, g, b, cc)
	msg = format_colors(msg)
	return outputChatBox(msg, send_to, r or 255, g or 255, b or 255, cc or true)
end

function getDuration(duration, form)
	if not tonumber(duration) then
		return false
	end
	duration = tonumber(duration)
	local seconds = 0
	if form == "s" then
		seconds = duration
	elseif form == "m" then
		seconds = math.floor(duration*60)
	elseif form == "h" then
		seconds = math.floor(duration*60*60)
	elseif form == "d" then
		seconds = math.floor(duration*60*60*24)
	end
	return seconds
end

function secondsToTimeDesc(seconds)
	if seconds then
		local tab = {{"day",60*60*24}, {"hour",60*60}, {"min",60}, {"sec",1}}
		for i,item in ipairs(tab) do
			local t = math.floor(seconds/item[2])
			if t > 0 or i == #tab then
				return tostring(t) .. " " .. item[1] .. (t~=1 and "s" or "")
			end
		end
	end
	return ""
end

function tableFind(tbl, value)
	for i = 1, #tbl do
		if(tbl[i] == value) then
			return i
		end
	end
	return nil
end