--[[
	Vultaic::Addon::Nametags
--]]

local font = "default-bold"
local fontScale = 1

local enabled = true
local nametags = {}
local g_screenX,g_screenY = guiGetScreenSize()
local bHideNametags = false

local NAMETAG_SCALE = 0.3
local NAMETAG_ALPHA_DISTANCE = 50
local NAMETAG_DISTANCE = 120
local NAMETAG_ALPHA = 120
local NAMETAG_TEXT_BAR_SPACE = 2
local NAMETAG_WIDTH = 40
local NAMETAG_HEIGHT = 4
local NAMETAG_TEXTSIZE = 0.7
local NAMETAG_OUTLINE_THICKNESS = 1
local NAMETAG_ALPHA_DIFF = NAMETAG_DISTANCE - NAMETAG_ALPHA_DISTANCE
NAMETAG_SCALE = 1/NAMETAG_SCALE * 1100 / g_screenY

local maxScaleCurve = { {0, 0}, {3, 3}, {13, 5} }
local textScaleCurve = { {0, 0.8}, {0.8, 1.2}, {99, 99} }
local textAlphaCurve = { {0, 0}, {25, 100}, {120, 190}, {255, 190} }

function math.lerp(from,to,alpha)
    return from + (to-from) * alpha
end

for key, player in ipairs( getElementsByType( "player" ) ) do
	setPlayerNametagShowing( player, false )
end

function math.evalCurve( curve, input )
	if input<curve[1][1] then
		return curve[1][2]
	end
	for idx=2,#curve do
		if input<curve[idx][1] then
			local x1 = curve[idx-1][1]
			local y1 = curve[idx-1][2]
			local x2 = curve[idx][1]
			local y2 = curve[idx][2]
			local alpha = (input - x1)/(x2 - x1);
			return math.lerp(y1,y2,alpha)
		end
	end
	return curve[#curve][2]
end

local function drawNametags()
	if bHideNametags then return end

	local clientDimension = getElementDimension(localPlayer)
	
	local x,y,z = getCameraMatrix()
	for i,player in ipairs(getElementsByType("player", getElementParent(localPlayer), true)) do
		setPlayerNametagShowing(player, false)
		while true do
			if player == localPlayer then break end
			if isPlayerDead(player) then break end
			if clientDimension ~= getElementDimension(player) then break end
			
			local element = getPedOccupiedVehicle(player)
			local yOffset = 0.95
			local px,py,pz
			local textSize = NAMETAG_TEXTSIZE
			if element then
				local occupants = getVehicleOccupants(element)
				local count = 0
				for i,v in pairs(occupants) do count = count + 1 end
				if count == 1 then
					px, py, pz = getElementPosition ( element )
				else
					if getVehicleOccupant(element) == player then textSize = 0.7 else textSize = 0.5 end
					element = player
					yOffset = 0.15
					px, py, pz = getPedBonePosition(element, 6)
				end
			else
				element = player
				textSize = 0.5
				yOffset = 0.15
				px, py, pz = getPedBonePosition(element, 6)
			end
			
			local pdistance = getDistanceBetweenPoints3D ( x,y,z,px,py,pz )
			if pdistance <= NAMETAG_DISTANCE then

				local sx,sy = getScreenFromWorldPosition ( px, py, pz+yOffset, 0.06 )
				if not sx or not sy then break end

				if lineOfSightClear and not isLineOfSightClear(x,y,z, px,py,pz+yOffset, true, false, false) then break end

				local scale = 1/(NAMETAG_SCALE * (pdistance / NAMETAG_DISTANCE))
				scale = math.evalCurve(maxScaleCurve,scale)
				local textscale = math.evalCurve(textScaleCurve,scale)
				local outlineThickness = NAMETAG_OUTLINE_THICKNESS*(scale)
				
				if getElementData(player, "isChatting") and chaticon then
					dxDrawImage(sx - 15 * scale, sy - 40 * scale, 30 * scale, 30 * scale, Path_To_Chat_Icon)
                end

				local r,g,b = 255,255,255
				local team = getPlayerTeam(player)
				if team then
					r,g,b = getTeamColor(team)
				end
				local offset = scale
				local a = getElementAlpha(element)
				dxDrawText( string.gsub(getPlayerName(player), "#%x%x%x%x%x%x", ""), sx + 1, sy - offset + 1, sx + 1, sy + 1, tocolor( 0,0,0, math.floor( a * 0.8 ) ), fontScale * textscale * textSize, font, "center", "bottom", false, false, false, false, true )
				dxDrawText( getPlayerName(player), sx, sy - offset, sx, sy, tocolor(r, g, b, a), fontScale * textscale * textSize, font, "center", "bottom", false, false, false, true, true )
			end
			break
		end
		
	end
end
addEventHandler( "onClientRender", root, drawNametags )