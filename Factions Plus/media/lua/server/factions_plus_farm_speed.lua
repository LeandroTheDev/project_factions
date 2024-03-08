---@diagnostic disable: undefined-global, lowercase-global
-- Check if feature is enabled
if SandboxVars.FactionsPlus.EnableFarmSpeed then
    -- Default function for calculate the speed
    function calcNextGrowing(nextGrowing, nextTime)
        if nextGrowing then
            return nextGrowing;
        end
        if SandboxVars.Farming == 1 then -- very fast
            nextTime = nextTime / 40; -- 40 times faster
        end
        if SandboxVars.Farming == 2 then -- fast
            nextTime = nextTime / 30; -- 30 times faster
        end
        if SandboxVars.Farming == 4 then -- slow
            nextTime = nextTime / 20; -- 20 times faster
        end
        if SandboxVars.Farming == 5 then -- very slow
            nextTime = nextTime / 10; -- 10 times faster
        end
        return SFarmingSystem.instance.hoursElapsed + nextTime;
    end
end