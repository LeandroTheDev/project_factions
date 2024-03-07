---@diagnostic disable: undefined-global
local lootboxes = {}

lootboxes.split = function(s, delimiter)
	local result = {};
	for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
		table.insert(result, match);
	end
	return result;
end

lootboxes.itemCount = function(tmp)
	local i = 0;
	local sum = 0;
	if (#tmp > 1) then
		while (i < #tmp) do
			i = i + 2;
			sum = sum + tonumber(tmp[i]);
		end
	end
	return sum;
end

lootboxes.readOptions = function()
	local tableTmp0 = SandboxVars.FactionsEconomy.itemTable0;
	local tableTmp1 = SandboxVars.FactionsEconomy.itemTable1;
	local tableTmp2 = SandboxVars.FactionsEconomy.itemTable2;
	local tableTmp3 = SandboxVars.FactionsEconomy.itemTable3;
	local tableTmp4 = SandboxVars.FactionsEconomy.itemTable4;
	local tableTmp5 = SandboxVars.FactionsEconomy.itemTable5;
	local tableTmp6 = SandboxVars.FactionsEconomy.itemTable6;
	ItemTable0 = lootboxes.split(tableTmp0, "/");
	ItemTable1 = lootboxes.split(tableTmp1, "/");
	ItemTable2 = lootboxes.split(tableTmp2, "/");
	ItemTable3 = lootboxes.split(tableTmp3, "/");
	ItemTable4 = lootboxes.split(tableTmp4, "/");
	ItemTable5 = lootboxes.split(tableTmp5, "/");
	ItemTable6 = lootboxes.split(tableTmp6, "/");
	Chance0 = lootboxes.itemCount(itemTable0);
	Chance1 = lootboxes.itemCount(itemTable1);
	Chance2 = lootboxes.itemCount(itemTable2);
	Chance3 = lootboxes.itemCount(itemTable3);
	Chance4 = lootboxes.itemCount(itemTable4);
	Chance5 = lootboxes.itemCount(itemTable5);
	Chance6 = lootboxes.itemCount(itemTable6);
end

-- Get a random item from item table
local function pickItem(itemTable, count)
	local ran = ZombRand(count) + 1;
	local i = 2;
	local tmpChance = tonumber(itemTable[i]);
	while (tmpChance < ran) do
		i = i + 2;
		tmpChance = tmpChance + tonumber(itemTable[i]);
	end
	return itemTable[i - 1]
end

-- Handle the open box method
local function openBox(itemTable, count)
	if (#itemTable > 1) then
		local player = getPlayer();
		local item_id = pickItem(itemTable, count);
		player:getInventory():AddItem(item_id);
	end
end


-- Functions called when opening a box
function LootBoxAmmoOpen()
	openBox(ItemTable0, Chance0);
end

function LootBoxClothesOpen()
	openBox(ItemTable1, Chance1);
end

function LootBoxMeleeOpen()
	openBox(ItemTable2, Chance2);
end

function LootBoxWeaponOpen()
	openBox(ItemTable3, Chance3);
end

function LootBoxAttachmentOpen()
	openBox(ItemTable4, Chance4);
end

function LootBoxClipOpen()
	openBox(ItemTable5, Chance5);
end

function LootBoxSpecialWeaponOpen()
	openBox(ItemTable6, Chance6);
end

-- Read options on start
Events.OnGameStart.Add(lootboxes.readOptions);     -- Singleplayer
Events.OnServerStarted.Add(lootboxes.readOptions); -- Multiplayer
