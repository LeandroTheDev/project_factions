---@diagnostic disable: undefined-global
require = "recipecode";

-- Call the server to add a safehouse point
function Recipe.OnGiveXP.UpgradeSafehouse(recipe, ingredients, result, player)
	sendClientCommand("ServerSafehouse", "addSafehousePoint", nil);
end

-- Declaring variables to be called in script text
UpgradeSafehouse = Recipe.OnGiveXP.UpgradeSafehouse;