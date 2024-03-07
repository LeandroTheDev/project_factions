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
								--print(i.." - "..tostring(o).." ("..tostring(o:getType())..")")

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
	local function OnServerCommand(module, command, arguments)
		-- Receives alerts from the server
		if module == "ServerSafehouse" and command == "updateSandbox" then
			-- Updating the Construction bonus points
			if arguments.ConstructionBonusPoints then
				getSandboxOptions():set("ConstructionBonusPoints", arguments.ConstructionBonusPoints)
			end
		end
	end
	Events.OnServerCommand.Add(OnServerCommand)
end
