---@diagnostic disable: undefined-global
require "Farming/SFarmingSystem"
-- Check if feature is enabled
if SandboxVars.FactionsPlus.EnableReduceSeedDrop then
	-- Default Function for harvest
	function SFarmingSystem:harvest(luaObject, player)
		local props = farming_vegetableconf.props[luaObject.typeOfSeed]
		local numberOfVeg = getVegetablesNumber(props.minVeg, props.maxVeg, props.minVegAutorized, props.maxVegAutorized,
			luaObject)
		if player then
			player:sendObjectChange('addItemOfType', { type = props.vegetableName, count = numberOfVeg })
		end
		if luaObject.hasSeed and player then
			for i = 1, numberOfVeg do
				-- Here we reduce the chance to spawn seed
				-- 25% Chance to drop 1 seed
				if ZombRand(2) == 0 then
					player:sendObjectChange('addItemOfType', { type = props.seedName, count = 1 })
				end
			end
		end

		luaObject.hasVegetable = false
		luaObject.hasSeed = false
		if luaObject.typeOfSeed == "Strawberry plant" then
			luaObject.nbOfGrow = 1
			luaObject.fertilizer = 0;
			self:growPlant(luaObject, nil, true)
			luaObject:saveData()
		else
			self:removePlant(luaObject)
		end
	end
end
