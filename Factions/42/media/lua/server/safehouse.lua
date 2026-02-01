if isClient() and not FactionsIsSinglePlayer then return end;

--#region Client Requests

local function claimSafehouse(module, command, player, args)
    local faction = GetPlayerFaction(player:getUsername())
    if faction == nil then return end
    if not FactionsData[faction:getName()] then return end

    -- Claim check
    local safehouse = Safehouse.getSafehouse(player:getSquare())
    if not safehouse then
        sendServerCommand(player, "Factions", "claimSafehouseResponse",
            { "Safehouse already claimed" })
        return
    end

    -- Points check
    local points = (FactionsData[faction:getName()]["points"] or 0) - GetFactionUsedPoints(faction)
    if points <= 0 then
        sendServerCommand(player, "Factions", "claimSafehouseResponse",
            { "Not enough points" })
        return
    end

    -- Cost check
    local safehouseCost = GetSafehouseCost(player:getBuilding())
    if safehouseCost > points then
        sendServerCommand(player, "Factions", "claimSafehouseResponse",
            { "Not enough points" })
        return
    end

    -- Safehouse update
    safehouse.setOwner(faction:getOwner())
    safehouse.setPlayers(faction:getPlayers())

    -- Client refresh
    local onlinePlayers = getOnlinePlayers()
    for i = 0, onlinePlayers:size() - 1 do
        local onlinePlayer = onlinePlayers:get(i)
        safehouse.updateSafehouse(onlinePlayer)
    end

    sendServerCommand(player, "Factions", "claimSafehouseResponse",
        { "Success" })
end

Events.OnClientCommand.Add(function(module, command, player, args)
    if module == "Factions" and command == "claimSafehouse" then
        claimSafehouse(module, command, player, args)
    end
end)

--#endregion
