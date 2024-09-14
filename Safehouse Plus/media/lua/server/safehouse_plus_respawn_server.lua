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
local fileWriter = getFileWriter("Logs/SafehousePlusRespawn.txt", false, true);
local function logger(log)
    local time = getCurrentTime();
    -- Write the log in it
    fileWriter:write("[" ..
        time.tm_min .. ":" .. time.tm_hour .. " " .. time.tm_mday .. "/" .. time.tm_mon .. "] " .. log .. "\n");
end

ServerRespawnCommands = {}
local ServerRespawnData;

-- Get the safehouse from username
local function getFaction(username)
    local factions = Faction.getFactions();
    for i = 0, factions:size() - 1 do
        local faction = factions:get(i);
        if faction:isOwner(username) then
            return faction;
        end
        local players = faction:getPlayers();
        for j = 0, players:size() - 1 do
            local player = players:get(j);
            if player == username then
                return faction;
            end
        end
    end
    return nil;
end

-- Check if player is enemy from that safehouse
local function isEnemy(safehouse, player)
    if not safehouse then
        return true
    end

    local owner = safehouse:getOwner();

    if player:getUsername() == owner then
        return false
    end

    local player_faction = getFaction(player:getUsername())
    local owner_faction = getFaction(safehouse:getOwner())

    if player_faction == owner_faction then
        return false
    else
        return true
    end
end

-- Verify if player can spawn in the bed
function ServerRespawnCommands.canSpawn(module, command, player, args)
    local playerSafehouseId = ServerRespawnData[player:getUsername()];
    -- Check if player safehouse not exist
    if playerSafehouseId == nil then
        logger(player:getUsername() .. " spawnpoint is not in valid safehouse, cannot respawn on it");
        sendServerCommand(player, "ServerRespawn", "canSpawn", {
            canSpawn = false,
        });
        return;
    end

    -- Get all safehouses from server
    local safehouses = SafeHouse.getSafehouseList();
    -- Check all safehouses
    for i = 0, safehouses:size() - 1 do
        local selectedSafehouse = safehouses:get(i);
        local selectedSafehouseId = tostring(selectedSafehouse:getX()) .. tostring(selectedSafehouse:getY());
        if playerSafehouseId == selectedSafehouseId then
            -- Verify if this safehouse is valid and
            -- the player owns this safehouse
            if isEnemy(selectedSafehouse, player) then
                -- Caso não for valida então ele não pode renascer
                logger(player:getUsername() .. " cannot respawn in safehouse, doesn't belong to it")
                sendServerCommand(player, "ServerRespawn", "canSpawn", {
                    canSpawn = false,
                });
                return;
            else
                -- If is not enemy so...
                logger(player:getUsername() .. " belongs to the safehouse so can respawn in safehouse bed");
                sendServerCommand(player, "ServerRespawn", "canSpawn", {
                    canSpawn = true,
                });
                return;
            end
        end
    end
    -- If the swipe cannot find anything
    -- This means the player factions doesnt own any safehouses
    logger(player:getUsername() .. " spawnpoint is on any empty safehouse, cannot spawn");
    sendServerCommand(player, "ServerRespawn", "canSpawn", {
        canSpawn = false,
    });
end

-- Change player spawnpoint
function ServerRespawnCommands.enableSpawn(module, command, player, args)
    -- Get the square where the player is in
    local square = getCell():getGridSquare(player:getX(), player:getY(), 0)
    -- Getting the safehouse where the player are in
    local safehouse = SafeHouse.getSafeHouse(square);
    -- Null check if exist
    if safehouse == nil then return end;
    -- Add in the table
    ServerRespawnData[player:getUsername()] = tostring(safehouse:getX()) .. tostring(safehouse:getY());
    logger(player:getUsername() .. " set a new respawn point in X: " .. safehouse:getX() .. " Y: " .. safehouse:getY());
end

-- Handler client message
Events.OnClientCommand.Add(function(module, command, player, args)
    if module == "ServerRespawn" and ServerRespawnCommands[command] then
        ServerRespawnCommands[command](module, command, player, args)
    end
end)

-- Load server data
Events.OnInitGlobalModData.Add(function(isNewGame)
    ServerRespawnData = ModData.getOrCreate("serverRespawnData");
end)
