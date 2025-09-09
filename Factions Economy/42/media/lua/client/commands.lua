local oldOnCommandEntered = ISChat.onCommandEntered;

function ISChat:onCommandEntered()
    oldOnCommandEntered(self);

    for _, stream in ipairs(ISChat.allChatStreams) do
        if luautils.stringStarts(stream.command, "/") then
            DebugPrintFactionsEconomy("Command executed: " .. stream.command);
        end
    end
end
