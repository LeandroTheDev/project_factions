---@diagnostic disable: undefined-global, deprecated
--Return Money Function
local function ReturnPoints(value, player)
	local username = player:getUsername();
	sendClientCommand("ServerPoints", "addPoints", { username, value });
	player:Say(getText("IGUI_Shop_Return"));
end

--Sell Item Function
local function SellItem(value, player)
	local username = player:getUsername();
	sendClientCommand("ServerPoints", "addPoints", { username, value });
	player:Say(getText("IGUI_Shop_Sell") .. " + " .. tostring(value));
end

--Return Money
function Recipe.OnGiveXP.ReturnMoney(craftRecipeData, player)
	ReturnPoints(1, player)
end

--Sell Carrot
function Recipe.OnGiveXP.SellCarrot(craftRecipeData, player)
	print("[Factions] " .. player:getUsername() .. " selled Carrots")
	SellItem(7, player)
end

--Sell Potato
function Recipe.OnGiveXP.SellPotato(craftRecipeData, player)
	print("[Factions] " .. player:getUsername() .. " selled Potatos")
	SellItem(9, player)
end

--Sell Strewberrie
function Recipe.OnGiveXP.SellStrewberrie(craftRecipeData, player)
	print("[Factions] " .. player:getUsername() .. " selled Strewberries")
	SellItem(4, player)
end

--Sell RedRadish
function Recipe.OnGiveXP.SellRedRadish(craftRecipeData, player)
	print("[Factions] " .. player:getUsername() .. " selled RedRadishs")
	SellItem(8, player)
end

--Sell Cabbage
function Recipe.OnGiveXP.SellCabbage(craftRecipeData, player)
	print("[Factions] " .. player:getUsername() .. " selled Cabbages")
	SellItem(7, player)
end

--Sell Tomato
function Recipe.OnGiveXP.SellTomato(craftRecipeData, player)
	print("[Factions] " .. player:getUsername() .. " selled Tomatos")
	SellItem(10, player)
end

--Sell Broccoli
function Recipe.OnGiveXP.SellBroccoli(craftRecipeData, player)
	print("[Factions] " .. player:getUsername() .. " selled Broccolis")
	SellItem(9, player)
end

--Sell Small Scrap
function Recipe.OnGiveXP.SellSmallScrap(craftRecipeData, player)
	print("[Factions] " .. player:getUsername() .. " selled Small Scrap")
	SellItem(1, player)
end

--Sell Medium Scrap
function Recipe.OnGiveXP.SellMediumScrap(craftRecipeData, player)
	print("[Factions] " .. player:getUsername() .. " selled Medium Scrap")
	SellItem(15, player)
end

--Sell Large Scrap
function Recipe.OnGiveXP.SellLargeScrap(craftRecipeData, player)
	print("[Factions] " .. player:getUsername() .. " selled Large Scrap")
	SellItem(100, player)
end
