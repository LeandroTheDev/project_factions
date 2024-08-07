---@diagnostic disable: undefined-global, lowercase-global
--This contains all bed sprites from vanilla
local spriteNames = {
    ["carpentry_02_73"] = true,
    ["carpentry_02_74"] = true,
    ["camping_01_10"] = true,
    ["camping_01_13"] = true,
    ["furniture_bedding_01_1"] = true,
    ["furniture_bedding_01_2"] = true,
    ["furniture_bedding_01_3"] = true,
    ["furniture_bedding_01_5"] = true,
    ["furniture_bedding_01_7"] = true,
    ["furniture_bedding_01_14"] = true,
    ["furniture_bedding_01_12"] = true,
    ["furniture_bedding_01_10"] = true,
    ["furniture_bedding_01_9"] = true,
    ["furniture_bedding_01_16"] = true,
    ["furniture_bedding_01_17"] = true,
    ["furniture_bedding_01_18"] = true,
    ["furniture_bedding_01_19"] = true,
    ["furniture_bedding_01_20"] = true,
    ["furniture_bedding_01_21"] = true,
    ["furniture_bedding_01_22"] = true,
    ["furniture_bedding_01_23"] = true,
    ["furniture_bedding_01_30"] = true,
    ["furniture_bedding_01_28"] = true,
    ["furniture_bedding_01_27"] = true,
    ["furniture_bedding_01_25"] = true,
    ["furniture_bedding_01_32"] = true,
    ["furniture_bedding_01_35"] = true,
    ["furniture_bedding_01_36"] = true,
    ["furniture_bedding_01_37"] = true,
    ["furniture_bedding_01_38"] = true,
    ["furniture_bedding_01_39"] = true,
    ["furniture_bedding_01_47"] = true,
    ["furniture_bedding_01_45"] = true,
    ["furniture_bedding_01_42"] = true,
    ["furniture_bedding_01_40"] = true,
    ["furniture_bedding_01_48"] = true,
    ["furniture_bedding_01_49"] = true,
    ["furniture_bedding_01_50"] = true,
    ["furniture_bedding_01_51"] = true,
    ["furniture_bedding_01_52"] = true,
    ["furniture_bedding_01_53"] = true,
    ["furniture_bedding_01_54"] = true,
    ["furniture_bedding_01_55"] = true,
    ["furniture_bedding_01_57"] = true,
    ["furniture_bedding_01_58"] = true,
    ["furniture_bedding_01_60"] = true,
    ["furniture_bedding_01_63"] = true,
    ["furniture_bedding_01_65"] = true,
    ["furniture_bedding_01_66"] = true,
    ["furniture_bedding_01_68"] = true,
    ["furniture_bedding_01_69"] = true,
    ["furniture_bedding_01_70"] = true,
    ["furniture_bedding_01_71"] = true,
    ["furniture_bedding_01_72"] = true,
    ["furniture_bedding_01_73"] = true,
    ["furniture_bedding_01_74"] = true,
    ["furniture_bedding_01_75"] = true,
    ["furniture_bedding_01_76"] = true,
    ["furniture_bedding_01_77"] = true,
    ["furniture_bedding_01_78"] = true,
    ["furniture_bedding_01_79"] = true,
    ["furniture_bedding_01_80"] = true,
    ["furniture_bedding_01_81"] = true,
    ["furniture_bedding_01_82"] = true,
    ["furniture_bedding_01_83"] = true,
    ["furniture_bedding_01_84"] = true,
    ["furniture_bedding_01_85"] = true,
    ["furniture_bedding_01_86"] = true,
    ["furniture_bedding_01_87"] = true,
    ["furniture_bedding_01_0"] = true,
    ["furniture_bedding_01_13"] = true,
    ["furniture_bedding_01_15"] = true,
    ["furniture_bedding_01_4"] = true,
    ["furniture_bedding_01_6"] = true,
    ["furniture_bedding_01_11"] = true,
    ["furniture_bedding_01_8"] = true,
    ["furniture_bedding_01_24"] = true,
    ["furniture_bedding_01_26"] = true,
    ["furniture_bedding_01_29"] = true,
    ["furniture_bedding_01_31"] = true,
    ["furniture_bedding_01_33"] = true,
    ["furniture_bedding_01_34"] = true,
    ["furniture_bedding_01_61"] = true,
    ["furniture_bedding_01_62"] = true,
    ["furniture_bedding_01_41"] = true,
    ["furniture_bedding_01_43"] = true,
    ["furniture_bedding_01_44"] = true,
    ["furniture_bedding_01_46"] = true,
    ["furniture_bedding_01_59"] = true,
    ["furniture_bedding_01_56"] = true,
    ["furniture_bedding_01_67"] = true,
    ["furniture_bedding_01_64"] = true,
    ["furniture_seating_indoor_01_1"] = true,
    ["furniture_seating_indoor_01_2"] = true,
    ["furniture_seating_indoor_01_16"] = true,
    ["furniture_seating_indoor_01_18"] = true,
    ["furniture_seating_indoor_01_27"] = true,
    ["furniture_seating_indoor_01_24"] = true,
    ["furniture_seating_indoor_02_19"] = true,
    ["furniture_seating_indoor_02_16"] = true,
    ["furniture_seating_indoor_02_25"] = true,
    ["furniture_seating_indoor_02_26"] = true,
    ["furniture_seating_indoor_02_35"] = true,
    ["furniture_seating_indoor_02_32"] = true,
    ["furniture_seating_indoor_02_49"] = true,
    ["furniture_seating_indoor_02_50"] = true,
    ["furniture_seating_indoor_02_61"] = true,
    ["furniture_seating_indoor_02_62"] = true,
    ["furniture_seating_indoor_03_1"] = true,
    ["furniture_seating_indoor_03_2"] = true,
    ["furniture_seating_indoor_03_9"] = true,
    ["furniture_seating_indoor_03_10"] = true,
    ["furniture_seating_indoor_03_17"] = true,
    ["furniture_seating_indoor_03_18"] = true,
    ["furniture_seating_indoor_03_32"] = true,
    ["furniture_seating_indoor_03_34"] = true,
    ["furniture_seating_indoor_03_67"] = true,
    ["furniture_seating_indoor_03_64"] = true,
    ["furniture_seating_outdoor_01_1"] = true,
    ["furniture_seating_outdoor_01_2"] = true,
    ["furniture_seating_outdoor_01_10"] = true,
    ["furniture_seating_outdoor_01_8"] = true,
    ["furniture_seating_outdoor_01_21"] = true,
    ["furniture_seating_outdoor_01_22"] = true,
    ["furniture_seating_outdoor_01_33"] = true,
    ["furniture_seating_outdoor_01_34"] = true,
    ["location_community_church_small_01_51"] = true,
    ["location_community_church_small_01_52"] = true,
    ["location_community_church_small_01_53"] = true,
    ["location_community_church_small_01_50"] = true,
    ["location_community_church_small_01_49"] = true,
    ["location_community_church_small_01_48"] = true,
    ["location_community_medical_01_3"] = true,
    ["location_community_medical_01_0"] = true,
    ["location_community_medical_01_21"] = true,
    ["location_community_medical_01_23"] = true,
    ["location_community_medical_01_16"] = true,
    ["location_community_medical_01_18"] = true,
    ["location_community_medical_01_35"] = true,
    ["location_community_medical_01_32"] = true,
    ["location_community_medical_01_75"] = true,
    ["location_community_medical_01_72"] = true,
    ["location_community_medical_01_77"] = true,
    ["location_community_medical_01_78"] = true,
    ["location_community_police_01_27"] = true,
    ["location_community_police_01_29"] = true,
    ["location_community_police_01_24"] = true,
    ["location_community_police_01_30"] = true,
    ["location_restaurant_diner_01_33"] = true,
    ["location_restaurant_diner_01_34"] = true,
    ["location_restaurant_generic_01_2"] = true,
    ["location_restaurant_generic_01_5"] = true,
    ["location_restaurant_generic_01_10"] = true,
    ["location_restaurant_generic_01_13"] = true,
    ["location_restaurant_pizzawhirled_01_45"] = true,
    ["location_restaurant_pizzawhirled_01_40"] = true,
    ["location_restaurant_spiffos_02_21"] = true,
    ["location_restaurant_spiffos_02_16"] = true,
    ["location_shop_mall_01_35"] = true,
    ["location_shop_mall_01_39"] = true,
    ["location_shop_mall_01_32"] = true,
    ["location_shop_mall_01_36"] = true,
    ["location_trailer_02_3"] = true,
    ["location_trailer_02_0"] = true,
    ["recreational_sports_01_43"] = true,
    ["recreational_sports_01_40"] = true,
}

-- Secondary function to check if player is on the safehouse, returns true if belongs to the safehouse
-- false if not belongs to the safehouse or the safehouse is not exist
local function BelongsToTheSafehouse()
    -- Get the player faction based on username
    local function GetPlayerFaction(username)
        -- Get all factions from the server
        local factions = Faction.getFactions();
        for i = 0, factions:size() - 1 do
            local faction = factions:get(i);
            -- If the player is the owner simple return the faction
            if faction:isOwner(username) then
                return faction;
            end
            local players = faction:getPlayers();
            -- If not we swipe the players in faction and see if the actual player is on it
            for j = 0, players:size() - 1 do
                local player = players:get(j);
                if player == username then
                    return faction;
                end
            end
        end
    end
    local player = getPlayer();
    -- Get player safehouse standing
    local safehouse = SafeHouse.getSafeHouse(player:getSquare());

    -- Check if the player is on a safehouse
    if not safehouse then
        return false
    end

    -- Fast check if is the owner
    local safehouseOwner = safehouse:getOwner();
    if player:getUsername() == safehouseOwner then
        return true;
    end

    -- Getting player faction
    local player_faction = GetPlayerFaction(player:getUsername());
    -- Getting the owner faction
    local owner_faction = GetPlayerFaction(safehouseOwner);

    -- Checking if the owner faction is the same as player faction
    if player_faction == owner_faction then
		return true;
	else
		return false
	end
end

-- On click set respawn function
function onSetRespawn(object, playerId)
    local player = getSpecificPlayer(playerId);
    if (not object:getSquare() or not luautils.walkAdj(player, object:getSquare())) then return end
    ISTimedActionQueue.add(SpawnpointAction:new(player, SandboxVars.SafehousePlus.SpawnpointTimer, object));
end

-- Create the set respawn buttons in beds
Events.OnFillWorldObjectContextMenu.Add(function(playerId, context, worldobjects)
    for _, object in ipairs(worldobjects) do
        if (SandboxVars.SafehousePlus.EnableSafehouseRespawn and spriteNames[object:getSprite():getName()]) then
            if BelongsToTheSafehouse() then
                context:addOption(getText("ContextMenu_Respawn_SetRespawn"), object, onSetRespawn, playerId);
                break;
            end
        end;
    end
end);
