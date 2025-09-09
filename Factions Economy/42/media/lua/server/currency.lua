FactionsEconomyCurrencyData = {};
FactionsEconomyCurrencyRecipe = FactionsEconomyCurrencyRecipe or {};
local currencyPertick = getSandboxOptions():getOptionByName("FactionsEconomy.CurrencyPerTick"):getValue();

--#region Tick

function GiveCurrencyToPlayers()
    if FactionsEconomyIsSinglePlayer then
        local player = getPlayer();
        -- Check if the key exists, if not add the value 0
        if not FactionsEconomyCurrencyData[player:getUsername()] then FactionsEconomyCurrencyData[player:getUsername()] = 0 end;

        -- Increment player currency
        FactionsEconomyCurrencyData[player:getUsername()] = FactionsEconomyCurrencyData[player:getUsername()] +
            currencyPertick;

        DebugPrintFactionsEconomy(player:getUsername() .. " currency: " .. FactionsEconomyCurrencyData[player:getUsername()]);
    else
        local onlinePlayers = getOnlinePlayers();
        for i = 0, onlinePlayers:size() - 1 do
            local player = onlinePlayers:get(i);
            -- Check if the key exists, if not add the value 0
            if not FactionsEconomyCurrencyData[player:getUsername()] then FactionsEconomyCurrencyData[player:getUsername()] = 0 end;

            -- Increment player currency
            FactionsEconomyCurrencyData[player:getUsername()] = FactionsEconomyCurrencyData[player:getUsername()] +
                currencyPertick;

            DebugPrintFactionsEconomy(player:getUsername() .. " currency: " .. FactionsEconomyCurrencyData[player:getUsername()]);
        end
    end
end

if getSandboxOptions():getOptionByName("FactionsEconomy.CurrencyFrequency"):getValue() == 1 then
    DebugPrintFactionsEconomy("Points Frequency: EveryOneMinute");
    Events.EveryOneMinute.Add(GiveCurrencyToPlayers);
elseif getSandboxOptions():getOptionByName("FactionsEconomy.CurrencyFrequency"):getValue() == 2 then
    DebugPrintFactionsEconomy("Points Frequency: EveryTenMinutes");
    Events.EveryTenMinutes.Add(GiveCurrencyToPlayers);
elseif getSandboxOptions():getOptionByName("FactionsEconomy.CurrencyFrequency"):getValue() == 3 then
    DebugPrintFactionsEconomy("Points Frequency: EveryHours");
    Events.EveryHours.Add(GiveCurrencyToPlayers);
elseif getSandboxOptions():getOptionByName("FactionsEconomy.CurrencyFrequency"):getValue() == 4 then
    DebugPrintFactionsEconomy("Points Frequency: EveryDays");
    Events.EveryDays.Add(GiveCurrencyToPlayers);
end

Events.OnInitGlobalModData.Add(function(isNewGame)
    FactionsEconomyCurrencyData = ModData.getOrCreate("FactionsEconomyCurrency");
end)

--#endregion

--#region Recipe Functions

FactionsEconomyCurrencyRecipe.ReturnCurrency = function(craftRecipeData, player)
    DebugPrintFactionsEconomy(player:getUsername() .. " returned currency");

    if not FactionsEconomyCurrencyData[player:getUsername()] then FactionsEconomyCurrencyData[player:getUsername()] = 0 end;

    FactionsEconomyCurrencyData[player:getUsername()] = FactionsEconomyCurrencyData[player:getUsername()] + 1;

    player:Say(getText("IGUI_Shop_Return"));
end

FactionsEconomyCurrencyRecipe.SellSmallScrap = function(craftRecipeData, player)
    DebugPrintFactionsEconomy(player:getUsername() .. " sell small scrap");

    if not FactionsEconomyCurrencyData[player:getUsername()] then FactionsEconomyCurrencyData[player:getUsername()] = 0 end;

    local smallScrapPrice = getSandboxOptions():getOptionByName("FactionsEconomy.SmallStackScrapValue"):getValue();

    FactionsEconomyCurrencyData[player:getUsername()] = FactionsEconomyCurrencyData[player:getUsername()] +
        smallScrapPrice;

    player:Say(getText("IGUI_Shop_Sell") .. " + " .. smallScrapPrice);
end

FactionsEconomyCurrencyRecipe.SellMediumScrap = function(craftRecipeData, player)
    DebugPrintFactionsEconomy(player:getUsername() .. " sell medium scrap");

    if not FactionsEconomyCurrencyData[player:getUsername()] then FactionsEconomyCurrencyData[player:getUsername()] = 0 end;

    local mediumScrapPrice = getSandboxOptions():getOptionByName("FactionsEconomy.MediumStackScrapValue"):getValue();

    FactionsEconomyCurrencyData[player:getUsername()] = FactionsEconomyCurrencyData[player:getUsername()] +
        mediumScrapPrice;

    player:Say(getText("IGUI_Shop_Sell") .. " + " .. mediumScrapPrice);
end

FactionsEconomyCurrencyRecipe.SellLargeScrap = function(craftRecipeData, player)
    DebugPrintFactionsEconomy(player:getUsername() .. " sell large scrap");

    if not FactionsEconomyCurrencyData[player:getUsername()] then FactionsEconomyCurrencyData[player:getUsername()] = 0 end;

    local largeScrapPrice = getSandboxOptions():getOptionByName("FactionsEconomy.LargeStackScrapValue"):getValue();

    FactionsEconomyCurrencyData[player:getUsername()] = FactionsEconomyCurrencyData[player:getUsername()] +
        largeScrapPrice;

    player:Say(getText("IGUI_Shop_Sell") .. " + " .. largeScrapPrice);
end

FactionsEconomyCurrencyRecipe.SellVegetable = function(craftRecipeData, player)
    DebugPrintFactionsEconomy(player:getUsername() .. " sell vegetable");

    if not FactionsEconomyCurrencyData[player:getUsername()] then FactionsEconomyCurrencyData[player:getUsername()] = 0 end;

    local vegetablePrice = getSandboxOptions():getOptionByName("FactionsEconomy.VegetableValue"):getValue();

    FactionsEconomyCurrencyData[player:getUsername()] = FactionsEconomyCurrencyData[player:getUsername()] +
        vegetablePrice;

    player:Say(getText("IGUI_Shop_Sell") .. " + " .. vegetablePrice);
end

--#endregion

--#region Client Requests

local function getCurrency(module, command, player, args)
    sendServerCommand(player, "FactionsEconomyCurrency", "receiveCurrency",
        { FactionsEconomyCurrencyData[player:getUsername()] or 0 })
end

Events.OnClientCommand.Add(function(module, command, player, args)
    if module == "FactionsEconomyCurrency" and command == "getCurrency" then
        getCurrency(module, command, player, args);
    end
end)

--#endregion
