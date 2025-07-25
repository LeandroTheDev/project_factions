---@diagnostic disable: undefined-global, deprecated

-- Check if is not a single player game
local isSingleplayer = false;
if not (not isClient() and not isServer()) then
    -- Check if is a client on the dedicated server
    if isClient() then
        print("Factions Shop has been disable reason: you are the client in dedicated server");
        return;
    end
else
    isSingleplayer = true;
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
local fileWriter = getFileWriter("Logs/FactionsEconomyShop.txt", false, true);
local function logger(log)
    local time = getCurrentTime();
    -- Write the log in it
    -- fileWriter:write("[" ..
    --     time.tm_hour .. ":" .. time.tm_min .. " " .. time.tm_mday .. "/" .. time.tm_mon .. "] " .. log .. "\n");
    print("[" ..
        time.tm_hour ..
        ":" .. time.tm_min .. " " .. time.tm_mday .. "/" .. time.tm_mon .. "-FactionsEconomy] " .. log .. "\n");
end

ServerShopData = {};
ShopItems = {};
TradeItems = {};

local function tableToString(table, level)
    level = level or 0
    local prefixo = string.rep("  ", level)
    if type(table) == "table" then
        local str = "{\n"
        for chave, valor in pairs(table) do
            str = str .. prefixo .. "  [" .. tostring(chave) .. "] = "
            if type(valor) == "table" then
                str = str .. tableToString(valor, level + 1) .. ",\n"
            else
                str = str .. tostring(valor) .. ",\n"
            end
        end
        str = str .. prefixo .. "}"
        return str
    else
        return tostring(table)
    end
end

local function PointsTick()
    if isSingleplayer then
        local username = getPlayer():getUsername();
        if not ServerShopData[username] then ServerShopData[username] = 0 end
        ServerShopData[username] = ServerShopData[username] + SandboxVars.FactionsEconomy.PointsPerTick
        logger(username ..
            " received: " .. SandboxVars.FactionsEconomy.PointsPerTick .. " total: " .. ServerShopData[username]);
    else
        local players = getOnlinePlayers()
        for i = 0, players:size() - 1 do
            local username = players:get(i):getUsername()
            if not ServerShopData[username] then ServerShopData[username] = 0 end
            ServerShopData[username] = ServerShopData[username] + SandboxVars.FactionsEconomy.PointsPerTick
            logger(username ..
                " received: " .. SandboxVars.FactionsEconomy.PointsPerTick .. " total: " .. ServerShopData[username]);
        end
    end
end

-- Simple load the items from storage in server Lua/FactionsEconomyItems.ini
local function LoadShopItems()
    local fileReader = getFileReader("FactionsEconomyItems.ini", true)
    local lines = {}
    local line = fileReader:readLine()
    while line do
        table.insert(lines, line)
        line = fileReader:readLine()
    end
    fileReader:close()
    logger("Shop items has been loaded");
    ShopItems = loadstring(table.concat(lines, "\n"))() or { ["missing"] = {} }
end

-- Simple load the items from the server data
local function LoadTradeItems()
    if ServerShopData["ServerTradeItems"] == nil then ServerShopData["ServerTradeItems"] = { ["No_Items"] = {} } end
    logger("Trade items has been loaded");
    TradeItems = ServerShopData["ServerTradeItems"];
end

Events.OnInitGlobalModData.Add(function(isNewGame)
    ServerShopData = ModData.getOrCreate("ServerShopData")

    LoadShopItems()
    LoadTradeItems()

    print("POINTS FREQUENCY: " .. SandboxVars.FactionsEconomy.PointsFrequency);

    if SandboxVars.FactionsEconomy.PointsFrequency == 2 then
        Events.EveryTenMinutes.Add(PointsTick)
    elseif SandboxVars.FactionsEconomy.PointsFrequency == 3 then
        Events.EveryHours.Add(PointsTick)
    elseif SandboxVars.FactionsEconomy.PointsFrequency == 4 then
        Events.EveryDays.Add(PointsTick)
    end
end)

local ServerPointsCommands = {}

-- Player add new item to the trade
function ServerPointsCommands.addTrade(module, command, player, args)
    logger(string.format("%s added %d %s item for %d points in trade", player:getUsername(),
        args[1].quantity, args[1].target, args[1].price));

    -- Verify if trade item is empty
    if ServerShopData["ServerTradeItems"].No_Items ~= nil then ServerShopData["ServerTradeItems"] = {} end
    -- Create category if not Exist
    if ServerShopData["ServerTradeItems"][args[1].category] == nil then ServerShopData["ServerTradeItems"][args[1].category] = {} end
    -- Add item
    table.insert(ServerShopData["ServerTradeItems"][args[1].category], args[1])
    -- Reload Trade Items
    LoadTradeItems();
end

-- Player buy trade
function ServerPointsCommands.buyTrade(module, command, player, args)
    logger(string.format("[Factions Economy] %s bought %s for %d points", player:getUsername(), args[1].type,
        args[1].price));
    local serverItem = ServerShopData["ServerTradeItems"][args[1].category][args[1].index]
    local clientItem = args[1]

    -- Verify if client and server are talking about the same item
    if serverItem.target == clientItem.target and serverItem.price == clientItem.price then
        -- Reduces Points from User
        if not ServerShopData[player:getUsername()] then ServerShopData[player:getUsername()] = 0 end
        -- Remove points from player buying
        ServerShopData[player:getUsername()] = ServerShopData[player:getUsername()] - math.abs(clientItem.price)
        -- Add points for player selling
        ServerShopData[serverItem.player] = ServerShopData[player:getUsername()] + math.abs(clientItem.price)
        -- Send item for player buying
        sendServerCommand(player, "ServerPoints", "receiveTradeItem", serverItem)
        -- Remove from List
        table.remove(ServerShopData["ServerTradeItems"][clientItem.category], clientItem.index)
    end

    --Reload Trade Items
    LoadTradeItems();
end

-- Get trade items
function ServerPointsCommands.loadTrade(module, command, player, args)
    sendServerCommand(player, module, command, TradeItems)
end

-- Buy from shop
function ServerPointsCommands.buyShop(module, command, player, args)
    logger(string.format("%s bought %s for %d points", player:getUsername(), args[2], args[1]))
    if not ServerShopData[player:getUsername()] then ServerShopData[player:getUsername()] = 0 end
    ServerShopData[player:getUsername()] = ServerShopData[player:getUsername()] - math.abs(args[1])
end

-- Buy vehicle from shop
function ServerPointsCommands.buyVehicle(module, command, player, args)
    local vehicle = addVehicleDebug(args[1], IsoDirections.S, nil, player:getSquare())
    for i = 0, vehicle:getPartCount() - 1 do
        local container = vehicle:getPartByIndex(i):getItemContainer()
        if container then
            container:removeAllItems()
        end
    end
    vehicle:repair()
    player:sendObjectChange("addItem", { item = vehicle:createVehicleKey() })
end

-- Get shop items
function ServerPointsCommands.loadShop(module, command, player, args)
    sendServerCommand(player, module, command, ShopItems)
end

-- Reload shop items
function ServerPointsCommands.reloadShop(module, command, player, args)
    LoadShopItems()
end

-- Return the points the player has
function ServerPointsCommands.getPoints(module, command, player, args)
    sendServerCommand(player, module, command, { ServerShopData[args and args[1] or player:getUsername()] or 0 })
end

-- Add points for the player
function ServerPointsCommands.addPoints(module, command, player, args)
    logger(string.format(args[1] .. " received " .. args[2] .. " points"));
    -- Null Check
    if not ServerShopData[args[1]] then ServerShopData[args[1]] = 0 end
    -- Adding the Points
    ServerShopData[args[1]] = ServerShopData[args[1]] + args[2];
end

Events.OnClientCommand.Add(function(module, command, player, args)
    if module == "ServerPoints" and ServerPointsCommands[command] then
        ServerPointsCommands[command](module, command, player, args)
    end
end)
