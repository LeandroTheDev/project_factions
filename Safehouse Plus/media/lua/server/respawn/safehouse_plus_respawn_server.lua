---@diagnostic disable: undefined-global

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
        print("[Safehouse] " .. player:getUsername() .. " spawnpoint is not in valid safehouse")
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
        --Se o id da safehouse do jogador for igual da varredura
        print("PLAYER SAFEHOUSE ID: " .. playerSafehouseId .. " VARREDURA: " .. selectedSafehouse:getId());
        if playerSafehouseId == selectedSafehouseId then
            -- Verify if this safehouse is valid and
            -- the player owns this safehouse
            if isEnemy(selectedSafehouse) then
                -- Caso não for valida então ele não pode renascer
                print("[Safehouse] " .. player:getUsername() .. " cannot spawn in safehouse, doesn't belong to it")
                sendServerCommand(player, "ServerRespawn", "canSpawn", {
                    canSpawn = false,
                });
                return;
            else
                -- If is not enemy so...
                print("[Safehouse] " .. player:getUsername() .. " belongs to the safehouse so can spawn in safehouse bed")
                sendServerCommand(player, "ServerRespawn", "canSpawn", {
                    canSpawn = true,
                });
                return;
            end
        end
    end
    -- If the swipe cannot find anything
    -- This means the player factions doesnt own any safehouses
    print("[Safehouse] " .. player:getUsername() .. " spawnpoint is on any empty safehouse, cannot spawn")
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
