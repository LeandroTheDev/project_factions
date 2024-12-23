---@diagnostic disable: undefined-global
-- Get the days, hours from the OS time based in timezone
local function getCurrentTime()
	local function remainder(a, b)
		return a - math.floor(a / b) * b;
	end
	local tm          = {};
	local daysInMonth = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
	local minutes, hours, days, year, month;
	local dayOfWeek;
	local seconds     = getTimestamp() + 0 * 3600;
	-- Calculate minutes
	minutes           = math.floor(seconds / 60);
	seconds           = seconds - (minutes * 60);
	-- Calculate hours
	hours             = math.floor(minutes / 60);
	minutes           = minutes - (hours * 60);
	-- Calculate days
	days              = math.floor(hours / 24);
	hours             = hours - (days * 24);

	-- Unix time starts in 1970 on a Thursday
	year              = 1970;
	dayOfWeek         = 4;

	while true do
		local leapYear = remainder(year, 4) == 0 and (remainder(year, 100) ~= 0 or remainder(year, 400) == 0);
		local daysInYear = 365;
		if leapYear then
			daysInYear = 366;
		end

		if days >= daysInYear then
			if leapYear then
				dayOfWeek = dayOfWeek + 2;
			else
				dayOfWeek = dayOfWeek + 1;
			end
			days = days - daysInYear;
			if dayOfWeek >= 7 then
				dayOfWeek = dayOfWeek - 7;
			end
			year = year + 1;
		else
			tm.tm_yday = days;
			dayOfWeek  = dayOfWeek + days;
			dayOfWeek  = remainder(dayOfWeek, 7);
			-- Calculate the month and day

			month      = 1;
			while month <= 12 do
				local dim = daysInMonth[month];

				-- Add a day to feburary if this is a leap year
				if month == 2 and leapYear then
					dim = dim + 1;
				end

				if days >= dim then
					days = days - dim;
				else
					break;
				end
				month = month + 1;
			end
			break;
		end
	end

	tm.tm_sec  = seconds;
	tm.tm_min  = minutes;
	tm.tm_hour = hours;
	tm.tm_hour = tm.tm_hour + tonumber(SandboxVars.Factions.Timezone);
	tm.tm_mday = days + 1;
	tm.tm_mon  = month;
	tm.tm_year = year;
	tm.tm_wday = dayOfWeek;
	return tm;
end

-- Get the file instance
local fileWriter = getFileWriter("Logs/FactionsEconomyLootBox.txt", false, true);
local function logger(log)
	local time = getCurrentTime();
	-- Write the log in it
	-- fileWriter:write("[" ..
	-- 	time.tm_hour .. ":" .. time.tm_min .. " " .. time.tm_mday .. "/" .. time.tm_mon .. "] " .. log .. "\n");
	print("[" ..
		time.tm_hour .. ":" .. time.tm_min .. " " .. time.tm_mday .. "/" .. time.tm_mon .. "] " .. log .. "\n");
end

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
function LootBoxAmmoOpen(recipe, ingredients, result, player)
	-- logger(player:getUsername() .. " opened ammo box");
	openBox(ItemTable0);
end

function LootBoxClothesOpen(recipe, ingredients, result, player)
	-- logger(player:getUsername() .. " opened clothes box");
	openBox(ItemTable1);
end

function LootBoxMeleeOpen(recipe, ingredients, result, player)
	-- logger(player:getUsername() .. " opened melee box");
	openBox(ItemTable2);
end

function LootBoxWeaponOpen(recipe, ingredients, result, player)
	-- logger(player:getUsername() .. " opened weapon box");
	openBox(ItemTable3);
end

function LootBoxAttachmentOpen(recipe, ingredients, result, player)
	-- logger(player:getUsername() .. " opened attachment box");
	openBox(ItemTable4);
end

function LootBoxClipOpen(recipe, ingredients, result, player)
	-- logger(player:getUsername() .. " opened magazines box");
	openBox(ItemTable5);
end

function LootBoxSpecialWeaponOpen(recipe, ingredients, result, player)
	-- logger(player:getUsername() .. " opened special weapon box");
	openBox(ItemTable6);
end

-- Read options on start
Events.OnGameStart.Add(lootboxes.readOptions);     -- Singleplayer
Events.OnServerStarted.Add(lootboxes.readOptions); -- Multiplayer
