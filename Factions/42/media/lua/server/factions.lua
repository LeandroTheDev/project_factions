-- {
--      "FactionName1": {
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
    for i, username in pairs(faction:getPlayers()) do
        local player = getPlayerFromUsername(username)
        if player then
            sendServerCommand(player, "Factions", "receivePoints",
                { points })
        end
    end
end

--#region Client Requests

local function updateFactionPoints(module, command, player, args)
    local faction = GetPlayerFaction(player:getUsername())
    if faction == nil then return end

    if not FactionsData[faction:getName()] then FactionsData[faction:getName()] = { points = 0 } end

    FactionsData[faction:getName()]["points"] = FactionsData[faction:getName()]["points"] + args.kills
end

Events.OnClientCommand.Add(function(module, command, player, args)
    if module == "Factions" and command == "updateFactionPoints" then
        updateFactionPoints(module, command, player, args)
    end
end)

--#endregion
