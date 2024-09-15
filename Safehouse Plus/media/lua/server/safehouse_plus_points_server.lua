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
local fileWriter = getFileWriter("Logs/SafehousePlusPoints.txt", false, true);
local function logger(log)
    local time = getCurrentTime();
    -- Write the log in it
    -- fileWriter:write("[" ..
    --     time.tm_hour .. ":" .. time.tm_min .. " " .. time.tm_mday .. "/" .. time.tm_mon .. "] " .. log .. "\n");
    print("[" ..
        time.tm_hour .. ":" .. time.tm_min .. " " .. time.tm_mday .. "/" .. time.tm_mon .. "] " .. log .. "\n");
end

-- Call the server to add a safehouse point
function Recipe.OnGiveXP.UpgradeSafehouse(recipe, ingredients, result, player)
    sendClientCommand("ServerSafehouse", "addSafehousePoint", nil);
end

-- Declaring variables to be called in script text
UpgradeSafehouse = Recipe.OnGiveXP.UpgradeSafehouse;

if isClient() then return end;

-- Stores the server and client communication
local ServerSafehouseCommands = {};
-- Stores all safehouse datas into ModData
local ServerSafehouseData = {};
-- Ticks to add points to the safehouse base on
local ServerSafehousePointsTicks = 1;

-- Calculate the score based in safehouse score
local function calculateScorePoints(score)
    -- Base value
    local result = SandboxVars.SafehousePlus.SafehouseBasePoints

    -- Swipe every number in score
    for _, points in ipairs(score) do
        -- If is multiple
        if points % pointsPerScore == 0 then
            -- Increase the base result
            result = result + basePoints
        end
    end

    -- Returning
    return result;
end

-- Secondary function to check if player is on the safehouse, returns true if belongs to the safehouse
-- false if not belongs to the safehouse or the safehouse is not exist
local function BelongsToTheSafehouse(player, safehouse)
    -- Check if the player is on a safehouse
    if not safehouse then
        return false
    end

    -- Fast check if is the owner
    local owner = safehouse:getOwner();
    if player:getUsername() == owner then
        return true
    end

    -- If not the owner we need to check all players from the safehouse,
    -- and if the actual player is on it
    for i = safehouse:getPlayers():size() - 1, 0, -1 do
        local safehousePlayerUsername = safehouseBeenCaptured:getPlayers():get(i);
        -- Check if safehousePlayerUsername is the same as the player
        if safehousePlayerUsername == player:getUsername() then
            return true
        end
    end
    -- Player dont belong to the safehouse
    return false
end

-- Add points for the safehouse
function ServerSafehouseCommands.addSafehousePoint(module, command, player, args)
    local safehouseToAddPoint = SafeHouse.getSafeHouse(player:getSquare());

    if not BelongsToTheSafehouse(player, safehouseToAddPoint) then
        logger(player:getUsername() .. " is trying to upgrade a safehouse that is not from him");
    end

    -- Check if player is not in a safehouse
    if safehouseToAddPoint == nil then
        sendServerCommand(player, "ServerSafehouse", "notInSafehouse", nil);
        return;
    end
    -- String position of the safehouse
    local safehousePosition = safehouseToAddPoint:getX() .. safehouseToAddPoint:getY();

    -- Null Check
    if not ServerSafehouseData["SafehousePoints"] then ServerSafehouseData["SafehousePoints"] = {} end
    if not ServerSafehouseData["SafehousePoints"][safehousePosition] then ServerSafehouseData["SafehousePoints"][safehousePosition] = 0 end

    -- Add the points to the safehouse
    ServerSafehouseData["SafehousePoints"][safehousePosition] =
        ServerSafehouseData["SafehousePoints"][safehousePosition] + 1;

    logger(player:getUsername() ..
        " adding upgrade to X: " .. safehouseToAddPoint:getX() .. " Y: " .. safehouseToAddPoint:getY());

    -- Send the message to the client
    sendServerCommand(player, "ServerSafehouse", "safehouseUpgraded", nil);
end

--Coletar pontos da safehouse
function ServerSafehouseCommands.reedeemSafehousePoints(module, command, player, args)
    local safehouseToRedeem = SafeHouse.getSafeHouse(player:getSquare());

    if not BelongsToTheSafehouse(player, safehouseToRedeem) then
        logger(player:getUsername() .. " is trying to redeem points from a safehouse that is not from him");
    end

    local safehousePosition = safehouseToRedeem:getX() .. safehouseToRedeem:getY();

    -- Null Check
    if not ServerSafehouseData["SafehouseRedeemPoints"] then ServerSafehouseData["SafehouseRedeemPoints"] = {} end
    if not ServerSafehouseData["SafehouseRedeemPoints"][safehousePosition] then ServerSafehouseData["SafehouseRedeemPoints"][safehousePosition] = 0; end

    -- Send to the client the points to redeem
    sendServerCommand(player, "ServerSafehouse", "reedemHousePoints",
        { points = ServerSafehouseData["SafehouseRedeemPoints"][safehousePosition] });

    logger(player:getUsername() ..
        " redeemed " ..
        ServerSafehouseData["SafehouseRedeemPoints"][safehousePosition] ..
        " points from X: " .. safehouseToRedeem:getX() .. " Y: " .. safehouseToRedeem:getY());

    -- Reseting the Points
    ServerSafehouseData["SafehouseRedeemPoints"][safehousePosition] = 0;
end

-- Add points to safehouse every hour in game
if SandboxVars.SafehousePlus.EnableSafehousePoints then
    Events.EveryHours.Add(function()
        --#region safehouse points calculation

        if ServerSafehousePointsTicks >= SandboxVars.SafehousePlus.SafehouseHoursPerPoints then
            ServerSafehousePointsTicks = 1;
            -- Null Check
            if not ServerSafehouseData["SafehouseRedeemPoints"] then ServerSafehouseData["SafehouseRedeemPoints"] = {} end
            if not ServerSafehouseData["SafehouseScore"] then ServerSafehouseData["SafehouseScore"] = {} end

            -- Swipe all safehouses to add points
            for safehousePosition, safehousePoints in pairs(ServerSafehouseData["SafehouseRedeemPoints"]) do
                -- Null Check
                if ServerSafehouseData["SafehouseScore"][safehousePosition] == nil then ServerSafehouseData["SafehouseScore"][safehousePosition] = 0 end

                -- Increment the value
                ServerSafehouseData["SafehouseRedeemPoints"][safehousePosition] = safehousePoints +
                    calculateScorePoints(ServerSafehouseData["SafehouseScore"][safehousePosition]);

                logger(safehousePosition .. " increased: " .. safehousePoints +
                    calculateScorePoints(ServerSafehouseData["SafehouseScore"][safehousePosition]) ..
                    " total: " .. ServerSafehouseData["SafehouseRedeemPoints"][safehousePosition]);
            end            
        else
            ServerSafehousePointsTicks = ServerSafehousePointsTicks + 1;
        end

        --#endregion

        --#region safehouse existence detection

        -- Get safehouses list
        if ServerSafehouseData["SafehouseRedeemPoints"] and SandboxVars.SafehousePlus.ResetPointsWhenNotClaimed then
            -- Get all safehouse in the server
            local safehouses = SafeHouse.getSafehouseList();
            -- Swipe all safehouses from points
            for safehousePosition, _ in ipairs(ServerSafehouseData["SafehouseRedeemPoints"]) do
                local stillExist = false;
                -- Swipe all safehouse from server
                for i = 0, safehouses:size() - 1 do
                    local selectedSafehouse = safehouses:get(i);
                    -- Getting safehouse position to check the condition
                    local existentSafehousePosition = selectedSafehouse:getX() .. selectedSafehouse:getY();
                    -- Checking if is the same as the existence in the server points
                    if existentSafehousePosition == safehousePosition then
                        stillExist = true;
                        break;
                    end
                end
                -- If not exist reset the redeem points
                if not stillExist then
                logger(safehousePosition .. " is not claimed points has been reseted");         
                    ServerSafehouseData["SafehouseRedeemPoints"][safehousePosition] = 0;
                end
            end
        end
        --#endregion
    end);
end

--Load Datas
Events.OnInitGlobalModData.Add(function(isNewGame)
    ServerSafehouseData = ModData.getOrCreate("ServerSafehouseData");
    if not ServerSafehouseData then ServerSafehouseData = {} end
end)

--Receives Commands from Clients
Events.OnClientCommand.Add(function(module, command, player, args)
    if module == "ServerSafehouse" and ServerSafehouseCommands[command] then
        ServerSafehouseCommands[command](module, command, player, args)
    end
end)
