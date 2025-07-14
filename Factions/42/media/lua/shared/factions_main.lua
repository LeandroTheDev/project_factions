---@diagnostic disable: undefined-global
FactionsCompatibility = true;
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
-- local fileWriter = getFileWriter("Logs/Factions.txt", false, true);
local function logger(log)
	local time = getCurrentTime();
	-- Write the log in it
	-- fileWriter:write("[" ..
	-- 	time.tm_hour .. ":" .. time.tm_min .. " " .. time.tm_mday .. "/" .. time.tm_mon .. "] " .. log .. "\n");
	print("[" ..
		time.tm_hour .. ":" .. time.tm_min .. " " .. time.tm_mday .. "/" .. time.tm_mon .. "-Factions] " .. log .. "\n");
end
-- Explanation about this file.
-- this file contains the utils features from the factions

FactionsMain = {};
FactionsMain.GUI = nil
FactionsMain.Points = 0;

local function tableFormat(tabela, nivel)
	nivel = nivel or 0
	local prefixo = string.rep("  ", nivel) -- Espaços para recuo
	if type(tabela) == "table" then
		local str = "{\n"
		for chave, valor in pairs(tabela) do
			str = str .. prefixo .. "  [" .. tostring(chave) .. "] = "
			if type(valor) == "table" then
				str = str .. tableFormat(valor, nivel + 1) .. ",\n"
			else
				str = str .. tostring(valor) .. ",\n"
			end
		end
		str = str .. prefixo .. "}"
		return str
	else
		return tostring(tabela)
	end
end

-- Get the safehouse cost based in the size of it
FactionsMain.getCost = function(safehouse, offset)
	offset = offset or 0;
	return math.ceil(((safehouse:getH() - offset) * (safehouse:getW() - offset)) / 100) - 1;
end

-- Get the factions used points
FactionsMain.getUsedPoints = function(username)
	local playerFaction = FactionsMain.getFaction(username);
	-- Check if player doesnt have factions
	if playerFaction == nil then return 0; end

	local factionOwner = playerFaction:getOwner();

	local used = 0;
	-- Get safehouses list
	local safehouses = SafeHouse.getSafehouseList();
	for i = 0, safehouses:size() - 1 do
		local safehouse = safehouses:get(i);
		-- Check if you are the owner
		if safehouse:getOwner() == factionOwner then
			-- Get the cost of this safehouse
			local value = FactionsMain.getCost(safehouse, 4);
			-- Increment the used value
			if value < 1 then
				value = 1;
			end
			used = used + value;
		end
	end
	return used;
end

-- Get the faction from a username
FactionsMain.getFaction = function(username)
	-- Get all factions from the server
	local factions = Faction.getFactions();
	for i = 0, factions:size() - 1 do
		local faction = factions:get(i);
		-- If the player is the owner simple return the faction
		if faction:isOwner(username) then
			return faction;
		end
		local players = faction:getPlayers();
		-- If not we swipe the players in faction and see if the actual player is on it
		for j = 0, players:size() - 1 do
			local player = players:get(j);
			if player == username then
				return faction;
			end
		end
	end
	return nil;
end

-- Check if is spawnpoint
FactionsMain.isSpawnPoint = function(square)
	if not square then
		print("[DEBUG] square is nil.")
		return false
	end

	local status, regions = pcall(getServerSpawnRegions)
	if not status or not regions then
		print("[ERROR] getServerSpawnRegions() failed or returned nil. Are you in singleplayer?")
		logger("[ERROR] getServerSpawnRegions() failed or returned nil. Are you in singleplayer?")
		return false
	end

	for regionIndex, region in ipairs(regions) do
		if not region.points then
			print("[WARNING] region.points is nil for region index:", regionIndex)
		else
			for pointIndex, point in ipairs(region.points) do
				if not (point.posX and point.posY and point.worldX and point.worldY) then
					print(string.format(
						"[ERROR] Invalid point structure at region %d, point %d. point = %s",
						regionIndex, pointIndex, tostring(point)
					))
				else
					local gx = point.posX:doubleValue() + point.worldX:doubleValue() * 300.0
					local gy = point.posY:doubleValue() + point.worldY:doubleValue() * 300.0
					local gridSquare = getCell():getGridSquare(gx, gy, 0)

					if not gridSquare then
						print(string.format(
							"[WARNING] getGridSquare returned nil at x=%d y=%d",
							gx, gy
						))
					else
						local building = gridSquare:getBuilding()
						if not building then
							print(string.format(
								"[INFO] No building found at x=%d y=%d", gx, gy
							))
						else
							local def = building:getDef()
							if square:getX() >= def:getX() and square:getX() < def:getX2()
								and square:getY() >= def:getY() and square:getY() < def:getY2() then
								print(string.format(
									"[DEBUG] Square is inside building at spawn region %d, point %d",
									regionIndex, pointIndex
								))
								return true
							end
						end
					end
				end
			end
		end
	end

	print("[DEBUG] Square is not inside any spawn region.")
	return false
end

-- Get floor count
FactionsMain.getFloorCount = function(def)
	local level = 0;
	if def then
		local rooms = def:getRooms();
		if rooms then
			for i = 0, rooms:size() - 1 do
				local room = rooms:get(i);
				local z = room:getZ();
				if z > level then
					level = z;
				end
			end
		end
	end
	return level;
end

-- Check if someone is inside
FactionsMain.isSomeoneInside = function(square, faction, level)
	-- If player doesnt have a faction simple return
	if not faction then
		return nil;
	end
	-- Check if square is valid
	if square then
		local building = square:getBuilding();
		if building then
			local def = building:getDef();
			local leader = faction:getOwner();
			if not level then
				level = FactionsMain.getFloorCount(def);
			end
			local x = def:getX() - 2;
			while x < (def:getX2() + 2) do
				x = x + 1;
				local y = def:getY() - 2;
				while y < def:getY2() + 2 do
					y = y + 1;
					local z = 0;
					while z < level do
						local _square = getCell():getGridSquare(x, y, z);
						if _square then
							for i = 0, _square:getMovingObjects():size() - 1 do
								local o = _square:getMovingObjects():get(i);

								if not o:getSquare():getProperties():Is(IsoFlagType.exterior) and o:getBuilding() then
									if instanceof(o, "IsoPlayer") then
										local member = false;

										for j = 0, faction:getPlayers():size() - 1 do
											local player = faction:getPlayers():get(j);
											if player == o:getUsername() then
												member = true;
												break
											end
										end

										if leader == o:getUsername() then
											member = true;
										end

										if not member then
											return true
										end
									elseif instanceof(o, "IsoZombie") then
										return true
									end
								end
							end
						end
						z = z + 1
					end
				end
			end
		end
	end

	return false
end

-- Check if is residential
FactionsMain.isResidential = function(square)
	local residential = false;
	if square then
		local building = square:getBuilding();
		if building then
			local has_kitchen, has_bedroom, has_bathroom;
			local rooms = building:getDef():getRooms();
			for i = 0, rooms:size() - 1 do
				local room = rooms:get(i);
				if room:getName() == "kitchen" then
					has_kitchen = true;
				elseif room:getName() == "bathroom" then
					has_bathroom = true;
				elseif room:getName() == "bedroom" or room:getName() == "livingroom" then
					has_bedroom = true;
				end
			end
			residential = has_bathroom and (has_kitchen or has_bedroom);
		end
	end

	return residential;
end

-- Returns true if is your team, and false if not, also nil if not exist
FactionsMain.isSafehouseFromTeam = function(square, player)
	local safehouse = SafeHouse.getSafeHouse(square);

	if not safehouse then
		return nil
	end

	local owner = safehouse:getOwner();

	-- Verify if the player is thhe owner
	if player:getUsername() == owner then
		return true;
	end

	-- Getting the faction owner username
	local owner_faction = FactionsMain.getFaction(safehouse:getOwner())

	-- If the faction owner is the same as safehouse owner
	if owner == owner_faction then
		return true;
	else
		return false;
	end
end

-- Sync all safehouse with the members of factions
FactionsMain.syncFactionMembers = function(safehouse)
	if not safehouse then return end;

	local ownerPlayer = getPlayerFromUsername(safehouse:getOwner());
	if not ownerPlayer then return end;

	local faction = FactionsMain.getFaction(safehouse:getOwner());

	-- Check if the faction exist
	if not faction then return end;

	for j = 0, faction:getPlayers():size() - 1 do
		local selectedPlayer = faction:getPlayers():get(j);
		if selectedPlayer and not safehouse:playerAllowed(selectedPlayer) then
			if getPlayerFromUsername(selectedPlayer) then
				sendSafehouseInvite(safehouse, ownerPlayer, selectedPlayer);
			end
		end
	end
end

-- Remove all members of safehouse
FactionsMain.safehouseRemoveMembers = function(safehouse)
	if safehouse then
		local players = safehouse:getPlayers();
		for i = 0, players:size() - 1 do
			local playerName = players:get(i);
			safehouse:removePlayer(playerName);
		end
	end
end

if isClient() then
	-- Last updated zombie kill
	local lastZombieKills;
	-- Actually zombie kills
	local actualZombieKills;

	--Receives from server and do a command
	local function OnServerCommand(module, command, arguments)
		--Receive Points from Server
		if module == "ServerFactionPoints" and command == "receivePoints" then
			FactionsMain.Points = arguments.points
		end
		-- Receives the new sandbox options
		if module == "ServerSafehouse" and command == "updateSandbox" then
			-- Updating the Construction bonus points
			if arguments.ConstructionBonusPoints then
				getSandboxOptions():set("ConstructionBonusPoints", arguments.ConstructionBonusPoints)
			end
		end
	end

	--Se o zumbi for morto então envie uma mensagem ao servidor
	local function CheckLastKills()
		local player = getPlayer()
		--Check nulls
		if lastZombieKills == nil then lastZombieKills = player:getZombieKills() end
		--Get Actual Zombie Kills
		actualZombieKills = player:getZombieKills()
		--Check if last kills is lower than actual kills
		if lastZombieKills < actualZombieKills then
			local quantity = actualZombieKills - lastZombieKills
			--Check if quantity is lower than 0
			if quantity < 0 then
				lastZombieKills = 0
				return
			end
			--Communicate the server
			sendClientCommand("ServerFactionPoints", "killedZombie", { quantity = quantity });
			--Reset Last Zombie Kills
			lastZombieKills = actualZombieKills
		end
		--Get Points Again
		sendClientCommand("ServerFactionPoints", "getPoints", nil)
	end

	--Check if player getkill changed
	Events.EveryOneMinute.Add(CheckLastKills)
	Events.OnServerCommand.Add(OnServerCommand)

	sendClientCommand("ServerFactionPoints", "getPoints", nil)
end

if isServer() then
	-- The functions with client and server communication is stored here
	local ServerFactionCommands = {};
	-- Used to store the factions points, auto save in moddata if changed,
	-- this is a list of the faction names that contains a object:
	-- [
	--		"Test Factions": {
	--			"zombieKills": 100, # Total factions zombie kills
	--			"points": 10, # This cannot be changed, its calculated by the faction kill
	--			"specialPoints": 2, # Used to increase faction points without using the "points"
	-- 		}
	-- ]
	ServerFactionPoints = {};

	--Receives from server and do a command
	local function zombiesKillPoints(kills)
		local killsPoints = 0;

		-- Converts the sandbox to a readable table
		local configuration = {}
		for pair in string.gmatch(SandboxVars.Factions.PointsPerZombieKills, "([^;]+)") do
			local zombieToKill, pointsToReceive = string.match(pair, "(%d+)=(%d+)");
			-- Converting to number
			zombieToKill = tonumber(zombieToKill);
			pointsToReceive = tonumber(pointsToReceive);

			-- Finished
			if not zombieToKill and not pointsToReceive then
				break;
			end

			-- Inserting into the configuration table
			table.insert(configuration, { zombieToKill = zombieToKill, pointsToReceive = pointsToReceive });
		end

		-- Swipe all configurations files to receive the exact kill points
		for i = 1, #configuration do
			-- If you have more kills than the configuration
			if kills >= configuration[i].zombieToKill then
				-- Add the points to the final result
				killsPoints = configuration[i].pointsToReceive;
			else -- If not
				-- Receive the actual points from the swipe
				break;
			end
		end

		-- logger("---------------------------");
		-- logger("function: zombiesKillPoints");
		-- logger("Kills: " .. kills);
		-- logger("Configuration: ");
		-- logger(tableFormat(configuration));
		-- logger("---------------------------");

		return killsPoints;
	end

	-- Zombie Kill
	function ServerFactionCommands.killedZombie(module, command, player, args)
		-- Get Player faction
		local playerFaction = FactionsMain.getFaction(player:getUsername());

		-- Check if player doesnt have a faction
		if playerFaction == nil then
			return
		end

		-- Null Check
		if ServerFactionPoints[playerFaction:getName()] == nil then ServerFactionPoints[playerFaction:getName()] = {} end
		if ServerFactionPoints[playerFaction:getName()]["zombieKills"] == nil then ServerFactionPoints[playerFaction:getName()]["zombieKills"] = 0 end
		if ServerFactionPoints[playerFaction:getName()]["points"] == nil then ServerFactionPoints[playerFaction:getName()]["points"] = 0 end
		if ServerFactionPoints[playerFaction:getName()]["specialPoints"] == nil then ServerFactionPoints[playerFaction:getName()]["specialPoints"] = 0 end

		-- Add new datas
		ServerFactionPoints[playerFaction:getName()]["zombieKills"] = ServerFactionPoints[playerFaction:getName()]
			["zombieKills"] + args.quantity;
		ServerFactionPoints[playerFaction:getName()]["points"] = zombiesKillPoints(ServerFactionPoints
			[playerFaction:getName()]["zombieKills"]) + ServerFactionPoints[playerFaction:getName()]["specialPoints"];

		-- logger("---------------------------");
		-- logger("function: ServerFactionCommands.killedZombie");
		-- logger(player:getUsername());
		-- logger("Zombie kills: " .. ServerFactionPoints[playerFaction:getName()]["zombieKills"]);
		-- logger("Points: " .. ServerFactionPoints[playerFaction:getName()]["points"]);
		-- logger("Special Points: " .. ServerFactionPoints[playerFaction:getName()]["specialPoints"]);
		-- logger("---------------------------");

		-- Send players from factions the new updated points
		local onlinePlayers = getOnlinePlayers();
		for i = playerFaction:getPlayers():size() - 1, 0, -1 do
			-- Swipe online players
			for j = 1, onlinePlayers:size() do
				-- Get the actual player
				local selectedPlayer = onlinePlayers:get(j - 1);
				local memberUsername = playerFaction:getPlayers():get(i);
				-- Check if faction player is the same as the swiped player
				if selectedPlayer:getUsername() == memberUsername then
					-- Refresh player points
					sendServerCommand(selectedPlayer, "ServerFactionPoints", "receivePoints",
						{ points = ServerFactionPoints[playerFaction:getName()]["points"] });
					break;
				end
			end
		end
	end

	-- Get factions points
	function ServerFactionCommands.getPoints(module, command, player, args)
		-- Receive player faction
		local playerFaction = FactionsMain.getFaction(player:getUsername());

		-- Check if player has faction
		if playerFaction == nil then
			return;
		end

		-- Null Check
		if ServerFactionPoints[playerFaction:getName()] == nil then ServerFactionPoints[playerFaction:getName()] = {} end
		if ServerFactionPoints[playerFaction:getName()]["zombieKills"] == nil then ServerFactionPoints[playerFaction:getName()]["zombieKills"] = 0 end
		if ServerFactionPoints[playerFaction:getName()]["points"] == nil then ServerFactionPoints[playerFaction:getName()]["points"] = 0 end
		if ServerFactionPoints[playerFaction:getName()]["specialPoints"] == nil then ServerFactionPoints[playerFaction:getName()]["specialPoints"] = 0 end

		-- Send the datas
		sendServerCommand(player, "ServerFactionPoints", "receivePoints",
			{
				points = ServerFactionPoints[playerFaction:getName()]["points"] +
					ServerFactionPoints[playerFaction:getName()]["specialPoints"]
			});
	end

	-- Add special points
	function ServerFactionCommands.addSpecialPoints(module, command, player, args)
		-- Receive player faction
		local playerFaction = FactionsMain.getFaction(player:getUsername())

		-- Check if player has faction
		if playerFaction == nil then
			return;
		end

		if args.quantity then
			if ServerFactionPoints[playerFaction:getName()]["specialPoints"] == nil then ServerFactionPoints[playerFaction:getName()]["specialPoints"] = 0 end
			ServerFactionPoints[playerFaction:getName()]["specialPoints"] = ServerFactionPoints[playerFaction:getName()]
				["specialPoints"] + args.quantity;
		else
			logger("[ERROR] Cannot add points from " .. player:getUsername() .. " factions, the quantity is nil");
		end
	end

	-- Remove special points
	function ServerFactionCommands.removeSpecialPoints(module, command, player, args)
		-- Receive player faction
		local playerFaction = FactionsMain.getFaction(player:getUsername())

		-- Check if player has faction
		if playerFaction == nil then
			return;
		end

		if args.quantity then
			if ServerFactionPoints[playerFaction:getName()]["specialPoints"] == nil then ServerFactionPoints[playerFaction:getName()]["specialPoints"] = 0 end
			ServerFactionPoints[playerFaction:getName()]["specialPoints"] = ServerFactionPoints[playerFaction:getName()]
				["specialPoints"] - args.quantity;
			-- Negative treatment
			if ServerFactionPoints[playerFaction:getName()]["specialPoints"] < 0 then
				ServerFactionPoints[playerFaction:getName()]["specialPoints"] = 0
			end
		else
			logger("[ERROR] Cannot remove points from " ..
				player:getUsername() .. " factions, the quantity is nil");
		end
	end

	-- Remove factions data
	function ServerFactionCommands.removeFaction(module, command, player, args)
		logger("[Factions] Faction " .. args.factionName .. " is been deleted by: " .. player:getUsername())
		ServerFactionPoints[args.factionName] = nil;
	end

	-- Load Mod Data
	Events.OnInitGlobalModData.Add(function(isNewGame)
		ServerFactionPoints = ModData.getOrCreate("ServerFactionPoints");
		if not ServerFactionPoints then ServerFactionPoints = {}; end
	end)

	-- Receives Commands from Clients
	Events.OnClientCommand.Add(function(module, command, player, args)
		if module == "ServerFactionPoints" and ServerFactionCommands[command] then
			ServerFactionCommands[command](module, command, player, args)
		end
	end)
end
