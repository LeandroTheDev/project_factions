---@diagnostic disable: undefined-global
if isClient() then return end;
require "Farming/SFarmingSystem"
-- Check if feature is enabled
if SandboxVars.FactionsPlus.EnableReduceSeedDrop then
	-- Default Function for harvest
	function SFarmingSystem:harvest(luaObject, player)
		local skill = player:getPerkLevel(Perks.Farming)
		local props = farming_vegetableconf.props[luaObject.typeOfSeed]
		local numberOfVeg = getVegetablesNumber(props.minVeg, props.maxVeg, props.minVegAutorized, props.maxVegAutorized, luaObject, skill)
	
		if numberOfVeg > 0 and props.isFlower and player then
			player:getBodyDamage():setUnhappynessLevel(bodyDamage:getUnhappynessLevel() - numberOfVeg/2 )
			player:getBodyDamage():setBoredomLevel(player:getBodyDamage():getBoredomLevel() - numberOfVeg/2 )
			player:getStats():setStress(stats:getStress() - numberOfVeg/2 )
		end
	
		if props.vegetableName and player then
			local items = player:getInventory():AddItems(props.vegetableName, tonumber(numberOfVeg));
			sendAddItemsToContainer(player:getInventory(), items);
		end
	
		if props.produceExtra and player then
			local items = player:getInventory():AddItems(props.produceExtra, tonumber(numberOfVeg));
			sendAddItemsToContainer(player:getInventory(), items);
		end
	
		if luaObject.hasSeed and player then
			local seedPerVeg = props.seedPerVeg or 0.5 -- Add sandbox var for changing it
			local number = math.min(tonumber(math.floor(numberOfVeg * seedPerVeg)), 1)
			local items = player:getInventory():AddItems(props.seedName, number);
			sendAddItemsToContainer(player:getInventory(), items);
		end
	
		luaObject.hasVegetable = false
		luaObject.hasSeed = false
	
		-- the strawberrie don't disapear, it goes on phase 2 again
	-- 	if luaObject.typeOfSeed == "Strawberryplant" then
		if props.growBack then
			luaObject.nbOfGrow = props.growBack
			luaObject.fertilizer = 0;
			self:growPlant(luaObject, nil, true)
	--         self:setSpriteName(farming_vegetableconf.getSpriteName(luaObject))
	--         luaObject:setSpriteName(farming_vegetableconf.getSpriteName(luaObject))
			local sprite = farming_vegetableconf.getSpriteName(luaObject)
			if sprite then luaObject:setSpriteName(sprite) end
	
			luaObject:saveData()
		else
			-- change the plant to a harvested(destroyed) tile instead of removing it
	-- 	    luaObject:destroyThis()
			luaObject:harvestThis()
	-- 		self:removePlant(luaObject)
		end
	end
end
