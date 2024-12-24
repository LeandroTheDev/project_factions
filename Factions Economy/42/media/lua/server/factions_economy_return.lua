---@diagnostic disable: undefined-global, deprecated
--Return Money
function Recipe.OnCreate.ReturnMoney(craftRecipeData, player)
	local username = player:getUsername();
	sendClientCommand("ServerPoints", "addPoints", { username, 1 });
	player:Say(getText("IGUI_Shop_Return"));
end