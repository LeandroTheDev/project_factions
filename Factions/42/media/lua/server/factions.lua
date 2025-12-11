-- {
--      "FactionName1": {
--          "points": 123,
--       },
--      "FactionName2": {
--          "points": 123,
--       }
-- }
FactionsData = {}

Events.OnInitGlobalModData.Add(function(isNewGame)
    FactionsData = ModData.getOrCreate("FactionsData");
end)

function RefreshFactionPlayersPoints(faction)
    if not faction then return end
    if not FactionsData[faction:getName()] then return end

    local points = FactionsData[faction:getName()]["points"]

    -- Iterate all players in faction
    for _, username in pairs(faction:getPlayers()) do
        local player = getPlayerFromUsername(username)
        if player then
            sendServerCommand(player, "Factions", "receivePoints",
                { points })

            DebugPrintFactions(player.getUsername() .. " refreshed points: " .. points)
        end
    end
end

Events.EveryTenMinutes.Add(function()
    local factions = Faction.getFactions()
    for i = 0, factions:size() - 1 do
        local faction = factions:get(i)
        RefreshFactionPlayersPoints(faction)
    end
end)

--#region Client Requests

local function updateFactionPoints(module, command, player, args)
    local faction = GetPlayerFaction(player:getUsername())
    if faction == nil then return end

    if not FactionsData[faction:getName()] then FactionsData[faction:getName()] = { points = 0 } end

    FactionsData[faction:getName()]["points"] = FactionsData[faction:getName()]["points"] + args.kills

    DebugPrintFactions(player.getUsername() ..
        " earned " .. args.kills .. " points for their faction: " .. faction.getName())
end

Events.OnClientCommand.Add(function(module, command, player, args)
    if module == "Factions" and command == "updateFactionPoints" then
        updateFactionPoints(module, command, player, args)
    end
end)

--#endregion
