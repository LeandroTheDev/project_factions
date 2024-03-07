---@diagnostic disable: undefined-global, deprecated
if isClient() then return end;
-- Call the server to add a safehouse point
function UpgradeSafehouse(recipe, ingredients, result, player)
	sendClientCommand("ServerSafehouse", "addSafehousePoint", nil);
end
