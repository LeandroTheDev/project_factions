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
local fileWriter = getFileWriter("Logs/SafehousePlusProtect.txt", false, true);
local function logger(log)
    local time = getCurrentTime();
    -- Write the log in it
    -- fileWriter:write("[" ..
    --     time.tm_min .. ":" .. time.tm_hour .. " " .. time.tm_mday .. "/" .. time.tm_mon .. "] " .. log .. "\n");
    print("[" ..
        time.tm_min .. ":" .. time.tm_hour .. " " .. time.tm_mday .. "/" .. time.tm_mon .. "] " .. log .. "\n");
end

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

-- Call the server to add a safehouse point
function Recipe.OnGiveXP.ProtectSafehouse(recipe, ingredients, result, player)
    sendClientCommand("ServerSafehouseProtection", "protectSafehouse", nil);
end

-- Declaring variables to be called in script text
ProtectSafehouse = Recipe.OnGiveXP.ProtectSafehouse;
if isClient() then return end;

-- Stores the server and client communication
local ServerSafehouseProtection = {};
-- Stores all safehouse protection datas into ModData
-- {
--  "factionName": [
--      "213123551" -- safehouse position concatened
--  ],
--  "factionName2": [
--      "313145121" -- safehouse position concatened
--  ]
-- }
local ServerSafehouseProtectionData = {};

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

-- "owner" if player belongs to the safehouse and is owner, "no" if not belongs, "yes", if the player belongs
local function belongsToSafehouse(safehouse, player)
    -- If safehouse does not exist
    if not safehouse then
        return "no"
    end

    -- Getting the safehouse owner
    local safehouseOwner = safehouse:getOwner();
    -- Checking if the player is the owner
    if player:getUsername() == safehouseOwner then
        return "owner"
    end

    -- Getting the faction name from the player
    local player_faction = getFaction(player:getUsername());
    if not player_faction then return "no" end;

    -- Getting the faction name from the owner
    local owner_faction = getFaction(safehouseOwner);

    -- Checking if player and owner are on the same faction
    if player_faction == owner_faction then
        return "yes"
    else
        return "no"
    end
end

-- Protect the player faction safehouse
function ServerSafehouseProtection.protectSafehouse(module, command, player, args)
    if not SandboxVars.SafehousePlus.EnableSafehouseProtection then return end;

    -- Getting a valid square
    local playerSquare = player:getSquare();
    if not playerSquare then
        logger(player:getUsername() ..
            " player square is null, cannot protect safehouse, returning item to player inventory");
        sendServerCommand(player, "ServerSafehouseProtection", "notBelongs", nil);
    end
    -- Getting the safehouse where player is standing
    local safehouse = SafeHouse.getSafeHouse(playerSquare);
    -- Checking if player is allied of the safehouse
    local safehouseResult = belongsToSafehouse(safehouse, player);
    if safehouseResult == "owner" then -- owner
        -- Getting the safehouse id
        local safehouseId = tostring(safehouse:getX()) .. tostring(safehouse:getY());
        local playerFaction = getFaction(player:getUsername());
        if not playerFaction then
            logger(player:getUsername() ..
                " cannot protect that safehouse player doesn't belongs to any faction, returning item to player inventory");
            sendServerCommand(player, "ServerSafehouseProtection", "notBelongs", nil);
            return;
        end
        local factionName = playerFaction:getName();

        -- Nil checks
        if not ServerSafehouseProtectionData[factionName] then ServerSafehouseProtectionData[factionName] = {} end;
        if #ServerSafehouseProtectionData[factionName] >= SandboxVars.SafehousePlus.SafehouseProtectionLimit then
            -- Remove the first index
            table.remove(ServerSafehouseProtectionData[factionName], 1)
            -- Add the new safehouse to the final list
            table.insert(ServerSafehouseProtectionData[factionName], safehouseId)
        else
            -- Add the new safehouse to the final list
            table.insert(ServerSafehouseProtectionData[factionName], safehouseId)
        end
        sendServerCommand(player, "ServerSafehouseProtection", "safehouseProtected", nil);
        logger(player:getUsername() ..
            " has protected the safehouse in X: " .. safehouse:getX() .. " Y: " .. safehouse:getY());
    elseif safehouseResult == "yes" then -- ally
        logger(player:getUsername() ..
            " cannot protect that safehouse player is not the safehouse owner, returning item to player inventory");
        sendServerCommand(player, "ServerSafehouseProtection", "notOwner", nil);
    else -- enemy or invalid
        logger(player:getUsername() ..
            " cannot protect that safehouse player doesn't belongs to the safehouse, returning item to player inventory");
        sendServerCommand(player, "ServerSafehouseProtection", "notBelongs", nil);
    end
end

-- Check for unclaimed safehouses, and remove the protection
if SandboxVars.SafehousePlus.EnableSafehouseProtection then
    Events.EveryOneMinute.Add(function()
        -- [
        --  {
        --      "factionName": "test",
        --      "safehouseId": "23142515",
        --  }
        -- ]
        local safehousesToRemove = {};


        local safehouses = SafeHouse.getSafehouseList();
        -- Swiping all saved safehouses protections from factions
        for factionName, safehousesProtecteds in pairs(ServerSafehouseProtectionData) do
            -- Swiping all safehouse from the actual faction
            for _, safehouseId in ipairs(safehousesProtecteds) do
                local exist = false;
                -- Swipe all safehouse in the server
                for i = 0, safehouses:size() - 1 do
                    -- Getting the actual safehouse
                    local selectedSafehouse = safehouses:get(i);
                    local selectedSafehouseId = tostring(selectedSafehouse:getX()) .. tostring(selectedSafehouse:getY());
                    -- Checking if is the same
                    if safehouseId == selectedSafehouseId then
                        exist = true;
                        break;
                    end
                end
                -- If not exist we will remove it
                if not exist then
                    table.insert(safehousesToRemove, { factionName = factionName, safehouseId = safehouseId });
                end
            end
        end

        -- Removing the safehouses marked to remove
        for _, safehouseObject in ipairs(safehousesToRemove) do
            local factionName = safehouseObject.factionName;
            local safehouseId = safehouseObject.safehouseId;

            -- Nullable check, theres no way to this to be null but why not checking...
            if ServerSafehouseProtectionData[factionName] then
                -- Finding the safehouse id, the iteration is reversed
                for i = #ServerSafehouseProtectionData[factionName], 1, -1 do
                    -- If is the same
                    if ServerSafehouseProtectionData[factionName][i] == safehouseId then
                        -- Removing the safehouse
                        table.remove(ServerSafehouseProtectionData[factionName], i);
                        logger("the safehouse: " ..
                            safehouseId ..
                            " has been removed from protections, because its no longer claimed by any faction");
                        break
                    end
                end
            end
        end
    end);
end

-- True if safehouse is protected, false if not protected
function SafehouseIsProtected(safehouse)
    -- Getting the safehouse id
    local selectedSafehouseId = tostring(safehouse:getX()) .. tostring(safehouse:getY());
    -- Swiping all factions
    for _, safehousesProtecteds in pairs(ServerSafehouseProtectionData) do
        -- Swiping all safehouse from the actual faction
        for _, safehouseId in ipairs(safehousesProtecteds) do
            if selectedSafehouseId == safehouseId then
                return true;
            end
        end
    end
    return false;
end

-- Load Datas
Events.OnInitGlobalModData.Add(function(isNewGame)
    ServerSafehouseProtectionData = ModData.getOrCreate("ServerSafehouseProtectionData");
    if not ServerSafehouseProtectionData then ServerSafehouseProtectionData = {} end
end)

-- Receives Commands from Clients
Events.OnClientCommand.Add(function(module, command, player, args)
    if module == "ServerSafehouseProtection" and ServerSafehouseProtection[command] then
        ServerSafehouseProtection[command](module, command, player, args)
    end
end)
