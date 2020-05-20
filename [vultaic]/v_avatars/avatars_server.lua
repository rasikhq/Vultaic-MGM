local pageURL = "https://forum.vultaic.com/uploads/"

function syncAvatar(data)
	if type(data) ~= "table" then
		return
	end
	local avatar = data.avatar
	if avatar then
		avatarHash = md5(tostring(avatar))
		local path = "avatarcache/"..avatarHash
		if fileExists(path) then
			setElementData(source, "avatarHash", avatarHash)
			--print(getPlayerName(source).."'s avatar is already stored")
		else
			--print(getPlayerName(source).."'s avatar is not stored, fetching...")
			fetchRemote(pageURL..avatar, 1, 10000, saveAvatar, "", false, source, avatarHash, path)
		end
	end
end
addEvent("login:onPlayerLogin", true)
addEventHandler("login:onPlayerLogin", root, syncAvatar)

function saveAvatar(responseData, errorNo, player, avatarHash, path)
	if errorNo == 0 then
		if fileExists(path) then
			fileDelete(path)
		end
		local avatar = fileCreate(path)
		if avatar then
			fileWrite(avatar, responseData)
			fileClose(avatar)
		end
		--setElementData(player, "avatarHash", avatarHash)
		--print("Downloaded and stored avatar for "..getPlayerName(player))
	end
end