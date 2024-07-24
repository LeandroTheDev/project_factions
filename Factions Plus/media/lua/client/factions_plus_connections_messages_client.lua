---@diagnostic disable: undefined-global
-- Connection Message
if SandboxVars.FactionsPlus.EnablePlayerJoinMessages then
    local function OnConnected()
        sendClientCommand("ServerMessages", "iconnected", nil);
    end

    Events.OnGameStart.Add(OnConnected);
end

-- Disconnect Message
if SandboxVars.FactionsPlus.EnablePlayerLeaveMessages then
    local function OnDisconnect()
        sendClientCommand("ServerMessages", "idisconnected", nil);
    end

    Events.OnDisconnect.Add(OnDisconnect);
end

-- Add the text to the player
local function addLineToChat(message, color, username, options)
    if not isClient() then return end

    if type(options) ~= "table" then
        options = {
            showTime = false,
            serverAlert = false,
            showAuthor = false,
        };
    end

    if type(color) ~= "string" then
        color = "<RGB:1,1,1>";
    end

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
            return tostring(username);
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

-- Called everytime the server send something to us
local function OnServerCommand(module, command, arguments)
    -- Player connected
    if module == "ServerMessages" and command == "playerconnected" then
        -- Adding a message to it
        addLineToChat(
            arguments.playerUsername .. " " .. getText("IGUI_Player_Connected"), "<RGB:" .. "144,238,144" .. ">");
    end
    -- Player disconnected
    if module == "ServerMessages" and command == "playerdisconnected" then
        -- Adding a message to it
        addLineToChat(
            arguments.playerUsername .. " " .. getText("IGUI_Player_Disconnected"), "<RGB:" .. "255,255,0" .. ">");
    end
    -- Player died
    if module == "ServerMessages" and command == "playerdead" then
        -- Adding a message to it
        addLineToChat(
            arguments.playerUsername .. " " .. getText("IGUI_Player_Dead"), "<RGB:" .. "255,0,0" .. ">");
    end
end
Events.OnServerCommand.Add(OnServerCommand)
