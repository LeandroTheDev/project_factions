---@diagnostic disable: undefined-global

-- Explanation about this file.
-- this file contains the serverside treatment for handling the capture system

local factions = {}
local FactionsCommands = {};
local ServerSafehouseData = {};

-- Default Values
factions.Timezone = 0;
factions.Start = 20
factions.End = 21
factions.Days = {};
factions.ResetData = false;

-- Simple read the Sandbox options
factions.readOptions = function()
	factions.Start = SandboxVars.Factions.TimeToEnableCapture;
	factions.End = SandboxVars.Factions.TimeToDisableCapture;
	factions.Timezone = SandboxVars.Factions.Timezone;
	local stringDays = SandboxVars.Factions.DaysOfWeek;
	-- Swipe the days into a variable
	for day in string.gmatch(stringDays, "%d+") do
		-- Get the day number
		local dayNumber = tonumber(day);
		table.insert(factions.Days, dayNumber);
	end

	print("[Factions] Fully Started")
end

-- Returns a boolean based on the parameter actualDay and enabled Days from factions
factions.checkDay = function(actualDay)
	-- Swipe the Days array
	for _, day in ipairs(factions.Days) do
		-- Check if days exist in the array
		if day == actualDay then
			return true
		end
	end
	return false
end

-- Check if capture is enabled, returns true if is enabled, false for not enabled
-- ServerSafehouseData is automatically reseted by this function
factions.checkIfCaptureIsEnabled = function()
	local currentTime = GetCurrentTime(factions.Timezone);
	-- Check if is not time to capture
	if (currentTime.tm_hour >= factions.End or currentTime.tm_hour < factions.Start) then
		factions.ResetData = true;
		return false
	else
		-- Check if is day for capture
		if factions.checkDay(currentTime.tm_wday) then
			-- Reset Data if necessary
			if factions.ResetData then ServerSafehouseData = {} else factions.ResetData = false end
			return true
		end
		factions.ResetData = true;
		return false
	end
end

-- Factions Commands

-- Capture empty safehouse
function FactionsCommands.captureEmptySafehouse(module, command, player, args)
	local safehouse = SafeHouse.getSafeHouse(player:getSquare());
	local playerFaction = FactionsMain.getFaction(player:getUsername());
	-- Check if safehouse is valid and player has a faction
	if safehouse == nil or playerFaction == nil then
		print("[Server] " .. player:getUsername() .. " faction or safehous invalid")
		return
	end
	safehouse:setOwner(playerFaction:getOwner());
	--Updating new safehouse
	FactionsMain.syncFactionMembers(safehouse, player);
	safehouse:syncSafehouse();
	-- Send the client he needs to sync too
	sendServerCommand(player, "ServerSafehouse", "syncCapturedSafehouse", { validation = true });
end

-- Capturing the enemy safehouse
function FactionsCommands.captureSafehouse(module, command, player, args)
	if not factions.checkIfCaptureIsEnabled() then
		print("[Factions] " .. player:getUsername() .. " is trying to capture a safehouse before the invasion time")
		sendServerCommand(player, "ServerSafehouse", "receiveCaptureConfirmation", { validation = false });
		return
	end
	local playerCapturing = player:getUsername();
	local playerFaction = FactionsMain.getFaction(playerCapturing);
	local playerLocation = player:getSquare();
	local safehouseBeenCaptured = SafeHouse.getSafeHouse(playerLocation);
	local safehouseLocation = {
		X = safehouseBeenCaptured:getX(),
		Y = safehouseBeenCaptured:getY(),
	}

	-- Check if player doesnt have factions
	if playerFaction == nil then
		sendServerCommand(player, "ServerSafehouse", "receiveCaptureConfirmation", { validation = false });
	end

	local safehouseBeenCaptureOwner = safehouseBeenCaptured:getOwner();
	--Verify if tables exist
	if ServerSafehouseData["SafehousePlayersCaptureBlock"] == nil then ServerSafehouseData["SafehousePlayersCaptureBlock"] = {} end
	if ServerSafehouseData["SafehouseListUnblocked"] == nil then ServerSafehouseData["SafehouseListUnblocked"] = {} end
	if ServerSafehouseData["SafehouseCaptureTimer"] == nil then ServerSafehouseData["SafehouseCaptureTimer"] = {} end

	--Add players factions of actual safehouse been captured to a list to Unblock Capture
	--So the safehouse captured can be recovery anytime for older owners during capture phase
	if ServerSafehouseData["SafehouseListUnblocked"][safehouseLocation.X .. safehouseLocation.X] == nil then
		ServerSafehouseData["SafehouseListUnblocked"][safehouseLocation.X .. safehouseLocation.Y] =
			safehouseBeenCaptureOwner
	end
	--Verify if the capturing player is the owner of old safehouse
	if ServerSafehouseData["SafehouseListUnblocked"][safehouseLocation.X .. safehouseLocation.Y] == playerCapturing then
		--Contact Player for confirming
		print("[Factions] " ..
			playerCapturing ..
			" is trying to recapture a old safehouse in X: " ..
			playerLocation:getX() .. " Y: " .. playerLocation:getY());
		sendServerCommand(player, "ServerSafehouse", "receiveCaptureConfirmation", { validation = true });
		ServerSafehouseData["SafehouseCaptureTimer"][safehouseLocation.X .. safehouseLocation.Y] = os.time();
		-- Alerting the players from the safehouse
		for i = safehouseBeenCaptured:getPlayers():size() - 1, 0, -1 do
			local safehousePlayer = getPlayerByUserName(safehouseBeenCaptured:getPlayers():get(i));
			-- Check if player is online
			if safehousePlayer ~= nil then
				-- Alert the player that the safehouse has been lost
				sendServerCommand(safehousePlayer, "ServerSafehouse", "alert",
					{
						safehouseName = "X: " .. safehouseLocation.X .. " Y: " .. safehouseLocation.Y,
						type = 1 -- Under Attack
					});
			end
		end
		-- Alert capturers that hes are capturing
		local playersFaction = playerFaction:getPlayers();
		for _, playerUsername in ipairs(playersFaction) do
			local factionPlayer = getPlayerFromUsername(playerUsername);
			-- Alert the player that the safehouse has been captured
			sendServerCommand(factionPlayer, "ServerSafehouse", "alert",
				{
					safehouseName = "X: " .. safehouseLocation.X .. " Y: " .. safehouseLocation.Y,
					type = 3
				});
		end
		return;
	end

	--Verifiy if the players already attacked today
	if ServerSafehouseData["SafehousePlayersCaptureBlock"][playerCapturing] == nil then
		--Add player to blocked
		ServerSafehouseData["SafehousePlayersCaptureBlock"][playerCapturing] = true
		--Contact Player for confirming
		print("[Factions] " ..
			playerCapturing ..
			" is trying to capture a safehouse in X: " .. playerLocation:getX() .. " Y: " .. playerLocation:getY());
		sendServerCommand(player, "ServerSafehouse", "receiveCaptureConfirmation", { validation = true });
		ServerSafehouseData["SafehouseCaptureTimer"][safehouseLocation.X .. safehouseLocation.Y] = os.time();
		-- Alerting the players from the safehouse
		for i = safehouseBeenCaptured:getPlayers():size() - 1, 0, -1 do
			local safehousePlayer = getPlayerByUserName(safehouseBeenCaptured:getPlayers():get(i));
			-- Check if player is online
			if safehousePlayer ~= nil then
				-- Alert the player that the safehouse has been lost
				sendServerCommand(safehousePlayer, "ServerSafehouse", "alert",
					{
						safehouseName = "X: " .. safehouseLocation.X .. " Y: " .. safehouseLocation.Y,
						type = 1 -- Under Attack
					});
			end
		end
		-- Alert capturers that hes are capturing
		local playersFaction = playerFaction:getPlayers();
		for _, playerUsername in ipairs(playersFaction) do
			local factionPlayer = getPlayerFromUsername(playerUsername);
			-- Alert the player that the safehouse has been captured
			sendServerCommand(factionPlayer, "ServerSafehouse", "alert",
				{
					safehouseName = "X: " .. safehouseLocation.X .. " Y: " .. safehouseLocation.Y,
					type = 3
				});
		end
	else
		--Contact player saying that is not time yet
		print("[Factions] " ..
			playerCapturing .. " trying to capture but hes already tried captured a safehouse this week");
		sendServerCommand(player, "ServerSafehouse", "receiveCaptureConfirmation", { validation = false });
	end
end

-- Finished the capture
function ServerSafehouseCommands.onCaptureSafehouse(module, command, player, args)
	-- Check if Faction is Nil
	local playerFaction = FactionsMain.getFaction(player:getUsername());
	local playerLocation = player:getSquare();
	local safehouseBeenCaptured = SafeHouse.getSafeHouse(playerLocation);
	-- Check if player doesnt have factions
	if playerFaction == nil then
		sendServerCommand(player, "ServerSafehouse", "safehouseCaptured", { validation = false });
	end
	-- Check if faction been captured is nill
	if safehouseBeenCaptured == nil then
		sendServerCommand(player, "ServerSafehouse", "safehouseCaptured", { validation = false });
		return
	end
	local safehouseLocation = {
		X = safehouseBeenCaptured:getX(),
		Y = safehouseBeenCaptured:getY(),
	}
	-- Check if Timer is Nil
	if ServerSafehouseData["SafehouseCaptureTimer"][safehouseLocation.X .. safehouseLocation.Y] == nil then
		sendServerCommand(player, "ServerSafehouse", "safehouseCaptured", { validation = false });
	end
	-- Get the time and reduces it to check the time lapsed
	local timeCapturePassed = os.time() -
		ServerSafehouseData["SafehouseCaptureTimer"][safehouseLocation.X .. safehouseLocation.Y]

	-- Limiar error
	if timeCapturePassed > 110 or timeCapturePassed < 90 then
		print("[Factions] " ..
			player:getUsername() .. " tried to capture a safehouse but the timer doesnt match: " .. timeCapturePassed)
		sendServerCommand(player, "ServerSafehouse", "safehouseCaptured", { validation = false });
		return
	end

	-- Releasing Safehouse and alerting all enemies
	for i = safehouseBeenCaptured:getPlayers():size() - 1, 0, -1 do
		local safehousePlayer = getPlayerByUserName(safehouseBeenCaptured:getPlayers():get(i));
		-- Check if player is online
		if safehousePlayer ~= nil then
			-- Alert the player that the safehouse has been lost
			sendServerCommand(safehousePlayer, "ServerSafehouse", "alert",
				{
					safehouseName = "X: " .. safehouseLocation.X .. " Y: " .. safehouseLocation.Y,
					type = 2
				});
		end
		-- Remove player use the Username String so we need to get the username again
		safehouseBeenCaptured:removePlayer(safehouseBeenCaptured:getPlayers():get(i));
	end

	-- Capturing Safehouse
	safehouseBeenCaptured:setOwner(playerFaction:getOwner());
	safehouseBeenCaptured:syncSafehouse();

	-- Syncing Data
	FactionsMain.syncFactionMembers(safehouseBeenCaptured, player);

	-- Get the faction usernames
	local playersFaction = playerFaction:getPlayers();
	for _, playerUsername in ipairs(playersFaction) do
		local factionPlayer = getPlayerFromUsername(playerUsername);
		-- Alert the player that the safehouse has been captured
		sendServerCommand(factionPlayer, "ServerSafehouse", "alert",
			{
				safehouseName = "X: " .. safehouseLocation.X .. " Y: " .. safehouseLocation.Y,
				type = 4
			});
	end
	--Finish
	sendServerCommand(player, "ServerSafehouse", "safehouseCaptured",
		{ validation = true });
	print("[Factions] " ..
		player:getUsername() ..
		" captured a safehouse in X: " .. playerLocation:getX() .. " Y: " .. playerLocation:getY());
end

--Receives Commands from Clients
Events.OnClientCommand.Add(function(module, command, player, args)
	if module == "ServerFactions" and FactionsCommands[command] then
		FactionsCommands[command](module, command, player, args)
	end
end)

-- Increase building life while not in capture
if SandboxVars.Factions.IncreaseConstructionLife then
	Events.EveryTenMinutes.Add(function()
		if factions.checkIfCaptureIsEnabled() then
			getSandboxOptions():set("ConstructionBonusPoints", 2)
			local players = getOnlinePlayers()
			-- Update sandbox to all players
			for i = players:size() - 1, 0, -1 do
				local player = players:get(i);
				sendServerCommand(player, "ServerSafehouse", "updateSandbox", { ConstructionBonusPoints = 2 });
			end
		else
			getSandboxOptions():set("ConstructionBonusPoints", 5)
			local players = getOnlinePlayers()
			-- Update sandbox to all players
			for i = players:size() - 1, 0, -1 do
				local player = players:get(i);
				sendServerCommand(player, "ServerSafehouse", "updateSandbox", { ConstructionBonusPoints = 5 });
			end
		end
	end)
end

-- Read Options on start
Events.OnGameStart.Add(factions.readOptions()); -- Singleplayer
Events.OnServerStarted.Add(factions.readOptions()); -- Multiplayer
