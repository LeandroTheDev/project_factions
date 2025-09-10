SafehousePlusCompatibility = true;
SafehousePlusName = "SafehousePlus";
SafehousePlusIsSinglePlayer = false;

if not isClient() and not isServer() then
    SafehousePlusIsSinglePlayer = true;
end

function DebugPrintSafehousePlus(log)
    if SafehousePlusIsSinglePlayer then
        print("[" .. SafehousePlusName .. "] " .. log);
    else
        if isClient() then
            print("[" .. SafehousePlusName .. "-Client] " .. log);
        else
            if isServer() then
                print("[" .. SafehousePlusName .. "-Server] " .. log);
            else
                print("[" .. SafehousePlusName .. "-Unkown] " .. log);
            end
        end
    end
end