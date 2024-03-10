---@diagnostic disable: undefined-global
-- Explanation about this file.
-- this file contains the utils features from the factions

FactionsMain = {};
FactionsMain.GUI = nil
FactionsMain.Points = 0;

-- Get the safehouse cost based in the size of it
FactionsMain.getCost = function(safehouse, offset)
	offset = offset or 0;
	return math.ceil(((safehouse:getH() - offset) * (safehouse:getW() - offset)) / 100) - 1;
end

-- Get the factions used points
FactionsMain.getUsedPoints = function(username)
	local used = 0;
	-- Get safehouses list
	local safehouses = SafeHouse.getSafehouseList();
	for i = 0, safehouses:size() - 1 do
		local safehouse = safehouses:get(i);
		-- Check if you are the owner
		if safehouse:getOwner() == username then
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
	if square then
		local status, regions = pcall(getServerSpawnRegions);
		if status and regions then
			for k1 = 1, #regions do
				for _, points in pairs(regions[k1].points) do
					for _, point in pairs(points) do
						local playerIsInSafeHouse = getCell():getGridSquare(
							point.posX:doubleValue() + point.worldX:doubleValue() * 300.0,
							point.posY:doubleValue() + point.worldY:doubleValue() * 300.0, 0.0);
						if playerIsInSafeHouse then
							local building = playerIsInSafeHouse:getBuilding();
							if building then
								local def = building:getDef();
								if square:getX() >= def:getX() and square:getX() < def:getX2() and square:getY() >= def:getY() and square:getY() < def:getY2() then
									return true;
								end
							end
						end
					end
				end
			end
		else
			print("[ERROR] getServerSpawnRegions() returned nil");
		end
	end

	return false;
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
										--print(tostring(o:getUsername()));
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
											--print("Found unknown survivor!")
											return true
										end
									elseif instanceof(o, "IsoZombie") then
										--print("Found zombie!")
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

-- Check if can be captured, return "valid" if is valid, and return a Language text is not
FactionsMain.canBeCaptured = function(square)
	-- Check if enemies is on the house or zombies
	if FactionsMain.isSomeoneInside(square, faction) then
		return getText("IGUI_Safehouse_SomeoneInside");
	end

	-- Checking if is spawnpoint
	if FactionsMain.isSpawnPoint(square) then
		return getText("IGUI_Safehouse_IsSpawnPoint");
	end

	-- Check if residential is allowed
	local flag = getServerOptions():getBoolean("SafehouseAllowNonResidential");
	if flag == false then
		if not FactionsMain.isResidential(square) then
			return getText("IGUI_Safehouse_NotHouse");
		end
	end

	return "valid";
end

-- Returns true if is your team, and false if not, also nil if not exist
FactionsMain.getSafehouseTeam = function(square)
	local safehouse = SafeHouse.getSafeHouse(square);

	if not safehouse then
		return nil
	end

	local player = getPlayer();
	local owner = safehouse:getOwner();

	if player:getUsername() == owner then
		return true
	end

	local player_faction = FactionsMain.getFaction(player:getUsername())
	local owner_faction = FactionsMain.getFaction(safehouse:getOwner())

	if player_faction == owner_faction then
		return true
	else
		return false
	end
end

-- Sync all safehouse with the members of factions
FactionsMain.syncFactionMembers = function(safehouse, player)
	-- Function to send invitiations to the safehouse for all members of the faction
	local function sendInvites(faction, username)
		for j = 0, faction:getPlayers():size() - 1 do
			local selectedPlayer = faction:getPlayers():get(j);
			if selectedPlayer ~= username and not safehouse:playerAllowed(selectedPlayer) then
				if getPlayerFromUsername(selectedPlayer) then
					sendSafehouseInvite(safehouse, player, selectedPlayer);
				end
			end
		end
	end
	local username = player:getUsername();
	local faction = FactionsMain.getFaction(username);
	-- Check if the faction exist
	if faction then
		-- Check if safehouse exist
		if safehouse then
			-- Check if you are the owner of the safehouse
			if safehouse:getOwner() == username then
				-- Send invites to the players of your factions
				sendInvites(faction, username)
			end
		else
			-- Get all safehouses
			local safehouses = SafeHouse.getSafehouseList();
			-- Swipe all safehouses
			for i = safehouses:size() - 1, 0, -1 do
				-- Get by index
				safehouse = safehouses:get(i)
				-- Check if you are the owner
				if safehouse:getOwner() == username then
					-- Send invites to the players of your factions
					sendInvites(faction, username);
				end
			end
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
	local ServerFactionCommands = {};
	local ServerFactionPoints = {};

	--Receives from server and do a command
	local function zombiesKillPoints(kills)
		local killsPoints = 0;
		if kills > 50 and kills <= 150 then
			killsPoints = 1;
		elseif kills > 150 and kills <= 200 then
			killsPoints = 2;
		elseif kills > 200 and kills <= 300 then
			killsPoints = 3;
		elseif kills > 300 and kills <= 850 then
			killsPoints = 4;
		elseif kills > 850 and kills <= 1500 then
			killsPoints = 6;
		elseif kills > 1500 and kills <= 2500 then
			killsPoints = 8;
		elseif kills > 2500 and kills <= 3500 then
			killsPoints = 10;
		elseif kills > 3500 and kills <= 5000 then
			killsPoints = 14;
		elseif kills > 5000 and kills <= 7000 then
			killsPoints = 18;
		elseif kills > 7000 and kills <= 9000 then
			killsPoints = 20;
		elseif kills > 9000 and kills <= 11000 then
			killsPoints = 22;
		elseif kills > 11000 and kills <= 13000 then
			killsPoints = 24;
		elseif kills > 13000 and kills <= 16000 then
			killsPoints = 26;
		elseif kills > 16000 and kills <= 20000 then
			killsPoints = 30;
		elseif kills > 20000 and kills <= 24000 then
			killsPoints = 32;
		elseif kills > 24000 and kills <= 28000 then
			killsPoints = 34;
		elseif kills > 28000 and kills <= 30000 then
			killsPoints = 36;
		elseif kills > 30000 and kills <= 34000 then
			killsPoints = 38;
		elseif kills > 34000 and kills <= 40000 then
			killsPoints = 40;
		elseif kills > 40000 and kills <= 50000 then
			killsPoints = 45;
		elseif kills > 50000 and kills <= 60000 then
			killsPoints = 50;
		elseif kills > 60000 and kills <= 70000 then
			killsPoints = 55;
		elseif kills > 70000 and kills <= 80000 then
			killsPoints = 60;
		elseif kills > 80000 and kills <= 90000 then
			killsPoints = 65;
		elseif kills > 90000 and kills <= 100000 then
			killsPoints = 70;
		elseif kills > 100000 and kills <= 150000 then
			killsPoints = 80;
		elseif kills > 150000 and kills <= 200000 then
			killsPoints = 90;
		elseif kills > 200000 and kills <= 250000 then
			killsPoints = 100;
		elseif kills >= 250000 then
			killsPoints = 110;
		end
		return killsPoints
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

		-- Add new datas
		ServerFactionPoints[playerFaction:getName()]["zombieKills"] = ServerFactionPoints[playerFaction:getName()]
			["zombieKills"] + args.quantity;
		ServerFactionPoints[playerFaction:getName()]["points"] = zombiesKillPoints(ServerFactionPoints
			[playerFaction:getName()]["zombieKills"]);

		-- Send players from factions the new updated points
		for i = playerFaction:getPlayers():size() - 1, 0, -1 do
			local member = playerFaction:getPlayers():get(i)
			sendServerCommand(member, "ServerFactionPoints", "receivePoints",
				{ points = ServerFactionPoints[playerFaction:getName()]["points"] });
		end
	end

	-- Get factions points
	function ServerFactionCommands.getPoints(module, command, player, args)
		-- Receive player faction
		local playerFaction = FactionsMain.getFaction(player:getUsername())

		-- Check if player has faction
		if playerFaction == nil then
			return
		end

		-- Null Check
		if ServerFactionPoints[playerFaction:getName()] == nil then ServerFactionPoints[playerFaction:getName()] = {} end
		if ServerFactionPoints[playerFaction:getName()]["zombieKills"] == nil then ServerFactionPoints[playerFaction:getName()]["zombieKills"] = 0 end
		if ServerFactionPoints[playerFaction:getName()]["points"] == nil then ServerFactionPoints[playerFaction:getName()]["points"] = 0 end

		-- Send the datas
		sendServerCommand(player, "ServerFactionPoints", "receivePoints",
			{ points = ServerFactionPoints[playerFaction:getName()]["points"] });
	end

	--Remove os pontos da facção
	function ServerFactionCommands.removeFaction(module, command, player, args)
		print("[Factions] Faction " .. args.factionName .. " is been deleted by: " .. player:getUsername())
		ServerFactionPoints[args.factionName] = nil;
	end

	--Load Mod Data
	Events.OnInitGlobalModData.Add(function(isNewGame)
		ServerFactionPoints = ModData.getOrCreate("ServerFactionPoints");
		if not ServerFactionPoints then ServerFactionPoints = {}; end
	end)

	--Receives Commands from Clients
	Events.OnClientCommand.Add(function(module, command, player, args)
		if module == "ServerFactionPoints" and ServerFactionCommands[command] then
			ServerFactionCommands[command](module, command, player, args)
		end
	end)
end
