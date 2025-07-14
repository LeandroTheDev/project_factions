---@diagnostic disable: undefined-global
require "ui/factions_label"
require "ISUI/ISPanel"
require "ISUI/ISButton"

-- Explanation about this file.
-- this file contains the UI for the safehouses

FactionsGUI = ISPanel:derive("FactionsGUI");
FactionsGUI.btnText = { getText("UI_Text_SafehouseClaim"), getText("UI_Text_SafehouseCapture"),
	getText("UI_Text_SafehouseView") }
FactionsGUI.captureTime = 50000;
FactionsGUI.updateTime = 500;
FactionsGUI.minimized = true;
FactionsGUI.finishedCapture = false;

local safehouseUI = nil;

local function getDeltaTimeInMillis(ts)
	return getTimeInMillis() - ts;
end

-- Creating the panel the right side of GUI

local panel = ISPanel:derive("FactionsGUIPanel");

function panel:onMouseDown(x, y) -- Overwrite moving
	self.moving = true;
end

function panel:onMouseUp(x, y) -- Overwrite moving
	self.moving = false;
end

function panel:onMouseMoveOutside(dx, dy) -- Overwrite moving
	self.moving = false;
end

-- Creating the badge on the left side of the GUI

Badge = ISPanel:derive("FactionsGUIBadge");

function Badge:initialise() -- Initialization Method
	ISPanel.initialise(self);
end

function Badge:update() -- Updates every ticks
	-- If is capturing a enemy safehouse
	if self.capture then
		-- Above that we are creating a timer per second for reducing,
		-- this is used to change the images in badge during the capture
		local delta = getDeltaTimeInMillis(self.timestamp);
		self.timestamp = getTimeInMillis()
		if self.state == 0 then
			self.timer = self.timer - delta;
			if self.timer < 1 then
				self.state = 1;
			end
		elseif self.state == 1 then
			-- In the final of the capture
			if self.timer > FactionsGUI.captureTime then
				-- Spam check for not spamming the server with requisitions
				if FactionsGUI.finishedCapture then return end
				-- We communicate with the server saying you finish capturing,
				-- the server will handle if makes sense the capture
				FactionsGUI.finishedCapture = true;
				sendClientCommand("ServerFactions", "onCaptureSafehouse", nil)
			else
				self.timer = self.timer + delta;
			end
		end
	end
end

function Badge:prerender() -- Before updating the screen render
	-- If is capturing
	if self.capture then
		-- Change the color based in the capture
		if self.state == 0 then -- first part
			self:drawTexture(self.texture_r[math.floor(self.timer / (FactionsGUI.captureTime / 20))], 0, 0, self.alpha, 1,
				1, 1);
		elseif self.state == 1 then -- second part
			self:drawTexture(self.texture_b[math.floor(self.timer / (FactionsGUI.captureTime / 20))], 0, 0, self.alpha, 1,
				1, 1);
		end
	else
		-- Change the color based in enemy or friendly
		if self.team == nil then -- empty
			self:drawTexture(self.freeTex, 0, 0, self.alpha, 1, 1, 1);
		elseif self.team then -- friendly
			self:drawTexture(self.blueTex, 0, 0, self.alpha, 1, 1, 1);
		else               -- enemy
			self:drawTexture(self.redTex, 0, 0, self.alpha, 1, 1, 1);
		end
	end
end

function Badge:onMouseMove(dx, dy) -- Overwrite moving
	if self.alpha == 0.75 and FactionsGUI.minimized then
		self.alpha = 1.0;
	end
end

function Badge:onMouseMoveOutside(dx, dy) -- Overwrite moving
	if self.alpha == 1.0 and FactionsGUI.minimized then
		self.alpha = 0.75;
	end
end

function Badge:onMouseUp() -- Overwrite moving
	if FactionsGUI.minimized then
		FactionsGUI.minimized = false;
		self.alpha = 1.0;
	else
		FactionsGUI.minimized = true;
		self:onMouseMove();
	end
end

function Badge:new(x, y) -- Instanciation the Badgez
	-- Getting the Badge image
	local defaultBadge = getTexture("media/ui/flag.png");
	-- Instanciating the panel badge
	local o = ISPanel:new(0, 0, defaultBadge:getWidth(), defaultBadge:getHeight());
	setmetatable(o, self)
	self.__index = self

	-- Setting the Sizee and Position
	o.width = defaultBadge:getWidth();
	o.height = defaultBadge:getHeight();
	o.x = x;
	o.y = y;

	-- Setting the Colors
	o.borderColor = { r = 0, g = 0, b = 0, a = 0 };
	o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 };

	-- Anchoring the Badge
	o.anchorLeft = true;
	o.anchorRight = false;
	o.anchorTop = false;
	o.anchorBottom = true;

	-- Default Textures for Badge
	o.freeTex = defaultBadge;
	o.redTex = getTexture("media/ui/red/Capture100.png");
	o.blueTex = getTexture("media/ui/blue/Capture100.png");

	-- Default variables
	o.timer = 0;
	o.capture = false;
	o.state = 0;
	o.noBackground = true;
	o.owner = nil;

	-- Default Opacity
	o.alpha = 1.0;
	-- If is minimized changes the opacity to lower
	if FactionsGUI.minimized then
		o.alpha = 0.75;
	end

	-- Instanciate other textures for the capture system
	o.texture_r = {}
	o.texture_b = {}
	for i = 0, 20 do
		o.texture_r[i] = getTexture("media/ui/red/Capture" .. tostring(i * 5) .. ".png");
		o.texture_b[i] = getTexture("media/ui/blue/Capture" .. tostring(i * 5) .. ".png");
	end

	return o
end

-- Now we are creating the main GUI

function FactionsGUI:initialise() -- UI initialization
	ISPanel.initialise(self);
end

function FactionsGUI:minimize() -- UI minimize overwrite
	self.panel:setVisible(false);
	self.backgroundColor.a = 0;
	self.borderColor.a = 0;
end

function FactionsGUI:update() -- UI every tick overwrite
	-- Check if player exist, fix for UI errors in respawn
	if not self.player then
		self.player = getPlayer();
		-- Disable UI
		FactionsMain.unloadUI();
	end

	-- Minimization check
	if FactionsGUI.minimized and self.panel:getIsVisible() then          -- check the variable is set to be minimized
		self:minimize();
	elseif not FactionsGUI.minimized and not self.panel:getIsVisible() then -- otherwises show up again
		self.panel:setVisible(true);
		self.borderColor.a = 0.1;
		self.panel.backgroundColor.a = 0;
		self:onMouseMove();
	end

	-- Limiter tick for updating
	if self.timer > 0 then
		local delta = getDeltaTimeInMillis(self.timestamp);
		self.timer = self.timer - delta
	else
		self.timer = FactionsGUI.updateTime;
		self:updateButtons();
	end

	-- Timestamp update
	self.timestamp = getTimeInMillis()
end

function FactionsGUI:updateButtons() -- Update dynamically the buttons based in self parameters
	-- If player is capturing disable the button
	if self.badge.capture then
		self.button:setEnable(false);
		self.internal = "";
		return;
	end

	-- If player is not in a faction simple do nothing,
	-- if someoneInside is nil is because hes doesnt have a faction
	if not self.faction then
		self.button:setEnable(false);
		self.button:setTooltip(getText("UI_Text_SafehouseWithoutFaction"))
		self.internal = "";
		return;
	end

	local safehouse = SafeHouse.getSafeHouse(self.player:getSquare());
	if safehouse then
		if safehouse:playerAllowed(self.player) then
			self.internal = "View";
			self.button:setEnable(true);
			return;
		else
			self.internal = "Capture";
			self.button:setEnable(true);
			return;
		end
	end

	local safehouseUnavailableReason = SafeHouse.canBeSafehouse(self.player:getSquare(), self.player);
	if safehouseUnavailableReason ~= "" then
		self.button:setEnable(false);
		self.button:setTooltip(safehouseUnavailableReason);
		self.internal = "Capture_Spawn";
		return;
	end

	-- Update the self someone inside
	self.someoneInside = FactionsMain.isSomeoneInside(self.player:getSquare(), self.faction, self.floors);

	-- Get available points
	local available = FactionsMain.Points - FactionsMain.getUsedPoints(self.player:getUsername());
	local pointsEnough = tonumber(available) >= tonumber(self.price);
	-- Check if someone is inside and is enabled
	if self.someoneInside then
		-- Set to false, because someone is inside and you cannot capture a safehouse with someone inside... dummy
		self.button:setEnable(false);
		self.button:setTooltip(getText("IGUI_Safehouse_SomeoneInside"));
		self.internal = "";
		return;
	elseif pointsEnough then -- Check if have points enough for capturing
		self.button:setEnable(true);
		self.button:setTooltip(getText("UI_Text_SafehousePointsAvailable", self.price, available));
		self.internal = "Capture_Empty";
		return;
	else -- Not enough points
		self.button:setEnable(false);
		self.button:setTooltip(getText("UI_Text_SafehouseNotEnoughPoints", available, self.price))
		self.internal = "";
		return;
	end
end

function FactionsGUI:createChildren() -- Overwrite the children creation method
	-- Creating the badge
	local badge = Badge:new(18, 18);
	-- Initializing the badge
	badge:initialise();
	-- Adding it to the Game GUI
	self:addChild(badge);
	self.badge = badge;
	self.badge.team = self.team;

	local offset = (badge:getX() * 2) + badge:getWidth();

	-- Setting the panel size and colors
	self.panel = panel:new(offset, 0, self.width - offset, self.height);
	self.panel.backgroundColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.5 };
	self.panel.borderColor = { r = 1, g = 1, b = 1, a = 0.0 };
	-- Initializing the panel
	self.panel:initialise();
	-- Adding it to the Game GUI
	self:addChild(self.panel);

	-- Setting the Size of texts
	local width_title = getTextManager():MeasureStringX(UIFont.NewLarge, self.titleText);
	local height_title = getTextManager():MeasureFont(UIFont.NewLarge);

	local width_faction = getTextManager():MeasureStringX(UIFont.NewMedium, self.factionText);
	local height_faction = getTextManager():MeasureFont(UIFont.NewMedium);

	local width_button = getTextManager():MeasureStringX(UIFont.NewMedium, self.buttonText);
	local height_button = getTextManager():MeasureFont(UIFont.NewMedium);

	-- Creating the Title Text
	local titleLabel = FactionsGUILabel:new((self.panel.width / 2) - (width_title / 2) - 1.5, 18 - 2, width_title,
		height_title,
		self.titleText, 1.0, 1.0, 1.0, 1.0, UIFont.NewLarge)
	-- Initializing
	titleLabel:initialise()
	-- Adding it to the Panel GUI
	self.panel:addChild(titleLabel);
	self.titleLabel = titleLabel;

	-- Creating the Faction Text
	local factionLabel = FactionsGUILabel:new((self.panel.width / 2) - (width_faction / 2) - 1.5, 18 + height_title,
		width_faction, height_faction, self.factionText, 1.0, 1.0, 1.0, 1.0, UIFont.NewMedium)
	-- Initializing
	factionLabel:initialise()
	-- Adding it to the Panel GUI
	self.panel:addChild(factionLabel);
	self.factionLabel = factionLabel;

	-- Creating the Capture Button
	local button = ISButton:new((self.panel.width / 2) - (width_button / 2) - 1.5, self.height - 10 - height_button,
		width_button, height_button, self.buttonText, self, FactionsGUI.onButtonClick)
	-- Initializing the button
	button:initialise()
	-- Adding it to the Panel GUI
	self.panel:addChild(button);
	self.button = button;
	self.button.internal = "";
	-- Update visibility based in the button data
	self.button:setVisible(self.buttonVisible);

	-- Getting the price of the house of the player standing house
	if FactionsMain.building then
		if instanceof(FactionsMain.building, "IsoBuilding") then
			self.price = FactionsMain.getCost(FactionsMain.building:getDef());
		elseif instanceof(FactionsMain.building, "SafeHouse") then
			self.price = FactionsMain.getCost(FactionsMain.building, 4);
		end
	end
	-- If the price is lower than one, set to one
	if self.price < 1 then
		self.price = 1;
	end

	-- Offset for making parent borders visible
	self.panel.y = 2;
	self.panel.width = self.panel:getWidth() - 2;
	self.panel.height = self.panel:getHeight() - 4;

	-- Check if is minimized so the function for minimization is called
	if FactionsGUI.minimized then
		self:minimize();
	end

	self:onMouseMoveOutside();
	self:updateButtons();
end

function FactionsGUI.onButtonClick() -- On the button click
	local internal = FactionsMain.GUI.internal;
	if internal == "View" then       -- View the safehouse button
		if safehouseUI then
			safehouseUI:removeFromUIManager()
		end
		safehouseUI = ISSafehouseUI:new(getCore():getScreenWidth() / 2 - 250, getCore():getScreenHeight() / 2 - 225, 500,
			450, FactionsMain.GUI.safehouse, getPlayer());
		safehouseUI:initialise()
		safehouseUI:addToUIManager()
	elseif internal == "Capture" then -- Capture the enemy safehouse button
		FactionsGUI.finishedCapture = false;
		-- Ask the server that you are trying to capture the safehouse
		sendClientCommand("ServerFactions", "captureSafehouse", nil);
	elseif internal == "Capture_Empty" then -- Capture Residential button
		-- IMPORTANT
		-- You cannot do that on the server side, the b42mp patch handle this in clientside, maybe in the official releases it will be different
		sendSafehouseClaim(getPlayer():getSquare(), getPlayer(), getPlayer():getUsername());

		-- Ask the server if is valid capturing the safehouse
		sendClientCommand("ServerFactions", "captureEmptySafehouse", nil);
	end
end

function FactionsGUI:onMouseMove(dx, dy) -- Overwrite Mouse
	if self.panel.backgroundColor.a ~= 0.5 and not FactionsGUI.minimized then
		self.backgroundColor.a = 0.4;
		self.panel.backgroundColor.a = 0.5;
		self.titleLabel.a = 1.0;
		self.factionLabel.a = 1.0;
		self.button:setVisible(self.buttonVisible);
	end
	if self.dragging == false then return end
	self.mouseOver = true;
	if self.moving or self.panel.moving then
		self:setX(self.x + dx);
		self:setY(self.y + dy);
	end
end

function FactionsGUI:onMouseMoveOutside(dx, dy) -- Overwrite Mouse
	if self.panel.backgroundColor.a ~= 0.1 and not FactionsGUI.minimized then
		self.backgroundColor.a = 0.2;
		self.panel.backgroundColor.a = 0.1;
		self.titleLabel.a = 0.5;
		self.factionLabel.a = 0.5;
		self.button:setVisible(false);
	end
	if self.dragging == false then return end
	if not self:getIsVisible() then return end
	self.moving = false;
	ISMouseDrag.dragView = nil;
end

function FactionsGUI:onMouseUp(x, y) -- Overwrite Mouse
	if self.dragging == false then return end
	if not self:getIsVisible() then return end
	self.moving = false;
	if ISMouseDrag.tabPanel then
		ISMouseDrag.tabPanel:onMouseUp(x, y);
	end
	ISMouseDrag.dragView = nil;
end

function FactionsGUI:onMouseDown(x, y) -- Overwrite Mouse
	if self.dragging == false then return end
	if not self:getIsVisible() then return end
	self.downX = x;
	self.downY = y;
	self.moving = true;
end

function FactionsGUI:RestoreLayout(name, layout) -- Overwrite Layout
	ISLayoutManager.DefaultRestoreWindow(self, layout)
end

function FactionsGUI:SaveLayout(name, layout) -- Overwrite Layout Save
	ISLayoutManager.DefaultSaveWindow(self, layout)
end

function FactionsGUI:new(titleText, factionText, buttonText, faction, team) -- Instanciate the FactionsGUI
	-- Creating the object to save the GUI
	local o = {}

	-- Instanciate the Panel
	o = ISPanel:new(0, 0, 0, 0);
	setmetatable(o, self)
	self.__index = self

	-- Instanciating the Size and Position
	o.height = 100;                             -- Size
	o.width = 400;                              -- Size
	o.x = 30;                                   -- Position
	o.y = (getCore():getScreenHeight() - 64 - 65); -- Position

	-- The GUI Color
	o.backgroundColor = { r = 0.05, g = 0.05, b = 0.05, a = 0.2 };
	o.borderColor = { r = 1, g = 1, b = 1, a = 0.1 };

	-- Default Titles
	o.titleText = titleText or getText("UI_Text_SafehouseEmpty");
	o.factionText = factionText or "";

	-- The player Entity
	local player = getPlayer()      -- Getting entity
	o.player = player;              -- Adding the entity player
	o.username = player:getUsername(); -- Player Username
	o.team = team;                  -- If the GUI is on a team safehouse or enemy

	-- Adding the player faction to the gui parameter
	o.faction = faction;

	-- Instanciate Variables
	local square = player:getSquare();
	if o.faction then
		o.owner = o.faction:getOwner();
		o.floors = FactionsMain.getFloorCount(def)
		o.someoneInside = FactionsMain.isSomeoneInside(square, o.faction, o.floors);
	end

	-- Button default text
	o.buttonText = buttonText or getText("UI_Text_SafehouseClaim");
	-- Default button visibility
	o.buttonVisible = true;

	-- Get the player safehouse by position
	o.safehouse = SafeHouse.getSafeHouse(square)

	-- Setting the default variables
	o.timer = FactionsGUI.updateTime;
	o.buttonVisible = true;
	o:setCapture(false);
	o.timestamp = getTimeInMillis();
	o.dragging = true;
	o.internal = "";

	return o
end

function FactionsGUI:startCapture() -- Start the capturing system
	-- Disable button
	self.button:setEnable(false);
	-- Add the message to the disabled button
	self.button:setTooltip(getTextOrNull("UI_Text_SafehouseProgress") or "Capture in progress");
	-- Add the sound for the player
	getSoundManager():PlaySound("baseCaptureStart", false, 1.0)

	-- Add the timer for the capture
	self.badge.timer = FactionsGUI.captureTime;
	self.badge.timestamp = getTimeInMillis()
	self.badge.capture = true;
end

local function OnServerCommand(module, command, arguments)
	--Starting Gui Capture Safehouse
	if module == "ServerSafehouse" and command == "receiveCaptureConfirmation" then
		if arguments.validation then
			FactionsMain.GUI:startCapture();
			getPlayer():Say(getText("UI_Text_SafehouseCapturing"))
		else
			-- SafehousePlus compatibility
			if arguments.reason == "cheat" then
				getPlayer():Say(getText("UI_Text_SafehouseCheat"))
			elseif arguments.reason == "nopoints" then
				getPlayer():Say(getText("UI_Text_SafehouseNoPoints"))
			elseif arguments.reason == "nottime" then
				getPlayer():Say(getText("UI_Text_SafehouseNotTimeCapture"))
			elseif arguments.reason == "protected" then
				getPlayer():Say(getText("UI_Text_SafehouseProtected"))
			else
				getPlayer():Say(getText("UI_Text_SafehouseNotTimeCapture"));
			end
		end
	end
	-- Safehouse Captured Sync
	if module == "ServerSafehouse" and command == "safehouseCaptured" then
		-- Add the sound for the player that capture finish
		getSoundManager():PlaySound("baseCaptureFinish", false, 1.0)
	end

	-- Changing safehouse owner
	if module == "ServerSafehouse" and command == "safehouseCaptureFinish" then
		local player = getPlayer();
		local safehouseBeenCaptured = SafeHouse.getSafeHouse(arguments.X, arguments.Y, arguments.W, arguments.H);

		if not safehouseBeenCaptured then return; end
		local faction = FactionsMain.getFaction(player:getUsername());

		-- Check if player has a faction
		if faction == nil then
			FactionsMain.unloadUI();
			return;
		end;

		-- Check if player is in a safehouse
		if safehouseBeenCaptured == nil then
			FactionsMain.unloadUI();
			return;
		end

		-- IMPORTANT
		-- You cannot do this serverside, probably on the official release it will be different
		safehouseBeenCaptured:setOwner(faction:getOwner());       -- Change owner to the faction owner
		FactionsMain.safehouseRemoveMembers(safehouseBeenCaptured); -- Remove all users from safehouse
		FactionsMain.syncFactionMembers(safehouseBeenCaptured); -- Sync faction members to the safehouse

		-- Update UI
		FactionsMain.unloadUI();
	end

	-- Sync faction members
	if module == "ServerSafehouse" and command == "syncCapturedSafehouse" then
		local safehouse = SafeHouse.getSafeHouse(arguments.safehouseId);
		if safehouse then
			FactionsMain.syncFactionMembers(safehouse);
		end

		-- Reload UI
		FactionsMain.unloadUI()
	end

	-- Update client safehouse owner
	if module == "ServerSafehouse" and command == "syncCapturedOwnerSafehouse" then
		local safehouse = SafeHouse.getSafeHouse(arguments.safehouseId);
		if safehouse then
			safehouse:setOwner(arguments.owner);

			getSoundManager():PlaySound("baseCaptureFinish", false, 1.0);
		end

		-- Reload UI
		FactionsMain.unloadUI()
	end
end
Events.OnServerCommand.Add(OnServerCommand)
