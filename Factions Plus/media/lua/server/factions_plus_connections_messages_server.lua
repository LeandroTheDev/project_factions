---@diagnostic disable: undefined-global
if isClient() then return end;
--Thanks chat gpt
local function formatarTabela(tabela, nivel)
    nivel = nivel or 0
    local prefixo = string.rep("  ", nivel) -- Espaços para recuo
    if type(tabela) == "table" then
        local str = "{\n"
        for chave, valor in pairs(tabela) do
            str = str .. prefixo .. "  [" .. tostring(chave) .. "] = "
            if type(valor) == "table" then
                str = str .. formatarTabela(valor, nivel + 1) .. ",\n"
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
local fileWriter = getFileWriter("Logs/FactionsPlusConnectionsMessages.txt", false, true);
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

local function sendMessageToAllPlayers(message, _playerUsername)
    local onlinePlayers = getOnlinePlayers();

    -- Swiping all online players
    for i = 0, onlinePlayers:size() - 1 do
        local selectedPlayer = onlinePlayers:get(i);
        sendServerCommand(selectedPlayer, "ServerMessages", message, { playerUsername = _playerUsername });
    end

    if message == "playerconnected" then
        logger(_playerUsername .. " connected");
    elseif message == "playerdisconnected" then
        logger(_playerUsername .. " disconnected");
    elseif message == "playerdied" then
        logger(_playerUsername .. " dead");
    end
end

-- Death message
if SandboxVars.FactionsPlus.EnablePlayerDeathMessages then
    local function OnPlayerDeath(player) sendMessageToAllPlayers("playerdead", player) end

    Events.OnPlayerDeath.Add(OnPlayerDeath);
end

-- Stores any old online players, is a List<string> with the username
local previousOnlinePlayers = {};
local lastTimeSeconds = 0;

-- Player message handler
if SandboxVars.FactionsPlus.EnablePlayerJoinMessages or SandboxVars.FactionsPlus.EnablePlayerLeaveMessages then
    Events.OnTick.Add(function()
        -- Tickrate detection
        if actualTicks < ticksToDetectPlayers then
            actualTicks = actualTicks + 1;
            return;
        end
        actualTicks = 0;

        -- Check if server was freeze (no players)
        local actualTime = getTimestamp() + 0 * 3600;
        if actualTime > lastTimeSeconds + 15 then
            logger("server was freezed, resetting variables");
            -- Resetting players
            previousOnlinePlayers = {}
        end 

        -- Getting online players
        local onlinePlayers = getOnlinePlayers();

        -- Detecting disconnected players
        -- Iterating over previousOnlinePlayers
        for i = 1, #previousOnlinePlayers do
            local selectedPreviousPlayer = previousOnlinePlayers[i];
            local isDisconnected = true;
            -- Iterating over onlinePlayers
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
                -- Sending a message to all players about the disconnected player
                if SandboxVars.FactionsPlus.EnablePlayerLeaveMessages then
                    sendMessageToAllPlayers("playerdisconnected", selectedPreviousPlayer);
                end
                -- Removing the player from the previousOnlinePlayers table
                table.remove(previousOnlinePlayers, i);
                i = i - 1; -- Adjusting index due to table.remove
            end
        end

        -- Detecting new players
        -- Iterating over onlinePlayers
        for i = 0, onlinePlayers:size() - 1 do
            local selectedPlayer = onlinePlayers:get(i);
            local isNew = true;
            -- Iterating over previousOnlinePlayers
            for j = 1, #previousOnlinePlayers do
                local selectedPreviousPlayer = previousOnlinePlayers[j];
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
                -- Sending a message to all players about the new connected player
                if SandboxVars.FactionsPlus.EnablePlayerJoinMessages then
                    sendMessageToAllPlayers("playerconnected", selectedPlayer:getUsername());
                end
            end
        end

        -- Adding actual seconds on the lastTimeSeconds
        lastTimeSeconds = getTimestamp() + 0 * 3600;
    end)
end
