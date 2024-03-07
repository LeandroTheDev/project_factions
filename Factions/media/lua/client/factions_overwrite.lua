---@diagnostic disable: undefined-global

-- Explanation about this file.
-- this file makes overwrites to client functions about safehouses and factions

require "ISUI/ISContextMenu"
require "ISUI/UserPanel/ISSafehouseUI"
require "ISUI/UserPanel/ISSafehouseAddPlayerUI"
require "ISUI/UserPanel/ISFactionUI"
require "ISUI/UserPanel/ISCreateFactionUI"
require "ISUI/UserPanel/ISFactionAddPlayerUI"

require "ui/factions"

-- Removing the View Safehouse Context Menu in right click on the ground
local _addOption = ISContextMenu.addOption;
function ISContextMenu:addOption(name, target, onSelect, param1, param2, param3, param4, param5, param6, param7, param8,
                                 param9, param10)
    if name == getText("ContextMenu_ViewSafehouse") or name == getText("ContextMenu_SafehouseClaim") then
        local arr = {};
        return arr;
    end
    return _addOption(self, name, target, onSelect, param1, param2, param3, param4, param5, param6, param7, param8,
        param9, param10);
end

local _addOptionOnTop = ISContextMenu.addOptionOnTop;
function ISContextMenu:addOptionOnTop(name, target, onSelect, param1, param2, param3, param4, param5, param6, param7,
                                      param8, param9, param10)
    if name == getText("ContextMenu_ViewSafehouse") or name == getText("ContextMenu_SafehouseClaim") then
        local arr = {};
        return arr;
    end
    return _addOptionOnTop(self, name, target, onSelect, param1, param2, param3, param4, param5, param6, param7, param8,
        param9, param10);
end

-- Override Functions

-- Default function to handle on click to create faction
local onClickCreateFaction = ISCreateFactionUI.onClick;

-- Function to handle the click to create faction
function ISCreateFactionUI:onClick(button)
    -- Default behavior
    onClickCreateFaction(self, button);

    -- Check if the pressed butto is ok
    if button.internal == "OK" then
        -- Reload the ui
        FactionsMain.unloadUI();
    end
end

-- Default function to handle on click add player faction
local onClickFactionAddPlayer = ISFactionAddPlayerUI.onClick;

-- Function to handle the click to add player faction
function ISFactionAddPlayerUI:onClick(button)
    -- Check if the button pressed is add player
    if button.internal == "ADDPLAYER" and self.changeOwnership then
        -- Transfers all safehouses to the new faction owner
        -- Swipe safehouses
        for i = 0, SafeHouse.getSafehouseList():size() - 1 do
            local safehouse = SafeHouse.getSafehouseList():get(i);
            -- Check if the safehouse is from the owner
            if self.faction:getOwner() == self.selectedPlayer then
                -- Change owner
                safehouse:setOwner(newOwner);
                -- Add the old owner as a normal ally
                safehouse:addPlayer(currentOwner);
                -- Update safehouse
                safehouse:syncSafehouse();
            end
        end
    end
    -- Default behavior
    onClickFactionAddPlayer(self, button);
    -- Reload ui
    FactionsMain.unloadUI();
end

-- Default function to handle the click to see the faction
local onClickFaction = ISFactionUI.onClick;

-- Function to handle the click to see the faction
function ISFactionUI:onClick(button)
    -- Check if the button pressed is remove
    if button.internal == "REMOVE" then
        -- Release safehouse on disband
        -- Get the owner username
        local ownerUsername = self.faction:getOwner();
        -- Get the player entity from owner
        local player = getPlayerFromUsername(ownerUsername);
        repeat
            local continue = false;
            -- Swipe all safehouses
            for i = SafeHouse.getSafehouseList():size() - 1, 0, -1 do
                -- Getting the actual index safehouse
                local safehouse = SafeHouse.getSafehouseList():get(i);
                -- Check if the owner username is the same from safehouse
                if safehouse:getOwner() == ownerUsername then
                    -- Remove safehouse
                    safehouse:removeSafeHouse(player);
                    continue = true;
                    break;
                end
            end
        until not continue
        -- Remove the faction
        self.faction:removeFaction();
        self:close()
        return;
    end
    -- Default behavior
    onClickFaction(self, button);
end

-- Default function to handle the on quit faction
local onQuitFaction = ISFactionUI.onQuitFaction;

-- Function to handle the on click faction
function ISFactionUI:onQuitFaction(button)
    -- Default behavior
    onQuitFaction(self, button);
    -- Check if the button pressed is yes
    if button.internal == "YES" then
        -- Reload ui
        FactionsMain.unloadUI();
    end
end

-- Default function to handle the on answser the invitation to the faction
local onAnswerFactionInvite = ISFactionUI.onAnswerFactionInvite;
-- Function to handle the answer inviation
function ISFactionUI:onAnswerFactionInvite(button)
    -- Default behavior
    onAnswerFactionInvite(self, button);
    -- Check if the button pressed is yes
    if button.internal == "YES" then
        -- Reload ui
        FactionsMain.unloadUI();
    end
end

-- Syncronizes the faction
function FactionsGUI.SyncFaction(factionName)
    -- Default function to sync faction from project zomboid
    ISFactionUI.SyncFaction(factionName)
    -- Reload ui
    FactionsMain.unloadUI();
end

-- Remove the default event from sync faction
Events.SyncFaction.Remove(ISFactionUI.SyncFaction);
-- Add your event
Events.SyncFaction.Add(FactionsGUI.SyncFaction);

--- SafehouseUI functions override

-- Update the tables from lists
local function updateSafehouseList()
    if ISSafehousesList.instance then
        ISSafehousesList.instance:populateList()
        if ISSafehousesList.instance.datas:size() == 0 then
            ISSafehousesList.instance:close()
        end
    end
end

-- Update the safehouse datas to the server when something happens
function FactionsGUI.OnSafehousesChanged()
    -- Default function to update safehouses in project zomboid
    ISSafehouseUI.OnSafehousesChanged()
    -- Update datas
    updateSafehouseList()
    -- Reload ui
    FactionsMain.unloadUI();
end

-- Remove the default event to update safehouses
Events.OnSafehousesChanged.Remove(ISSafehouseUI.OnSafehousesChanged)
-- Add your event
Events.OnSafehousesChanged.Add(FactionsGUI.OnSafehousesChanged)

-- Accept invites only from faction members (accept invitations to multiple safehouses)
FactionsGUI.ReceiveSafehouseInvite = function(safehouse, host)
    if ISSafehouseUI.inviteDialogs[host] then
        if ISSafehouseUI.inviteDialogs[host]:isReallyVisible() then return end
        ISSafehouseUI.inviteDialogs[host] = nil
    end

    if FactionsMain.getFaction(getPlayer():getUsername()) == FactionsMain.getFaction(host) then
        safehouse:addPlayer(getPlayer():getUsername());
        acceptSafehouseInvite(safehouse, host)
        print("Joined safehouse - " .. safehouse:getTitle())
    else
        local modal = ISModalDialog:new(getCore():getScreenWidth() / 2 - 175, getCore():getScreenHeight() / 2 - 75, 350,
            150, getText("IGUI_SafehouseUI_Invitation", host), true, nil, ISSafehouseUI.onAnswerSafehouseInvite);
        modal:initialise()
        modal:addToUIManager()
        modal.safehouse = safehouse;
        modal.host = host;
        modal.moveWithMouse = true;
        ISSafehouseUI.inviteDialogs[host] = modal
    end
end

-- Remove the default event for receiving safehouse invite
Events.ReceiveSafehouseInvite.Remove(ISSafehouseUI.ReceiveSafehouseInvite);
-- Add your event
Events.ReceiveSafehouseInvite.Add(FactionsGUI.ReceiveSafehouseInvite);

-- Default function to handle the Invite to Safehouse accept
local onAnswerSafehouseInvite = ISSafehouseUI.onAnswerSafehouseInvite;

-- Function to handle the Invitations to Safehouse (faction) wrong name indie stone
function ISSafehouseUI:onAnswerSafehouseInvite(button)
    -- Default behavior
    onAnswerSafehouseInvite(self, button);
    -- Check if the button pressed is yes
    if button.internal == "YES" then
        -- Reload UI to remove button
        FactionsMain.unloadUI();
    end
end

--  Default function to handle the On Title Changed
local onChangeTitleSafehouse = ISSafehouseUI.onChangeTitle;

-- Function to handle the On Title Changed
function ISSafehouseUI:onChangeTitle(button)
    -- Default behavior
    onChangeTitleSafehouse(self, button);
    -- Check if the button pressed is ok, so the title is changed
    if button.internal == "OK" then
        -- Reload UI to remove button
        FactionsMain.unloadUI();
    end
end

-- Default function to handle quit safehouse
local onQuitSafehouse = ISSafehouseUI.onQuitSafehouse;

-- Function to handle the quit safehouse
function ISSafehouseUI:onQuitSafehouse(button)
    -- Default behavior
    onQuitSafehouse(self, button);

    -- Update the safehouse list from our overwrited function
    updateSafehouseList();
    -- Reload UI to remove button
    FactionsMain.unloadUI();
end

-- Default function to handle on safehouse click
local onClickSafehouse = ISSafehouseUI.onClick;

-- The function to handle the on safehouse click
function ISSafehouseUI:onClick(button)
    -- We need to check the change owner ship function
    if button.internal == "CHANGEOWNERSHIP" then
        -- Only admins can do this so we check it
        if getAccessLevel() ~= "admin" then
            return;
        end
    end
    -- Default behaviour
    onClickSafehouse(self, button);
end

-- Default function to handle on mouse click, we override it to your new function
local onOptionMouseDownUserPanel = ISUserPanelUI.onOptionMouseDown;

-- The function to handle the button pressed
function ISUserPanelUI:onOptionMouseDown(button, x, y)
    -- Check if the button is from the Safehouse Panel
    if button.internal == "SAFEHOUSEPANEL" then
        if SafeHouse.hasSafehouse(self.player) then
            -- Creating the Safehouse UI Modal
            local safehouseModal = ISSafehousesList:new(50, 50, 600, 600, getPlayer());

            -- Initializing
            safehouseModal:initialise();
            safehouseModal.teleportBtn:setEnabled(false);
            safehouseModal.teleportBtn:setVisible(false);
            safehouseModal:addToUIManager();
        end
        return;
    end
    -- Default behaviour
    onOptionMouseDownUserPanel(self, button, x, y);
end

-- Override the population list function from Safehouse List
function ISSafehousesList:populateList()
    -- Clear previously datas from Safehouse List
    self.datas:clear();
    -- Swipe players in user safehouse
    for i = 0, SafeHouse.getSafehouseList():size() - 1 do
        -- Get all users safehouse based in index
        local safe = SafeHouse.getSafehouseList():get(i);
        -- Get the user acess level
        local accessLevel = getAccessLevel();
        -- List all safehouses only if admin/moderator/gm/etc, otherwise list safehouses where player is allowed
        if (accessLevel ~= "" and accessLevel ~= "None") or safe:playerAllowed(getPlayer():getUsername()) then
            -- Add the safehouse title to the Safehouse List
            self.datas:addItem(safe:getTitle(), safe);
        end
    end
end

-- Override the population list function from Safehouse Add List
function ISSafehouseAddPlayerUI:populateList()
    -- Check if the player is on the safehouse and return the safehouse if exist and nil if not
    local function isOnTheSafehouse(safehouse, username)
        local players = safehouse:getPlayers();
        for i = 0, players:size() - 1 do
            if players:get(i) == username then
                return safehouse;
            end
        end
    end

    -- Clear previously player list
    self.playerList:clear();

    -- Check if the scoreboard exists
    if not self.scoreboard then return end

    -- Swiping all scoreboards names
    for i = 1, self.scoreboard.usernames:size() do
        -- Getting data by index
        local username = self.scoreboard.usernames:get(i - 1)
        local displayName = self.scoreboard.displayNames:get(i - 1)

        -- Check if is not the owner, so only show the players that is not the owner
        if self.safehouse:getOwner() ~= username then
            local newPlayer = {};
            newPlayer.username = username;
            -- Check if the new player is already in safehouse, if exist will return the safehouse
            local isAlreadyInSafehouse = isOnTheSafehouse(self.safehouse, username);
            if isAlreadyInSafehouse then
                -- If is differente from Safehouse shows the safehouse title
                if isAlreadyInSafehouse:getTitle() ~= "Safehouse" then
                    newPlayer.tooltip = getText("IGUI_SafehouseUI_AlreadyHaveSafehouse",
                        "(" .. isAlreadyInSafehouse:getTitle() .. ")");
                else
                    newPlayer.tooltip = getText("IGUI_SafehouseUI_AlreadyHaveSafehouse", "");
                end
            end
            -- Add the player username and display name to the list
            local item = self.playerList:addItem(displayName, newPlayer);
            -- Check if player is already added to the safehouse so add the tooltip to the item to show the message
            if newPlayer.tooltip then
                item.tooltip = newPlayer.tooltip;
            end
        end
    end
end
