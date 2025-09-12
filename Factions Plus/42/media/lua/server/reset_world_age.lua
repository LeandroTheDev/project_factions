if not getSandboxOptions():getOptionByName("FactionsPlus.EnableCalendarReset"):getValue() then return end

Events.EveryDays.Add(function()
    local gameTime = getGameTime();
    local actualDay = gameTime:getDay();
    local actualMonth = gameTime:getMonth();
    local actualYear = gameTime:getYear();

    DebugPrintFactionsPlus("Actual Calendar: " .. "D:" .. actualDay .. " M:" .. actualMonth .. " Y:" .. actualYear);

    -- Setting the calendary to actual day
    gameTime:setStartDay(actualDay);
    gameTime:setStartMonth(actualMonth);
    gameTime:setStartYear(actualYear);
    gameTime:setStartTimeOfDay(0.0);
    gameTime:save();

    -- Updating also the sandbox option
    getSandboxOptions():set("StartMonth", actualMonth);
    getSandboxOptions():set("StartDay", actualDay);
    getSandboxOptions():set("StartYear", actualYear);
    getSandboxOptions():set("TimeSinceApo", 0);

    if FactionsPlusIsSinglePlayer then
        local player = getPlayer();

        sendServerCommand(player, "ResetWorldAge", "updateSandbox",
            { StartMonth = actualMonth, StartDay = actualDay, StartYear = actualYear });
    else
        local onlinePlayers = getOnlinePlayers();
        for i = 0, onlinePlayers:size() - 1 do
            local player = onlinePlayers:get(i);

            sendServerCommand(player, "ResetWorldAge", "updateSandbox",
                { StartMonth = actualMonth, StartDay = actualDay, StartYear = actualYear });
        end
    end

    DebugPrintFactionsPlus("Start days has been reseted!")
end);
