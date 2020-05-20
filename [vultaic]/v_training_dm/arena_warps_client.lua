local WarpData = {}
local clanColor = "#138c5e"
addEventHandler("onClientJoinArena", resourceRoot,
function(data)
	addCommandHandler("sw", CMD_SaveWarp, false)
	addCommandHandler("lw", CMD_LoadWarp, false)
	addCommandHandler("rw", CMD_RemoveWarp, false)
	addCommandHandler("dw", CMD_RemoveWarp, false)
end)
addEventHandler("onClientLeaveArena", resourceRoot,
function()
	removeCommandHandler("sw", CMD_SaveWarp)
	removeCommandHandler("lw", CMD_LoadWarp)
	removeCommandHandler("rw", CMD_RemoveWarp)
	removeCommandHandler("dw", CMD_RemoveWarp)
end)
addEventHandler("mapmanager:onMapLoad", localPlayer, function()
	WarpData = {}
end)
function CMD_SaveWarp( command, param )
	local vehicle = localPlayer:getOccupiedVehicle()
	
	if( not vehicle ) then
		return true;
	end
	
	local vehicleModel = getVehicleModelFromName( vehicle:getName() )
	local vehicleHealth = vehicle:getHealth()
	local vehiclePosition = { vehicle:getPosition() }
	local vehicleRotation = { vehicle:getRotation() }
	local vehicleVelocity = { vehicle:getVelocity() }
	local vehicleAngularVelocity = { vehicle:getAngularVelocity() }
	local vehicleNitro = {
		Nitro = vehicle:getUpgradeOnSlot( 8 ),
		NitroLevel = nil,
		NitroActivated = false
	}
	
	if( vehicleNitro.Nitro ) then
		vehicleNitro.NitroLevel = getVehicleNitroLevel( vehicle ) or 0;
		vehicleNitro.NitroActivated = isVehicleNitroActivated( vehicle );
	end
	
	table.insert( WarpData, #WarpData + 1, {
		VehicleModel = vehicleModel,
		VehicleHealth = vehicleHealth,
		VehicleNitro = vehicleNitro,
		VehiclePosition = vehiclePosition,
		VehicleRotation = vehicleRotation,
		VehicleVelocity = vehicleVelocity,
		VehicleAngularVelocity = vehicleAngularVelocity
	} )
	
	outputChatBox( clanColor.."* [#" .. #WarpData .. "] #FFFFFFWarp Saved", 255, 255, 255, true );
end
function CMD_LoadWarp( command, param )
	local warpSlot = tonumber( param ) or #WarpData;
	if( WarpData[ warpSlot ] ~= nil ) then
		local _warpData = WarpData[ warpSlot ];
		local vehicle = localPlayer:getOccupiedVehicle();
		local bNitro = _warpData.VehicleNitro.Nitro == 1010;
		
		if( not vehicle or isPedDead( localPlayer ) ) then
			return true;
		end
		
		if( getVehicleModelFromName( vehicle:getName() ) ~= _warpData.VehicleModel ) then
			vehicle:setModel( _warpData.VehicleModel );
			triggerServerEvent( "syncPlayerVehicle", resourceRoot, vehicle, _warpData.VehicleModel );
		end
		
		vehicle:setFrozen( true );
		vehicle:setHealth( _warpData.VehicleHealth );
		
		vehicle:addUpgrade( 1010 );
		if(not bNitro) then
			vehicle:removeUpgrade( 1010 );
		end

		vehicle:setPosition( unpack( _warpData.VehiclePosition ) );
		vehicle:setRotation( unpack( _warpData.VehicleRotation ) );

		setTimer( function( pVehicle, pVehicleVelocity, pVehicleAngularVelocity, tNitro )
			if( not pVehicle or not isElement( pVehicle ) ) then
				return true;
			end
			pVehicle:setFrozen( false );
			pVehicle:setVelocity( unpack( pVehicleVelocity ) );
			pVehicle:setAngularVelocity( unpack( pVehicleAngularVelocity ) );
			if( tNitro.Nitro and not pVehicle:getUpgradeOnSlot( 8 ) ) then
				pVehicle:addUpgrade( 1010 );
			end
			setVehicleNitroActivated( pVehicle, false );
			setVehicleNitroLevel( pVehicle, tNitro.NitroLevel );
			setVehicleNitroActivated( pVehicle, tNitro.NitroActivated )
		end, 1000, 1, vehicle, _warpData.VehicleVelocity, _warpData.VehicleAngularVelocity, _warpData.VehicleNitro );
		
		arena.allowToptime = false
		outputChatBox( clanColor.."* [#" .. warpSlot .. "] #FFFFFFWarp loaded", 255, 255, 255, true );
	end
end
function CMD_RemoveWarp( command, param )
	local warpSlot = #WarpData;
	if( WarpData[ warpSlot ] ~= nil ) then
		table.remove( WarpData, warpSlot );
		outputChatBox( clanColor.."* [#" .. warpSlot .. "] #FFFFFFWarp deleted", 255, 255, 255, true );
	end
end