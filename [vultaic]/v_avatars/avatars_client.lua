local waitingQueue = {}
local fetchingQueue = {}
local avatarTextures = {}
local maximumAvatarsToFetchAtTheSameTime = 1

addEventHandler("onClientResourceStart", resourceRoot,
function(dataName)
	defaultAvatarTexture = dxCreateTexture("img/default-avatar.png")
	for i, player in pairs(getElementsByType("player")) do
		syncPlayerAvatar(player)
	end
end)

function syncPlayerAvatar(player, avatarHash)
	if not isElement(player) or fetchingQueue[player] then
		return
	end
	if countFetchingQueue() > maximumAvatarsToFetchAtTheSameTime then
		waitingQueue[player] = true
		return --print("There are "..maximumAvatarsToFetchAtTheSameTime.." downloads in the queue already, postponing...")
	end
	local avatarHash = avatarHash and avatarHash or getElementData(player, "avatarHash")
	if avatarHash then
		local path = "avatarcache/"..avatarHash
		if fileExists(path) then
			--print(getPlayerName(player).."'s avatar is already stored in client")
			--createAvatarTexture(player, path)
		else
			--print(getPlayerName(player).."'s avatar is not stored in client, fetching...")
			fetchRemote("http://164.132.114.156:8080/mainavatarcache/"..avatarHash, path, 2, 10000, saveAvatar, "", false, player, avatarHash, path)
			fetchingQueue[player] = true
		end
	end
end

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
		--print("Downloaded and stored avatar for "..getPlayerName(player).." in client")
		--createAvatarTexture(player, path)
	else
		--print("Failed to download avatar for "..getPlayerName(player).." [Error no: "..errorNo.."]")
	end
	if waitingQueue[player] then
		waitingQueue[player] = nil
	end
	if fetchingQueue[player] then
		fetchingQueue[player] = nil
	end
	if countFetchingQueue() == 0 and countWaitingQueue() > 0 and (not waitingQueueTimer or not isTimer(waitingQueueTimer)) then
		waitingQueueTimer = setTimer(checkWaitingQueue, 1000, 0)
		--print("Activated the queue checks")
	end
end

function createAvatarTexture(player, path)
	if not isElement(player) or (avatarTextures[player] and isElement(avatarTextures[player])) then
		return
	end
	if path and fileExists(path) then
		avatarTextures[player] = dxCreateTexture(path)
		--print("Created avatar texture for "..getPlayerName(player))
	end
end

function getAvatarTexture(player)
	--local avatar = nil
	--if isElement(player) and avatarTextures[player] then
	--	avatar = avatarTextures[player]
	--end
	--return avatar or defaultAvatarTexture
	return defaultAvatarTexture
end

addEventHandler("onClientPlayerQuit", root,
function()
	if avatarTextures[source] then
		destroyElement(avatarTextures[source])
		avatarTextures[source] = nil
	end
end)

function checkWaitingQueue()
	if countWaitingQueue() == 0 or countFetchingQueue() > 0 then
		if waitingQueueTimer and isTimer(waitingQueueTimer) then
			killTimer(waitingQueueTimer)
		end
		--print("Deactivated the queue checks")
		return
	end
	--print("Checking the remaining avatars")
	local k = 1
	for player in pairs(waitingQueue) do
		syncPlayerAvatar(player)
		k = k + 1
		if k > maximumAvatarsToFetchAtTheSameTime then
			break
		end
	end
	if waitingQueueTimer and isTimer(waitingQueueTimer) then
		killTimer(waitingQueueTimer)
	end
end

function countWaitingQueue()
	local k = 0
	for player in pairs(waitingQueue) do
		k = k + 1
	end
	return k
end

function countFetchingQueue()
	local k = 0
	for player in pairs(fetchingQueue) do
		k = k + 1
	end
	return k
end

addEventHandler("onClientElementDataChange", root,
function(dataName)
	if dataName == "avatarHash" then
		syncPlayerAvatar(source, getElementData(source, "avatarHash"))
	end
end)