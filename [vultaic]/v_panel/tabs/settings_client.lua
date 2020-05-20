-- 'Settings' tab
local settings = {id = 5, title = "Settings", scrollable = true, margin = 2}
local content = nil
local items = {}
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
-- Settings
local options = {
	["private_messages"] = {
		title = "Private messages",
		description = "Toggle your private messages on/off. People won't be able to message you if this is disabled.",
		enabled_value = "On",
		disabled_value = "Off",
		order = 1
	},
	["enable_carfade"] = {
		title = "Car fade",
		description = "Nearby vehicles will be faded when this is enabled.",
		enabled_value = "On",
		disabled_value = "Off",
		order = 2
	},
	["enable_carhide"] = {
		title = "Car hide",
		description = "All vehicles will be hidden when this is enabled. We recommend to enable it for low-end PCs.",
		enabled_value = "On",
		disabled_value = "Off",
		order = 3
	},
	["enable_decohider"] = {
		title = "Deco hider",
		description = "Having FPS issues? Disable map decorations for a smoother gameplay experience.",
		enabled_value = "On",
		disabled_value = "Off",
		order = 4
	},
	["enable_hom"] = {
		title = "Show invisible roads",
		description = "Bored of invisible roads? This feature is for you.",
		enabled_value = "On",
		disabled_value = "Off",
		order = 5
	},
	["disable_overlays"] = {
		title = "Disable overlays",
		description = "Disable all overlays around.",
		enabled_value = "Off",
		disabled_value = "On",
		order = 6
	},
	["disable_neons"] = {
		title = "Disable neons",
		description = "Disable all neons around.",
		enabled_value = "Off",
		disabled_value = "On",
		order = 7
	},
	["disable_smoke"] = {
		title = "Anti-smoke",
		description = "Disable tire smokes. Suggested for low-end PCs.",
		enabled_value = "On",
		disabled_value = "Off",
		order = 8
	},
	["disable_arenachat"] = {
		title = "Disable arena chats",
		description = "Tired of arena-chat spam? Disable it.",
		enabled_value = "On",
		disabled_value = "Off",
		order = 9
	},
	["disable_globalchat"] = {
		title = "Disable global chat",
		description = "Tired of global-chat spam? Disable it.",
		enabled_value = "On",
		disabled_value = "Off",
		order = 10
	},
	["enable_rocketlines"] = {
		title = "Projectile lines",
		description = "Follow your rockets with a laser in shooter. Suggested for an easier aim & defence.",
		enabled_value = "On",
		disabled_value = "Off",
		order = 11
	},
	["force_player_blips"] = {
		title = "Player blips",
		description = "Always show player blips on radar, no matter what.",
		enabled_value = "On",
		disabled_value = "Off",
		order = 12
	},
	["radar_projectiles"] = {
		title = "Projectiles blips",
		description = "Show projectiles shot by players on radar (Hunter/Shooter rockets).",
		enabled_value = "On",
		disabled_value = "Off",
		order = 13
	},
	["disable_speedo"] = {
		title = "Disable speedometer",
		description = "Toggle speedometer on/off.",
		enabled_value = "On",
		disabled_value = "Off",
		order = 14
	},
	["draw_distance"] = {
		title = "Extreme Draw distance",
		description = "Turn extreme draw distance on/off. Extremely laggy for low-end PCs.",
		enabled_value = "On",
		disabled_value = "Off",
		order = 15
	},
}

-- Initialization
local function initTab()
	local offset = 2
	local height = (panel.height - 18) * 0.125
	local _options = {}
	for option, data in pairs(options) do
		table.insert(_options, {
			id = option,
			data = data
		})
	end
	table.sort(_options, function(a, b) return (a.data.order < b.data.order) end)
	for i, option in pairs(_options) do
		items["custom_"..option.id] = {type = "custom", x = 2, y = offset, width = panel.width - 4, height = height, checkbox = option.id}
		items["custom_"..option.id].renderingFunction = function(x, y, item)
			local checkbox = items["checkbox_"..item.checkbox]
			dxDrawRectangle(x, y, item.width, item.height, tocolor(255, 255, 255, 5))
			if checkbox then
				local r, g, b = checkbox.r, checkbox.g, checkbox.b
				dxDrawRectangle(x, y, 2, item.height, tocolor(r, g, b, 255))
			end
		end
		items["label_"..option.id] = {type = "label", text = option.data.title, x = 20, y = offset + 10, width = panel.width * 0.75 - 5, height = height * 0.5, font = dxlib.getFont("RobotoCondensed-Regular", 14), verticalAlign = "top"}
		items["label_"..option.id.."_description"] = {type = "label", text = option.data.description, x = 20, y = offset + height * 0.5, width = panel.width * 0.75 - 5, height = height * 0.5, verticalAlign = "top"}
		items["checkbox_"..option.id] = {type = "checkbox", x = panel.width - 72, y = offset, width = 62, height = height}
		items["checkbox_"..option.id].onCheck = function(checked)
			saveSetting(option.id, checked)
		end
		offset = offset + height + 2
	end
	-- Tab registration
	content = panel.initTab(settings.id, settings, items)
	loadSettings()
end
addEventHandler("onClientResourceStart", resourceRoot, initTab)

function saveSetting(setting, enabled)
	local option = options[setting]
	if not option then
		return
	end
	local value = enabled and option.enabled_value or option.disabled_value
	if value then
		exports.v_settings:setClientVariable(setting, value)
	end
end

function loadSettings()
	for option, data in pairs(options) do
		local enabledValue = data.enabled_value
		local checked = enabledValue and exports.v_settings:getClientVariable(option) == enabledValue and true or false
		items["checkbox_"..option].checked = checked
	end
end

addEvent("settings:onSettingChange", true)
addEventHandler("settings:onSettingChange", localPlayer,
function(variable, value)
	local option = options[variable]
	if option then
		local enabledValue = option.enabled_value
		local checked = enabledValue and exports.v_settings:getClientVariable(variable) == enabledValue and true or false
		items["checkbox_"..variable].checked = checked
	end
end)