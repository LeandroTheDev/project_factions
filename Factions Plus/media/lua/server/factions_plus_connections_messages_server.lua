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
local fileWriter = getFileWriter("Logs/FactionsPlusConnectionsMessages.txt", true, false);
local function logger(log)
    local time = getCurrentTime();
    -- Write the log in it
    fileWriter:write("[" ..
        time.tm_min .. ":" .. time.tm_hour .. " " .. time.tm_mday .. "/" .. time.tm_mon .. "] " .. log .. "\n");

    -- Close the file
    fileWriter:close();
end

local ticksToDetectPlayers = SandboxVars.FactionsPlus.MessagesCheckPerTick;
local actualTicks = 0;

local function sendMessageToAllPlayers(message, player)
    local onlinePlayers = getOnlinePlayers();

    -- Swiping all online players
    for i = 0, onlinePlayers:size() - 1 do
        local selectedPlayer = onlinePlayers:get(i);
        sendServerCommand(selectedPlayer, "ServerMessages", message, { playerUsername = player:getUsername() });
    end

    if message == "playerconnected" then
        logger(player:getUsername() .. " connected");
    elseif message == "playerdisconnected" then
        logger(player:getUsername() .. " disconnected");
    elseif message == "playerdied" then
        logger(player:getUsername() .. " dead");
    end
end

-- Death message
if SandboxVars.FactionsPlus.EnablePlayerDeathMessages then
    local function OnPlayerDeath(player) sendMessageToAllPlayers("playerdead", player) end

    Events.OnPlayerDeath.Add(OnPlayerDeath);
end

-- Stores any old online players, is a List<string> with the username
local previousOnlinePlayers = {};

-- Player message handler
if SandboxVars.FactionsPlus.EnablePlayerJoinMessages or SandboxVars.FactionsPlus.EnablePlayerLeaveMessages then
    Events.OnTick.Add(function()
        -- Tickrate detection
        if actualTicks < ticksToDetectPlayers then
            actualTicks = actualTicks + 1; return
        end
        actualTicks = 0;

        -- Getting online players
        local onlinePlayers = getOnlinePlayers();
        if not players then return end -- server empty

        -- Detecting disconnected players
        -- Swiping all previous players
        for i = 0, previousOnlinePlayers:size() - 1 do
            local selectedPreviousPlayer = previousOnlinePlayers:get(i);
            local isDisconnected = true;
            -- Swiping all online players
            for j = 0, onlinePlayers:size() - 1 do
                local selectedPlayer = onlinePlayers:get(j);
                -- Checking if player is still online
                if selectedPlayer:getUsername() == selectedPreviousPlayer then
                    isDisconnected = false;
                    break;
                end
            end
            -- Checking if player disconnected
            if isDisconnected then
                -- Sending a message to all players the disconnected player
                if SandboxVars.FactionsPlus.EnablePlayerLeaveMessages then
                    sendMessageToAllPlayers("playerconnected", selectedPreviousPlayer);
                end
                -- Removing the player from the previousOnlinePlayers table
                for x = #previousOnlinePlayers, 1, -1 do
                    -- Checking the exact index
                    if previousOnlinePlayers[x] == selectedPreviousPlayer then
                        -- Removing the player from previous
                        table.remove(previousOnlinePlayers, x);
                        -- Reducing the index because we removed a value from the table
                        i = i - 1;
                        break;
                    end
                end
            end
        end

        -- Detecting new players
        -- Swiping all online players
        for i = 0, onlinePlayers:size() - 1 do
            local selectedPlayer = onlinePlayers:get(i);
            local isNew = true;
            -- Swiping all previous players
            for j = 0, previousOnlinePlayers:size() - 1 do
                local selectedPreviousPlayer = previousOnlinePlayers:get(j);
                -- Checking if the previous player is already added
                if selectedPlayer:getUsername() == selectedPreviousPlayer then
                    isNew = false;
                    break;
                end
            end
            -- Checking if the player is new
            if isNew then
                -- Adding it to the previous players
                table.insert(previousOnlinePlayers, selectedPlayer:getUsername());
                -- Sending a message to all players the new connected player
                if SandboxVars.FactionsPlus.EnablePlayerJoinMessages then
                    sendMessageToAllPlayers("playerconnected", selectedPlayer:getUsername());
                end
            end
        end
    end)
end
