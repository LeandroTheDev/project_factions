---@diagnostic disable: undefined-global
if isClient() then return end;
local lootboxes = {}

-- Split the sandbox string to a valid object
-- { name = "", chance = "" }
lootboxes.split = function(stringTable)
	local result = {}
	-- Spliting the strings
	local parts = stringTable:split("/")
	-- Swipe the parts
	for i = 1, #parts, 2 do
		-- Creating the object
		table.insert(result, { name = parts[i], chance = tonumber(parts[i + 1]) })
	end
	return result
end

-- Load the variables to make the calculation
lootboxes.readOptions = function()
	local tableTmp0 = SandboxVars.FactionsEconomy.itemTable0;
	local tableTmp1 = SandboxVars.FactionsEconomy.itemTable1;
	local tableTmp2 = SandboxVars.FactionsEconomy.itemTable2;
	local tableTmp3 = SandboxVars.FactionsEconomy.itemTable3;
	local tableTmp4 = SandboxVars.FactionsEconomy.itemTable4;
	local tableTmp5 = SandboxVars.FactionsEconomy.itemTable5;
	local tableTmp6 = SandboxVars.FactionsEconomy.itemTable6;
	ItemTable0 = lootboxes.split(tableTmp0);
	ItemTable1 = lootboxes.split(tableTmp1);
	ItemTable2 = lootboxes.split(tableTmp2);
	ItemTable3 = lootboxes.split(tableTmp3);
	ItemTable4 = lootboxes.split(tableTmp4);
	ItemTable5 = lootboxes.split(tableTmp5);
	ItemTable6 = lootboxes.split(tableTmp6);
end

-- Handle the open box method
local function openBox(itemTable)
	-- Truly random by BoboDev
	local player = getPlayer();
	local item_id = nil;
	while item_id == nil do
		-- Random a item in the array
		local selectedChance = ZombRand(#itemTable) + 1;
		-- Get the item from array
		local currentItem = itemTable[selectedChance];
		-- Roll a chance, if hit them add to item
		if currentItem.chance <= (ZombRand(100) + 1) then
			item_id = currentItem.name;
		end
		-- If not repeat the process until the chance hit
	end
	player:getInventory():AddItem(item_id);
end


-- Functions called when opening a box
function LootBoxAmmoOpen()
	openBox(ItemTable0);
end

function LootBoxClothesOpen()
	openBox(ItemTable1);
end

function LootBoxMeleeOpen()
	openBox(ItemTable2);
end

function LootBoxWeaponOpen()
	openBox(ItemTable3);
end

function LootBoxAttachmentOpen()
	openBox(ItemTable4);
end

function LootBoxClipOpen()
	openBox(ItemTable5);
end

function LootBoxSpecialWeaponOpen()
	openBox(ItemTable6);
end

-- Read options on start
Events.OnGameStart.Add(lootboxes.readOptions);     -- Singleplayer
Events.OnServerStarted.Add(lootboxes.readOptions); -- Multiplayer
