local downloading = {}
local avatarCache = {}

addEventHandler("onClientResourceStart", resourceRoot,
function()
	for i, player in pairs(getElementsByType("player")) do
		local path = getElementData(player, "avatarHash")
		if path then
			downloadAvatar(path, player)
		end
	end
end)

addEvent("login:onAvatarDataReceive", true)
addEventHandler("login:onAvatarDataReceive", resourceRoot,
function(username, data)
	saveDownloadedFile(data, 0, "avatar_"..username, localPlayer, true)
	if isElement(clientPreviewAvatar) then
		destroyElement(clientPreviewAvatar)
	end
	clientPreviewAvatar = dxCreateTexture("avatarcache/avatar_"..username)
	setElementData(localPlayer, "previewAvatarTexture", clientPreviewAvatar, false)
end)

function downloadAvatar(path, player)
	if downloading[path] then
		return
	end
	print("Downloading avatar from "..path)
	fetchRemote("http://164.132.114.156:8080/devavatarcache/"..path, path, 1, 10000, saveDownloadedFile, "", false, path, player)
	downloading[path] = true
end

function saveDownloadedFile(responseData, errorNo, path, player, noAssign)
	if errorNo == 0 then
		if fileExists("avatarcache/"..path) then
			fileDelete("avatarcache/"..path)
		end
		local file = fileCreate("avatarcache/"..path)
		if file then
			fileWrite(file, responseData)
			fileClose(file)
			if not noAssign then
				assignPlayerAvatar(player, path)
			end
			print("Client created avatar cache for "..path)
		end
	end
	if downloading[path] then
		downloading[path] = nil
	end
end

addEventHandler("onClientElementDataChange", root,
function(dataName)
	if dataName == "avatarHash" then
		local filePath = getElementData(source, "avatarHash")
		if filePath then
			downloadAvatar(filePath, source)
		end
	end
end)

function assignPlayerAvatar(player, path)
	if isElement(player) and type(path) == "string" and fileExists("avatarcache/"..path) then
		if not avatarCache[player] then
			avatarCache[player] = dxCreateTexture("avatarcache/"..path)
		end
		if avatarCache[player] then
			setElementData(player, "avatarTexture", avatarCache[player], false)
		end
	end
end

addEventHandler("onClientPlayerQuit", root,
function()
	if isElement(avatarCache[source]) then
		destroyElement(avatarCache[source])
	end
	avatarCache[source] = nil
end)