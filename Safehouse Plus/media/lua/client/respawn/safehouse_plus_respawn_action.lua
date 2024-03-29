---@diagnostic disable: undefined-global

SpawnpointAction = ISBaseTimedAction:derive("SpawnpointAction")

function SpawnpointAction:isValid()
    return true;
end

function SpawnpointAction:start()
    self.character:faceThisObject(self.object);
end

function SpawnpointAction:stop()
    ISBaseTimedAction.stop(self);
end

function SpawnpointAction:perform()
    setPlayerRespawn(self.character);
    sendClientCommand("ServerRespawn", "enableSpawn", nil);
    self.character:Say(getText("IGUI_Respawn_SayRespawn"));
    ISBaseTimedAction.perform(self);
end

function SpawnpointAction:new(character, time, object)	
    local o = {};
    setmetatable(o, self);
    self.__index = self;
    o.character = character;
    o.object = object;
    o.stopOnWalk = true;
    o.stopOnRun = true;
    o.maxTime = time;
    return o;
end