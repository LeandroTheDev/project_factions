---@diagnostic disable: undefined-global, deprecated
--Return Money Function
local function ReturnPoints(value)
	local username = getPlayer():getUsername()
	sendClientCommand("ServerPoints", "addPoints", { username, value })
	getPlayer():Say(getText("IGUI_Shop_Return"))
end

--Sell Item Function
local function SellItem(value)
	local username = getPlayer():getUsername()
	sendClientCommand("ServerPoints", "addPoints", { username, value })
	getPlayer():Say(getText("IGUI_Shop_Sell") .. " + " .. tostring(value))
end

--Return Money
function Recipe.FactionsSell.Money(recipe, ingredients, result, player)
	ReturnPoints(1)
end

--Sell Carrot
function Recipe.FactionsSell.Carrot(recipe, ingredients, result, player)
	print("[Factions] " .. player:getUsername() .. " selled Carrots")
	SellItem(7)
end

--Sell Potato
function Recipe.FactionsSell.Potato(recipe, ingredients, result, player)
	print("[Factions] " .. player:getUsername() .. " selled Potatos")
	SellItem(9)
end

--Sell Strewberrie
function Recipe.FactionsSell.Strewberrie(recipe, ingredients, result, player)
	print("[Factions] " .. player:getUsername() .. " selled Strewberries")
	SellItem(4)
end

--Sell RedRadish
function Recipe.FactionsSell.RedRadish(recipe, ingredients, result, player)
	print("[Factions] " .. player:getUsername() .. " selled RedRadishs")
	SellItem(8)
end

--Sell Cabbage
function Recipe.FactionsSell.Cabbage(recipe, ingredients, result, player)
	print("[Factions] " .. player:getUsername() .. " selled Cabbages")
	SellItem(7)
end

--Sell Tomato
function Recipe.FactionsSell.Tomato(recipe, ingredients, result, player)
	print("[Factions] " .. player:getUsername() .. " selled Tomatos")
	SellItem(10)
end

--Sell Broccoli
function Recipe.FactionsSell.Broccoli(recipe, ingredients, result, player)
	print("[Factions] " .. player:getUsername() .. " selled Broccolis")
	SellItem(9)
end

--Sell Small Scrap
function Recipe.FactionsSell.SmallScrap(recipe, ingredients, result, player)
	print("[Factions] " .. player:getUsername() .. " selled Small Scrap")
	SellItem(1)
end

--Sell Medium Scrap
function Recipe.FactionsSell.MediumScrap(recipe, ingredients, result, player)
	print("[Factions] " .. player:getUsername() .. " selled Medium Scrap")
	SellItem(15)
end

--Sell Large Scrap
function Recipe.FactionsSell.LargeScrap(recipe, ingredients, result, player)
	print("[Factions] " .. player:getUsername() .. " selled Large Scrap")
	SellItem(100)
end

--Sells Commands
SellMoney = Recipe.FactionsSell.Money
SellCarrot = Recipe.FactionsSell.Carrot
SellPotato = Recipe.FactionsSell.Potato
SellStrewberrie = Recipe.FactionsSell.Strewberrie
SellRedRadish = Recipe.FactionsSell.RedRadish
SellCabbage = Recipe.FactionsSell.Cabbage
SellTomato = Recipe.FactionsSell.Tomato
SellBroccoli = Recipe.FactionsSell.Broccoli
SellSmallScrap = Recipe.FactionsSell.SmallScrap
SellMediumScrap = Recipe.FactionsSell.MediumScrap
SellLargeScrap = Recipe.FactionsSell.LargeScrap
