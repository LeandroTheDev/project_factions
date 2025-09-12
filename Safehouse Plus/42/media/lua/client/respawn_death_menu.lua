if not getSandboxOptions():getOptionByName("SafehousePlus.EnableRespawnMechanic"):getValue() then return end

-- Default Functions
local CoopMapSpawnSelect_clickNext = CoopMapSpawnSelect.clickNext;
local ISPostDeathUI_render = ISPostDeathUI.render;
local ISPostDeathUI_onRespawn = ISPostDeathUI.onRespawn;

-- Spam server check
local alreadyChecked = false;

function ISPostDeathUI:render(...)
    local seconds = (self.timeOfDeath + getSandboxOptions():getOptionByName("SafehousePlus.RespawnCooldown"):getValue() + 4) -
        getTimestamp();
    self.buttonQuit:setTitle(getText("IGUI_Respawn_DeathUI_Respawn") .. ((seconds > 0) and (" " .. seconds .. "") or ""));
    self.buttonQuit:setEnable(seconds <= 0);
    ISPostDeathUI_render(self, ...);

    -- Save player for later
    self.player = getSpecificPlayer(self.playerIndex);
    -- Ask the server if hes can spawn in the bed
    if (seconds <= 5 and not alreadyChecked) then
        alreadyChecked = true;
        -- Disabled for now, need to rework factions first
        -- local coords = getPlayerRespawn(self.player);
        -- sendClientCommand("ServerRespawn", "canSpawn", {
        --     x = coords.x,
        --     y = coords.y,
        --     z = coords.z,
        -- });
    end
end

-- This is a button "NEW CHARACTER" on death screen
function ISPostDeathUI:onRespawn(...)
    alreadyChecked = false;
    self.buttonQuit.AutoRespawn = true;
    ISPostDeathUI_onRespawn(self, ...);
end

-- When "RESPAWN" button is clicked on death screen
function ISPostDeathUI:onQuitToDesktop(...)
    alreadyChecked = false;
    self.buttonQuit.AutoRespawn = true;
    ISPostDeathUI_onRespawn(self, ...);
    local CCC = CoopCharacterCreation.instance;
    if (not CCC) then return end;

    -- Rename "NEXT" button to "RESPAWN"
    CCC.mapSpawnSelect.nextButton:setTitle(getText("IGUI_Respawn_CCC_Respawn"));

    -- Safehouse respawn is enabled
    if getSandboxOptions():getOptionByName("SafehousePlus.EnableSafehouseRespawn"):getValue() then
        local function receiveRespawn(module, command, arguments)
            if module == "SafehousePlusRespawn" and command == "receiveRespawn" then
                Events.OnServerCommand.Remove(receiveRespawn);

                local coords = arguments;
                local isRespawn = (coords.x ~= nil) and (coords.y ~= nil) and (coords.z ~= nil);

                if isRespawn then
                    -- Create respawn points
                    local item = {
                        name = getText("IGUI_Respawn_Bed"),
                        region = nil,
                        dir = "",
                        worldimage = nil,
                        desc = getText("IGUI_Respawn_In_Bed")
                    }

                    -- Add respawn in bed as new option
                    CCC.mapSpawnSelect.listbox:insertItem(0, item.name, item);
                    -- Disable zoom for the spawn in bed
                    CCC.mapSpawnSelect.listbox.items[1].item.zoomS = 0;
                end;
            end
        end
        if SafehousePlusIsSinglePlayer then
            receiveRespawn("SafehousePlusRespawn", "receiveRespawn", GetPlayerRespawn(getPlayer()));
        else
            Events.OnServerCommand.Add(receiveRespawn);
        end
    end
end

-- This will run when "NEXT" ("RESPAWN") is pressed inside spawn selection
function CoopMapSpawnSelect:clickNext(...)
    alreadyChecked = false;
    --Check if it is custom spawn selection made by respawn
    if (not CoopCharacterCreation.instance) then return end;
    local title = self.nextButton:getTitle();
    if (title ~= getText("IGUI_Respawn_CCC_Respawn")) then return CoopMapSpawnSelect_clickNext(self, ...) end;
    local selected = self.listbox.items[self.listbox.selected].item;
    local self = CoopCharacterCreation.instance;

    -- Hide spawn selection screen
    self:removeFromUIManager();
    CoopCharacterCreation.setVisibleAllUI(true);
    CoopCharacterCreation.instance = nil;

    -- Hide death menu screen
    if (ISPostDeathUI.instance[self.playerIndex]) then
        ISPostDeathUI.instance[self.playerIndex]:removeFromUIManager();
        ISPostDeathUI.instance[self.playerIndex] = nil;
    end

    -- If selected respawn then update respawn location
    if (selected.name ~= getText("IGUI_Respawn_Bed")) then
        if SafehousePlusIsSinglePlayer then
            RemovePlayerRespawn(getPlayer());
            SetRespawnRegion(getPlayer(), selected.region);
        else
            sendClientCommand("SafehousePlusRespawn", "setRespawnRegion", selected);
        end
    end

    -- Spawn player for mouse & keyboard
    if (not self.joypadData) then
        setPlayerMouse(nil);
    else --Spawn player for controller
        local controller = self.joypadData.controller;
        local joypadData = JoypadState.joypads[self.playerIndex + 1];
        JoypadState.players[self.playerIndex + 1] = joypadData;
        joypadData.player = self.playerIndex;
        joypadData:setController(controller);
        joypadData:setActive(true);
        local username = nil;

        if (isClient() and self.playerIndex > 0) then
            username = CoopUserName.instance:getUserName();
        end

        setPlayerJoypad(self.playerIndex, self.joypadIndex, nil, username);

        self.joypadData.focus = nil;
        self.joypadData.lastfocus = nil;
        self.joypadData.prevfocus = nil;
        self.joypadData.prevprevfocus = nil;
    end

    if SafehousePlusIsSinglePlayer then
        -- Load player data
        LoadPlayer(getPlayer());
        SetHealth(getPlayer(), getSandboxOptions():getOptionByName("SafehousePlus.HealthOnRespawn"):getValue());

        -- Teleport player to respawn location
        if (selected.name == getText("IGUI_Respawn_Bed")) then
            LoadRespawnLocation(getPlayer());
        end

        -- Save player respawn location
        SetPlayerRespawn(getPlayer());
    else
        sendClientCommand("SafehousePlusRespawn", "loadPlayer", nil);
        -- triggerEvent("OnClothingUpdated", getPlayer());
    end
end
