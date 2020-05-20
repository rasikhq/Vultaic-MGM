-- 'Settings' tab
local settings = {id = 6, title = "Help", scrollable = true, margin = 2}
local content = nil
local items = {
	["rectangle_header"] = {type = "rectangle", x = 0, y = 0, width = panel.width, height = 40, color = tocolor(25, 25, 25, 245)},
	["label_header"] = {type = "label", text = "What are you looking for?", x = 10, y = 0, width = panel.width - 10, height = 40, verticalAlign = "center"},
}
helpTable = {
	{
		title = "Server Rules",
		rows = {
			"Do not exploit any bugs or glitches, report them.",
			"If a player is breaking any rules, use /report to inform any ingame admins or take proper evidence and report on forum.",
			"English only in Global chat, use L for language chat.",
			"Bantering is fine but don't do serious offenses that dishearten any player, this includes their personality, country, religion or life whatsoever.",
			"Do not provoke others.",
			"Don't react to rule breaking with rule breaking.",
			"Don't disobey admins. (Members in Vultaic group on scoreboard)",

		},
		introduction = "Make sure to read through all the server rules to avoid any mishaps."
	},
	{
		title = "Basic information",
		rows = {
			"Join lobby / Leave arena by holding F1.",
			"Switch between different music modes by using M.",
			"Toggle map shaders & textures by using N. (Experimental, glitches are expected on some maps)",
			"Language chat key: L. Use /lang [CountryCode] to switch to that language for example /lang SK"
		},
		introduction = "The very basic information regarding how to navigate in server."
	},
	{
		title = "Gameplay help",
		rows = {
			"Press F2 to toggle carhide.",
			"Press F3 to toggle carfade.",
			"Press F4 to toggle decoration hider.",
			"Press F5 to view toptimes.",
			"Press F6 to show toggle hidden objects.",
			"Press F7 to enter userpanel.",
			"Press F9 to toggle radar.",
			"Press F10 to toggle HUD.",
			"To follow a player with guidlines use /follow [Player name/ID] (Optional: Use lines instead of 3D arrows)."
		},
		introduction = "Get to know all the hotkeys to make your gameplay better."
	},
	{
		title = "Clans",
		rows = {
			"To invite a player, go to userpanel, Statistics tab, select the player, and press Invite to clan.",
			"To accept a clan's invitation, go to userpanel, Clans tab, select the clan you have been invited to, and press accept."
		},
		introduction = "Do you have any questions how Clans system works? You may find the answer here!"
	},
	{
		title = "Training",
		rows = {
			"Go back to maps selection via F1.",
			"/sw to save a warp.",
			"/lw (Optional: Warp number | Default: Last warp) to load a warp.",
			"/dw or /rw to delete/remove the last saved warp.",
			"You can get toptimes in training arena but these tops are distinct to training only."
		},
		introduction = "All the necessary information related to Training arena."
	}
}
-- Optimization
local dxCreateRenderTarget = dxCreateRenderTarget
local dxSetRenderTarget = dxSetRenderTarget
local dxSetBlendMode = dxSetBlendMode
local dxDrawRectangle = dxDrawRectangle
local dxDrawText = dxDrawText
local dxDrawImage = dxDrawImage
local dxDrawImageSection = dxDrawImageSection
local unpack = unpack
local tocolor = tocolor
local math_min = math.min
local math_max = math.max
local math_floor = math.floor
local tableInsert = table.insert
local tableRemove = table.remove
local pairs = pairs
local interpolateBetween = interpolateBetween

-- Initialization
local function initTab()
	local offset = 42
	local height = (panel.height - 56) * 0.125
	for i, help in pairs(helpTable) do
		items["custom_"..i] = {type = "custom", x = 2, y = offset, width = panel.width - 4, height = height}
		items["custom_"..i].renderingFunction = function(x, y, item)
			dxDrawRectangle(x, y, item.width, item.height, tocolor(255, 255, 255, 5))
		end
		items["label_"..i.."_title"] = {type = "label", text = help.title, x = 20, y = offset + 10, width = panel.width, height = height * 0.5, font = dxlib.getFont("RobotoCondensed-Regular", 14), verticalAlign = "top"}
		items["label_"..i.."_intro"] = {type = "label", text = help.introduction, x = 20, y = offset + height * 0.5, width = panel.width, height = height * 0.5, verticalAlign = "top"}
		items["button_"..i] = {type = "button", text = "Read", x = panel.width - 120, y = offset + (height - 35)/2, width = 100, height = 35}
		items["button_"..i].onClick = function()
			viewHelp(i)
		end
		offset = offset + height + 2
	end
	-- Tab registration
	content = panel.initTab(settings.id, settings, items)
end
addEventHandler("onClientResourceStart", resourceRoot, initTab)