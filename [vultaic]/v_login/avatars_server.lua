local pageURL = "https://forum.vultaic.com/uploads/"
local downloading = {}

addEventHandler("onResourceStart", resourceRoot,
function()
	for i, player in pairs(getElementsByType("player")) do
		setElementData(player, "avatarHash", nil)
	end
end)

addEventHandler("onPlayerJoin", root,
function()
	setElementData(source, "avatarHash", nil)
end)

function getAvatar(username)
	local POST = toJSON({username = username})
	fetchRemote("https://forum.vultaic.com/mta_getavatar.php", 1, 10000, receiveAvatarContent, POST, false, username, source)
end
addEvent("login:getAvatar", true)
addEventHandler("login:getAvatar", root, getAvatar)

function receiveAvatarContent(responseData, errorNo, username, player)
	if errorNo == 0 then
		local responseData = fromJSON(responseData)
		if type(responseData) == "table" and responseData.error == 0 and responseData.avatar then
			local path = "avatar_"..username
			fetchRemote(pageURL..responseData.avatar, path, 1, 10000,
			function(responseData, errorNo, path, player)
				saveDownloadedFile(responseData, errorNo, path)
				triggerClientEvent(player, "login:onAvatarDataReceive", resourceRoot, username, responseData)
			end, "", false, path, player)			
		end
	end
end

function downloadAvatar(url, player, username)
	if type(url) == "string" then
		local username = username or getElementData(player, "username")
		if not username then
			return
		end
		local path = "avatar_"..username
		if downloading[path] then
			return
		end
		local avatarPath = "avatarcache/"..path
		if fileExists(avatarPath) then
			fileDelete(avatarPath)
		end
		fetchRemote(pageURL..url, path, 1, 10000, saveDownloadedFile, "", false, path, player)
		downloading[path] = true
	end
end

function saveDownloadedFile(responseData, errorNo, path, player)
	if errorNo == 0 then
		local file = fileCreate("avatarcache/"..path)
		if file then
			fileWrite(file, responseData)
			fileClose(file)
			if isElement(player) then
				setElementData(player, "avatarHash", path)
			end
			print("Created avatar cache for "..path)
		end
	end
	if downloading[path] then
		downloading[path] = nil
	end
end