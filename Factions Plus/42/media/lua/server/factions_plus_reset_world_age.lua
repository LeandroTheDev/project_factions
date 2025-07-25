---@diagnostic disable: undefined-global
if not SandboxVars.FactionsPlus.EnableCalendarReset then return end
Events.EveryDays.Add(function()
    local gameTime = getGameTime();
    local actualDay = gameTime:getDay();
    local actualMonth = gameTime:getMonth();
    local actualYear = gameTime:getYear();

    print("[Game Time] Actual Calendar: " .. "D:" .. actualDay .. " M:" .. actualMonth .. " Y:" .. actualYear);

    -- Setting the calendary to actual day
    gameTime:setStartDay(actualDay);
    gameTime:setStartMonth(actualMonth);
    gameTime:setStartYear(actualYear);
    gameTime:setStartTimeOfDay(0.0);

    -- Updating also the sandbox option
    getSandboxOptions():set("StartMonth", actualMonth);
    getSandboxOptions():set("StartDay", actualDay);
    getSandboxOptions():set("StartYear", actualYear);

    print("[Game Time] Start days has been reseted!")
end);
