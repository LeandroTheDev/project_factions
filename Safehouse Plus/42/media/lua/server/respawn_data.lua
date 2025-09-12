local RespawnData = {};

--#region Utils

local function clearInventory(player)
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
end

local function clearBandages(player)
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

local function clearWounds(player)
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

local function setPlayerRespawn(player)
    local pModData = player:getModData();
    pModData.RespawnX = player:getX();
    pModData.RespawnY = player:getY();
    pModData.RespawnZ = player:getZ();
end

local function removePlayerRespawn(player)
    local pModData = player:getModData();
    pModData.RespawnX = nil;
    pModData.RespawnY = nil;
    pModData.RespawnZ = nil;
end

local function getPlayerRespawn(player)
    local pModData = player:getModData();
    return { x = pModData.RespawnX, y = pModData.RespawnY, z = pModData.RespawnZ };
end

local function setRespawnRegion(player, region)
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

local function setAutoRespawn(player, bAutoRespawn)
    local pModData = player:getModData();
    pModData.AutoRespawn = bAutoRespawn;
end

local function isAutoRespawn(player)
    local pModData = player:getModData();
    local bAutoRespawn = false;
    if (pModData.AutoRespawn ~= nil) then bAutoRespawn = pModData.AutoRespawn end
    return bAutoRespawn;
end

local function setHealth(player, health)
    local parts = player:getBodyDamage():getBodyParts();
    health = 80 + (20 * health / 100);

    for i = 0, parts:size() - 1 do
        parts:get(i):SetHealth(health);
    end
end

--#endregion

--#region Save Player

local function savePlayerLevels(player)
    RespawnData[player:getUsername()].Xp = {};
    RespawnData[player:getUsername()].Levels = {};
    local perks = PerkFactory.PerkList;

    for i = 0, perks:size() - 1 do
        local perk = perks:get(i);

        RespawnData[player:getUsername()].Levels[perk] = player:getPerkLevel(perk);
        RespawnData[player:getUsername()].Xp[perk] = player:getXp():getXP(perk);
    end
end

local function savePlayerBoosts(player)
    RespawnData[player:getUsername()].Boosts = {};
    local perks = PerkFactory.PerkList;
    local boosts = player:getXp();

    for i = 0, perks:size() - 1 do
        local perk = perks:get(i);
        RespawnData[player:getUsername()].Boosts[perk] = boosts:getPerkBoost(perk);
    end
end

local function savePlayerBooks(player)
    RespawnData[player:getUsername()].SkillBooks = {};
    local items = getAllItems(); -- Get all loaded items in the game

    -- For each item check if is a literature item and the player readed it
    for i = 0, items:size() - 1 do
        if (items:get(i):getTypeString() == "Literature") then
            local item = items:get(i):InstanceItem(items:get(i):getName());
            if (item ~= nil and item:IsLiterature() and item:getNumberOfPages() > 0) then
                RespawnData[player:getUsername()].SkillBooks[item:getFullType()] = player:getAlreadyReadPages(item
                :getFullType());
            end
        end
    end
end

local function savePlayerMedia(player)
    RespawnData[player:getUsername()].Media = {};

    for _, media in pairs(RecMedia) do
        for _, line in pairs(media.lines or {}) do
            if (player:isKnownMediaLine(line.text)) then
                table.insert(RespawnData[player:getUsername()].Media, line.text);
            end;
        end
    end
end

local function savePlayerMultipliers(player)
    RespawnData[player:getUsername()].Multipliers = {};
    local perks = PerkFactory.PerkList;

    for i = 0, perks:size() - 1 do
        local perk = perks:get(i);
        RespawnData[player:getUsername()].Multipliers[perk] = player:getXp():getMultiplier(perk);
    end
end

local function savePlayerInventory(player)
    RespawnData[player:getUsername()].Hotbar = player:getModData().hotbar;
    local WornItems = player:getWornItems();
    RespawnData[player:getUsername()].WornItems = {};

    for i = 0, WornItems:size() - 1 do
        RespawnData[player:getUsername()].WornItems[i] = WornItems:get(i);
    end

    local AttachedItems = player:getAttachedItems();
    RespawnData[player:getUsername()].AttachedItems = {};

    for i = 0, AttachedItems:size() - 1 do
        RespawnData[player:getUsername()].AttachedItems[i] = AttachedItems:get(i);
    end

    RespawnData[player:getUsername()].Items = player:getInventory():getItems():clone();
end

local function saveHandItems(player)
    player:dropHeavyItems();

    RespawnData[player:getUsername()].PrimaryHandItem = player:getPrimaryHandItem();
    player:setPrimaryHandItem(nil);

    RespawnData[player:getUsername()].SecondaryHandItem = player:getSecondaryHandItem();
    player:setSecondaryHandItem(nil);
end

local function saveRespawnBaseLocation(player)
    local pModData = player:getModData();
    RespawnData[player:getUsername()].X = pModData.RespawnX;
    RespawnData[player:getUsername()].Y = pModData.RespawnY;
    RespawnData[player:getUsername()].Z = pModData.RespawnZ;
end

local function savePlayerModel(player)
    RespawnData[player:getUsername()].Visual = {};
    RespawnData[player:getUsername()].Visual.SkinTexture = player:getVisual():getSkinTextureIndex();
    RespawnData[player:getUsername()].Visual.SkinTextureName = player:getVisual():getSkinTexture();
    RespawnData[player:getUsername()].Visual.NonAttachedHair = player:getVisual():getNonAttachedHair();
    RespawnData[player:getUsername()].Visual.BodyHair = player:getVisual():getBodyHairIndex();
    RespawnData[player:getUsername()].Visual.Outfit = player:getVisual():getOutfit();
    RespawnData[player:getUsername()].Visual.HairModel = player:getVisual():getHairModel();
    RespawnData[player:getUsername()].Visual.BeardModel = player:getVisual():getBeardModel();
    RespawnData[player:getUsername()].Visual.SkinColor = player:getVisual():getSkinColor();
    RespawnData[player:getUsername()].Visual.HairColor = player:getVisual():getHairColor();
    RespawnData[player:getUsername()].Visual.BeardColor = player:getVisual():getBeardColor();

    if (RespawnData[player:getUsername()].Visual.Outfit) then
        RespawnData[player:getUsername()].Visual.Outfit = RespawnData[player:getUsername()].Visual.Outfit:clone();
    end

    RespawnData[player:getUsername()].Descriptor = {};
    RespawnData[player:getUsername()].Descriptor.Age = player:getAge();
    RespawnData[player:getUsername()].Descriptor.Female = player:isFemale();
    RespawnData[player:getUsername()].Descriptor.Forename = player:getDescriptor():getForename();
    RespawnData[player:getUsername()].Descriptor.Surname = player:getDescriptor():getSurname();
end

local function savePlayerNutrition(player)
    RespawnData[player:getUsername()].Nutrition = {};
    RespawnData[player:getUsername()].Nutrition.Calories = player:getNutrition():getCalories();
    RespawnData[player:getUsername()].Nutrition.Proteins = player:getNutrition():getProteins();
    RespawnData[player:getUsername()].Nutrition.Lipids = player:getNutrition():getLipids();
    RespawnData[player:getUsername()].Nutrition.Carbohydrates = player:getNutrition():getCarbohydrates();
    RespawnData[player:getUsername()].Nutrition.Weight = player:getNutrition():getWeight();
end

local function savePlayerFitness(player)
    RespawnData[player:getUsername()].Fitness = {};
    RespawnData[player:getUsername()].Fitness.Regularity = player:getFitness():getRegularityMap();
    RespawnData[player:getUsername()].Fitness.Stiffness = {};

    local parts = player:getBodyDamage():getBodyParts();

    for i = 0, parts:size() - 1 do
        RespawnData[player:getUsername()].Fitness.Stiffness[i] = parts:get(i):getStiffness();
    end
end

local function savePlayerStats(player)
    RespawnData[player:getUsername()].Stats = {};
    RespawnData[player:getUsername()].Stats.Anger = player:getStats():getAnger();
    RespawnData[player:getUsername()].Stats.Boredom = player:getStats():getBoredom();
    RespawnData[player:getUsername()].Stats.Morale = player:getStats():getMorale();
    RespawnData[player:getUsername()].Stats.Fatigue = player:getStats():getFatigue();
    RespawnData[player:getUsername()].Stats.Fitness = player:getStats():getFitness();
    RespawnData[player:getUsername()].Stats.Stress = player:getStats():getStress();
    RespawnData[player:getUsername()].Stats.StressFromCigarettes = player:getStats():getStressFromCigarettes();
    RespawnData[player:getUsername()].Stats.Fear = player:getStats():getFear();
    RespawnData[player:getUsername()].Stats.Panic = player:getStats():getPanic();
    RespawnData[player:getUsername()].Stats.Sanity = player:getStats():getSanity();
    RespawnData[player:getUsername()].Stats.Drunkenness = player:getStats():getDrunkenness();
end

local function savePlayerFavoriteRecipes(player)
    local pModData = player:getModData();
    RespawnData[player:getUsername()].FavoriteRecipes = {};

    for k, v in pairs(pModData) do
        if (k:sub(0, 16) == "craftingFavorite") then
            RespawnData[player:getUsername()].FavoriteRecipes[k] = v;
        end
    end
end

local function savePlayer(player)
    saveRespawnBaseLocation(player);
    savePlayerLevels(player);
    savePlayerBoosts(player);
    savePlayerBooks(player);
    savePlayerMedia(player);
    savePlayerMultipliers(player);
    savePlayerModel(player);
    savePlayerNutrition(player);
    savePlayerFitness(player);
    savePlayerStats(player);
    savePlayerFavoriteRecipes(player);

    RespawnData.Traits = player:getTraits();
    RespawnData.Profession = player:getDescriptor():getProfession();
    RespawnData.Recipes = player:getKnownRecipes();
    RespawnData.ZombieKills = player:getZombieKills();
    RespawnData.SurvivorKills = player:getSurvivorKills();
    RespawnData.HoursSurvived = player:getHoursSurvived();
    RespawnData.LevelUpMultiplier = player:getLevelUpMultiplier();
    RespawnData.AutoRespawn = isAutoRespawn(player);

    DebugPrintSafehousePlus("[Respawn] Player Saved");
end

-- On death we need to save player data
Events.OnCharacterDeath.Add(function(player)
    if (not instanceof(player, "IsoPlayer")) then return end

    DebugPrintSafehousePlus("[Respawn] Saving iso player: " .. player:getUsername());

    RespawnData[player:getUsername()] = {};

    -- Save player inventory if keep inventory is true
    if getSandboxOptions():getOptionByName("SafehousePlus.KeepInventory"):getValue() then
        saveHandItems(player);
        DebugPrintSafehousePlus("[Respawn] Hand items saved: " .. player:getUsername());

        savePlayerInventory(player);
        DebugPrintSafehousePlus("[Respawn] Inventoy items saved: " .. player:getUsername());
    end

    -- Save player data
    savePlayer(player);

    -- Clear inventory for our and other players if keep inventory is true
    if getSandboxOptions():getOptionByName("SafehousePlus.KeepInventory"):getValue() then
        clearInventory(player);
        DebugPrintSafehousePlus("[Respawn] Dead body cleared: " .. player:getUsername());

        -- Tell client the corpse is dead
        player:setOnDeathDone(true);
    end
end);

--#endregion

--#region Load Player

local function loadPlayerLevels(player)
    for perk, level in pairs(RespawnData[player:getUsername()].Levels or {}) do
        local perkLevel = player:getPerkLevel(perk);

        while (perkLevel > 0) do
            player:LoseLevel(perk);
            perkLevel = perkLevel - 1;
        end

        player:getXp():setXPToLevel(perk, 0);
        player:getXp():AddXP(perk, RespawnData[player:getUsername()].Xp[perk], true, false, false);
    end
end

local function loadPlayerBoosts(player)
    local prof = ProfessionFactory.getProfession(RespawnData[player:getUsername()].Profession);

    for perk, boost in pairs(RespawnData[player:getUsername()].Boosts or {}) do
        prof:addXPBoost(perk, boost);
    end

    player:getDescriptor():setProfessionSkills(prof);
    player:getDescriptor():setProfession(RespawnData[player:getUsername()].Profession);
end

local function loadPlayerTraits(player)
    player:getTraits():clear();

    for i = 0, RespawnData[player:getUsername()].Traits:size() - 1 do
        player:getTraits():add(RespawnData[player:getUsername()].Traits:get(i));
    end
end

local function loadPlayerBooks(player)
    for book, pages in pairs(RespawnData[player:getUsername()].SkillBooks or {}) do
        player:setAlreadyReadPages(book, pages);
    end
end

local function loadPlayerMultipliers(player)
    for perk, amount in pairs(RespawnData[player:getUsername()].Multipliers or {}) do
        player:getXp():addXpMultiplier(perk, amount, 0, 10);
    end
end

local function loadPlayerRecipes(player)
    for i = 0, RespawnData[player:getUsername()].Recipes:size() - 1 do
        player:learnRecipe(RespawnData[player:getUsername()].Recipes:get(i));
    end
end

local function loadPlayerFavoriteRecipes(player)
    local pModData = player:getModData();

    for k, v in pairs(RespawnData[player:getUsername()].FavoriteRecipes) do
        pModData[k] = v;
    end
end

local function loadPlayerMedia(player)
    for _, id in ipairs(RespawnData[player:getUsername()].Media or {}) do
        player:addKnownMediaLine(id);
    end
end

local function loadPlayerInventory(player)
    --Needed in case if player inventory will be full
    local isUnlimitedCarry = player:isUnlimitedCarry();
    player:setUnlimitedCarry(true);

    --Assign new player's container to old items
    for i = 0, RespawnData[player:getUsername()].Items:size() - 1 do
        RespawnData[player:getUsername()].Items:get(i):setEquipParent(player);
        RespawnData[player:getUsername()].Items:get(i):setContainer(player:getInventory());
    end

    --Set items
    player:getInventory():setItems(RespawnData[player:getUsername()].Items);

    --Set back worn items, clothes, belts, etc
    for _, WornItem in pairs(RespawnData[player:getUsername()].WornItems or {}) do
        player:getWornItems():setItem(WornItem:getLocation(), WornItem:getItem());
    end

    --Set back attached items, items in belts
    for _, AttachedItem in pairs(RespawnData[player:getUsername()].AttachedItems or {}) do
        player:getAttachedItems():setItem(AttachedItem:getLocation(), AttachedItem:getItem());
    end

    --Restore hotbar UI order
    if (RespawnData[player:getUsername()].Hotbar ~= nil) then
        player:getModData().hotbar = RespawnData
            [player:getUsername()].Hotbar
    end

    --Put item in hand/s
    player:setPrimaryHandItem(RespawnData[player:getUsername()].PrimaryHandItem);
    player:setSecondaryHandItem(RespawnData[player:getUsername()].SecondaryHandItem);

    --Revert unlimited carry
    player:setUnlimitedCarry(isUnlimitedCarry);
end

local function loadRespawnLocation(player)
    if ((RespawnData[player:getUsername()].X ~= nil) and (RespawnData[player:getUsername()].Y ~= nil) and (RespawnData[player:getUsername()].Z ~= nil)) then
        player:setX(RespawnData[player:getUsername()].X);
        player:setY(RespawnData[player:getUsername()].Y);
        player:setZ(RespawnData[player:getUsername()].Z);
    end;
end

local function loadPlayerModel(player)
    if (RespawnData[player:getUsername()].Visual) then
        player:getVisual():setSkinTextureIndex(RespawnData[player:getUsername()].Visual.SkinTexture)
        player:getVisual():setSkinTextureName(RespawnData[player:getUsername()].Visual.SkinTextureName);
        player:getVisual():setNonAttachedHair(RespawnData[player:getUsername()].Visual.NonAttachedHair);
        player:getVisual():setBodyHairIndex(RespawnData[player:getUsername()].Visual.BodyHair);
        player:getVisual():setOutfit(RespawnData[player:getUsername()].Visual.Outfit);
        player:getVisual():setHairModel(RespawnData[player:getUsername()].Visual.HairModel);
        player:getVisual():setBeardModel(RespawnData[player:getUsername()].Visual.BeardModel);
        player:getVisual():setSkinColor(RespawnData[player:getUsername()].Visual.SkinColor);
        player:getVisual():setHairColor(RespawnData[player:getUsername()].Visual.HairColor);
        player:getVisual():setBeardColor(RespawnData[player:getUsername()].Visual.BeardColor);
    end

    if (RespawnData[player:getUsername()].Descriptor) then
        player:setAge(RespawnData[player:getUsername()].Descriptor.Age);
        player:setFemale(RespawnData[player:getUsername()].Descriptor.Female);
        player:getDescriptor():setFemale(RespawnData[player:getUsername()].Descriptor.Female);
        player:getDescriptor():setForename(RespawnData[player:getUsername()].Descriptor.Forename);
        player:getDescriptor():setSurname(RespawnData[player:getUsername()].Descriptor.Surname);
    end
end

local function loadPlayerNutrition(player)
    player:getNutrition():setCalories(RespawnData[player:getUsername()].Nutrition.Calories);
    player:getNutrition():setProteins(RespawnData[player:getUsername()].Nutrition.Proteins);
    player:getNutrition():setLipids(RespawnData[player:getUsername()].Nutrition.Lipids);
    player:getNutrition():setCarbohydrates(RespawnData[player:getUsername()].Nutrition.Carbohydrates);
    player:getNutrition():setWeight(RespawnData[player:getUsername()].Nutrition.Weight);
end

local function loadPlayerFitness(player)
    player:getFitness():setRegularityMap(RespawnData[player:getUsername()].Fitness.Regularity);

    local parts = player:getBodyDamage():getBodyParts();

    for i, _ in pairs(RespawnData[player:getUsername()].Fitness.Stiffness or {}) do
        parts:get(i):setStiffness(RespawnData[player:getUsername()].Fitness.Stiffness[i]);
    end
end

local function loadPlayerStats(player)
    player:getStats():setAnger(RespawnData[player:getUsername()].Stats.Anger);
    player:getStats():setBoredom(RespawnData[player:getUsername()].Stats.Boredom);
    player:getStats():setMorale(RespawnData[player:getUsername()].Stats.Morale);
    player:getStats():setFatigue(RespawnData[player:getUsername()].Stats.Fatigue);
    player:getStats():setFitness(RespawnData[player:getUsername()].Stats.Fitness);
    player:getStats():setStress(RespawnData[player:getUsername()].Stats.Stress);
    player:getStats():setStressFromCigarettes(RespawnData[player:getUsername()].Stats.StressFromCigarettes);
    player:getStats():setFear(RespawnData[player:getUsername()].Stats.Fear);
    player:getStats():setPanic(RespawnData[player:getUsername()].Stats.Panic);
    player:getStats():setSanity(RespawnData[player:getUsername()].Stats.Sanity);
    player:getStats():setDrunkenness(RespawnData[player:getUsername()].Stats.Drunkenness);
end

local function loadPlayer(player)
    clearInventory(player);

    if (getSandboxOptions():getOptionByName("SafehousePlus.KeepInventory"):getValue()) then
        loadPlayerInventory(player);
    end

    loadPlayerLevels(player);
    loadPlayerBooks(player);
    loadPlayerMultipliers(player);
    loadPlayerRecipes(player);
    loadPlayerFavoriteRecipes(player);
    loadPlayerMedia(player);
    loadPlayerNutrition(player);
    loadPlayerFitness(player);
    loadPlayerStats(player);
    player:setZombieKills(RespawnData[player:getUsername()].ZombieKills);
    player:setSurvivorKills(RespawnData[player:getUsername()].SurvivorKills);
    player:setHoursSurvived(RespawnData[player:getUsername()].HoursSurvived);
    clearWounds(player);

    loadPlayerModel(player);
    loadPlayerBoosts(player);
    loadPlayerTraits(player);
    player:setLevelUpMultiplier(RespawnData[player:getUsername()].LevelUpMultiplier);
    setAutoRespawn(player, RespawnData[player:getUsername()].AutoRespawn);
    clearBandages(player);
end

--#endregion

--#region Server Communication

-- Create a global function to load from clientside
if SafehousePlusIsSinglePlayer then
    function LoadPlayer(player)
        loadPlayer(player);
    end

    function LoadRespawnLocation(player)
        loadRespawnLocation(player);
    end

    function SetPlayerRespawn(player)
        setPlayerRespawn(player);
    end

    function SetHealth(player, health)
        setHealth(player, health);
    end

    function RemovePlayerRespawn(player)
        removePlayerRespawn(player);
    end

    function SetRespawnRegion(player, region)
        setRespawnRegion(player, region);
    end

    function GetPlayerRespawn(player)
        getPlayerRespawn(player);
    end
else -- If not create a server command
    Events.OnClientCommand.Add(function(module, command, player, args)
        if module == "SafehousePlusRespawn" and command == "setRespawnRegion" then
            removePlayerRespawn(player);
            setRespawnRegion(player, args.region);
        elseif module == "SafehousePlusRespawn" and command == "loadPlayer" then
            loadPlayer(player);

            setHealth(player, getSandboxOptions():getOptionByName("SafehousePlus.HealthOnRespawn"):getValue());

            loadRespawnLocation(player);

            setPlayerRespawn(player);

            sendHumanVisual(player);
            sendEquip(player);
            syncVisuals(player);
            player:update();
        elseif module == "SafehousePlusRespawn" and command == "getRespawn" then
            local coords = getPlayerRespawn(player);
            sendServerCommand(player, "SafehousePlusRespawn", "receiveRespawn", coords);
        elseif module == "SafehousePlusRespawn" and command == "setPlayerRespawn" then
            setPlayerRespawn(player);
        end
    end)
end

--#endregion

-- Maybe in future make a respawn after quit from the death screen
-- Events.OnInitGlobalModData.Add(function(isNewGame)
--     RespawnData = ModData.getOrCreate("SafehousePlusRespawnData");
-- end)
