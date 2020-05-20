languages = {}

function getPlayerLanguage(player)
	if isElement(player) then
		local realLanguage = getElementData(player, "countryCode")
		local language = exports.v_mysql:getPlayerStats(player, "language") or realLanguage
		setElementData(player, "language", language or "none")
		if not language then
			return
		end
		initLanguage(language)
		initLanguage(realLanguage)
	end
end
addEvent("mysql:onPlayerLogin", true)
addEventHandler("mysql:onPlayerLogin", root, function() getPlayerLanguage(source) end)

function initLanguage(language)
	if language and not languages[language] then
		languages[language] = true
	end
end

addEventHandler("onResourceStart", resourceRoot,
function()
	for i, player in pairs(getElementsByType("player")) do
		getPlayerLanguage(player)
		bindKey(player, "L", "down", "chatbox", "language")
	end
	initLanguage("veryprivate")
end)

addEventHandler("onPlayerJoin", root,
function()
	getPlayerLanguage(player)
	bindKey(source, "L", "down", "chatbox", "language")
end)

addEvent("onPlayerCountryDetected", true)
addEventHandler("onPlayerCountryDetected", root,
function()
	getPlayerLanguage(source)
end)

addCommandHandler("lang",
function(player, command, language)
	local logged = getElementData(player, "LoggedIn")
	if not logged then
		return outputChatBox("Language :: #FFFFFFYou have to be logged in to change your language", player, 25, 132, 109, true)
	end
	if not language then
		return outputChatBox("Language :: #FFFFFFPlease enter a language to join", player, 25, 132, 109, true)
	end
	local language = tostring(language):upper()
	if languages[language] or language == "NONE" then
		if language == "NONE" then
			exports.v_mysql:setPlayerStats(player, "language", "0")
			setElementData(player, "language", nil)
			outputChatBox("Language :: #FFFFFF Your language has has been reset", player, 25, 132, 109, true)
		else
			exports.v_mysql:setPlayerStats(player, "language", language)
			setElementData(player, "language", language)
			outputChatBox("Language :: #FFFFFF Your language has been set to: "..language, player, 25, 132, 109, true)
		end
	else
		return outputChatBox("Language :: #FFFFFF This language chat does not exist", player, 25, 132, 109, true)
	end
end)

function doLanguageChat(player, command, ...)
	if isPlayerMuted(player) then
		return outputChatBox("You are muted", player, 255, 0, 0, true)
	end
	local language = getElementData(player, "language")
	if not language or not languages[language] then
		return
	end
	local message = table.concat({...}, " ")
	triggerEvent("onPlayerChat", player, message, 4)
end
addCommandHandler("language", doLanguageChat)