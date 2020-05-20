addEventHandler("onClientResourceStart", resourceRoot,
function()
	noDirtShader = dxCreateShader("fx/replace.fx")
	engineApplyShaderToWorldTexture(noDirtShader, "vehiclegrunge*")
end)