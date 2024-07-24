---@diagnostic disable: undefined-global
local function sendMessageToAllPlayers(message, player)
    local onlinePlayers = getOnlinePlayers();

    -- Swiping all online players
    for i = 0, onlinePlayers:size() - 1 do
        local selectedPlayer = onlinePlayers:get(i);
        sendServerCommand(selectedPlayer, "ServerMessages", message, { playerUsername = player:getUsername() });
    end
end

-- Death message
if SandboxVars.FactionsPlus.EnablePlayerDeathMessages then
    local function OnPlayerDeath(player) sendMessageToAllPlayers("playerdead", player) end

    Events.OnPlayerDeath.Add(OnPlayerDeath);
end

-- Player message handler
Events.OnClientCommand.Add(function(module, command, player, args)
    -- Connection message
    if module == "ServerMessages" and command == "iconnected" and SandboxVars.FactionsPlus.EnablePlayerJoinMessages then
        sendMessageToAllPlayers("playerconnected", player);
    end
    -- Disconnect message
    if module == "ServerMessages" and command == "idisconnected" and SandboxVars.FactionsPlus.EnablePlayerLeaveMessages then
        sendMessageToAllPlayers("playerdisconnected", player);
    end
end)
