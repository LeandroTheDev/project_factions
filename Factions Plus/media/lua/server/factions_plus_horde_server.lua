---@diagnostic disable: undefined-global, deprecated
if isClient() then return end

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
local fileWriter = getFileWriter("Logs/FactionsPlusHordes.txt", true, false);
local function logger(log)
	local time = getCurrentTime();
	-- Write the log in it
	fileWriter:write("[" ..
		time.tm_min .. ":" .. time.tm_hour .. " " .. time.tm_mday .. "/" .. time.tm_mon .. "] " .. log .. "\n");

	-- Close the file
	fileWriter:close();
end

--#region lua utils
local function stringToList(str)
	local list = {}
	for item in string.gmatch(str, "([^/]+)") do
		table.insert(list, item)
	end
	return list
end
--#endregion

-- Performance variavels
local tickBeforeNextZed = 10; -- Ticks to spawn a zed
local actualTick = 0;         -- Actual server tick used with tickBeforeNextZed

-- This is all the zombies that should spawn when calling the smoke flare
local zombieOutfitTable = stringToList(SandboxVars.FactionsPlus.HordeCommonZombies);

-- This is the rare zombies
local zombieRareOutfitTable = stringToList(SandboxVars.FactionsPlus.HordeRareZombies);

local playerZombie = {}; -- Para hordas aleatorias

--
-- #region Random Horders
--

-- Check if its time to start any random horde
function CheckRandomHordes()
	-- Getting the frequency chance
	local chance = SandboxVars.FactionsPlus.HordeNightFrequency * 100

	-- Checking the chance
	if ZombRand(100) + 1 <= chance then
		-- Starting the random horde
		StartRandomHorde();
	else
		logger("Random horde check no");
		SpecialLocationHordeCheck();
	end
end

-- Start the horde, if specificPlayer was added, then the horde will start only for him
function StartRandomHorde(specificPlayer)
	-- Verifying if single player
	if specificPlayer then
		-- Random number between +50% -50%
		local zombieCount = SandboxVars.FactionsPlus.HordeNightBaseQuantity * ((ZombRand(150) / 100) + 0.5);

		-- Getting difficulty
		local difficulty
		if SandboxVars.FactionsPlus.HordeNightBaseQuantity > zombieCount then
			difficulty = "Easy";
		else
			difficulty = "Hard";
		end

		-- Adding it to the horde table
		playerBeacons[specificPlayer:getUsername()] = {};
		playerBeacons[specificPlayer:getUsername()]["zombieCount"] = zombieCount;
		playerBeacons[specificPlayer:getUsername()]["zombieSpawned"] = 0;
		playerBeacons[specificPlayer:getUsername()]["player"] = specificPlayer;
		playerBeacons[specificPlayer:getUsername()]["airdropArea"] = {
			x = specificPlayer:getX(),
			y = specificPlayer:getY(),
			z =
				specificPlayer:getZ()
		};

		-- Send alert to the player
		sendServerCommand(specificPlayer, "ServerHorde", "alert", { difficulty = difficulty });

		logger("Unique Horde spawning on: " .. specificPlayer:getUsername() .. " Quantity: " .. zombieCount)

		-- Adicionamos o OnTick para spawnar os zumbis
		Events.OnTick.Add(CheckHordeRemainingForSpecificHorde);
	else -- All players online
		local players = getOnlinePlayers();
		-- Swipe all onlien players
		for i = 0, players:size() - 1 do
			-- Getting the player by the index
			local player = players:get(i)
			-- Random number between +50% -50%
			local zombieCount = SandboxVars.FactionsPlus.HordeNightBaseQuantity * ((ZombRand(150) / 100) + 0.5);

			-- Getting difficulty
			local difficulty
			if SandboxVars.FactionsPlus.HordeNightBaseQuantity > zombieCount then
				difficulty = "Easy";
			else
				difficulty = "Hard";
			end

			-- Adding it to the horde table
			playerZombie[player:getUsername()] = {};
			playerZombie[player:getUsername()]["zombieCount"] = zombieCount;
			playerZombie[player:getUsername()]["zombieSpawned"] = 0;
			playerZombie[player:getUsername()]["player"] = player;

			-- Send alert to the player
			sendServerCommand(player, "ServerHorde", "alert", { difficulty = difficulty });

			logger("All players Horde spawning on: " .. specificPlayer:getUsername() .. " quantity: " .. zombieCount);
		end

		-- Adding the tick event to spawn zombies
		Events.OnTick.Add(CheckHordeRemaining);
	end
end

-- Add a single zombie to the player
function SpawnOneZombie(player, isSingleHorde)
	local pLocation = player:getCurrentSquare();
	local zLocationX = 0;
	local zLocationY = 0;
	local canSpawn = false;
	local sandboxDistance = SandboxVars.FactionsPlus.HordeZombieSpawnDistance;
	for i = 0, 100 do
		if ZombRand(2) == 0 then
			zLocationX = ZombRand(10) - 10 + sandboxDistance;
			zLocationY = ZombRand(sandboxDistance * 2) - sandboxDistance;
			if ZombRand(2) == 0 then
				zLocationX = 0 - zLocationX;
			end
		else
			zLocationY = ZombRand(10) - 10 + sandboxDistance;
			zLocationX = ZombRand(sandboxDistance * 2) - sandboxDistance;
			if ZombRand(2) == 0 then
				zLocationY = 0 - zLocationY;
			end
		end
		zLocationX = zLocationX + pLocation:getX();
		zLocationY = zLocationY + pLocation:getY();
		local spawnSpace = getWorld():getCell():getGridSquare(zLocationX, zLocationY, 0);
		if spawnSpace then
			local isSafehouse = SafeHouse.getSafeHouse(spawnSpace);
			if spawnSpace:isSafeToSpawn() and spawnSpace:isOutside() and isSafehouse == nil then
				canSpawn = true;
				break
			end
		else
			logger("[Spawning] Space not Loaded for " .. player:getUsername());
		end
		if i == 100 then
			logger("[Spawning] can't find a place to spawn " .. player:getUsername());
		end
	end
	if canSpawn then
		-- Getting the zombie rarity
		local outfit
		if ZombRand(100) + 1 == 1 then
			outfit = zombieRareOutfitTable[ZombRand(#zombieRareOutfitTable) + 1];
		else
			outfit = zombieOutfitTable[ZombRand(#zombieOutfitTable) + 1];
		end
		-- Adding the zombie
		addZombiesInOutfit(zLocationX, zLocationY, 0, 1, outfit, 50, false, false, false, false, 1.5);
		-- Checking if is single horde spawn
		if isSingleHorde then
			-- Adding one more to the zombie table spawned
			playerBeacons[player:getUsername()]["zombieSpawned"] = playerBeacons[player:getUsername()]["zombieSpawned"] +
				1;
		else
			-- Adding one more to the zombie table spawned
			playerZombie[player:getUsername()]["zombieSpawned"] = playerZombie[player:getUsername()]["zombieSpawned"] + 1;
		end
		-- Adding a sound to the zombie follow the player
		getWorldSoundManager():addSound(player, player:getCurrentSquare():getX(),
			player:getCurrentSquare():getY(), player:getCurrentSquare():getZ(), 200, 10);
	end
end

-- Checking if horde is over
function CheckHordeRemaining()
	-- Getting all online players
	local players = getOnlinePlayers();
	-- Players exited
	local playersLogout = {};
	-- Updating the tickrate
	if actualTick <= tickBeforeNextZed then
		actualTick = actualTick + 1;
		return
	end
	actualTick = 0;

	-- Swipe to verify if all zombies has already spawned to the player
	local allZombiesSpawned = true;
	local jumpPlayer = {}; -- Object with name of the user and a boolean indicating if need to jump {"test1" = true, "test2" = false}
	for playerUsername, playerSpawns in pairs(playerZombie) do
		-- Checking if player spawned everthing
		if playerSpawns.zombieSpawned < playerSpawns.zombieCount then
			-- Player cannot jump the spawnzombie function
			jumpPlayer[playerUsername] = false;
			allZombiesSpawned = false;

			-- Checking players logout
			local logout = true;
			for i = 0, players:size() - 1 do
				-- Getting player index
				local player = players:get(i)
				-- verifying if exist
				if player:getUsername() == playerUsername then
					logout = false;
					break;
				end
			end
			if logout then
				logger(playerUsername " logout during horde!!");
				table.insert(playersLogout, playerSpawns.player);
			end
		else
			-- In that case he can skip the zombiespawn function
			jumpPlayer[playerUsername] = true;
		end
	end

	-- Disposing this event when all zombies has spawned
	if allZombiesSpawned then
		-- Resetamos as Variaveis
		Events.OnTick.Remove(CheckHordeRemaining);
		playerZombie = {};
		logger("Horde is over for now...");
		return
	end

	-- In this case we are going to spawn zombies to all players that need to be spawned
	for i = 0, players:size() - 1 do
		-- Getting the player by index
		local player = players:get(i)
		-- Checking if need to skip the player
		if not jumpPlayer[player:getUsername()] then
			-- Checking if is admin
			if player:getAccessLevel() ~= "None" then
				-- If is ignore
				playerZombie[player:getUsername()]["zombieSpawned"] = 9999;
				logger("Ignoring " .. player:getUsername() .. " because he is admin");
				return;
			end
			-- Spawning zombie
			SpawnOneZombie(player);
		end
	end

	-- Check for players that logout
	-- and continue spawning the zombies haha
	if #playersLogout > 0 then
		for i = 1, #playersLogout do
			SpawnOneZombie(playersLogout[i]);
		end
	end
end

Events.EveryHours.Add(CheckRandomHordes);

--
-- #endregion
--

--
-- #region Specific location hordes
--

-- Store all special locations to spawn horde
local specialLocationCoordinates = {}

-- Read airdrop positions from Lua file
local function readHordeSpecialLocationsPositions()
	logger("[Reading] Loading horde special positions...")
	local fileReader = getFileReader("HordeSpecialPositions.ini", true);
	local lines = {}
	local line = fileReader:readLine()
	while line do
		table.insert(lines, line)
		line = fileReader:readLine()
	end
	fileReader:close();
	specialLocationCoordinates = loadstring(table.concat(lines, "\n"))() or {}
	logger("[Reading] Success loaded horde special positions!");
end

-- Check if the player is inside of special location
local function checkPlayerInSpecialLocation(playerX, playerY)
	-- Swipe all special locations available
	for i = 1, #specialLocationCoordinates do
		local specialLocation = specialLocationCoordinates[i]
		-- Verifying every side of the square if the player is inside it
		local topLeft = playerX > specialLocation.topLeft.x and playerY > specialLocation.topLeft.y;
		local bottomLeft = playerX > specialLocation.bottomLeft.x and playerY < specialLocation.bottomLeft.y;
		local topRight = playerX < specialLocation.topRight.x and playerY > specialLocation.topRight.y;
		local bottomRight = playerX < specialLocation.bottomRight.x and playerY < specialLocation.bottomRight.y;
		-- Verify if he is inside of all squares
		if topLeft and bottomLeft and topRight and bottomRight then
			return true
		end
	end
	return false;
end

-- Start special horde for the player inside the special locations
function StartSpecialHorde()
	-- Getting the player list
	local players = getOnlinePlayers();
	-- Swiping all online players
	local isEmpty = true;
	for i = 0, players:size() - 1 do
		-- Getting the player index
		local player = players:get(i);
		-- Checking if the player is inside the square
		if checkPlayerInSpecialLocation(player:getX(), player:getY()) then
			-- Random difficulty
			local zombieCount = SandboxVars.FactionsPlus.SpecialHordeNightBaseQuantity * ((ZombRand(150) / 100) + 0.5) *
				2;

			-- Getting the difficulty
			local difficulty
			if SandboxVars.FactionsPlus.SpecialHordeNightBaseQuantity * 2 > zombieCount then
				difficulty = "Hard";
			else
				difficulty = "Insane";
			end

			-- Adding player to the table
			playerZombie[player:getUsername()] = {};
			playerZombie[player:getUsername()]["zombieCount"] = zombieCount;
			playerZombie[player:getUsername()]["zombieSpawned"] = 0;
			playerZombie[player:getUsername()]["player"] = player;

			-- Sending any alert to the player
			sendServerCommand(player, "ServerHorde", "alert", { difficulty = difficulty });

			logger("Special Horde spawning on: " .. player:getUsername() .. " quantity: " .. zombieCount)
			isEmpty = false;
		end
	end
	-- Checking if theres is players to spawn zombies
	if not isEmpty then
		-- Tick for spawning the zombies
		Events.OnTick.Add(CheckHordeRemaining);
	else
		logger("No players in special locations to spawn a horde... :(");
	end
end

-- This functions is called when the global horde check is false
-- this will check for special locations hordes
function SpecialLocationHordeCheck()
	local chance = SandboxVars.FactionsPlus.SpecialHordeNightFrequency * 100
	-- Checking the chance
	if ZombRand(100) + 1 <= chance then
		StartSpecialHorde();
	else
		logger("Special location checked no");
	end
end

-- Loading data
Events.OnInitGlobalModData.Add(function(isNewGame)
	readHordeSpecialLocationsPositions();
end)

---
--- #endregion
---
