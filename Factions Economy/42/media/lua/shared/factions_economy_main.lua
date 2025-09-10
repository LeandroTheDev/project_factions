FactionsEconomyCompatibility = true;
FactionsEconomyName = "FactionsEconomy";
FactionsEconomyIsSinglePlayer = false;

if not isClient() and not isServer() then
    FactionsEconomyIsSinglePlayer = true;
end

function DebugPrintFactionsEconomy(log)
    if FactionsEconomyIsSinglePlayer then
        print("[" .. FactionsEconomyName .. "] " .. log);
    else
        if isClient() then
            print("[" .. FactionsEconomyName .. "-Client] " .. log);
        else
            if isServer() then
                print("[" .. FactionsEconomyName .. "-Server] " .. log);
            else
                print("[" .. FactionsEconomyName .. "-Unkown] " .. log);
            end
        end
    end
end
