if not getSandboxOptions():getOptionByName("SafehousePlus.EnableSafehouseCreateKey"):getValue() then return end

local doorlocksystem = {}
doorlocksystem.onFillWorldObjectContextMenu = function(playerId, context, worldobjects, test)
	-- Receive the player
	local player = getSpecificPlayer(playerId)

	-- Swipe objects
	for a, door in ipairs(worldobjects) do
		-- If is a door
		if instanceof(door, 'IsoDoor') then
			-- Add the key option
			local KeyMenu = context:addOption(getText("IGUI_Door_Lock"), worldobjects);
			local subMenu = ISContextMenu:getNew(context);
			doorlocksystem.context = context
			doorlocksystem.subMenu = subMenu
			context:addSubMenu(KeyMenu, subMenu);
			subMenu:addOption(getText("IGUI_Door_Create_Key"), worldobjects, doorlocksystem.userGetKey, player, door)
		end
	end
end

-- Secondary function to check if player is on the safehouse, returns true if belongs to the safehouse
-- false if not belongs to the safehouse or the safehouse is not exist
local function BelongsToTheSafehouse()
	-- TO DO
	return true;
end

-- Creates the gey for the user
doorlocksystem.userGetKey = function(worldobjects, player, door)
	-- Verify if the player belongs to the safehouse
	if BelongsToTheSafehouse() then
		-- Gets the door id
		local keycode = door:getKeyId();
		-- Create a key
		local doorkey = player:getInventory():AddItem('Base.Key1');
		-- Change the key id to the door id
		doorkey:setKeyId(keycode);
		-- Change the name and the keycode
		doorkey:setName('SafeHouse #' .. keycode);
		player:Say(getText("IGUI_Door_Key_Created"));
	else
		player:Say(getText("IGUI_Door_Key_Not_Created"));
	end
end

-- Calls the function when the world create
Events.OnFillWorldObjectContextMenu.Add(doorlocksystem.onFillWorldObjectContextMenu)
