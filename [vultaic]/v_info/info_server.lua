local messages = {
	"Visit us at [www.vultaic.com]",
	"Join our discord [https://discordapp.com/invite/g7bp2Bq] to be notified of our development and exciting [sneak peaks]!",
	"If you'd like to ignore messages from a certain player, you can do so using [/ignore]",
    "Become a donator to enjoy our exclusive garage upgrades.",
    "Are you having FPS issues? Take a look at the settings. ([F7 > Settings])",
    "Create your clan today for $500K, 50% off for donators! ([F7 > Clans])",
    "Bugged map(-s)? Report them at [www.vultaic.com]!",
    "Help us improve your gameplay experience by posting your ideas at our suggestions sub-forum.",
    "All available controls, commands and server rules can be found at our help panel. ([F7 > Help])",
}
local i = 1--math.random(#messages)
function outputRandomMessage()
	i = i + 1
	if i > #messages then
		i = 1
	end
	message = messages[i]
	message = string.gsub(message, "#%x%x%x%x%x%x", "")
	message = string.gsub(message, "%[", "#19846D")
	message = string.gsub(message, "%]", "#FFFFFF")
	outputChatBox("[INFO] #FFFFFF"..message, root, 25, 132, 109, true)
end
outputRandomMessage()
setTimer(outputRandomMessage, 60000 * 10, 0)