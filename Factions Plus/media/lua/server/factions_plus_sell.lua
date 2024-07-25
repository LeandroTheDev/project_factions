---@diagnostic disable: undefined-global, deprecated
if isClient() then return end;

--Return Money Function
local function ReturnPoints(value, player)
	local username = getPlayer():getUsername();
	sendServerCommand("ServerPoints", "addPoints", { username, value });
	getPlayer():Say(getText("IGUI_Shop_Return"));
end

--Sell Item Function
local function SellItem(value, player)
	local username = getPlayer():getUsername();
	sendServerCommand("ServerPoints", "addPoints", { username, value });
	getPlayer():Say(getText("IGUI_Shop_Sell") .. " + " .. tostring(value));
end

--Return Money
function Recipe.OnGiveXP.ReturnMoney(recipe, ingredients, result, player)
	ReturnPoints(1, player)
end

--Sell Carrot
function Recipe.OnGiveXP.SellCarrot(recipe, ingredients, result, player)
	print("[Factions] " .. player:getUsername() .. " selled Carrots")
	SellItem(7, player)
end

--Sell Potato
function Recipe.OnGiveXP.SellPotato(recipe, ingredients, result, player)
	print("[Factions] " .. player:getUsername() .. " selled Potatos")
	SellItem(9, player)
end

--Sell Strewberrie
function Recipe.OnGiveXP.SellStrewberrie(recipe, ingredients, result, player)
	print("[Factions] " .. player:getUsername() .. " selled Strewberries")
	SellItem(4, player)
end

--Sell RedRadish
function Recipe.OnGiveXP.SellRedRadish(recipe, ingredients, result, player)
	print("[Factions] " .. player:getUsername() .. " selled RedRadishs")
	SellItem(8, player)
end

--Sell Cabbage
function Recipe.OnGiveXP.SellCabbage(recipe, ingredients, result, player)
	print("[Factions] " .. player:getUsername() .. " selled Cabbages")
	SellItem(7, player)
end

--Sell Tomato
function Recipe.OnGiveXP.SellTomato(recipe, ingredients, result, player)
	print("[Factions] " .. player:getUsername() .. " selled Tomatos")
	SellItem(10, player)
end

--Sell Broccoli
function Recipe.OnGiveXP.SellBroccoli(recipe, ingredients, result, player)
	print("[Factions] " .. player:getUsername() .. " selled Broccolis")
	SellItem(9, player)
end

--Sell Small Scrap
function Recipe.OnGiveXP.SellSmallScrap(recipe, ingredients, result, player)
	print("[Factions] " .. player:getUsername() .. " selled Small Scrap")
	SellItem(1, player)
end

--Sell Medium Scrap
function Recipe.OnGiveXP.SellMediumScrap(recipe, ingredients, result, player)
	print("[Factions] " .. player:getUsername() .. " selled Medium Scrap")
	SellItem(15, player)
end

--Sell Large Scrap
function Recipe.OnGiveXP.SellLargeScrap(recipe, ingredients, result, player)
	print("[Factions] " .. player:getUsername() .. " selled Large Scrap")
	SellItem(100, player)
end

-- Declaring variables to be called in script text
ReturnMoney = Recipe.OnGiveXP.ReturnMoney;
SellCarrot = Recipe.OnGiveXP.SellCarrot;
SellPotato = Recipe.OnGiveXP.SellPotato;
SellStrewberrie = Recipe.OnGiveXP.SellStrewberrie;
SellRedRadish = Recipe.OnGiveXP.SellRedRadish;
SellCabbage = Recipe.OnGiveXP.SellCabbage;
SellTomato = Recipe.OnGiveXP.SellTomato;
SellBroccoli = Recipe.OnGiveXP.SellBroccoli;
SellSmallScrap = Recipe.OnGiveXP.SellSmallScrap;
SellMediumScrap = Recipe.OnGiveXP.SellMediumScrap;
SellLargeScrap = Recipe.OnGiveXP.SellLargeScrap;
