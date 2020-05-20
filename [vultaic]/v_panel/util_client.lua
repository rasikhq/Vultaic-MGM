function isClientInLobby()
	return getElementData(localPlayer, "arena") == nil or getElementData(localPlayer, "arena") == "lobby" and true or false
end

function getPlayerFromUsername(username)
	if username then
		for i, player in pairs(getElementsByType("player")) do
			local _username = getElementData(player, "LoggedIn") and getElementData(player, "username")
			if username and _username == username then
				return player
			end
		end
	end
end

function getPlayerRGB(player)
	if not isElement(player) then
		return
	end
	if getElementData(player, "member") then
		return 25, 132, 109
	elseif getElementData(player, "donator") then
		return 5, 255, 5
	end
	return 255, 255, 255
end

function dxDrawPlayerAvatar(player, x, y, size, alpha)
	if not isElement(player) then
		return
	end
	if not panel.maskShader then
		panel.maskShader = dxCreateShader("fx/mask.fx")
	end
	if not panel.maskTexture then
		panel.maskTexture = dxCreateTexture("img/circle.png")
		dxSetShaderValue(panel.maskShader, "maskTexture", panel.maskTexture)
	end
	local texture = exports.v_avatars:getAvatarTexture(player)
	dxSetShaderValue(panel.maskShader, "imageTexture", texture)
	return dxDrawImage(x, y, size, size, panel.maskShader, 0, 0, 0, tocolor(255, 255, 255, tonumber(alpha or 255)), false)
end

function string.split(str)
	if not str or type(str) ~= "string" then
		return false
	end
	return split(str, " ")
end

function getBoundingString(text, fontScale, font, width, height)
	local splitString = string.split(tostring(text))
	local text, textWidth, textData, fontHeight = "", 0, {}, dxGetFontHeight(fontScale, font)
	local maxWidth = 0
	local offset = 0
	for i = 1, #splitString do
		if text == "" then
			text = text..splitString[i]
		else
			text = text.." "..splitString[i]
		end
		textWidth = dxGetTextWidth(text:gsub("#%x%x%x%x%x%x", ""), fontScale, font)
		if textWidth > width then
			table.insert(textData, text)
			if textWidth > maxWidth then
				maxWidth = textWidth
			end
			text = ""
			textWidth = 0
			offset = offset + fontHeight
			if offset + fontHeight >= height then
				break
			end
		elseif i == #splitString then
			table.insert(textData, text)
			if textWidth > maxWidth then
				maxWidth = textWidth
			end
		end
	end
	if #textData == 0 then
		text = ""
		for i = 1, #splitString do
			if text == "" then
				text = text..splitString[i]
			else
				text = text.." "..splitString[i]
			end
		end
		maxWidth = dxGetTextWidth(text:gsub("#%x%x%x%x%x%x", ""), fontScale, font)
		table.insert(textData, text)
	end
	return textData
end

function getCleanString(str)
	local chars = {"%[", "%]", "%.", "%-", "%'", "%\"", "%(", "%)", "%!", "% ", "%,", "%?"}
	for i, char in pairs(chars) do
		str = str:gsub(char, '')
	end
	return str
end

function table.copy(tab, recursive)
    local ret = {}
    for key, value in pairs(tab) do
        if (type(value) == "table") and recursive then
        	ret[key] = table.copy(value)
        else
        	ret[key] = value
        end
    end
    return ret
end

function hexToRGB(hex) 
	hex = hex:gsub("#", "") 
	return tonumber("0x"..hex:sub(1, 2)), tonumber("0x"..hex:sub(3, 4)), tonumber("0x"..hex:sub(5, 6)) 
end

function rgbToHex(r, g, b)
	return string.format("#%.2X%.2X%.2X", r or 255, g or 255, b or 255)
end

_getPlayerName = getPlayerName
function getPlayerName(player)
	local name = _getPlayerName(player)
	local team = getPlayerTeam(player)
	if team then
		local r, g, b = getTeamColor(team)
		name = rgbToHex(r, g, b)..name
	end
	return name
end