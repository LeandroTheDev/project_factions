---@diagnostic disable: undefined-global, deprecated

-- Call the server to add a safehouse point
function Recipe.SafehousePlus.UpgradeSafehouse(recipe, ingredients, result, player)
	sendClientCommand("ServerSafehouse", "addSafehousePoint", nil);
end

--Sells Commands
AddUpgrade = Recipe.SafehousePlus.UpgradeSafehouse;
