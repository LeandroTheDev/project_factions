---@diagnostic disable: undefined-global
if isClient() then return end;
local ServerSafehouseCommands = {};
local ServerSafehouseData = {};

-- Calculate the score based in safehouse points
local function calculateScorePoints(points)
    local result = points / 2
    if result <= 1 then
        return 1
    else
        return result
    end
end

-- Add points for the safehouse
function ServerSafehouseCommands.addSafehousePoint(module, command, player, args)
    local safehouseToAddPoint = SafeHouse.getSafeHouse(player:getSquare());
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
Events.EveryHours.Add(function()
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
end);

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
