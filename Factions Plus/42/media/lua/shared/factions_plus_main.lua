FactionsPlusCompatibility = true;
FactionsPlusName = "FactionsPlus";
FactionsPlusIsSinglePlayer = false;

if not isClient() and not isServer() then
    FactionsPlusIsSinglePlayer = true;
end

function DebugPrintFactionsPlus(log)
    if FactionsPlusIsSinglePlayer then
        print("[" .. FactionsPlusName .. "] " .. log);
    else
        if isClient() then
            print("[" .. FactionsPlusName .. "-Client] " .. log);
        else
            if isServer() then
                print("[" .. FactionsPlusName .. "-Server] " .. log);
            else
                print("[" .. FactionsPlusName .. "-Unkown] " .. log);
            end
        end
    end
end