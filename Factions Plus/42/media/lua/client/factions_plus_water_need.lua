---@diagnostic disable: undefined-global, lowercase-global
-- Check if feature is enabled
if SandboxVars.FactionsPlus.EnableReduceWaterNeed then
	-- Default function for watering crops
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
				plant:water(nil, uses);
	
				for i=1,uses do
					if(waterLvl < 100) then
						self:useItemOneUnit()
						waterLvl = waterLvl + 50 -- Add sandbox var for changing it
						if(waterLvl > 100) then
							waterLvl = 100
						end
					end
				end
			end
		end
	
		return true;
	end
end
