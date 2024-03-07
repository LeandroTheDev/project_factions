---@diagnostic disable: undefined-global, deprecated
ServerShopData = {};
local shopItems = {};
local tradeItems = {};

--Thanks chat gpt
-- local function formatarTabela(tabela, nivel)
--     nivel = nivel or 0
--     local prefixo = string.rep("  ", nivel) -- Espaços para recuo
--     if type(tabela) == "table" then
--         local str = "{\n"
--         for chave, valor in pairs(tabela) do
--             str = str .. prefixo .. "  [" .. tostring(chave) .. "] = "
--             if type(valor) == "table" then
--                 str = str .. formatarTabela(valor, nivel + 1) .. ",\n"
--             else
--                 str = str .. tostring(valor) .. ",\n"
--             end
--         end
--         str = str .. prefixo .. "}"
--         return str
--     else
--         return tostring(tabela)
--     end
-- end

local function PointsTick()
    local players = getOnlinePlayers()
    for i = 0, players:size() - 1 do
        local username = players:get(i):getUsername()
        if not ServerShopData[username] then ServerShopData[username] = 0 end
        ServerShopData[username] = ServerShopData[username] + SandboxVars.FactionsEconomy.PointsPerTick
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
    print("[Factions Economy] Shop items has been loaded")
    shopItems = loadstring(table.concat(lines, "\n"))() or { ["Missing Configuration"] = {} }
end

-- Simple load the items from the server data
local function LoadTradeItems()
    if ServerShopData["ServerTradeItems"] == nil then ServerShopData["ServerTradeItems"] = { ["No_Items"] = {} } end
    print("[Factions Economy] Trade items has been loaded")
    tradeItems = ServerShopData["ServerTradeItems"];
end

Events.OnInitGlobalModData.Add(function(isNewGame)
    ServerShopData = ModData.getOrCreate("ServerShopData")

    LoadShopItems()
    LoadTradeItems()

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
    print(string.format("[Factions Economy] %s added %d %s item for %d points in trade", player:getUsername(),
        args[1].quantity, args[1].target, args[1].price))

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
    print(string.format("[Factions Economy] %s bought %s for %d points", player:getUsername(), args[1].type,
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
    sendServerCommand(player, module, command, tradeItems)
end

-- Buy from shop
function ServerPointsCommands.buyShop(module, command, player, args)
    print(string.format("[Factions Economy] %s bought %s for %d points", player:getUsername(), args[2], args[1]))
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
    sendServerCommand(player, module, command, shopItems)
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
    print(string.format("[Factions Economy] " .. args[1] .. " Received " .. args[2] .. " Points"));
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
