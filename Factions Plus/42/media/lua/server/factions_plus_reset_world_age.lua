---@diagnostic disable: undefined-global
if not SandboxVars.FactionsPlus.EnableCalendarReset then return end
Events.EveryDays.Add(function()
    -- Recebemos a classe que contem todas as informações que queremos
    local gameTime = getGameTime();
    -- Recebemos o dia atual
    local actualDay = gameTime:getDay();
    -- Recebemos o mes atual
    local actualMonth = gameTime:getMonth();
    -- Recebemos o ano atual
    local actualYear = gameTime:getYear();

    print("[Game Time] Actual Calendar: " .. "D:" .. actualDay .. " M:" .. actualMonth .. " Y:" .. actualYear);

    -- Setamos o calendario inicial para o dial atual
    -- afim de resetar as comidas estragadas
    gameTime:setStartDay(actualDay);
    gameTime:setStartMonth(actualMonth);
    gameTime:setStartYear(actualYear);
    gameTime:setStartTimeOfDay(0.0);

    print("[Game Time] Start days has been reseted!")
end);
