local noSmokeShader = dxCreateShader("fx/nosmoke.fx")
local blink = dxCreateTexture("fx/blink.png")
dxSetShaderValue(noSmokeShader, "gTexture", blink)
local smokeDisabled = false

function disableSmoke()
	engineApplyShaderToWorldTexture(noSmokeShader, "collisionsmoke")
	engineApplyShaderToWorldTexture(noSmokeShader, "cloudmasked")
end

function enableSmoke()
	engineRemoveShaderFromWorldTexture(noSmokeShader, "collisionsmoke")
	engineRemoveShaderFromWorldTexture(noSmokeShader, "cloudmasked")
end

addEventHandler("onClientResourceStart", resourceRoot,
function()
	local state = exports.v_settings:getClientVariable("disable_smoke") == "On"
	if state then
		toggleSmoke(state)
	end
end)

addEvent("settings:onSettingChange", true)
addEventHandler("settings:onSettingChange", localPlayer,
function(variable, value)
	if variable == "disable_smoke" then
		local state = value == "On"
		toggleSmoke(state, true)
	end
end)

function toggleSmoke(state, notifyDisplay)
	smokeDisabled = state and true or false
	if smokeDisabled then
		disableSmoke()
		if notifyDisplay then
			triggerEvent("notification:create", localPlayer, "Anti-smoke", "Smokes are now disabled")
		end
	else
		enableSmoke()
		if notifyDisplay then
			triggerEvent("notification:create", localPlayer, "Anti-smoke", "Smokes are now enabled")
		end
	end
end