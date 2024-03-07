---@diagnostic disable: undefined-global, deprecated
if isClient() then return end;
--Return Money Function
local function ReturnPoints(value, player)
	sendServerCommand("ServerPoints", "addPoints", { player:getUsername(), value })
	player:Say(getText("IGUI_Shop_Return"))
end

--Sell Item Function
local function SellItem(value, player)
	sendServerCommand("ServerPoints", "addPoints", { player:getUsername(), value })
	player:Say(getText("IGUI_Shop_Sell") .. " + " .. tostring(value))
end

--Return Money
function ReturnMoney(recipe, ingredients, result, player)
	ReturnPoints(1, player)
end

--Sell Carrot
function SellCarrot(recipe, ingredients, result, player)
	print("[Factions] " .. player:getUsername() .. " selled Carrots")
	SellItem(7, player)
end

--Sell Potato
function SellPotato(recipe, ingredients, result, player)
	print("[Factions] " .. player:getUsername() .. " selled Potatos")
	SellItem(9, player)
end

--Sell Strewberrie
function SellStrewberrie(recipe, ingredients, result, player)
	print("[Factions] " .. player:getUsername() .. " selled Strewberries")
	SellItem(4, player)
end

--Sell RedRadish
function SellRedRadish(recipe, ingredients, result, player)
	print("[Factions] " .. player:getUsername() .. " selled RedRadishs")
	SellItem(8, player)
end

--Sell Cabbage
function SellCabbage(recipe, ingredients, result, player)
	print("[Factions] " .. player:getUsername() .. " selled Cabbages")
	SellItem(7, player)
end

--Sell Tomato
function SellTomato(recipe, ingredients, result, player)
	print("[Factions] " .. player:getUsername() .. " selled Tomatos")
	SellItem(10, player)
end

--Sell Broccoli
function SellBroccoli(recipe, ingredients, result, player)
	print("[Factions] " .. player:getUsername() .. " selled Broccolis")
	SellItem(9, player)
end

--Sell Small Scrap
function SellSmallScrap(recipe, ingredients, result, player)
	print("[Factions] " .. player:getUsername() .. " selled Small Scrap")
	SellItem(1, player)
end

--Sell Medium Scrap
function SellMediumScrap(recipe, ingredients, result, player)
	print("[Factions] " .. player:getUsername() .. " selled Medium Scrap")
	SellItem(15, player)
end

--Sell Large Scrap
function SellLargeScrap(recipe, ingredients, result, player)
	print("[Factions] " .. player:getUsername() .. " selled Large Scrap")
	SellItem(100, player)
end
