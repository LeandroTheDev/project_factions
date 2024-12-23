---@diagnostic disable: undefined-global
Events.OnCreatePlayer.Add(function(id, player)
    --Save player location when created new character
    if (player:getHoursSurvived() == 0) then
        setPlayerRespawn(player);
    end
end);

-- Other players on MP also recive this event
-- For themselve's and other's player death
Events.OnCharacterDeath.Add(function(character)
    if (not instanceof(character, "IsoPlayer")) then return end
    local isMe = (character:getOnlineID() == getPlayer():getOnlineID());

    -- Save and remove our items from hands
    if (isMe and SandboxVars.SafehousePlus.KeepInventory) then
        saveEquipItems(character);
    end

    -- Save our player data
    if (isMe) then savePlayer(character) end

    -- Clear inventory for our and other players
    if (SandboxVars.SafehousePlus.KeepInventory) then
        clearInventory(character);
    end
    
    -- Fix corpse duplication glitch on MP
    if (isClient() and not isMe) then
        character:setOnDeathDone(true);
    end
end);