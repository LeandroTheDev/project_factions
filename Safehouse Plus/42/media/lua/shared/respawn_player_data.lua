Respawn = Respawn or {}

--Save player

function savePlayer(player)
    saveRespawnLocation(player);
    savePlayerLevels(player);
    savePlayerBoosts(player);
    savePlayerBooks(player);
    savePlayerMedia(player);
    savePlayerMultipliers(player);
    savePlayerInventory(player);
    savePlayerModel(player);
    savePlayerNutrition(player);
    savePlayerFitness(player);
    savePlayerStats(player);
    savePlayerFavoriteRecipes(player);

    Respawn.Traits = player:getTraits();
    Respawn.Profession = player:getDescriptor():getProfession();
    Respawn.Recipes = player:getKnownRecipes();
    Respawn.ZombieKills = player:getZombieKills();
    Respawn.SurvivorKills = player:getSurvivorKills();
    Respawn.HoursSurvived = player:getHoursSurvived();
    Respawn.LevelUpMultiplier = player:getLevelUpMultiplier();
    Respawn.AutoRespawn = isAutoRespawn(player);
end

function savePlayerLevels(player)
    Respawn.Xp = {};
    Respawn.Levels = {};
    local perks = PerkFactory.PerkList;

    for i = 0, perks:size() - 1 do
        local perk = perks:get(i);

        Respawn.Levels[perk] = player:getPerkLevel(perk);
        Respawn.Xp[perk] = player:getXp():getXP(perk);
    end
end

function savePlayerBoosts(player)
    Respawn.Boosts = {};
    local perks = PerkFactory.PerkList;
    local boosts = player:getXp();

    for i = 0, perks:size() - 1 do
        local perk = perks:get(i);
        Respawn.Boosts[perk] = boosts:getPerkBoost(perk);
    end
end

function savePlayerBooks(player)
    Respawn.SkillBooks = {};
    local items = getAllItems();

    for i = 0, items:size() - 1 do
        if (items:get(i):getTypeString() == "Literature") then
            local item = items:get(i):InstanceItem(items:get(i):getName());
            if (item ~= nil and item:IsLiterature() and item:getNumberOfPages() > 0) then
                Respawn.SkillBooks[item:getFullType()] = player:getAlreadyReadPages(item:getFullType());
            end
        end
    end
end

function savePlayerMedia(player)
    Respawn.Media = {};

    for _, media in pairs(RecMedia) do
        for _, line in pairs(media.lines or {}) do
            if (player:isKnownMediaLine(line.text)) then
                table.insert(Respawn.Media, line.text);
            end;
        end
    end
end

function savePlayerMultipliers(player)
    Respawn.Multipliers = {};
    local perks = PerkFactory.PerkList;

    for i = 0, perks:size() - 1 do
        local perk = perks:get(i);
        Respawn.Multipliers[perk] = player:getXp():getMultiplier(perk);
    end
end

function savePlayerInventory(player)
    Respawn.Hotbar = player:getModData().hotbar;
    local WornItems = player:getWornItems();
    Respawn.WornItems = {};

    for i = 0, WornItems:size() - 1 do
        Respawn.WornItems[i] = WornItems:get(i);
    end

    local AttachedItems = player:getAttachedItems();
    Respawn.AttachedItems = {};

    for i = 0, AttachedItems:size() - 1 do
        Respawn.AttachedItems[i] = AttachedItems:get(i);
    end

    Respawn.Items = player:getInventory():getItems():clone();
end

function saveRespawnLocation(player)
    local pModData = player:getModData();
    Respawn.X = pModData.RespawnX;
    Respawn.Y = pModData.RespawnY;
    Respawn.Z = pModData.RespawnZ;
end

function saveEquipItems(player)
    player:dropHeavyItems();

    Respawn.PrimaryHandItem = player:getPrimaryHandItem();
    player:setPrimaryHandItem(nil);

    Respawn.SecondaryHandItem = player:getSecondaryHandItem();
    player:setSecondaryHandItem(nil);
end

function savePlayerModel(player)
    Respawn.Visual = {};
    Respawn.Visual.SkinTexture = player:getVisual():getSkinTextureIndex();
    Respawn.Visual.SkinTextureName = player:getVisual():getSkinTexture();
    Respawn.Visual.NonAttachedHair = player:getVisual():getNonAttachedHair();
    Respawn.Visual.BodyHair = player:getVisual():getBodyHairIndex();
    Respawn.Visual.Outfit = player:getVisual():getOutfit();
    Respawn.Visual.HairModel = player:getVisual():getHairModel();
    Respawn.Visual.BeardModel = player:getVisual():getBeardModel();
    Respawn.Visual.SkinColor = player:getVisual():getSkinColor();
    Respawn.Visual.HairColor = player:getVisual():getHairColor();
    Respawn.Visual.BeardColor = player:getVisual():getBeardColor();

    if (Respawn.Visual.Outfit) then
        Respawn.Visual.Outfit = Respawn.Visual.Outfit:clone();
    end

    Respawn.Descriptor = {};
    Respawn.Descriptor.Age = player:getAge();
    Respawn.Descriptor.Female = player:isFemale();
    Respawn.Descriptor.Forename = player:getDescriptor():getForename();
    Respawn.Descriptor.Surname = player:getDescriptor():getSurname();
end

function savePlayerNutrition(player)
    Respawn.Nutrition = {};
    Respawn.Nutrition.Calories = player:getNutrition():getCalories();
    Respawn.Nutrition.Proteins = player:getNutrition():getProteins();
    Respawn.Nutrition.Lipids = player:getNutrition():getLipids();
    Respawn.Nutrition.Carbohydrates = player:getNutrition():getCarbohydrates();
    Respawn.Nutrition.Weight = player:getNutrition():getWeight();
end

function savePlayerFitness(player)
    Respawn.Fitness = {};
    Respawn.Fitness.Regularity = player:getFitness():getRegularityMap();
    Respawn.Fitness.Stiffness = {}

    local parts = player:getBodyDamage():getBodyParts();

    for i = 0, parts:size() - 1 do
        Respawn.Fitness.Stiffness[i] = parts:get(i):getStiffness();
    end
end

function savePlayerStats(player)
    Respawn.Stats = {};
    Respawn.Stats.Anger = player:getStats():getAnger();
    Respawn.Stats.Boredom = player:getStats():getBoredom();
    Respawn.Stats.Morale = player:getStats():getMorale();
    Respawn.Stats.Fatigue = player:getStats():getFatigue();
    Respawn.Stats.Fitness = player:getStats():getFitness();
    Respawn.Stats.Stress = player:getStats():getStress();
    Respawn.Stats.StressFromCigarettes = player:getStats():getStressFromCigarettes();
    Respawn.Stats.Fear = player:getStats():getFear();
    Respawn.Stats.Panic = player:getStats():getPanic();
    Respawn.Stats.Sanity = player:getStats():getSanity();
    Respawn.Stats.Drunkenness = player:getStats():getDrunkenness();
end

function savePlayerFavoriteRecipes(player)
    local pModData = player:getModData();
    Respawn.FavoriteRecipes = {}

    for k, v in pairs(pModData) do
        if (k:sub(0, 16) == "craftingFavorite") then
            Respawn.FavoriteRecipes[k] = v;
        end
    end
end

--Load player

function loadPlayer(player)
    clearInventory(player);

    if (SandboxVars.SafehousePlus.KeepInventory) then
        loadPlayerInventory(player);
        loadPlayerLevels(player);
        loadPlayerBooks(player);
        loadPlayerMultipliers(player);
        loadPlayerRecipes(player);
        loadPlayerFavoriteRecipes(player);
        loadPlayerMedia(player);
        loadPlayerNutrition(player);
        loadPlayerFitness(player);
        loadPlayerStats(player);
        player:setZombieKills(Respawn.ZombieKills);
        player:setSurvivorKills(Respawn.SurvivorKills);
        player:setHoursSurvived(Respawn.HoursSurvived);
        clearWounds(player);
    end

    loadPlayerModel(player);
    loadPlayerBoosts(player);
    loadPlayerTraits(player);
    player:setLevelUpMultiplier(Respawn.LevelUpMultiplier);
    setAutoRespawn(player, Respawn.AutoRespawn);
    clearBandages(player);
end

function loadPlayerLevels(player)
    for perk, level in pairs(Respawn.Levels or {}) do
        local perkLevel = player:getPerkLevel(perk);

        while (perkLevel > 0) do
            player:LoseLevel(perk);
            perkLevel = perkLevel - 1;
        end

        player:getXp():setXPToLevel(perk, 0);
        player:getXp():AddXP(perk, Respawn.Xp[perk], true, false, false);
    end
end

function loadPlayerBoosts(player)
    local prof = ProfessionFactory.getProfession(Respawn.Profession);

    for perk, boost in pairs(Respawn.Boosts or {}) do
        prof:addXPBoost(perk, boost);
    end

    player:getDescriptor():setProfessionSkills(prof);
    player:getDescriptor():setProfession(Respawn.Profession);
end

function loadPlayerTraits(player)
    player:getTraits():clear();

    for i = 0, Respawn.Traits:size() - 1 do
        player:getTraits():add(Respawn.Traits:get(i));
    end
end

function loadPlayerBooks(player)
    for book, pages in pairs(Respawn.SkillBooks or {}) do
        player:setAlreadyReadPages(book, pages);
    end
end

function loadPlayerMultipliers(player)
    for perk, amount in pairs(Respawn.Multipliers or {}) do
        player:getXp():addXpMultiplier(perk, amount, 0, 10);
    end
end

function loadPlayerRecipes(player)
    for i = 0, Respawn.Recipes:size() - 1 do
        player:learnRecipe(Respawn.Recipes:get(i));
    end
end

function loadPlayerFavoriteRecipes(player)
    local pModData = player:getModData();

    for k, v in pairs(Respawn.FavoriteRecipes) do
        pModData[k] = v;
    end
end

function loadPlayerMedia(player)
    for _, id in ipairs(Respawn.Media or {}) do
        player:addKnownMediaLine(id);
    end
end

function loadPlayerInventory(player)
    --Needed in case if player inventory will be full
    local isUnlimitedCarry = player:isUnlimitedCarry();
    player:setUnlimitedCarry(true);

    --Assign new player's container to old items
    for i = 0, Respawn.Items:size() - 1 do
        Respawn.Items:get(i):setEquipParent(player);
        Respawn.Items:get(i):setContainer(player:getInventory());
    end

    --Set items
    player:getInventory():setItems(Respawn.Items);

    --Set back worn items, clothes, belts, etc
    for _, WornItem in pairs(Respawn.WornItems or {}) do
        player:getWornItems():setItem(WornItem:getLocation(), WornItem:getItem());
    end

    --Set back attached items, items in belts
    for _, AttachedItem in pairs(Respawn.AttachedItems or {}) do
        player:getAttachedItems():setItem(AttachedItem:getLocation(), AttachedItem:getItem());
    end

    --Restore hotbar UI order
    if (Respawn.Hotbar ~= nil) then player:getModData().hotbar = Respawn.Hotbar end

    --Put item in hand/s
    player:setPrimaryHandItem(Respawn.PrimaryHandItem);
    player:setSecondaryHandItem(Respawn.SecondaryHandItem);

    --Revert unlimited carry
    player:setUnlimitedCarry(isUnlimitedCarry);
    --player:update(); --I have no clue if this does anything

    if (isClient()) then
        triggerEvent("OnClothingUpdated", player);
    end
end

function loadRespawnLocation(player)
    if ((Respawn.X ~= nil) and (Respawn.Y ~= nil) and (Respawn.Z ~= nil)) then
        player:setX(Respawn.X);
        player:setY(Respawn.Y);
        player:setZ(Respawn.Z);
    end;
end

function loadPlayerModel(player)
    if (Respawn.Visual) then
        player:getVisual():setSkinTextureIndex(Respawn.Visual.SkinTexture)
        player:getVisual():setSkinTextureName(Respawn.Visual.SkinTextureName);
        player:getVisual():setNonAttachedHair(Respawn.Visual.NonAttachedHair);
        player:getVisual():setBodyHairIndex(Respawn.Visual.BodyHair);
        player:getVisual():setOutfit(Respawn.Visual.Outfit);
        player:getVisual():setHairModel(Respawn.Visual.HairModel);
        player:getVisual():setBeardModel(Respawn.Visual.BeardModel);
        player:getVisual():setSkinColor(Respawn.Visual.SkinColor);
        player:getVisual():setHairColor(Respawn.Visual.HairColor);
        player:getVisual():setBeardColor(Respawn.Visual.BeardColor);
    end

    if (Respawn.Descriptor) then
        player:setAge(Respawn.Descriptor.Age);
        player:setFemale(Respawn.Descriptor.Female);
        player:getDescriptor():setFemale(Respawn.Descriptor.Female);
        player:getDescriptor():setForename(Respawn.Descriptor.Forename);
        player:getDescriptor():setSurname(Respawn.Descriptor.Surname);
    end
end

function loadPlayerNutrition(player)
    player:getNutrition():setCalories(Respawn.Nutrition.Calories);
    player:getNutrition():setProteins(Respawn.Nutrition.Proteins);
    player:getNutrition():setLipids(Respawn.Nutrition.Lipids);
    player:getNutrition():setCarbohydrates(Respawn.Nutrition.Carbohydrates);
    player:getNutrition():setWeight(Respawn.Nutrition.Weight);
end

function loadPlayerFitness(player)
    player:getFitness():setRegularityMap(Respawn.Fitness.Regularity);

    local parts = player:getBodyDamage():getBodyParts();

    for i, _ in pairs(Respawn.Fitness.Stiffness or {}) do
        parts:get(i):setStiffness(Respawn.Fitness.Stiffness[i]);
    end
end

function loadPlayerStats(player)
    player:getStats():setAnger(Respawn.Stats.Anger);
    player:getStats():setBoredom(Respawn.Stats.Boredom);
    player:getStats():setMorale(Respawn.Stats.Morale);
    player:getStats():setFatigue(Respawn.Stats.Fatigue);
    player:getStats():setFitness(Respawn.Stats.Fitness);
    player:getStats():setStress(Respawn.Stats.Stress);
    player:getStats():setStressFromCigarettes(Respawn.Stats.StressFromCigarettes);
    player:getStats():setFear(Respawn.Stats.Fear);
    player:getStats():setPanic(Respawn.Stats.Panic);
    player:getStats():setSanity(Respawn.Stats.Sanity);
    player:getStats():setDrunkenness(Respawn.Stats.Drunkenness);
end

--Other

function clearInventory(player)
    local isUnlimitedCarry = player:isUnlimitedCarry();
    player:setUnlimitedCarry(true);

    --Need to unequip default equped items
    local WornItems = {};

    --Remove item while looping will cause an error
    for i = 0, player:getWornItems():size() - 1 do
        WornItems[i] = player:getWornItems():get(i):getItem();
    end

    --Unequip worn items
    for i, WornItem in pairs(WornItems or {}) do
        player:removeWornItem(WornItem);
    end

    player:getWornItems():clear();     --Worn items, like clothes and belt
    player:getAttachedItems():clear(); --Attched items, like attached to belt
    player:setPrimaryHandItem(nil);
    player:setSecondaryHandItem(nil);

    local playerInventory = player:getInventory();
    playerInventory:getItems():clear();
    playerInventory:removeAllItems();
    player:setInventory(playerInventory);
    player:setUnlimitedCarry(isUnlimitedCarry);
    --player:update(); --I have no clue if this does anything

    if (isClient()) then
        triggerEvent("OnClothingUpdated", player);
    end
end

function clearBandages(player)
    local items = player:getWornItems();
    local parts = player:getBodyDamage():getBodyParts();

    for i = items:size() - 1, 0, -1 do
        if (items:get(i):getLocation() == "Bandage") then
            player:getInventory():Remove(items:get(i):getItem());
            items:remove(items:get(i):getItem());
        end
    end

    for i = 0, parts:size() - 1 do
        parts:get(i):setBandaged(false, 0);
    end

    player:resetModelNextFrame();
end

function clearWounds(player)
    local parts = player:getBodyDamage():getBodyParts();

    for i = 0, parts:size() - 1 do
        parts:get(i):SetBitten(true);
        parts:get(i):setScratched(true, true);
        parts:get(i):setCut(true, true);
    end

    player:getBodyDamage():setBodyPartsLastState();

    for i = 0, parts:size() - 1 do
        parts:get(i):SetBitten(false);
        parts:get(i):setScratched(false, true);
        parts:get(i):setScratchTime(0);
        parts:get(i):setCut(false, true);
        parts:get(i):setCutTime(0);
        parts:get(i):setBiteTime(0);
        parts:get(i):SetBitten(false);
        parts:get(i):SetInfected(false);
        parts:get(i):setInfectedWound(false);
        parts:get(i):SetFakeInfected(false);
    end
end

function setPlayerRespawn(player)
    local pModData = player:getModData();
    pModData.RespawnX = player:getX();
    pModData.RespawnY = player:getY();
    pModData.RespawnZ = player:getZ();
end

function removePlayerRespawn(player)
    local pModData = player:getModData();
    pModData.RespawnX = nil;
    pModData.RespawnY = nil;
    pModData.RespawnZ = nil;
end

function getPlayerRespawn(player)
    local pModData = player:getModData();
    return { x = pModData.RespawnX, y = pModData.RespawnY, z = pModData.RespawnZ };
end

function setRespawnRegion(player, region)
    local spawn = region.points[player:getDescriptor():getProfession()];
    if (not spawn) then spawn = region.points["unemployed"] end

    if (spawn) then
        local randSpawnPoint = spawn[(ZombRand(#spawn) + 1)];
        getWorld():setLuaPosX(randSpawnPoint.posX);
        getWorld():setLuaPosY(randSpawnPoint.posY);
        getWorld():setLuaPosZ(randSpawnPoint.posZ or 0);

        player:setX(randSpawnPoint.posX);
        player:setY(randSpawnPoint.posY);
        player:setZ(randSpawnPoint.posZ or 0);
        setPlayerRespawn(player);
    end
end

function setAutoRespawn(player, bAutoRespawn)
    local pModData = player:getModData();
    pModData.AutoRespawn = bAutoRespawn;
end

function isAutoRespawn(player)
    local pModData = player:getModData();
    local bAutoRespawn = false;
    if (pModData.AutoRespawn ~= nil) then bAutoRespawn = pModData.AutoRespawn end
    return bAutoRespawn;
end

function setHealth(player, health)
    local parts = player:getBodyDamage():getBodyParts();
    local health = 80 + (20 * health / 100);

    for i = 0, parts:size() - 1 do
        parts:get(i):SetHealth(health);
    end
end
