if isClient() or not FactionsIsSinglePlayer then return end;

FactionsEconomyLootBoxRecipe = FactionsEconomyLootBoxRecipe or {};

FactionsEconomyLootBoxRecipe.OpenLootBox = function(craftRecipeData, player)
    DebugPrintFactionsEconomy(player:getUsername() .. " trying to open a loot box...");

    local consumedItems = craftRecipeData:getAllConsumedItems();

    for i = 0, consumedItems:size() - 1 do
        local item = consumedItems:get(i);
        local sandboxTable = "FactionsEconomy." .. item:getType();

        DebugPrintFactionsEconomy(player:getUsername() ..
            " lootbox opened: " .. item:getType() .. ", Sandbox Table: " .. sandboxTable);
        local chanceTable = getSandboxOptions():getOptionByName(sandboxTable):getValue();

        -- Convert string to table
        local result = {}
        for key, value in chanceTable:gmatch("([^/]+)/([^/]+)/") do
            table.insert(result, { key = key, value = tonumber(value) });
        end

        local function shuffle(table)
            for j = #table, 2, -1 do
                local x = ZombRand(j) + 1;
                table[j], table[x] = table[x], table[j];
            end
        end
        shuffle(result);

        -- Check if table value exist
        if #result <= 0 then
            DebugPrintFactionsEconomy("No values found for lootbox: " .. item:getType());
            return;
        end

        -- Items iteration
        local maxChances = 0;
        while true do
            if maxChances > 20 then
                DebugPrintFactionsEconomy(player:getUsername() .. " has reach the loot box row limit, wow!");

                local randomEntry = result[ZombRand(#result) + 1];
                player:getInventory():AddItems(randomEntry.key, 1);

                DebugPrintFactionsEconomy(player:getUsername() ..
                    " received: " .. randomEntry.key .. ", from lootbox: " .. item:getType());
                return;
            end

            for _, entry in ipairs(result) do
                local chance = ZombRand(100) + 1;
                if entry.value > chance then
                    player:getInventory():AddItems(entry.key, 1);

                    DebugPrintFactionsEconomy(player:getUsername() ..
                        " received: " .. entry.key .. ", from lootbox: " .. item:getType());
                    return;
                end
            end
            maxChances = maxChances + 1;
        end
    end
end
