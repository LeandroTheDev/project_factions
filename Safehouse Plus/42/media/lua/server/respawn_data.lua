if not getSandboxOptions():getOptionByName("SafehousePlus.EnableRespawnMechanic"):getValue() then return end

local RespawnData = {};

--#region Utils

-- Clear all items from the player inventory
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

    player:getWornItems():clear();
    player:getAttachedItems():clear();
    player:setPrimaryHandItem(nil);
    player:setSecondaryHandItem(nil);

    local playerInventory = player:getInventory();
    playerInventory:getItems():clear();
    playerInventory:removeAllItems();
    player:setInventory(playerInventory);
    player:setUnlimitedCarry(isUnlimitedCarry);
end

-- Clear all bandages attached to the player
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

-- Remove all wounds from the player
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

-- Currently player position will be the next respawn position
local function setPlayerRespawn(player)
    local pModData = player:getModData();
    pModData.RespawnX = player:getX();
    pModData.RespawnY = player:getY();
    pModData.RespawnZ = player:getZ();
end

-- Set the player respawn based on the Menu Regions from map selector
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

-- Remove the currently player respawn saved
local function removePlayerRespawn(player)
    local pModData = player:getModData();
    pModData.RespawnX = nil;
    pModData.RespawnY = nil;
    pModData.RespawnZ = nil;
end

-- Get the coords of the player respawn { x = 123, y = 123, z = 123 }
local function getPlayerRespawn(player)
    local pModData = player:getModData();
    return { x = pModData.RespawnX, y = pModData.RespawnY, z = pModData.RespawnZ };
end

-- Update player health to a disered amount
local function setHealth(player, health)
    local parts = player:getBodyDamage():getBodyParts();
    health = 80 + (20 * health / 100);

    for i = 0, parts:size() - 1 do
        parts:get(i):SetHealth(health);
    end
end

-- Returns the player unique id
local function getUniqueId(player)
    if SafehousePlusIsSinglePlayer then
        -- I don't know how to detect split screen players 🤭
        -- Split screen players cannot die at same time
        return tostring(1);
    else
        if player:getSteamID() then
            return tostring(player:getSteamID());
        else
            return tostring(player:getOnlineID());
        end
    end
end

--#endregion

--#region Save Player

local function savePlayerLevels(player)
    RespawnData[getUniqueId(player)].Xp = {};
    RespawnData[getUniqueId(player)].Levels = {};
    local perks = PerkFactory.PerkList;

    for i = 0, perks:size() - 1 do
        local perk = perks:get(i);

        RespawnData[getUniqueId(player)].Levels[perk] = player:getPerkLevel(perk);
        RespawnData[getUniqueId(player)].Xp[perk] = player:getXp():getXP(perk);
    end
end

local function savePlayerBoosts(player)
    RespawnData[getUniqueId(player)].Boosts = {};
    local perks = PerkFactory.PerkList;
    local boosts = player:getXp();

    for i = 0, perks:size() - 1 do
        local perk = perks:get(i);
        RespawnData[getUniqueId(player)].Boosts[perk] = boosts:getPerkBoost(perk);
    end
end

local function savePlayerBooks(player)
    RespawnData[getUniqueId(player)].SkillBooks = {};
    local items = getAllItems(); -- Get all loaded items in the game

    -- For each item check if is a literature item and the player readed it
    for i = 0, items:size() - 1 do
        if (items:get(i):getTypeString() == "Literature") then
            local item = items:get(i):InstanceItem(items:get(i):getName());
            if (item ~= nil and item:IsLiterature() and item:getNumberOfPages() > 0) then
                RespawnData[getUniqueId(player)].SkillBooks[item:getFullType()] = player:getAlreadyReadPages(item
                    :getFullType());
            end
        end
    end
end

local function savePlayerMedia(player)
    RespawnData[getUniqueId(player)].Media = {};

    for _, media in pairs(RecMedia) do
        for _, line in pairs(media.lines or {}) do
            if (player:isKnownMediaLine(line.text)) then
                table.insert(RespawnData[getUniqueId(player)].Media, line.text);
            end;
        end
    end
end

local function savePlayerMultipliers(player)
    RespawnData[getUniqueId(player)].Multipliers = {};
    local perks = PerkFactory.PerkList;

    for i = 0, perks:size() - 1 do
        local perk = perks:get(i);
        RespawnData[getUniqueId(player)].Multipliers[perk] = player:getXp():getMultiplier(perk);
    end
end

local function savePlayerInventory(player)
    RespawnData[getUniqueId(player)].Hotbar = player:getModData().hotbar;
    local WornItems = player:getWornItems();
    RespawnData[getUniqueId(player)].WornItems = {};

    for i = 0, WornItems:size() - 1 do
        RespawnData[getUniqueId(player)].WornItems[i] = WornItems:get(i);
    end

    local AttachedItems = player:getAttachedItems();
    RespawnData[getUniqueId(player)].AttachedItems = {};

    for i = 0, AttachedItems:size() - 1 do
        RespawnData[getUniqueId(player)].AttachedItems[i] = AttachedItems:get(i);
    end

    RespawnData[getUniqueId(player)].Items = player:getInventory():getItems():clone();
end

local function saveHandItems(player)
    player:dropHeavyItems();

    RespawnData[getUniqueId(player)].PrimaryHandItem = player:getPrimaryHandItem();
    player:setPrimaryHandItem(nil);

    RespawnData[getUniqueId(player)].SecondaryHandItem = player:getSecondaryHandItem();
    player:setSecondaryHandItem(nil);
end

local function saveRespawnBaseLocation(player)
    local pModData = player:getModData();
    RespawnData[getUniqueId(player)].X = pModData.RespawnX;
    RespawnData[getUniqueId(player)].Y = pModData.RespawnY;
    RespawnData[getUniqueId(player)].Z = pModData.RespawnZ;
end

local function savePlayerModel(player)
    RespawnData[getUniqueId(player)].Visual = {};
    RespawnData[getUniqueId(player)].Visual.SkinTexture = player:getVisual():getSkinTextureIndex();
    RespawnData[getUniqueId(player)].Visual.SkinTextureName = player:getVisual():getSkinTexture();
    RespawnData[getUniqueId(player)].Visual.NonAttachedHair = player:getVisual():getNonAttachedHair();
    RespawnData[getUniqueId(player)].Visual.BodyHair = player:getVisual():getBodyHairIndex();
    RespawnData[getUniqueId(player)].Visual.Outfit = player:getVisual():getOutfit();
    RespawnData[getUniqueId(player)].Visual.HairModel = player:getVisual():getHairModel();
    RespawnData[getUniqueId(player)].Visual.BeardModel = player:getVisual():getBeardModel();
    RespawnData[getUniqueId(player)].Visual.SkinColor = player:getVisual():getSkinColor();
    RespawnData[getUniqueId(player)].Visual.HairColor = player:getVisual():getHairColor();
    RespawnData[getUniqueId(player)].Visual.BeardColor = player:getVisual():getBeardColor();

    if (RespawnData[getUniqueId(player)].Visual.Outfit) then
        RespawnData[getUniqueId(player)].Visual.Outfit = RespawnData[getUniqueId(player)].Visual.Outfit:clone();
    end

    RespawnData[getUniqueId(player)].Descriptor = {};
    RespawnData[getUniqueId(player)].Descriptor.Age = player:getAge();
    RespawnData[getUniqueId(player)].Descriptor.Female = player:isFemale();
    RespawnData[getUniqueId(player)].Descriptor.Forename = player:getDescriptor():getForename();
    RespawnData[getUniqueId(player)].Descriptor.Surname = player:getDescriptor():getSurname();
end

local function savePlayerNutrition(player)
    RespawnData[getUniqueId(player)].Nutrition = {};
    RespawnData[getUniqueId(player)].Nutrition.Calories = player:getNutrition():getCalories();
    RespawnData[getUniqueId(player)].Nutrition.Proteins = player:getNutrition():getProteins();
    RespawnData[getUniqueId(player)].Nutrition.Lipids = player:getNutrition():getLipids();
    RespawnData[getUniqueId(player)].Nutrition.Carbohydrates = player:getNutrition():getCarbohydrates();
    RespawnData[getUniqueId(player)].Nutrition.Weight = player:getNutrition():getWeight();
end

local function savePlayerFitness(player)
    RespawnData[getUniqueId(player)].Fitness = {};
    RespawnData[getUniqueId(player)].Fitness.Regularity = player:getFitness():getRegularityMap();
    RespawnData[getUniqueId(player)].Fitness.Stiffness = {};

    local parts = player:getBodyDamage():getBodyParts();

    for i = 0, parts:size() - 1 do
        RespawnData[getUniqueId(player)].Fitness.Stiffness[i] = parts:get(i):getStiffness();
    end
end

local function savePlayerStats(player)
    RespawnData[getUniqueId(player)].Stats = {};
    RespawnData[getUniqueId(player)].Stats.Anger = player:getStats():getAnger();
    RespawnData[getUniqueId(player)].Stats.Boredom = player:getStats():getBoredom();
    RespawnData[getUniqueId(player)].Stats.Morale = player:getStats():getMorale();
    RespawnData[getUniqueId(player)].Stats.Fatigue = player:getStats():getFatigue();
    RespawnData[getUniqueId(player)].Stats.Fitness = player:getStats():getFitness();
    RespawnData[getUniqueId(player)].Stats.Stress = player:getStats():getStress();
    RespawnData[getUniqueId(player)].Stats.StressFromCigarettes = player:getStats():getStressFromCigarettes();
    RespawnData[getUniqueId(player)].Stats.Fear = player:getStats():getFear();
    RespawnData[getUniqueId(player)].Stats.Panic = player:getStats():getPanic();
    RespawnData[getUniqueId(player)].Stats.Sanity = player:getStats():getSanity();
    RespawnData[getUniqueId(player)].Stats.Drunkenness = player:getStats():getDrunkenness();
end

local function savePlayerFavoriteRecipes(player)
    local pModData = player:getModData();
    RespawnData[getUniqueId(player)].FavoriteRecipes = {};

    for k, v in pairs(pModData) do
        if (k:sub(0, 16) == "craftingFavorite") then
            RespawnData[getUniqueId(player)].FavoriteRecipes[k] = v;
        end
    end
end

local function savePlayer(player)
    RespawnData[getUniqueId(player)] = {};

    -- Save player inventory if keep inventory is true
    if getSandboxOptions():getOptionByName("SafehousePlus.KeepInventory"):getValue() then
        saveHandItems(player);
        DebugPrintSafehousePlus("[Respawn] Hand items saved: " .. player:getUsername());

        savePlayerInventory(player);
        DebugPrintSafehousePlus("[Respawn] Inventoy items saved: " .. player:getUsername());
    end

    saveRespawnBaseLocation(player);
    savePlayerLevels(player);
    savePlayerBoosts(player);
    savePlayerBooks(player);
    savePlayerMedia(player);
    savePlayerMultipliers(player);
    savePlayerModel(player);
    savePlayerNutrition(player);
    savePlayerFitness(player);

    if getSandboxOptions():getOptionByName("SafehousePlus.KeepStats"):getValue() then
        savePlayerStats(player);
        DebugPrintSafehousePlus("[Respawn] Stats saved: " .. player:getUsername());
    end

    savePlayerFavoriteRecipes(player);

    RespawnData[getUniqueId(player)].Traits = player:getTraits();
    RespawnData[getUniqueId(player)].Profession = player:getDescriptor():getProfession();
    RespawnData[getUniqueId(player)].Recipes = player:getKnownRecipes();
    RespawnData[getUniqueId(player)].ZombieKills = player:getZombieKills();
    RespawnData[getUniqueId(player)].SurvivorKills = player:getSurvivorKills();
    RespawnData[getUniqueId(player)].HoursSurvived = player:getHoursSurvived();
    RespawnData[getUniqueId(player)].LevelUpMultiplier = player:getLevelUpMultiplier();

    DebugPrintSafehousePlus("[Respawn] Player Saved");
end

-- On death we need to save player data
Events.OnCharacterDeath.Add(function(player)
    if (not instanceof(player, "IsoPlayer")) then return end

    DebugPrintSafehousePlus("[Respawn] Saving iso player: " .. player:getUsername());

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
    for perk, level in pairs(RespawnData[getUniqueId(player)].Levels or {}) do
        local perkLevel = player:getPerkLevel(perk);

        while (perkLevel > 0) do
            player:LoseLevel(perk);
            perkLevel = perkLevel - 1;
        end

        player:getXp():setXPToLevel(perk, 0);
        player:getXp():AddXP(perk, RespawnData[getUniqueId(player)].Xp[perk], true, false, false);
    end
end

local function loadPlayerBoosts(player)
    local prof = ProfessionFactory.getProfession(RespawnData[getUniqueId(player)].Profession);

    for perk, boost in pairs(RespawnData[getUniqueId(player)].Boosts or {}) do
        prof:addXPBoost(perk, boost);
    end

    player:getDescriptor():setProfessionSkills(prof);
    player:getDescriptor():setProfession(RespawnData[getUniqueId(player)].Profession);
end

local function loadPlayerTraits(player)
    player:getTraits():clear();

    for i = 0, RespawnData[getUniqueId(player)].Traits:size() - 1 do
        player:getTraits():add(RespawnData[getUniqueId(player)].Traits:get(i));
    end
end

local function loadPlayerBooks(player)
    for book, pages in pairs(RespawnData[getUniqueId(player)].SkillBooks or {}) do
        player:setAlreadyReadPages(book, pages);
    end
end

local function loadPlayerMultipliers(player)
    for perk, amount in pairs(RespawnData[getUniqueId(player)].Multipliers or {}) do
        player:getXp():addXpMultiplier(perk, amount, 0, 10);
    end
end

local function loadPlayerRecipes(player)
    for i = 0, RespawnData[getUniqueId(player)].Recipes:size() - 1 do
        player:learnRecipe(RespawnData[getUniqueId(player)].Recipes:get(i));
    end
end

local function loadPlayerFavoriteRecipes(player)
    local pModData = player:getModData();

    for k, v in pairs(RespawnData[getUniqueId(player)].FavoriteRecipes) do
        pModData[k] = v;
    end
end

local function loadPlayerMedia(player)
    for _, id in ipairs(RespawnData[getUniqueId(player)].Media or {}) do
        player:addKnownMediaLine(id);
    end
end

local function loadPlayerInventory(player)
    --Needed in case if player inventory will be full
    local isUnlimitedCarry = player:isUnlimitedCarry();
    player:setUnlimitedCarry(true);

    --Assign new player's container to old items
    for i = 0, RespawnData[getUniqueId(player)].Items:size() - 1 do
        RespawnData[getUniqueId(player)].Items:get(i):setEquipParent(player);
        RespawnData[getUniqueId(player)].Items:get(i):setContainer(player:getInventory());
    end

    --Set items
    player:getInventory():setItems(RespawnData[getUniqueId(player)].Items);

    --Set back worn items, clothes, belts, etc
    for _, WornItem in pairs(RespawnData[getUniqueId(player)].WornItems or {}) do
        player:getWornItems():setItem(WornItem:getLocation(), WornItem:getItem());
    end

    --Set back attached items, items in belts
    for _, AttachedItem in pairs(RespawnData[getUniqueId(player)].AttachedItems or {}) do
        player:getAttachedItems():setItem(AttachedItem:getLocation(), AttachedItem:getItem());
    end

    --Restore hotbar UI order
    if (RespawnData[getUniqueId(player)].Hotbar ~= nil) then
        player:getModData().hotbar = RespawnData[getUniqueId(player)].Hotbar
    end

    --Put item in hand/s
    player:setPrimaryHandItem(RespawnData[getUniqueId(player)].PrimaryHandItem);
    player:setSecondaryHandItem(RespawnData[getUniqueId(player)].SecondaryHandItem);

    --Revert unlimited carry
    player:setUnlimitedCarry(isUnlimitedCarry);
end

local function loadRespawnLocation(player)
    if ((RespawnData[getUniqueId(player)].X ~= nil) and (RespawnData[getUniqueId(player)].Y ~= nil) and (RespawnData[getUniqueId(player)].Z ~= nil)) then
        player:setX(RespawnData[getUniqueId(player)].X);
        player:setY(RespawnData[getUniqueId(player)].Y);
        player:setZ(RespawnData[getUniqueId(player)].Z);
    end;
end

local function loadPlayerModel(player)
    if (RespawnData[getUniqueId(player)].Visual) then
        player:getVisual():setSkinTextureIndex(RespawnData[getUniqueId(player)].Visual.SkinTexture)
        player:getVisual():setSkinTextureName(RespawnData[getUniqueId(player)].Visual.SkinTextureName);
        player:getVisual():setNonAttachedHair(RespawnData[getUniqueId(player)].Visual.NonAttachedHair);
        player:getVisual():setBodyHairIndex(RespawnData[getUniqueId(player)].Visual.BodyHair);
        player:getVisual():setOutfit(RespawnData[getUniqueId(player)].Visual.Outfit);
        player:getVisual():setHairModel(RespawnData[getUniqueId(player)].Visual.HairModel);
        player:getVisual():setBeardModel(RespawnData[getUniqueId(player)].Visual.BeardModel);
        player:getVisual():setSkinColor(RespawnData[getUniqueId(player)].Visual.SkinColor);
        player:getVisual():setHairColor(RespawnData[getUniqueId(player)].Visual.HairColor);
        player:getVisual():setBeardColor(RespawnData[getUniqueId(player)].Visual.BeardColor);
    end

    if (RespawnData[getUniqueId(player)].Descriptor) then
        player:setAge(RespawnData[getUniqueId(player)].Descriptor.Age);
        player:setFemale(RespawnData[getUniqueId(player)].Descriptor.Female);
        player:getDescriptor():setFemale(RespawnData[getUniqueId(player)].Descriptor.Female);
        player:getDescriptor():setForename(RespawnData[getUniqueId(player)].Descriptor.Forename);
        player:getDescriptor():setSurname(RespawnData[getUniqueId(player)].Descriptor.Surname);
    end
end

local function loadPlayerNutrition(player)
    player:getNutrition():setCalories(RespawnData[getUniqueId(player)].Nutrition.Calories);
    player:getNutrition():setProteins(RespawnData[getUniqueId(player)].Nutrition.Proteins);
    player:getNutrition():setLipids(RespawnData[getUniqueId(player)].Nutrition.Lipids);
    player:getNutrition():setCarbohydrates(RespawnData[getUniqueId(player)].Nutrition.Carbohydrates);
    player:getNutrition():setWeight(RespawnData[getUniqueId(player)].Nutrition.Weight);
end

local function loadPlayerFitness(player)
    player:getFitness():setRegularityMap(RespawnData[getUniqueId(player)].Fitness.Regularity);

    local parts = player:getBodyDamage():getBodyParts();

    for i, _ in pairs(RespawnData[getUniqueId(player)].Fitness.Stiffness or {}) do
        parts:get(i):setStiffness(RespawnData[getUniqueId(player)].Fitness.Stiffness[i]);
    end
end

local function loadPlayerStats(player)
    player:getStats():setAnger(RespawnData[getUniqueId(player)].Stats.Anger);
    player:getStats():setBoredom(RespawnData[getUniqueId(player)].Stats.Boredom);
    player:getStats():setMorale(RespawnData[getUniqueId(player)].Stats.Morale);
    player:getStats():setFatigue(RespawnData[getUniqueId(player)].Stats.Fatigue);
    player:getStats():setFitness(RespawnData[getUniqueId(player)].Stats.Fitness);
    player:getStats():setStress(RespawnData[getUniqueId(player)].Stats.Stress);
    player:getStats():setStressFromCigarettes(RespawnData[getUniqueId(player)].Stats.StressFromCigarettes);
    player:getStats():setFear(RespawnData[getUniqueId(player)].Stats.Fear);
    player:getStats():setPanic(RespawnData[getUniqueId(player)].Stats.Panic);
    player:getStats():setSanity(RespawnData[getUniqueId(player)].Stats.Sanity);
    player:getStats():setDrunkenness(RespawnData[getUniqueId(player)].Stats.Drunkenness);
end

local function loadPlayer(player)
    clearInventory(player);

    if getSandboxOptions():getOptionByName("SafehousePlus.KeepInventory"):getValue() then
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

    if getSandboxOptions():getOptionByName("SafehousePlus.KeepStats"):getValue() then
        loadPlayerStats(player);
    end

    player:setZombieKills(RespawnData[getUniqueId(player)].ZombieKills);
    player:setSurvivorKills(RespawnData[getUniqueId(player)].SurvivorKills);
    player:setHoursSurvived(RespawnData[getUniqueId(player)].HoursSurvived);
    clearWounds(player);

    loadPlayerModel(player);
    loadPlayerBoosts(player);
    loadPlayerTraits(player);
    player:setLevelUpMultiplier(RespawnData[getUniqueId(player)].LevelUpMultiplier);
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
        return getPlayerRespawn(player);
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
