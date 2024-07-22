---@diagnostic disable: undefined-global
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
        print("[Factions Plus] " ..
        player:getUsername() .. " is trying to add points from a safehouse that is not from him");
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

    -- Send the message to the client
    sendServerCommand(player, "ServerSafehouse", "safehouseUpgraded", nil);
end

--Coletar pontos da safehouse
function ServerSafehouseCommands.reedeemSafehousePoints(module, command, player, args)
    local safehouseToAddPoint = SafeHouse.getSafeHouse(player:getSquare());

    if not BelongsToTheSafehouse(player, safehouseToAddPoint) then
        print("[Factions Plus] " ..
        player:getUsername() .. " is trying to redeem points from a safehouse that is not from him");
    end

    local safehousePosition = safehouseToAddPoint:getX() .. safehouseToAddPoint:getY();

    -- Null Check
    if not ServerSafehouseData["SafehouseRedeemPoints"] then ServerSafehouseData["SafehouseRedeemPoints"] = {} end
    if not ServerSafehouseData["SafehouseRedeemPoints"][safehousePosition] then ServerSafehouseData["SafehouseRedeemPoints"][safehousePosition] = 0; end

    -- Send to the client the points to redeem
    sendServerCommand(player, "ServerSafehouse", "reedemHousePoints",
        { points = ServerSafehouseData["SafehouseRedeemPoints"][safehousePosition] });

    -- Reseting the Points
    ServerSafehouseData["SafehouseRedeemPoints"][safehousePosition] = 0;
end

-- Add points to safehouse every hour in game
if SandboxVars.SafehousePlus.EnableSafehousePoints then
    Events.EveryHours.Add(function()
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
            end
        else
            ServerSafehousePointsTicks = ServerSafehousePointsTicks + 1;
        end
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
