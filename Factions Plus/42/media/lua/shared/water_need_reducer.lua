if not getSandboxOptions():getOptionByName("FactionsPlus.EnableReduceWaterNeed"):getValue() then return end

-- SPlantGlobalObject.lua
if SPlantGlobalObject then
    function SPlantGlobalObject:water(waterSource, uses)
        for i = 1, uses do
            if self.waterLvl < 100 then
                if waterSource then
                    if waterSource:getCurrentUsesFloat() > 0 then
                        waterSource:Use()
                    end
                end
                self.waterLvl = self.waterLvl +
                    getSandboxOptions():getOptionByName("FactionsPlus.WaterLevelIncreasePerTick"):getValue()
                if self.waterLvl > 100 then
                    self.waterLvl = 100
                end
            end
        end
        -- we notice the hour of our last water, because if we don't water the plant every 48 hours, she die
        self.lastWaterHour = SFarmingSystem.instance.hoursElapsed;
        self:saveData()
    end
end

-- ISWaterPlantAction.lua
function ISWaterPlantAction:complete()
    if self.item then
        self.item:setJobDelta(0.0);
    end
    -- we check for the watering item's existence, just in case it has already been used up.
    if self.item and self.uses > 0 then
        if self.item:getContainer() then
            self.item:getContainer():setDrawDirty(true);
        end
        --         self.item:setJobDelta(0.0);
        -- 	local args = { x = self.sq:getX(), y = self.sq:getY(), z = self.sq:getZ(), uses = self.uses }
        -- 	CFarmingSystem.instance:sendCommand(self.character, 'water', args)

        -- Hack: use the water, too hard to get the server to update the client's inventory
        local plant = SFarmingSystem.instance:getLuaObjectOnSquare(self.sq)
        local waterLvl = plant.waterLvl
        local uses = self.uses
        --         local uses = self.uses - self.usesUsed

        if uses > 0 then
            -- SPlantGlobalObject:water
            plant:water(nil, uses);

            for i = 1, uses do
                if (waterLvl < 100) then
                    self:useItemOneUnit()
                    waterLvl = waterLvl +
                        getSandboxOptions():getOptionByName("FactionsPlus.WaterLevelIncreasePerTick"):getValue();
                    if (waterLvl > 100) then
                        waterLvl = 100
                    end
                end
            end
        end
    end

    return true;
end
