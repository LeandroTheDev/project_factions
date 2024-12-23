---@diagnostic disable: undefined-global, lowercase-global
-- Check if feature is enabled
if SandboxVars.FactionsPlus.EnableReduceWaterNeed then
	-- Default function for watering crops
	function ISWaterPlantAction:perform()
		self.item:getContainer():setDrawDirty(true);
		self.item:setJobDelta(0.0);

		if self.sound and self.sound ~= 0 then
			self.character:getEmitter():stopOrTriggerSound(self.sound)
		end

		local args = { x = self.sq:getX(), y = self.sq:getY(), z = self.sq:getZ(), uses = self.uses }
		CFarmingSystem.instance:sendCommand(self.character, 'water', args)

		local plant = CFarmingSystem.instance:getLuaObjectOnSquare(self.sq)
		local waterLvl = plant.waterLvl
		for i = 1, self.uses do
			if (waterLvl < 100) then
				if self.item:getUsedDelta() > 0 then
					self.item:Use()
				end
				-- Default is 5, we need to increase this number
				-- so wen the player watering the seed its water more
				-- than necessary
				waterLvl = waterLvl + 20
				if (waterLvl > 100) then
					waterLvl = 100
				end
			end
		end
		local leftUses = math.floor(self.item:getUsedDelta() / self.item:getUseDelta())
		self.item:setUsedDelta(leftUses * self.item:getUseDelta())

		ISBaseTimedAction.perform(self);
	end
end
