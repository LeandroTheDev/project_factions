---@diagnostic disable: undefined-global, cast-local-type
-- Check if this feature is enabled
if not SandboxVars.SafehousePlus.EnableSafehousePoints then return end

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
		local safehousePlayerUsername = safehouse:getPlayers():get(i);
		-- Check if safehousePlayerUsername is the same as the player
		if safehousePlayerUsername == player:getUsername() then
			return true
		end
	end
	-- Player dont belong to the safehouse
	return false
end

-- Call to the server to reedeem the points of the safehouse
local function redeemPoints()
	sendClientCommand("ServerSafehouse", "reedeemSafehousePoints", nil)
end

-- Show the Redeem safehouse points button if the player belongs to the safehouse
local function OnPreFillWorldObjectContextMenu(player, context, worldObjects, test)
	if BelongsToTheSafehouse() then
		context:addOption(getText("IGUI_Redeem_Safehouse_Points"), worldObjects, redeemPoints, nil)
	end
end

-- Add the function to handle the world context
Events.OnPreFillWorldObjectContextMenu.Add(OnPreFillWorldObjectContextMenu)

-- Handle the server side
local function OnServerCommand(module, command, arguments)
	if module == "ServerSafehouse" and command == "reedemHousePoints" then
		-- Success message
		getPlayer():Say(getText("IGUI_Redeem_Safehouse_Claimed") .. tostring(arguments.points));
		-- THIS NEEDS TO CHANGE i think
		sendClientCommand("ServerPoints", "addPoints", { getPlayer():getUsername(), arguments.points });
	end
	if module == "ServerSafehouse" and command == "notInSafehouse" then
		-- Error message player not in safehouse
		getPlayer():Say(getText("IGUI_Redeem_Safehouse_Not_In_Safehouse"));
		-- Return the item to the player
		getPlayer():getInventory():AddItem("Base.UpgradeSafehouse");
	end
	if module == "ServerSafehouse" and command == "safehouseUpgraded" then
		-- Success message
		getPlayer():Say(getText("IGUI_Redeem_Safehouse_Upgraded"));
	end
end
Events.OnServerCommand.Add(OnServerCommand)
