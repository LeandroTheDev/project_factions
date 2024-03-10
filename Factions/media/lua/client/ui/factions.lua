---@diagnostic disable: undefined-global
require "ui/factions_gui"
require "factions_main"

-- Explanation about this file.
-- this file contains the button utils for FactionsGUI

-- Treatment for resolutions change
FactionsMain.onResolutionChange = function()
	if FactionsMain.GUI then
		FactionsMain.GUI:setX(30);
		FactionsMain.GUI:setY(getCore():getScreenHeight() - 129);
	end
end

-- Treatment for getting the safehous from custom sources
local function getSafehouseWithoutBuilding(square)
	local safehouse = SafeHouse.getSafeHouse(square);
	if safehouse then
		for x = safehouse:getX() + 2, safehouse:getX2() - 4 do
			for y = safehouse:getY() + 2, safehouse:getY2() - 4 do
				local sq = getCell():getGridSquare(x, y, 0);
				if sq then
					if sq:getBuilding() then
						return safehouse, false;
					end
				end
			end
		end
	end
	return safehouse, true;
end

FactionsMain.building = nil;
FactionsMain.x = 0;
FactionsMain.y = 0;
-- Creates or destroys UI, if player is inside/outside the safehouse
FactionsMain.update = function()
	local player = getPlayer();
	if player then
		local square = player:getSquare()
		if square then
			-- Treatment for nil safehouses
			local safehouse, isCustom = getSafehouseWithoutBuilding(square);
			local building = square:getBuilding()
			-- Check building does not exist and safehouse is custom
			if isCustom and not building then
				building = safehouse;
			end
			-- Check if player is not dead and the building variable exist
			local allowed = not player:isDead() and building;

			-- Check if gui does not exist and allowed is enabled
			if not FactionsMain.GUI and allowed then
				-- Texts for the buttons
				local safehouseText = nil;
				local factionText = nil;
				local buttonText = nil;

				-- This is the faction of the safehouse the player are in
				local safehouse_faction = nil;
				-- This is the faction of the player
				local player_faction = FactionsMain.getFaction(player:getUsername());

				-- If true this means the safehouse is from your team
				-- false means its a enemy, nil means empty safehouse
				local team = nil;

				-- Add this building to the global variable building
				FactionsMain.building = building;

				-- Check if the safehouse exist
				if safehouse then
					safehouseText = safehouse:getTitle();
					safehouse_faction = FactionsMain.getFaction(safehouse:getOwner());
					-- Check if the faction from the safehouse exist
					if safehouse_faction then
						-- Creates the text
						factionText = getText("UI_Text_LabelFaction") .. tostring(safehouse_faction:getName())
						-- Check if the player faction is them same from the safehouse faction
						if player_faction == safehouse_faction then
							team = true;
							buttonText = FactionsGUI.btnText[3]
						else
							team = false;
							buttonText = FactionsGUI.btnText[2]
						end
					end
				end

				-- Instanciate the Button UI
				FactionsMain.GUI = FactionsGUI:new(safehouseText, factionText, buttonText, player_faction, team);
				FactionsMain.GUI:initialise();
				FactionsMain.GUI:addToUIManager();
				ISLayoutManager.RegisterWindow('FactionsUI', FactionsGUI, FactionsMain.GUI);
				FactionsMain.x, FactionsMain.y = FactionsMain.GUI.x, FactionsMain.GUI.y;
			elseif FactionsMain.GUI and (not allowed or FactionsMain.building ~= building) then
				FactionsMain.building = nil
				-- Save the UI position
				if FactionsMain.x ~= FactionsMain.GUI.x or FactionsMain.y ~= FactionsMain.GUI.y then
					ISLayoutManager.OnPostSave();
				end
				-- Remove the Button UI if exist
				FactionsMain.GUI:removeFromUIManager()
				FactionsMain.GUI = nil;
			end
		end
	end
end

-- Add the event update to the game frame
Events.OnGameStart.Add(function() Events.OnTick.Add(FactionsMain.update); end)
-- Add the event resolution change
Events.OnResolutionChange.Add(FactionsMain.onResolutionChange)

-- Remove the UI if exist
FactionsMain.unloadUI = function()
	-- Check the GUI existence
	if FactionsMain.GUI then
		FactionsMain.GUI:removeFromUIManager()
		FactionsMain.GUI = nil;
	end
end

-- Alert the online players specific behaviours
FactionsMain.alert = function(safehouse, type)
	-- Add the text to the player
	local function addLineToChat(message, color)
		if not isClient() then return end


		local options = {
			showTime = false,
			serverAlert = false,
			showAuthor = false,
		};

		if options.showTime then
			local dateStamp = Calendar.getInstance():getTime();
			local dateFormat = SimpleDateFormat.new("H:mm");
			if dateStamp and dateFormat then
				message = color .. "[" .. tostring(dateFormat:format(dateStamp) or "N/A") .. "]  " .. message;
			end
		else
			message = color .. message;
		end

		local msg = {
			getText = function(_)
				return message;
			end,
			getTextWithPrefix = function(_)
				return message;
			end,
			isServerAlert = function(_)
				return options.serverAlert;
			end,
			isShowAuthor = function(_)
				return options.showAuthor;
			end,
			getAuthor = function(_)
				return tostring(getPlayer():getUsername());
			end,
			setShouldAttractZombies = function(_)
				return false
			end,
			setOverHeadSpeech = function(_)
				return false
			end,
		};

		if not ISChat.instance then return; end;
		if not ISChat.instance.chatText then return; end;
		ISChat.addLineInChat(msg, 0);
	end
	-- Under attack
	if type == 1 then
		addLineToChat(getText("UI_Text_SafehouseUnderAttack", safehouse), "<RGB:" .. "255,0,0" .. ">");
		getSoundManager():PlaySound("baseUnderAttackSound", false, 1.0);
		-- Is being captured
	elseif type == 3 then
		addLineToChat(getText("UI_Text_SafehouseIsBeingCaptured", safehouse), "<RGB:" .. "255,255,0" .. ">");
		getSoundManager():PlaySound("baseCaptureStart", false, 1.0);
	else
		-- Safehouse lost
		if type == 2 then
			addLineToChat(getText("UI_Text_SafehouseWasLost", safehouse), "<RGB:" .. "255,0,0" .. ">");
			-- Safehouse success captured
		elseif type == 4 then
			addLineToChat(getText("UI_Text_SafehouseWasCaptured", safehouse), "<RGB:" .. "0,255,0" .. ">");
		end
		getSoundManager():PlaySound("baseCaptureFinish", false, 1.0);
	end
end

local function OnServerCommand(module, command, arguments)
	-- Receives alerts from the server
	if module == "ServerSafehouse" and command == "alert" then
		FactionsMain.alert(arguments.safehouseName, arguments.type);
	end
end
Events.OnServerCommand.Add(OnServerCommand)
