---@diagnostic disable: undefined-global, cast-local-type
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
	local player = getPlayer();
	-- Get player safehouse standing
	local safehouse = SafeHouse.getSafeHouse(player:getSquare());

	-- Check if the player is on a safehouse
	if not safehouse then
		return false
	end

	-- Fast check if is the owner
	local owner = safehouse:getOwner();
	if player:getUsername() == owner then
		return true
	end

	-- If not the owner we need to check all players from the safehouse,
	-- and if the actual player is on it
	for i = safehouse:getPlayers():size() - 1, 0, -1 do
		local safehousePlayerUsername = safehouseBeenCaptured:getPlayers():get(i);
		-- Check if safehousePlayerUsername is the same as the player
		if safehousePlayerUsername == player:getUsername() then
			return true
		end
	end
	-- Player dont belong to the safehouse
	return false
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
