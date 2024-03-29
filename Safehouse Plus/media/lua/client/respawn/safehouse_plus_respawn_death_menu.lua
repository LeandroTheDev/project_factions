---@diagnostic disable: undefined-global
-- Default Functions
local CoopMapSpawnSelect_clickNext = CoopMapSpawnSelect.clickNext;
local ISPostDeathUI_render = ISPostDeathUI.render;
local ISPostDeathUI_onRespawn = ISPostDeathUI.onRespawn;

local allowRespawn = true;
-- Spam server check
local alreadyChecked = false;

-- Handle server message
local function OnServerCommand(module, command, arguments)
    -- Receive allow respawn is enabled
    if module == "ServerRespawn" and command == "canSpawn" then
        allowRespawn = arguments.canSpawn;
    end
end

function ISPostDeathUI:render(...)
    local seconds = (self.timeOfDeath + SandboxVars.SafehousePlus.RespawnCooldown + 4) - getTimestamp();
    self.buttonQuit:setTitle(getText("IGUI_Respawn_DeathUI_Respawn") .. ((seconds > 0) and (" " .. seconds .. "") or ""));
    self.buttonQuit:setEnable(seconds <= 0);
    ISPostDeathUI_render(self, ...);

    -- Save player for later
    self.player = getSpecificPlayer(self.playerIndex);
    -- Ask the server if hes can spawn in the bed
    if (seconds <= 5 and not alreadyChecked) then
        local coords = getPlayerRespawn(self.player);
        alreadyChecked = true;
        sendClientCommand("ServerRespawn", "canSpawn", {
            x = coords.x,
            y = coords.y,
            z = coords.z,
        });
    end
    --If auto respawn then press respawn button
    if ((seconds <= 0) and isAutoRespawn(self.player) and (not self.buttonQuit.AutoRespawn)) then
        local activate = self.buttonQuit.sounds["activate"];
        self.buttonQuit.sounds["activate"] = nil;
        self.buttonQuit:forceClick();
        self.buttonQuit.sounds["activate"] = activate;
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

    -- Check if player can respawn
    local coords = getPlayerRespawn(self.player);
    local isRespawn = SandboxVars.SafehousePlus.EnableSafehouseRespawn and (coords.x ~= nil) and (coords.y ~= nil) and
        (coords.z ~= nil);

    if (isRespawn and allowRespawn) then
        -- Create respawn points
        local item = {
            name = getText("IGUI_Respawn_Bed"),
            region = nil,
            dir = "",
            worldimage = nil,
            desc = getText("IGUI_Respawn_In_Bed")
        }

        --Add respawn as new option
        CCC.mapSpawnSelect.listbox:insertItem(0, item.name, item);
    end;
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
        removePlayerRespawn(getPlayer());
        setRespawnRegion(getPlayer(), selected.region);
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

    -- Load player data
    loadPlayer(getPlayer());
    setHealth(getPlayer(), SandboxVars.SafehousePlus.HealthOnRespawn);

    -- Teleport player to respawn location
    if (selected.name == getText("IGUI_Respawn_Bed")) then
        loadRespawnLocation(getPlayer());
    end

    -- Save player respawn location
    setPlayerRespawn(getPlayer());
end

Events.OnServerCommand.Add(OnServerCommand)
